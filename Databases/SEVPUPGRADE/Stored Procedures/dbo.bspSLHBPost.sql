SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  procedure [dbo].[bspSLHBPost]
/***********************************************************
* CREATED: SE   5/28/97
* MODIFIED: GG 04/22/99   (SQL 7.0)
*       	GH 01/13/2000 Added update code for notes when @transtype='C' (Notes weren't being updated if changed)
*           GG 05/16/00 - Removed PrevWC and WC columns from bSLIT
*           GF 09/15/2000 - Put back section to add compliance group when interfaced from PM.
*           GR 09/15/00 - added attachments code
*           kb 12/14/00 - issue #11647
*           GF 02/10/2001 - change the update to PMSL interface date to be more restrictive.
*           DANF 03/27/2001 - Added AddedMth and AddedBatchID
*           bc 06/12/01 - issue # 13730
*			RM 02/22/02 - Updated for changes in attachment process
*           CMW 03/15/02 - issue # 16503 JCCP column name changes.
*           kb 3/20/2 - issue #16614
*           CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*			GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*			GG 06/11/02 - #17564 - insert bJCCD.PostedUnits = 0
*			MV 02/11/03	 - #17821 - add compliance code if bHQCP.AllInvoiceYN='N'
*			MV 03/06/03 - #20094 - commented out bSLCT insert code so btSLHD update trigger handles it.
*			MV 06/05/03 - #21422 - can change status from closed to complete, null out MthClosed
*			RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
*			RT 12/03/03 - issue 18616, reindex attachments when posting type A or C batches.
*			ES 04/06/04 - #24219 Allow notes to update if null; more efficient SQL
*			DC 04/30/08 - #127181 - Store the batch ID of the SL Close batch in the SLHD table
*			DC 06/25/08 - #128435 - Add taxes to SL
*			DC 10/23/08 - #130749 - Remove Committed Cost Flag
*			GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*			DC 11/10/08 - #130029 - JCCD tax amounts doesn't match SLIT after tax rate change
*			DC 03/04/09 - #129889 - AUS SL - Track Claimed  and Certified amounts
*			DC 05/15/09 - #133440 - Ensure stored procedures/triggers are using the correct attachment delete proc
*			DC 12/24/09 - #130175 - SLIT needs to match POIT
*			DC 02/03/10 - #129892 - Handle max retainage
*			DC 06/25/10 - #135813 - expand subcontract number
*			JG 09/23/10 - TFS #491 - Inclusions/Exclusions Addition
*			JG 10/06/10 - TFS #491 - Inclusions/Exclusions Addition
*			GF 06/29/2011 TK-06515 update to PMSL changes more than one record
*			GF 04/30/2012 TK-14595 #146332 update to PMSL missing PCO pending of item type regular
*			GF 11/09/2012 TK-18033 SL Claim Enhancement. Changed to Use ApprovalRequired
*			TL  01/24/2013 TK-20732 Added code to prevent a change order item from being udpated before the orginal item has been enterfaced
*
*
* USAGE:
* Posts a validated batch of SLHB and SLIB entries
* deletes successfully posted bSLHB and SLIB rows
* clears bSLIA
*
* INPUT PARAMETERS
*   @co           SL Co#
*   @mth          Month of batch
*   @batchid      Batch ID to validate
*   @dateposted   Posting date to write out if successful
*   @source       Batch source
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @source bSource, @errmsg varchar(255) output)

as
set nocount on
    
declare @rcode int, @opencursor tinyint, @tablename char(20), @inuseby bVPUserName,  
	@complied bYN, @keyfield varchar(255), @updatekeyfield varchar(255), @deletekeyfield varchar(128)
    
/*Header declares*/
declare @seq int, @transtype char(1), @sl VARCHAR(30), --bSL, DC #135813
	@jcco bCompany, @job bJob, @description bItemDesc, --bDesc,  DC #135813
	@vendorgroup bGroup, @vendor bVendor, @status tinyint, @holdcode bHoldCode, @payterms bPayTerms,
	@compgroup varchar(10), --@ctdescription bItemDesc, --bDesc,   DC #135813
	@ctverify bYN, @ctexpdate bDate, @ctcomplied bYN,
	@ctseq int, @compcode bCompCode, @origdate bDate, @Notes varchar(256)
    
