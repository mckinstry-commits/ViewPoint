SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    procedure [dbo].[bspPOCBPost]
/************************************************************************
* Created: ??
* Modified by: GG 04/22/99  (SQL 7.0)
*              GG 11/12/99 - Cleanup
*              GR 08/24/00 - Added notes file into POCD table issue#10297
*              GR 09/27/00 - Added code for document attachments
*              GF 02/10/2001 - Changed update to PMMF interface date to be more restrictive
*              DANF 05/30/01 - Added Error check to insert of detail.
*              MV 6/14/01 - Issue 12769 BatchUserMemoUpdate
*              TV/RM 02/22/02 Attachment Fixin
*              CMW 03/15/02 - Issue # 16503
*              CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*				GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*				GG 06/11/02 - #17565 - set bJCCD.PostedUnits = 0
*				GF 06/13/02 - #17573 - check bPMMF for interfaced record, if found remove interface date.
*				SR 06/18/02 (Issue 11657) - get the next Seq number from POCD
*				GF - 02/03/2003 - issue #20058 need to set INMT.AuditYN back to INCO.AuditMatl
*				MV 10/14/03 - #22320 - insert ChgTotCost from bPOCB to bPOCD
*				RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
*				RT 12/04/03 - #18616, Reindex attachments after posting A or C records.
*				ES 04/07/04 - #24219 Allow Notes to be updated to NULL, and simplify code.
*				MV 07/22/04 - #24999 for update to bPOCD join on POTrans not ChangeOrder
*				MV 02/14/05 - #27089 - include Mth in POCD update join
*				DC 01/24/08 - #121529 - Increase the description to 60.
*				DC 02/11/08 - #120588  - When a PO change order is modified in PO Change Order Entry, modify the data in PMMF
*				DC 04/29/08 - #120634 - Add a column to POCD for ChgToTax
*				DC 09/25/08 - #120803 - JCCD committed cost not updated w/ tax rate change
*				DC 10/21/08 - #128052 - Remove Committed Cost Flag
*				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*		TJL 04/06/09 - Issue #131500, When trans added back for Change, JC Committed not recognizing GST when reversing old value
*				DC 5/18/09 - #133438 - Ensure stored procedures/triggers are using the correct attachment delete proc
*				DC 10/8/09 - #122288 - Store tax rate in POItem
*				GF 05/10/2010 - issue #139509 - use PO Month and PO Trans when deleting and updating PMMF.
*				DAN SO 04/01/2011 - TK-03816 - New POCONum field added (PO Change Order Number -> link to PM PO Change Order)
*				GF 05/23/2011 - TK-05347
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				GF 07/30/2011 - TK-07650 PO Item Line enhancement
*				GF 12/20/2011 TK-10927 update to PMMF for PM Interface records by POCONum
*				GF 01/22/2012 TK-11964 TK-12013 #145600 #145627
*				GF 10/09/2012 TK-18382 147184 display pending POCO for interface if approved
*
*
*
* Posts a validated batch of PO Change Order entries
* Deletes successfully posted bPOCB rows and clears bHQCC when complete
*
* Inputs:
*   @co             PO Company
*   @mth            Batch month
*   @batchid        Batch ID
*   @dateposted     Posting Date
*   @source         Source - 'PO Change' or 'PM Intface'
*
* returns 1 and message if error
*************************************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @source bSource, @errmsg varchar(255) output)
   
 as
 set nocount on
   
declare @rcode int, @POCBopencursor tinyint, @POCAopencursor tinyint, @POCIopencursor tinyint, @status tinyint,
	@errorstart varchar(60), @taxgroup bGroup, @taxcode bTaxCode, @taxrate bRate, @factor smallint,
	@jctrans bTrans, @guid uniqueIdentifier, @Notes varchar(256), @COSeq int 
   
     -- POCB declares
declare @seq int, @transtype char(1), @potrans bTrans, @po varchar(30), @poitem bItem, @changeorder varchar(10),
	@actdate bDate, @description bItemDesc, @um bUM, @changecurunits bUnits, @chgcurunitcost bUnitCost, @ecm bECM,
	@changecurcost bDollar, @changebounits bUnits, @changebocost bDollar, @oldpo varchar(30), @oldpoitem bItem,
	@oldactdate bDate, @oldum bUM, @oldchgcurunits bUnits, @oldcurunitcost bUnitCost, @oldecm bECM,
	@oldchgcurcost bDollar, @oldchgbounits bUnits, @oldchgbocost bDollar, @keyfield varchar(128),
	@updatekeyfield varchar(128), @deletekeyfield varchar(128), @chgtotcost bDollar,
	@chgtotax bDollar,  --DC #120634
	@totalcmtdtax bDollar, @remcmtdtax bDollar, --DC #122288
	@POCONum smallint --TK-03816
   
     -- POCA declares
declare @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @oldnew tinyint,
		@vendorgroup bGroup, @vendor bVendor, @matlgroup bGroup, @material bMatl, @pounits bUnits, @jcum bUM,
		@cmtdunits bUnits, @totalcmtdcost bDollar, @remaincmtdcost bDollar, @recvdninvd bDollar,
		----TK-07650
		@POITKeyID BIGINT, @OldItemUC bUnitCost
   
     -- POCI declares
declare @inco bCompany, @loc bLoc, @onorder bUnits

SET @rcode = 0
   
	/* check for date posted */
	if @dateposted is null
		begin
		select @errmsg = 'Missing posting date!', @rcode = 1
		goto bspexit
		end
   
	/* validate HQ Batch */
	exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'POCB', @errmsg output, @status output
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
   
	-- use a cursor to process PO Change Order batch entries
	declare bcPOCB cursor for
	select BatchSeq, BatchTransType, POTrans, PO, POItem, ChangeOrder, ActDate, Description,
		UM, ChangeCurUnits, CurUnitCost, ECM, ChangeCurCost, ChangeBOUnits, ChangeBOCost,
		OldPO, OldPOItem, OldActDate, OldUM, OldCurUnits, OldUnitCost, OldECM, OldCurCost, OldBOUnits, OldBOCost,
		UniqueAttchID, ChgTotCost,
		ChgToTax,  --DC #120634
		POCONum  --TK-03816
	from bPOCB with (nolock)
	where Co = @co and Mth = @mth and BatchId = @batchid
   
	open bcPOCB
	select @POCBopencursor = 1      -- set open cursor flag
   
	-- loop through all entries in the batch
	POCB_loop:
	fetch next from bcPOCB into @seq, @transtype, @potrans, @po, @poitem, @changeorder,
		@actdate, @description, @um, @changecurunits, @chgcurunitcost, @ecm,
		@changecurcost, @changebounits, @changebocost, @oldpo, @oldpoitem, @oldactdate, @oldum,
		@oldchgcurunits, @oldcurunitcost, @oldecm, @oldchgcurcost, @oldchgbounits, @oldchgbocost,
		@guid, @chgtotcost, 
		@chgtotax,  --DC #120634
		@POCONum  --TK-03816
		
	if @@fetch_status <> 0 goto POCB_end
   
	select @errorstart = 'PO Change Batch Seq# ' + convert(varchar(6),@seq)
   
	begin transaction
   
	--Issue 11657
	select @COSeq=isnull(MAX(Seq),0) 
	from POCD with (nolock) 
	where POCo=@co and PO=@po and POItem=@poitem
	
	select @COSeq=@COSeq + 1
   
	if @transtype = 'A'	   -- add PO Change Order
		begin
 		-- get next available transaction # for bPOCD
 		exec @potrans = bspHQTCNextTrans 'bPOCD', @co, @mth, @errmsg output
 		if @potrans = 0
			begin
			select @errmsg = @errorstart + ' - ' + isnull(@errmsg,''), @rcode = 1
			goto POCB_posting_error
            end

 		-- add PO Change Detail
		--ES 04/07/04 - Issue 24219
 		insert bPOCD (POCo, Mth, POTrans, PO, POItem, ChangeOrder, ActDate, Description, UM, ChangeCurUnits,
 				CurUnitCost, ECM, ChangeCurCost, ChangeBOUnits, ChangeBOCost, PostedDate, BatchId, InUseBatchId,
           		UniqueAttchID, Seq, ChgTotCost, Notes,
				ChgToTax,  --DC #120634
				POCONum)   --TK-03816
		select @co, @mth, @potrans, @po, @poitem, @changeorder, @actdate, @description, @um, @changecurunits,
 				@chgcurunitcost, @ecm, @changecurcost, @changebounits, @changebocost, @dateposted, @batchid, null,
           		@guid, @COSeq, @chgtotcost, Notes,
				@chgtotax,  --DC #120634
				@POCONum --TK-03816
		from bPOCB
		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
		if @@rowcount <> 1
			begin
            select @errmsg = @errorstart + ' - Error inserting PO Change Order Detail.', @rcode = 1
            goto POCB_posting_error
            end

		--update potrans# in the batch record for BatchUserMemoUpdate
		update bPOCB set POTrans = @potrans
		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   
		end
        	   
	if @transtype = 'C'	   -- update
		begin
             -- update PO Change Detail
   			--ES 04/07/04 Issue 24219
     	update bPOCD
     	set PO = @po, POItem = @poitem, ChangeOrder = @changeorder, ActDate = @actdate, Description = @description,
                 UM = @um, ChangeCurUnits = @changecurunits, CurUnitCost = @chgcurunitcost, ECM = @ecm,
                 ChangeCurCost = @changecurcost, ChangeBOUnits = @changebounits, ChangeBOCost = @changebocost,
                 BatchId = @batchid, PostedDate = @dateposted, InUseBatchId = null, UniqueAttchID = @guid,
   				 ChgTotCost = @chgtotcost, Notes = b.Notes, 
				 ChgToTax = @chgtotax,  --DC #120634
				 POCONum = @POCONum --TK-03816
   		from bPOCD d
		join bPOCB b on d.POCo=b.Co and b.PO=d.PO and b.POItem=d.POItem and b.Mth=d.Mth and b.POTrans = d.POTrans 
        where b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.BatchSeq=@seq
     		
		if @@rowcount <> 1
			begin
			select @errmsg = @errorstart + '- Unable to update PO Change Detail!', @rcode = 1
			goto POCB_posting_error
			end

		--DC #120588 TK-05347
		if exists(select TOP 1 1 from bPMMF WITH (NOLOCK) where POCo=@co and POMth=@mth and POTrans=@potrans)
			BEGIN
			----TK-18382
			UPDATE bPMMF 
			SET MtlDescription = b.Description,
				Units = b.ChangeCurUnits, Notes = b.Notes,
				UnitCost = b.CurUnitCost, Amount = b.ChangeCurCost
			from bPMMF d join bPOCB b on d.POCo=b.Co and d.POMth=b.Mth and d.POTrans=b.POTrans
			where d.POCo=@co and d.POMth=@mth and d.POTrans=@potrans
			END
		end
   
	if @transtype = 'D'    	-- delete
		begin   
		-- remove PO Change Detail
		delete bPOCD where POCo = @co and Mth = @mth and POTrans = @potrans
		if @@rowcount <> 1
			begin
			select @errmsg = @errorstart + ' - Unable to delete PO Change Detail transaction!', @rcode = 1
			goto POCB_posting_error
			end
   		
   		----TK-18382
        ---- update bPMMF set interface date to null for deleted record
		update bPMMF 
				set InterfaceDate=null, SendFlag='N', POMth = null, POTrans = NULL
		WHERE POCo=@co 
			AND POMth=@mth
			AND POTrans=@potrans
		--from bPMMF d join bPOCB b on d.POCo=b.Co and d.POMth=b.Mth and d.POTrans=b.POTrans
		--	where d.POCo=@co and d.PO=@po and d.POItem=@poitem and d.SendFlag='Y' and d.InterfaceDate is not null
		--	--/*and d.RecordType='C'*/ and d.ACO=@changeorder
		--	END
		end
      
	if @transtype in ('C','D')      -- back out 'old' values from PO Item
		BEGIN
		-- get Tax info from PO Item
		select  @taxgroup = TaxGroup, @taxcode = TaxCode,
				----DC #122288
				@taxrate = TaxRate, @POITKeyID = KeyID
		from dbo.bPOIT with (nolock)
		where POCo = @co and PO = @oldpo and POItem = @oldpoitem
		if @@rowcount = 0
			begin
			select @errmsg = @errorstart + ' - Invalid PO Item - unable to update!', @rcode = 1
			goto POCB_posting_error
			end

		-- get unit cost factor
		select @factor = case @oldecm when 'C' then 100 when 'M' then 1000 else 1 END

		---- TK-07650 update POIT with unit cost change first
		SET @OldItemUC = 0
		update dbo.bPOIT
			SET @OldItemUC = CurUnitCost,
				CurUnitCost = CASE UM WHEN 'LS' THEN 0
							  ELSE (CurUnitCost - @oldcurunitcost)
							  END,
				PostedDate = @dateposted
		WHERE KeyID=@POITKeyID
		IF @@ROWCOUNT <> 1
			begin
			select @errmsg = @errorstart + ' - Unable to update PO Item values!', @rcode = 1
			goto POCB_posting_error
			END