declare @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @slitem bItem, @oldnew tinyint,
	@itemdesc bItemDesc, @um bUM, @changeunits bUnits, @jcum bUM, @changecost bDollar, @jctrans bTrans,
	@jcunits bUnits, @errorstart varchar(50), @inusebatchid bBatchID, @opencursorSLIA tinyint,@guid uniqueidentifier,
	@taxgroup bGroup, @taxcode bTaxCode, @taxrate bRate, --DC #128435
	@curtax bDollar, @curcost bDollar,  --DC #128435
	@totalcmtdtax bDollar, @remcmtdtax bDollar, --DC #130175
	@maxretgopt char(1), @maxretgpct bPct, @maxretgamt bDollar, @inclacoinmaxyn bYN, @maxretgdiststyle char(1)   --DC #129892
	----TK-18033
	,@ApprovalRequired CHAR(1)

select @rcode = 0, @opencursor = 0, @opencursorSLIA = 0
    
/* check for date posted */
if @dateposted is null
	begin
	select @errmsg = 'Missing posting date!', @rcode = 1
	goto bspexit
	end
    
/* validate HQ Batch */
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'SLHB', @errmsg output, @status output
if @rcode <> 0 goto bspexit
if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
	begin
	select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
	goto bspexit
	end
    
	/* set HQ Batch status to 4 (posting in progress) */
	update bHQBC
	set Status = 4, DatePosted = @dateposted
	where Co = @co and Mth = @mth and BatchId = @batchid
	if @@rowcount = 0
		begin
		select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
		goto bspexit
		end
    
	/* declare cursor on SL Header Batch for validation */
	declare bcSLHB cursor for
	select BatchSeq, BatchTransType, SL, JCCo, Job, Description, VendorGroup, Vendor,
		HoldCode, PayTerms, CompGroup, Status, OrigDate,UniqueAttchID,
		MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN, MaxRetgDistStyle  --DC #129892
		----TK-18033
		,ApprovalRequired
	from bSLHB
	where Co = @co and Mth = @mth and BatchId = @batchid
    
	/* open cursor */
	open bcSLHB
	/* set open cursor flag to true */
	select @opencursor = 1
    
	/* loop through all rows in SLHB and update their info.*/
	sl_posting_loop:
		fetch next from bcSLHB into @seq, @transtype, @sl, @jcco, @job, @description,
             @vendorgroup, @vendor, @holdcode, @payterms, @compgroup, @status, @origdate, @guid,
             @maxretgopt, @maxretgpct, @maxretgamt, @inclacoinmaxyn, @maxretgdiststyle  --DC #129892
			 ----TK-18033
			 ,@ApprovalRequired
	if @@fetch_status <> 0 goto sl_posting_end
    
	select @errorstart = 'Seq#' + convert(varchar(6),@seq)
    
	BEGIN TRANSACTION
    
	if @transtype = 'A'	/* adding new SL */
		begin
		
		/* insert SL Header */
		insert bSLHD (SLCo, SL, JCCo, Job, Description, VendorGroup, Vendor,
			HoldCode, PayTerms, CompGroup, Status, MthClosed, InUseMth, InUseBatchId, Purge,
			OrigDate, AddedMth, AddedBatchID,Approved,UniqueAttchID, Notes,
			MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN, MaxRetgDistStyle
			----TK-18033
			,ApprovalRequired)
		select @co, @sl, @jcco, @job, @description, @vendorgroup, @vendor,
			@holdcode, @payterms, @compgroup, @status, null, null, null, 'N', @origdate, @mth, 
			@batchid,'Y',@guid, Notes,
			@maxretgopt, @maxretgpct, @maxretgamt, @inclacoinmaxyn, @maxretgdiststyle  --DC #129892
			----TK-18033
			,@ApprovalRequired
		from bSLHB where Co = @co and Mth = @mth and BatchId = @batchid and SL = @sl and Co = @co

		/*now insert all the items from SLIB for this sl */
		insert into bSLIT (SLCo, SL, SLItem, ItemType, Addon, AddonPct, JCCo, Job, PhaseGroup, Phase,
			JCCType, Description, UM, GLCo, GLAcct, WCRetPct, SMRetPct, VendorGroup, Supplier,
			OrigUnits, OrigUnitCost, OrigCost, CurUnits, CurUnitCost, CurCost, StoredMatls,
			InvUnits, InvCost, Notes, AddedMth, AddedBatchID,
			TaxType, TaxCode, TaxGroup,OrigTax, CurTax,  --DC #128435
			JCCmtdTax,  --DC #130029
			JCRemCmtdTax, TaxRate, GSTRate)  --DC #130175
		select Co, @sl, SLItem, ItemType, Addon, AddonPct, JCCo, Job, PhaseGroup, Phase,
			JCCType, Description, UM, GLCo, GLAcct, WCRetPct, SMRetPct, VendorGroup, Supplier,
			OrigUnits, OrigUnitCost, OrigCost, OrigUnits, OrigUnitCost, OrigCost, 0, 0, 0, Notes, @mth, @batchid,
			TaxType, TaxCode, TaxGroup, OrigTax, OrigTax,  --DC #128435
			JCCmtdTax,  --DC #130029
			JCRemCmtdTax, TaxRate, GSTRate  --DC #130175
		from bSLIB
		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
		
		/*now insert all the items from SLIB for this sl */ -- JG TFS# 491
		INSERT INTO vSLInExclusions (Co, SL, Seq, [Type], PhaseGroup, Phase, Detail, DateEntered, 
									EnteredBy, Notes, UniqueAttchID)
		SELECT	b.Co, @sl, b.Seq, b.[Type], b. PhaseGroup, b.Phase, b.Detail, b.DateEntered, 
				b.EnteredBy, b.Notes, b.UniqueAttchID
        FROM vSLInExclusionsBatch b
        WHERE b.Co=@co 
        AND b.Mth=@mth 
        AND b.BatchId=@batchid 
        AND b.BatchSeq=@seq
        
        end
            
	if @transtype = 'C'	/* update existing SLs */
		begin
		update bSLHD
		set JCCo=@jcco, Job=@job, Description=@description, VendorGroup=@vendorgroup, Vendor=@vendor,
			HoldCode=@holdcode, PayTerms=@payterms, CompGroup=@compgroup, Status=@status, OrigDate = @origdate,
			MthClosed = Case @status when 2 then MthClosed else null end,/*0 then null else MthClosed end,*/
			SLCloseBatchID = Case @status when 2 then SLCloseBatchID else null end,  --DC #127181
			Approved='Y',UniqueAttchID=@guid, Notes = b.Notes, 
			MaxRetgOpt = b.MaxRetgOpt, MaxRetgPct = b.MaxRetgPct, MaxRetgAmt = b.MaxRetgAmt, --DC #129892
			InclACOinMaxYN = b.InclACOinMaxYN, MaxRetgDistStyle = b.MaxRetgDistStyle  --DC #129892
			----TK-18033
			,ApprovalRequired = b.ApprovalRequired
		from bSLHD d
			join bSLHB b on d.SLCo=b.Co and b.SL=d.SL
		where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@seq 

		if @@rowcount = 0
			begin
			select @errmsg = @errorstart + ': Unable to update SL Header.', @rcode = 1
			goto sl_posting_error
			end

		/* first insert any new items to this changed Header.*/
		insert into bSLIT (SLCo, SL, SLItem, ItemType, Addon, AddonPct, JCCo, Job,
			PhaseGroup, Phase, JCCType, Description, UM, GLCo, GLAcct, WCRetPct, SMRetPct,
			VendorGroup, Supplier, OrigUnits, OrigUnitCost, OrigCost, CurUnits, CurUnitCost,
			CurCost, StoredMatls, InvUnits, InvCost, Notes, AddedMth, AddedBatchID,
			TaxType, TaxCode, TaxGroup,OrigTax, CurTax,  --DC #128435
			JCCmtdTax,  --DC #130029
			JCRemCmtdTax, TaxRate, GSTRate)  --DC #130175			
		select Co, @sl, SLItem, ItemType, Addon, AddonPct, JCCo, Job,
			PhaseGroup, Phase, JCCType, Description, UM, GLCo, GLAcct, WCRetPct, SMRetPct,
			VendorGroup, Supplier, OrigUnits, OrigUnitCost, OrigCost, OrigUnits, OrigUnitCost,
			OrigCost, 0, 0, 0, Notes, @mth, @batchid,
			TaxType, TaxCode, TaxGroup, OrigTax, OrigTax,  --DC #128435
			JCCmtdTax,  --DC #130029
			JCRemCmtdTax, TaxRate, GSTRate  --DC #130175
		from bSLIB
		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and BatchTransType = 'A'
		
		/* first insert any new Inclusions/Exclusions to this changed Header.*/ -- JG TFS# 491
		INSERT INTO vSLInExclusions (Co, SL, Seq, [Type], PhaseGroup, Phase, Detail, DateEntered, 
									EnteredBy, Notes, UniqueAttchID)
		SELECT	b.Co, @sl, b.Seq, b.[Type], b.PhaseGroup, b.Phase, b.Detail, b.DateEntered, 
				b.EnteredBy, b.Notes, b.UniqueAttchID
        FROM vSLInExclusionsBatch b
        WHERE b.Co=@co 
        AND b.Mth=@mth 
        AND b.BatchId=@batchid 
        AND b.BatchSeq=@seq 
        AND BatchTransType = 'A'
		
		/* now update all the items that were changed */
		update bSLIT
		set ItemType=b.ItemType, Addon=b.Addon, AddonPct=b.AddonPct, JCCo=b.JCCo, Job=b.Job,
			PhaseGroup=b.PhaseGroup, Phase=b.Phase, JCCType=b.JCCType, Description=b.Description,
			UM=b.UM, GLCo=b.GLCo, GLAcct=b.GLAcct, WCRetPct=b.WCRetPct, SMRetPct=b.SMRetPct,
			VendorGroup=b.VendorGroup, Supplier=b.Supplier, OrigUnits=b.OrigUnits, OrigUnitCost=b.OrigUnitCost,
			OrigCost=b.OrigCost,				
			CurUnits=CASE when (d.CurUnits=d.OrigUnits and d.CurCost=d.OrigCost)
						THEN b.OrigUnits ELSE d.CurUnits - b.OldOrigUnits + b.OrigUnits END,
			CurUnitCost=CASE when (d.CurUnits=d.OrigUnits and d.CurCost=d.OrigCost)
						THEN b.OrigUnitCost ELSE d.CurUnitCost   END,
			--DC #128435 Added Taxrate to CurCost calculation
			CurCost=CASE when (d.CurUnits=d.OrigUnits and d.CurCost=d.OrigCost)
					THEN b.OrigCost ELSE 
						case b.UM when 'LS' then d.CurCost - b.OldOrigCost + b.OrigCost else
							(d.CurUnits - b.OldOrigUnits + b.OrigUnits) *
							(d.CurUnitCost - b.OldOrigUnitCost + b.OrigUnitCost) end END,
			--DC #128435
			CurTax = (b.TaxRate * --DC #130175 (dbo.vfHQTaxRate(b.TaxGroup, b.TaxCode, h.OrigDate)*  
					(CASE when (d.CurUnits=d.OrigUnits and d.CurCost=d.OrigCost) THEN b.OrigCost ELSE 
						case b.UM when 'LS' then d.CurCost - b.OldOrigCost + b.OrigCost else
							(d.CurUnits - b.OldOrigUnits + b.OrigUnits) *
							(d.CurUnitCost - b.OldOrigUnitCost + b.OrigUnitCost) end END)),				
			Notes=b.Notes,
			TaxType=b.TaxType, TaxCode=b.TaxCode,TaxGroup=b.TaxGroup,OrigTax=b.OrigTax, --DC #128435
			JCCmtdTax = b.JCCmtdTax, --DC #130029				
			JCRemCmtdTax = b.JCRemCmtdTax, TaxRate = b.TaxRate, GSTRate = b.GSTRate  --DC #130175
		from bSLIT d
			join SLHB h on h.Co = d.SLCo and d.SL = h.SL
			join SLIB b on d.SLCo = b.Co and d.SLItem = b.SLItem and b.Co = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId and b.BatchSeq = h.BatchSeq
		where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@seq and d.SL=@sl and b.BatchTransType='C'
		
		
		/* now update all the Inclusions/Exclusions that were changed */ -- JG TFS# 491
		UPDATE i
		SET i.[Type]=b.[Type], i.PhaseGroup=b.PhaseGroup, i.Phase=b.Phase, i.Detail=b.Detail, i.DateEntered = b.DateEntered, 
		i.EnteredBy=b.EnteredBy, i.Notes=b.Notes, i.UniqueAttchID=b.UniqueAttchID
		FROM  vSLInExclusions i
			  JOIN vSLInExclusionsBatch b	ON	b.Co = i.Co
											AND b.Seq = i.Seq
		WHERE i.Co = @co
		AND i.SL = @sl
		AND b.Mth = @mth
		AND b.BatchId = @batchid
		AND b.BatchSeq = @seq
		AND b.BatchTransType = 'C'
		
		/*Finally delete any items that were marked for deletion of the changed batch*/
		delete bSLIT
		from bSLIT d
			join bSLIB b on d.SLCo=b.Co and d.SLItem = b.SLItem
		where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@seq and d.SL=@sl and b.BatchTransType='D'
		
		/* Finally delete any Inclusions/Exclusions that no longer exist.*/ -- JG TFS# 491
		DELETE i
		FROM vSLInExclusions i
			  JOIN vSLInExclusionsBatch b	ON	b.Co = i.Co
											AND b.Seq = i.Seq
		WHERE i.Co = @co
		AND i.SL = @sl
		AND b.Mth = @mth
		AND b.BatchId = @batchid
		AND b.BatchSeq = @seq
		AND b.BatchTransType = 'D'
		
		end
    
	if @transtype = 'D'	/* delete existing Subcontract, all Items, and all Inclusions/Exclusions */
		begin
		
		/*first delete all inclusions/exclusions*/  -- JG TFS# 491
		DELETE vSLInExclusions
		FROM vSLInExclusions i
			JOIN vSLInExclusionsBatch b	ON i.Co=b.Co
										AND i.Seq=b.Seq
		WHERE b.Co=@co AND b.Mth=@mth AND b.BatchId=@batchid
		AND b.BatchSeq=@seq AND i.SL=@sl									
		
		/*then delete all items*/
		delete bSLIT
		from bSLIT d
		join bSLIB b on d.SLCo=b.Co and d.SLItem = b.SLItem
		where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@seq
		 and d.SL=@sl and b.BatchTransType='D'

		/* now delete the Header */
		delete bSLHD where SLCo=@co and SL=@sl

		end
    
	-- update Interface date in PM if source is PM Intface
	if @source = 'PM Intface' --or @transtype = 'C' -- issue #16614 added the @transtype part
		begin
		-- update original records in PMSL, set interface date
		update dbo.bPMSL set InterfaceDate=@dateposted, IntFlag = NULL
		from dbo.bPMSL p join dbo.bSLIB s on p.SLCo=s.Co and p.SLItem=s.SLItem
		where p.SLCo=@co AND p.Project=s.Job
			AND p.SL=@sl 
			AND p.SLItem=s.SLItem 
			AND s.Co=@co 
			AND s.Mth=@mth 
			AND s.BatchId=@batchid
			AND s.BatchSeq=@seq 
			AND p.Vendor is not null 
			AND p.InterfaceDate is null 
			AND p.SendFlag='Y'
			---- TK-06515
			AND p.SubCO IS NULL
			----TK-14595
			AND p.Phase = s.Phase
			AND p.CostType = s.JCCType
			--AND (p.RecordType='O' OR (p.RecordType = 'C' AND (p.ACO IS NOT NULL OR p.PCO IS NOT NULL)))
			AND (p.RecordType='O' 
				    OR (p.RecordType = 'C' AND p.ACO IS NOT NULL)
				    OR (p.RecordType = 'C' AND p.PCO IS NOT NULL 
							AND  NOT EXISTS(SELECT 1 FROM dbo.bPMSL b
							where b.PMCo = p.PMCo
							and b.Project = p.Project
							AND b.SLCo = p.SLCo
							AND b.SL = p.SL
							AND b.SLItem = p.SLItem
							AND b.SendFlag='Y' 
							AND b.InterfaceDate is NULL
							AND b.SubCO IS NULL
							AND b.RecordType = 'O')))
			

		-- update change order records in PMSL, set interface date and record type
		update dbo.bPMSL set InterfaceDate=@dateposted, IntFlag=Null
		from dbo.bPMSL p join dbo.bSLIB s on p.SLCo=s.Co and p.SLItem=s.SLItem
		where p.SLCo=@co and p.Project=s.Job
			AND p.SL=@sl 
			AND p.SLItem=s.SLItem 
			AND s.Co=@co 
			AND s.Mth=@mth 
			AND s.BatchId=@batchid
			AND s.BatchSeq=@seq 
			AND p.Vendor is not null 
			AND p.InterfaceDate is null 
			AND p.SendFlag='Y' 
			AND p.IntFlag='I'  
			---- TK-06515
			AND p.SubCO IS NOT NULL
			----TK-14595
			AND p.Phase = s.Phase
			AND p.CostType = s.JCCType

		
		end --PM SL Interface section

	
	if @transtype <> 'D'
		begin
		exec @rcode = bspBatchUserMemoUpdate @co , @mth , @batchid , @seq, 'SL Inclusions/Exclusions' , @errmsg output
		if @rcode <> 0 goto sl_posting_error
		end
    
	/*Remove SLInExclusionsBatch records*/
	delete from vSLInExclusionsBatch where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq        

	if @transtype <> 'D'
		begin
		exec @rcode = bspBatchUserMemoUpdate @co , @mth , @batchid , @seq, 'SL Entry Items' , @errmsg output
		if @rcode <> 0 goto sl_posting_error
		end
    
	/*Remove SLIB records*/
	delete from bSLIB where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
    
	if @transtype <> 'D'
		begin
		exec @rcode =  bspBatchUserMemoUpdate @co , @mth , @batchid , @seq, 'SL Entry', @errmsg output
		if @rcode <> 0 goto sl_posting_error
		end
    
	/* delete current row from cursor */
	delete from bSLHB where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
    
	/* commit transaction */
	commit transaction
   
   	--issue 18616
   	if @transtype in ('A','C')
   		begin
   		if @guid is not null
   			begin
   			exec @rcode = bspHQRefreshIndexes null, null, @guid, null
   			end
   		end
   
	goto sl_posting_loop
    
     sl_posting_error:		/* error occured within transaction - rollback any updates and continue */
         rollback transaction
         goto bspexit
    
     sl_posting_end:			/* no more rows to process */
         if @opencursor=1
             begin
             close bcSLHB
             deallocate bcSLHB
             select @opencursor=0
             end
    
      /* make sure batch is empty */
      if exists(select * from bSLHB where Co = @co and Mth = @mth and BatchId = @batchid)
         begin
         select @errmsg = 'Not all Subcontract entries were posted - unable to close batch!', @rcode = 1
         goto bspexit
         end
    
      if exists(select * from bSLIB where Co = @co and Mth = @mth and BatchId = @batchid)
         begin
         select @errmsg = 'Not all Subcontract item entries were posted - unable to close batch!', @rcode = 1
         goto bspexit
        end
        
	  if exists(select * from vSLInExclusionsBatch where Co = @co and Mth = @mth and BatchId = @batchid)
         begin
         select @errmsg = 'Not all Subcontract inclusions/exclusions entries were posted - unable to close batch!', @rcode = 1
         goto bspexit
        end
    
	jc_update:	/* update JC Using entries from bSLIA */    
		/* declare cursor on SL JC Distribution Batch for posting */
		declare bcSLIA cursor for
		select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, SLItem, OldNew, SL, Description,
			VendorGroup, Vendor, UM, ChangeUnits, ChangeCost, JCUM, JCUnits,
			TotalCmtdTax, RemCmtdTax  --DC #130175
		from bSLIA
		where SLCo = @co and Mth = @mth and BatchId = @batchid
    
		/* open cursor */
		open bcSLIA
		select @opencursorSLIA = 1
    
		/* loop through all rows in this batch */
		jc_posting_loop:
		fetch next from bcSLIA into @jcco, @job, @phasegroup, @phase, @jcctype, @seq,
			@slitem, @oldnew, @sl, @itemdesc, @vendorgroup, @vendor, @um, @changeunits,
			@changecost, @jcum, @jcunits,
			@totalcmtdtax, @remcmtdtax  --DC #130175
		
		if @@fetch_status <> 0 goto jc_posting_loop_end
    
		BEGIN TRANSACTION
    
		if @changeunits <> 0 or @changecost <> 0
			begin
			/* get next available transaction # for JCCD */
			exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
			if @jctrans = 0
				begin
				select @errmsg = isnull(@errmsg,'') + ': Error in JC Update seq: ' + convert(varchar(5), @seq), @rcode = 1
				goto jc_posting_error
				end

			insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
				JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, PostTotCmUnits, PostRemCmUnits,
				UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost, VendorGroup, Vendor, APCo, SL, SLItem,
				TotalCmtdTax, RemCmtdTax)  --DC #130175)
			values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @dateposted,
				'SL', @source, @itemdesc, @batchid, @um, 0, @changeunits, @changeunits,
				@jcum, @jcunits, @changecost, @jcunits, @changecost, @vendorgroup, @vendor, @co, @sl, @slitem,
				@totalcmtdtax, @remcmtdtax)  --DC #130175)
			end
               			
			/* delete current row from cursor */
			delete bSLIA
			where SLCo = @co and Mth = @mth and BatchId = @batchid and JCCo=@jcco and Job=@job
				and PhaseGroup=@phasegroup and Phase=@phase and JCCType=@jcctype and BatchSeq=@seq
				and SLItem=@slitem and OldNew=@oldnew
      	    if @@rowcount <> 1
				begin
				select @errmsg = 'Error removing batch sequence ' + convert(varchar(10), @seq) + ' from batch.'
				goto jc_posting_error
       	        end
    
			/* commit transaction */
			COMMIT TRANSACTION
			goto jc_posting_loop
    
         jc_posting_error:
             ROLLBACK TRANSACTION
             select @rcode = 1
             goto bspexit
    
         jc_posting_loop_end:
             if @opencursorSLIA=1
                 begin
                 close bcSLIA
                 deallocate bcSLIA
                 select @opencursorSLIA=0
                 end
    
     /* make sure batch is empty */
     if exists(select * from bSLIA with (nolock) where SLCo = @co and Mth = @mth and BatchId = @batchid)
         begin
         select @errmsg = 'Not all job cost batch entries were posted - unable to close batch!', @rcode = 1
         goto bspexit
         end
    
    -- set interface levels note string
    select @Notes=Notes 
    from bHQBC
    where Co = @co and Mth = @mth and BatchId = @batchid
    if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
		select @Notes=@Notes + 'JC Interface set at: Y' 
    
	/* delete HQ Close Control entries */
	delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
    
	/* set HQ Batch status to 5 (posted) */
	update bHQBC
	set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
	where Co = @co and Mth = @mth and BatchId = @batchid
	if @@rowcount = 0
		begin
      	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
      	goto bspexit
      	end
    
     bspexit:
      	if @opencursor = 1
      		begin
      		close bcSLHB
      		deallocate bcSLHB
      		end
      	if @opencursorSLIA = 1
      		begin
      		close bcSLIA
      		deallocate bcSLIA
      		end
    
        if @rcode<>0 select @errmsg=isnull(@errmsg,'') + char(13) + char(10) + '[bspSLHBPost]'
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLHBPost] TO [public]
GO