--DECLARE @LineBOUnits bUnits
--SELECT @LineBOUnits = BOUnits
--FROM dbo.vPOItemLine
--WHERE POITKeyID=@POITKeyID
--	AND POItemLine = 1
--SELECT @errmsg = dbo.vfToString(@oldchgbounits) + ',' + dbo.vfToString(@LineBOUnits)
--SET @rcode = 1
--GOTO POCB_posting_error

		----TK-07650 update PO Item line values - back out 'old' values
		UPDATE dbo.vPOItemLine
			SET CurUnits	= CASE item.UM WHEN 'LS' THEN 0
							  ELSE (line.CurUnits - @oldchgcurunits)
							  END,
				CurCost		= CASE item.UM WHEN 'LS' THEN (line.CurCost - @oldchgcurcost)
							  ELSE ((line.CurUnits - @oldchgcurunits) * (@OldItemUC - @oldcurunitcost)) / @factor
							  END,
				CurTax		= CASE item.UM WHEN 'LS' THEN ((line.CurCost - @oldchgcurcost) * @taxrate)
							  ELSE (((line.CurUnits - @oldchgcurunits) * (@OldItemUC - @oldcurunitcost)) / @factor) * @taxrate
							  END,     			                      
				BOUnits		= CASE item.UM WHEN 'LS' THEN 0
							  ELSE line.BOUnits - @oldchgbounits
							  END,
				BOCost		= CASE item.UM WHEN 'LS' THEN (line.BOCost - @oldchgbocost)
							  ELSE 0
							  END,
				PostedDate = @dateposted,
				---- so trigger will not update JC
				LineDelete = 'C'
		FROM dbo.vPOItemLine line
		INNER JOIN dbo.bPOIT item ON item.KeyID=line.POITKeyID
		WHERE line.POITKeyID=@POITKeyID
			AND line.POItemLine = 1
		IF @@ROWCOUNT <> 1
			begin
			select @errmsg = @errorstart + ' - Unable to update (old) PO Item line values!', @rcode = 1
			goto POCB_posting_error
			end

		--update bPOIT
		--set CurUnits = case UM when 'LS' then 0 else (CurUnits - @oldchgcurunits) end,
  --   			CurUnitCost = case UM when 'LS' then 0 else (CurUnitCost - @oldcurunitcost) end,
  --   			CurCost = case when UM = 'LS' then (CurCost - @oldchgcurcost) else
  --   			     ((CurUnits - @oldchgcurunits) * (CurUnitCost - @oldcurunitcost)) / @factor end,
  --              CurTax = case UM when 'LS' then ((CurCost - @oldchgcurcost) * @taxrate) else
  --                   (((CurUnits - @oldchgcurunits) * (CurUnitCost - @oldcurunitcost)) / @factor) * @taxrate end,
  --   			BOUnits = case UM when 'LS' then 0 else (BOUnits - @oldchgbounits) end,
  --   			BOCost = case UM when 'LS' then (BOCost - @oldchgbocost) else 0 end,
  --   			---- TK-07650
  --   			PostedDate = @dateposted
		--where POCo = @co and PO = @oldpo and POItem = @oldpoitem
		--if @@rowcount <> 1
		--	begin
		--	select @errmsg = @errorstart + ' - Unable to update (old) PO Item values!', @rcode = 1
		--	goto POCB_posting_error
		--	end
		END
   
	if @transtype in ('A','C')      -- update PO Item with 'new' values
		begin
		-- get Tax info from PO Item
		select  @taxgroup = TaxGroup, @taxcode = TaxCode,
				----DC #122288
				@taxrate = TaxRate, @POITKeyID = KeyID
		from dbo.bPOIT with (nolock)
		where POCo = @co and PO = @po and POItem = @poitem
		if @@rowcount = 0
			begin
			select @errmsg = @errorstart + ' - Invalid PO Item - unable to update!', @rcode = 1
			goto POCB_posting_error
			end
			
		-- get unit cost factor
		select @factor = case @ecm when 'C' then 100 when 'M' then 1000 else 1 end

		---- TK-07650 update POIT with unit cost change first
		SET @OldItemUC = 0
		update dbo.bPOIT
			SET @OldItemUC = CurUnitCost,
				CurUnitCost = CASE UM WHEN 'LS' THEN 0
							  ELSE (CurUnitCost + @chgcurunitcost)
							  END,
				PostedDate = @dateposted
		WHERE KeyID=@POITKeyID
		IF @@ROWCOUNT <> 1
			begin
			select @errmsg = @errorstart + ' - Unable to update PO Item values!', @rcode = 1
			goto POCB_posting_error
			END


		----TK-07650 update PO Item line with 'new' changes
		UPDATE dbo.vPOItemLine
			SET CurUnits	= CASE item.UM WHEN 'LS' THEN 0
							  ELSE (line.CurUnits + @changecurunits)
							  END,
				CurCost		= CASE item.UM WHEN 'LS' THEN (line.CurCost + @changecurcost)
							  ELSE ((line.CurUnits + @changecurunits) * (@OldItemUC + @chgcurunitcost)) / @factor
							  END,
				CurTax		= CASE item.UM WHEN 'LS' THEN ((line.CurCost + @changecurcost) * @taxrate)
							  ELSE (((line.CurUnits + @changecurunits) * (@OldItemUC + @chgcurunitcost)) / @factor) * @taxrate
							  END,     			                      
				BOUnits		= CASE item.UM WHEN 'LS' THEN 0
							  ELSE line.BOUnits + @changebounits
							  END,
				BOCost		= CASE item.UM WHEN 'LS' THEN (line.BOCost + @changebocost)
							  ELSE 0
							  END,
				PostedDate = @dateposted,
				---- so trigger will not update JC
				LineDelete = 'C'
		FROM dbo.vPOItemLine line
		INNER JOIN dbo.bPOIT item ON item.KeyID=line.POITKeyID
		WHERE line.POITKeyID=@POITKeyID
			AND line.POItemLine = 1
		IF @@ROWCOUNT <> 1
			begin
			select @errmsg = @errorstart + ' - Unable to update PO Item line with new values!', @rcode = 1
			goto POCB_posting_error
			end

		---- update PO Item with 'new' changes
		--update POIT
		--set CurUnits = case UM when 'LS' then 0 else (CurUnits + @changecurunits) end,
  --   			CurUnitCost = case UM when 'LS' then 0 else (CurUnitCost + @chgcurunitcost) end,
  --   			CurCost = case when UM = 'LS' then (CurCost + @changecurcost) else
  --   			     ((CurUnits + @changecurunits) * (CurUnitCost + @chgcurunitcost)) / @factor end,
  --               CurTax = case when UM = 'LS' then ((CurCost + @changecurcost) * @taxrate) else
  --   			     (((CurUnits + @changecurunits) * (CurUnitCost + @chgcurunitcost)) / @factor) * @taxrate end,     			                      
  --   			BOUnits = case UM when 'LS' then 0 else BOUnits + @changebounits end,
  --           	BOCost = case UM when 'LS' then (BOCost + @changebocost) else 0 end,
  --           	---- TK-07650
  --   			PostedDate = @dateposted
		--where POCo = @co and PO = @po and POItem = @poitem
		--if @@rowcount <> 1
		--	begin
		--	select @errmsg = @errorstart + ' - Unable to update PO Item values!', @rcode = 1
		--	goto POCB_posting_error
		--	end
   
		-- update Interface Date in PM Materials
		--#120588 Update POMth and POTrans in PMMF TK-05347
		if @source = 'PM Intface'
			BEGIN
			UPDATE dbo.bPMMF 
			SET InterfaceDate=@dateposted, POMth=@mth, POTrans=@potrans
			where POCo = @co
				AND PO = @po
				AND POItem = @poitem
				----TK-10927
				AND POCONum = @POCONum
				AND InterfaceDate IS NULL
				AND SendFlag = 'Y'
			END
		end
   
             /* call bspBatchUserMemoUpdate to update user memos in bPOCD before deleting the batch record */
	if @transtype in ('A', 'C')
		begin
		exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'PO ChgOrder', @errmsg output
		if @rcode <> 0 goto POCB_posting_error
		end
   
         -- delete current entry from batch
		delete bPOCB
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
		if @@rowcount <> 1
			begin
			select @errmsg = @errorstart + ' - Error removing entry from batch.', @rcode = 1
			goto POCB_posting_error
			end
   
	commit transaction
   
   	--issue 18616
   	if @transtype in ('A','C')
   		begin
   		if @guid is not null
   			begin
   			exec @rcode = bspHQRefreshIndexes null, null, @guid, null
   			end
   		end
   
         goto POCB_loop      -- next batch entry
   
     POCB_posting_error:
         rollback transaction
         goto bspexit
   
     POCB_end:   -- finished with PO Change Batch entries
         close bcPOCB
         deallocate bcPOCB
         select @POCBopencursor = 0
   
     -- create a cursor on PO Change JC Distribution Batch for posting
     declare bcPOCA cursor for
     select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, OldNew, PO, POItem, VendorGroup, Vendor,
     	MatlGroup, Material, Description, ActDate, UM, POUnits, JCUM, CmtdUnits, TotalCmtdCost, RemainCmtdCost, RecvdNInvd,
     	TotalCmtdTax, RemCmtdTax  --DC #122288
     from bPOCA with (nolock)
     where POCo = @co and Mth = @mth and BatchId = @batchid
   
     open bcPOCA
     select @POCAopencursor = 1
   
     -- process each PO JC Distribution entry
     POCA_loop:
         fetch next from bcPOCA into @jcco, @job, @phasegroup, @phase, @jcctype, @seq, @oldnew, @po, @poitem,
             @vendorgroup, @vendor, @matlgroup, @material, @description, @actdate, @um, @pounits, @jcum, @cmtdunits,
             @totalcmtdcost, @remaincmtdcost, @recvdninvd,
             @totalcmtdtax, @remcmtdtax  --DC #122288
   
         if @@fetch_status <> 0 goto POCA_end
   
         select @errorstart = 'PO JC Distribution Seq# ' + convert(varchar(6),@seq)
   
         begin transaction
   
		----TK-07650
		if @pounits <> 0 or @totalcmtdcost <> 0 or @remaincmtdcost <> 0
			begin
			-- get next available transaction # for JCCD
			exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
			if @jctrans = 0
				begin
				select @errmsg = @errorstart + ' - ' + isnull(@errmsg,''), @rcode = 1
				goto POCA_posting_error
				end

			-- add JC Cost Detail
			insert dbo.bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
					JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, PostTotCmUnits, PostRemCmUnits,
					UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost,	VendorGroup, Vendor, APCo,
					PO, POItem, MatlGroup, Material,
					----DC #122288 TK-07650
					TotalCmtdTax, RemCmtdTax, POItemLine)
			values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @actdate,
					'PO', @source, @description, @batchid, @um, 0, @pounits, @pounits,
					@jcum, @cmtdunits, @totalcmtdcost, @cmtdunits, @remaincmtdcost,  @vendorgroup, @vendor, @co,
					@po, @poitem, @matlgroup, @material,
					--DC #122288 TK-07650
					@totalcmtdtax, @remcmtdtax, 1)
			if @@rowcount <> 1
				begin
				select @errmsg = @errorstart + ' - Error inserting JC Cost Detail.', @rcode = 1
				goto POCA_posting_error
				end   
			end
      
         -- update JC Cost by Period with change to Received N/Invoiced
         if @recvdninvd <> 0
             begin
             update bJCCP
             set RecvdNotInvcdCost = RecvdNotInvcdCost + @recvdninvd
             where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
                 and Phase = @phase and CostType = @jcctype
             if @@rowcount = 0
                 begin
                 insert bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, RecvdNotInvcdCost)
                 values(@jcco, @job, @phasegroup, @phase, @jcctype, @mth, @recvdninvd)
                 end
             end
   
     	-- delete current PO JC Distribution entry
         delete bPOCA
         where POCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
             and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype
             and BatchSeq = @seq and OldNew =  @oldnew
     	if @@rowcount <> 1
             begin
             select @errmsg = @errorstart + ' - Error removing entry from batch.', @rcode = 1
             goto POCA_posting_error
             end
   
         commit transaction
         goto POCA_loop      -- next PO Job distribution entry
   
     POCA_posting_error:
       rollback transaction
         goto bspexit
   
     POCA_end:
         close bcPOCA
         deallocate bcPOCA
         select @POCAopencursor = 0
   
     -- create a cursor on PO Change IN Distribution Batch for posting
     declare bcPOCI cursor for
     select INCo, Loc, MatlGroup, Material, BatchSeq, OldNew, OnOrder
     from bPOCI with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid
   
     open bcPOCI
     select @POCIopencursor = 1
   
     -- process each PO IN Distribution entry
     POCI_loop:
         fetch next from bcPOCI into @inco, @loc, @matlgroup, @material, @seq, @oldnew, @onorder
   
         if @@fetch_status <> 0 goto POCI_end
   
         select @errorstart = 'PO IN Distribution Seq# ' + convert(varchar(6),@seq)
   
         begin transaction

		----TK-07148 TK-07440 TK-07438
		----TK-11964 need to update on order for PO Item Line 1
         if @onorder <> 0
             begin
             update bINMT
             set OnOrder = OnOrder + @onorder, AuditYN = 'N'     -- do not trigger HQMA update
             where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
             if @@rowcount = 0
                 begin
                 select @errmsg = @errorstart + ' - Unable to update values for IN Material!', @rcode = 1
                 goto POCI_posting_error
                 end
   			 -- reset audit flag in INMT
   			 update bINMT set AuditYN = 'Y'
   			 from bINMT a where a.INCo=@inco and a.Loc=@loc and a.MatlGroup=@matlgroup and a.Material=@material
             end
   
         -- delete current PO IN Distribution entry
         delete bPOCI
         where POCo = @co and Mth = @mth and BatchId = @batchid and INCo = @inco and Loc = @loc
             and MatlGroup = @matlgroup and Material = @material and BatchSeq = @seq and OldNew = @oldnew
     	if @@rowcount <> 1
             begin
             select @errmsg = @errorstart + ' - Error removing entry from batch.', @rcode = 1
             goto POCI_posting_error
             end
   
         commit transaction
         goto POCI_loop      -- next PO IN distribution entry
   
     POCI_posting_error:
         rollback transaction
         goto bspexit
   
     POCI_end:
         close bcPOCI
         deallocate bcPOCI
         select @POCIopencursor = 0
   
     -- make sure batch tables are empty
     if exists(select * from bPOCB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
     	begin
     	select @errmsg = 'Not all PO Change Order batch entries were posted - unable to close batch!', @rcode = 1
     	goto bspexit
     	end
     if exists(select * from bPOCA with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
     	begin
     	select @errmsg = 'Not all JC Distributions were posted - unable to close batch!', @rcode = 1
     	goto bspexit
     	end
     if exists(select * from bPOCI with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
     	begin
     	select @errmsg = 'Not all IN Distributions were posted - unable to close batch!', @rcode = 1
     	goto bspexit
     	end
   
     -- unlock PO Header and Items that where in this batch
     update bPOHD
     set InUseMth = null, InUseBatchId = null
     where POCo = @co and InUseMth = @mth and InUseBatchId = @batchid
   
     update bPOIT
     set InUseMth = null, InUseBatchId = null
     where POCo = @co and InUseMth = @mth and InUseBatchId = @batchid
   
   -- set interface levels note string
       select @Notes=Notes from bHQBC with (nolock)
       where Co = @co and Mth = @mth and BatchId = @batchid
       if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
       select @Notes=@Notes +
           'EM Interface Level set at: ' + convert(char(1), a.RecEMInterfacelvl) + char(13) + char(10) +
           'GL Exp Interface Level set at: ' + convert(char(1), a.GLRecExpInterfacelvl) + char(13) + char(10) +
           'IN Interface Level set at: ' + convert(char(1), a.RecINInterfacelvl) + char(13) + char(10) +
           'JC Interface Level set at: ' + convert(char(1), a.RecJCInterfacelvl) + char(13) + char(10)
       from bPOCO a with (nolock) where POCo=@co
   
     -- delete HQ Close Control entries
     delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
     -- update HQ Batch status to 5 (posted)
     update bHQBC
     set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
     where Co = @co and Mth = @mth and BatchId = @batchid
     if @@rowcount = 0
     	begin
     	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
     	goto bspexit
     	end
   
     bspexit:
     	if @POCBopencursor = 1
     		begin
     		close bcPOCB
     		deallocate bcPOCB
     		end
     	if @POCAopencursor = 1
     		begin
     		close bcPOCA
     		deallocate bcPOCA
     		end
         if @POCIopencursor = 1
     		begin
     		close bcPOCI
     		deallocate bcPOCI
     		end
     	return @rcode






GO
GRANT EXECUTE ON  [dbo].[bspPOCBPost] TO [public]
GO
