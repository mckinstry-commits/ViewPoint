
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  procedure [dbo].[bspPOHBPost]
/***********************************************************
* CREATED: SE   5/3/97
* MODIFIED: GG 04/22/99    (SQL 7.0)
*           JE 09/10/99 - changed CurCost for a changed PO Item
*       	GG 11/03/99 - Cleanup - added IN Co and Location added to PO Header
*                           - removed PO Compliance updates - (done in POHD insert trigger)
*           GF 09/20/2000 - Update compliance codes for compliance group if source PM interface
*           GR 09/25/00 - Added attachments code
*           GF 02/10/2001 - Changed update to PMMF interface date to be more restrictive
*           DANF 03/27/01 - Added Columns AddedMth and Added BatchId on insert
*           DANF 05/30/01 - Added check for inserted detail.
*           MV 07/06/01 - Issue 12769 BatchUserMemoUpdate
*           TV/RM 02/22/02 Attachment Fix
*           CMW 03/15/02 - issue # 16503 JCCP column name changes.
*           kb 3/20/2 - issue #16614
*           CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*			GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*			GG 06/11/02 - #17565 - insert bJCCD.PostedUnits = 0
*			kb 6/26/2 - issue #17643 to skip adding compliance codes for group if compliance codes exist in POCT on a changed PO
*			GF 07/30/2002 - issue #17354 - Added Attention, OldAttention column to POHB. Attention to POHD.
*			GG 08/27/02 - #17965 - fix updates to Backordered and Current values with u/m change 
*			MV 11/07/02 - #18037 - insert or update PayAddressSeq,POAddressSeq to bPOHD from bPOHB
*			MV 01/28/03 - #20094 - return posting err msg if bPOCT insert fails.
*			GF 02/03/2003 - issue #20058 need to set INMT.AuditYN back to INCO.AuditMatl
*			MV 02/11/03 - #17821 add compliance code if bHQCT.AllInvoiceYN = 'N'
*			MV 02/21/03 - #19934 - backout received units/costs when changing from standing PO to regular PO
*			MV 03/06/03 - #20094 - rej1 fix - let POHD update trigger add comp codes to bPOCT
*			MV 05/13/03 - #18763 - Specify Pay Type during PO Entry - insert/update PayType
*			MV 05/13/03 - added 'with (nolock)' to selects and 'local fast_forward' to cursors
*			RT 08/21/03 - #21582 - Added new column 'Address2'.
*			RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
*			RT 12/04/03 - #18616, Reindex attachments after posting A or C records.
*			MV 03/02/04 - #18769 - Pay Category
*			ES 04/07/04 - #23819 - Update ActualDate in JCCD with OrderDate from POHD
*			MV 10/13/04 - #25606 - update JCCD with POIA RemUnits, RemCmtdUnits, RemCost 
*			GF 01/04/05 - #26675 changed update for PMMF interface date to include PMMF.IntFlag in where clause
*			MV 02/28/06 - #120360 - look at orig and cur from POIT to determine if a PO is going from standing to regular
*			DC 10/30/07 - #123917 - bspPOHBPost updates POIT notes if not necessary - performance problem.
*									Solution:  I changed the notes data type from Text to Varchar(max)
*										so we don't need to do a seperate update for the notes column.
*			DC 03/24/08 - #127571 - Modify POEntry  for International addresses
*			DC 04/07/08 - #127019 - Co input on grid does not validate, F4 or F5
*			DC 04/30/08 - #127181 - Store the batch ID of the PO Close batch in the POHD table
*			DC 09/25/08 - #120803 - JCCD committed cost not updated w/ tax rate change
*			DC 10/21/08 - #128052 - Remove CmtdDetailToJC column
*			GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*			DC 11/07/08 - #130833 -  add the 'Supplier' field to the PO Entry form
*			TJL 04/06/09 - Issue #131500, When trans added back for Change, JC Committed not recognizing GST when reversing old value
*			DC 05/18/09 - #133438 - Ensure stored procedures/triggers are using the correct attachment delete proc
*			DC 09/29/09 - #122288 - Store Tax Rate in POItem
*			MH 12/02/10 - #131640 - Changes for SM
*			JVH 3/22/11 - TK-02802 - Added code to copy links for SM Work Orders
*			GF 06/29/2011 - TK-06515 TK-06796 update to PMMF changes more than one record
*			GF 7/27/2011 - TK-07144 changed to varchar(30)
*			GF 07/30/2011 - TK-07148 TK-07440 TK-07438 TK-07030 PO Item Line insert, update, delete and on order to INMT
*			GF 01/22/2012 TK-11964 TK-12013 #145600 #145627
*			JVH 09/12/2012 TK-17835 Fixed the issue where the PO Item's Curr values were being updated incorrectly.
*			GF 10/09/2012 TK-18382 147184 display pending POCO for interface if approved
*			TL  03/21/2013 TFS  Task 43487 - Adding back this code block to fix PO Line Item Distribution Update
*
* USAGE:
*  Called from the PO Batch Posting program to update a batch of PO Entry postings.
*
* INPUT:
*   @co            PO Company
*   @mth           Month of batch
*   @batchid       Batch ID
*   @dateposted    Posting date to write out if successful
*   @source        Identifies source of update - PO Entry or PM Intface

* OUTPUT:
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null,
	@source bSource, @errmsg varchar(255) output)

as
set nocount on

declare @rcode int, @POHBopencursor tinyint, @POIBopencursor tinyint, @POIAopencursor tinyint,
	@POIIopencursor tinyint, @errorstart varchar(50),  @status tinyint,
	@onorder bUnits, @seq int, @transtype char(1), @po varchar(30), @vendorgroup bGroup, @vendor bVendor,
	@jcco bCompany, @inco bCompany, @oldnew tinyint, @jcum bUM, @cmtdunits bUnits,@cmtdcost bDollar,
	@jctrans bTrans, @trans bTrans, @guid uniqueIdentifier, @remunits bUnits, @remcmtdunits bUnits,
	@remcmtdcost bDollar, @smco bCompany, @smworkorder int, @smscope int,@smphasegroup bGroup, @smphase bPhase,@smjccosttype bJCCType
    
 -- Item declares
declare @poitem bItem, @itemtranstype char(1), @itemtype tinyint, @matlgroup bGroup, @material bMatl,
	@vendmatid varchar(30), @itemdesc bItemDesc, @um bUM, @recvyn bYN, @posttoco bCompany, @loc bLoc, @job bJob,
	@phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @equip bEquip, @comptype varchar(10),@component bEquip,
	@emgroup bGroup, @costcode bCostCode, @emctype bEMCType, @wo bWO, @woitem bItem, @glco bCompany, @glacct bGLAcct,
	@reqdate bDate, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @origunits bUnits, @origunitcost bUnitCost,
	@origecm bECM, @origcost bDollar, @origtax bDollar, @oldorigunits bUnits, @oldorigunitcost bUnitCost, @oldorigecm bECM,
	@oldorigcost bDollar, @poitcurunits bUnits, @poitcurunitcost bUnitCost, @poitorigcost bDollar,@poitorigunits bUnits,
	@poitcurecm bECM, @poitcurcost bDollar, @poitbounits bUnits, @poitbocost bDollar, @curunits bUnits,
	@curunitcost bUnitCost, @curecm bECM, @curcost bDollar, @curtax bDollar, @bounits bUnits, @bocost bDollar,
	@factor smallint, @taxrate bRate, @compgroup varchar(10), @ctdescription bDesc, @ctverify bYN,
	@ctcomplied bYN, @ctseq int, @compcode bCompCode, @keyfield varchar(128), @updatekeyfield varchar(128),
	@deletekeyfield varchar(128), @oldreqnum varchar(20), @reqnum varchar(20), @Notes varchar(256), @poitum bUM,
	@poitrecdunits bUnits, @poitrecdcost bDollar, @paytype tinyint, @paycategory int, @orddate bDate,
	@poibnotes varchar(max),  -- DC #123917
	@incoitem bCompany, @emcoitem bCompany, @jccoitem bCompany,  --DC #127019
	@supplier bVendor, @suppliergroup bGroup  --DC #130833
    
declare @gstrate bRate, @pstrate bRate, @valueadd char(1), @jccmtdtax bDollar , --DC #120803
		@gsttaxamt bDollar, @psttaxamt bDollar, @HQTXdebtGLAcct bGLAcct,
		@totalcmtdtax bDollar, @remcmtdtax bDollar --DC #122288

---- TK-07440 TK-07438 TK-07439
DECLARE @POITKeyID BIGINT, @POITCurTax bDollar, @OldOrigTax bDollar
					
SET @rcode = 0
    
/* check for date posted */
if @dateposted is null
	BEGIN
    select @errmsg = 'Missing posting date!', @rcode = 1
    goto bspexit
    END
    
/* validate HQ Batch */
/* select @source = 'PO Entry' - removed bacause now source is passed in - 4/27/98 */
--exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'POHB', @errmsg output, @status output
--if @rcode <> 0 goto bspexit
--if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
--	BEGIN
--    select @errmsg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''!', @rcode = 1
--    goto bspexit
--    END
    
/* set HQ Batch status to 4 (posting in progress) */
update bHQBC
set Status = 4, DatePosted = @dateposted
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	BEGIN
  	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
  	goto bspexit
 	END
 
-- declare cursor on PO Header Batch for updates
declare bcPOHB cursor local fast_forward for
select BatchSeq, BatchTransType, PO, UniqueAttchID
from bPOHB with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
    
open bcPOHB
select @POHBopencursor = 1

-- loop through all rows in PO Header Batch
POHB_loop:
	fetch next from bcPOHB into @seq, @transtype, @po, @guid
    
	if @@fetch_status <> 0 goto po_posting_end

    select @errorstart = 'Seq#' + convert(varchar(6),@seq)

    BEGIN TRANSACTION
          

    if @transtype = 'A'     -- new PO
		BEGIN
        -- insert PO Header
        insert bPOHD (POCo, PO, VendorGroup, Vendor, Description, OrderDate, OrderedBy,
            ExpDate, Status, JCCo, Job, INCo, Loc, ShipLoc, Address, City, State, Zip, ShipIns, Country, --DC #127571
            HoldCode, PayTerms, CompGroup, Purge, Notes, AddedMth, AddedBatchID, Approved, 
			Attention, UniqueAttchID,PayAddressSeq,POAddressSeq, Address2)
        select Co, PO, VendorGroup, Vendor, Description, OrderDate, OrderedBy,
            ExpDate, Status, JCCo, Job, INCo, Loc, ShipLoc, Address, City, State, Zip, ShipIns, Country, --DC #127571
            HoldCode, PayTerms, CompGroup, 'N', Notes, @mth, @batchid, 'Y', Attention,
			UniqueAttchID,PayAddressSeq, POAddressSeq, Address2
        from bPOHB with (nolock)
        where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
        if @@rowcount = 0
            BEGIN
            select @errmsg = @errorstart + ' - Unable to add PO Header!'
            goto po_posting_error
            END
        
        --If we the PO is linked to a work order we want to copy that link.
        --This will only do an insert because we are using an inner join if a link record
        --exists in vSMWorkOrderPOHB
        INSERT dbo.vSMWorkOrderPOHD (POCo, PO, SMCo, WorkOrder)
        SELECT bPOHB.Co, bPOHB.PO, vSMWorkOrderPOHB.SMCo, vSMWorkOrderPOHB.WorkOrder
        FROM dbo.bPOHB 
			INNER JOIN dbo.vSMWorkOrderPOHB ON bPOHB.Co = vSMWorkOrderPOHB.POCo AND bPOHB.Mth = vSMWorkOrderPOHB.BatchMth 
				AND bPOHB.BatchId = vSMWorkOrderPOHB.BatchId AND bPOHB.BatchSeq = vSMWorkOrderPOHB.BatchSeq
        WHERE bPOHB.Co = @co AND bPOHB.Mth = @mth AND bPOHB.BatchId = @batchid AND bPOHB.BatchSeq = @seq
        
        END
    
     if @transtype = 'C'	    -- update existing PO Header
		BEGIN
		update bPOHD
		set VendorGroup = b.VendorGroup, Vendor = b.Vendor, Description = b.Description, OrderDate = b.OrderDate,
			OrderedBy = b.OrderedBy, ExpDate = b.ExpDate, Status = b.Status, JCCo = b.JCCo, Job = b.Job,
			INCo = b.INCo, Loc = b.Loc, ShipLoc = b.ShipLoc, Address = b.Address, City = b.City, State = b.State,
			Zip = b.Zip, ShipIns = b.ShipIns, Country = b.Country,
			HoldCode = b.HoldCode, PayTerms = b.PayTerms, CompGroup = b.CompGroup,
			MthClosed = case b.Status when 2 then h.MthClosed else null end,    -- clear Mth Closed if not 'Closed'
			POCloseBatchID = case b.Status when 2 then h.POCloseBatchID else null end,  --DC #127181
			InUseMth = null, InUseBatchId = null, Approved = 'Y', Attention = b.Attention, Notes = b.Notes,
			UniqueAttchID = b.UniqueAttchID, PayAddressSeq=b.PayAddressSeq, POAddressSeq=b.POAddressSeq,
			Address2=b.Address2
		from bPOHB b
		join bPOHD h on h.POCo = b.Co and h.PO = b.PO
		where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @seq

		if @@rowcount <> 1
			BEGIN
			select @errmsg = @errorstart + ' - Unable to update PO Header!', @rcode = 1
			goto po_posting_error
			END
		END
    
		--update PO Header user memo columns
		if @transtype in ('A','C')
			BEGIN
			exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'PO Entry', @errmsg output
			if @rcode <> 0  goto po_posting_error
			END
    
		-- create a cursor to process Items for this PO
		declare bcPOIB cursor local fast_forward for
		select POItem, BatchTransType, ItemType, MatlGroup, Material, VendMatId, Description, UM, RecvYN,
			PostToCo, Loc, Job, PhaseGroup, Phase, JCCType, Equip, CompType, Component, EMGroup, CostCode,
			EMCType, WO, WOItem, GLCo, GLAcct, ReqDate, TaxGroup, TaxCode, TaxType, OrigUnits, OrigUnitCost,
			OrigECM, OrigCost, OrigTax, OldOrigUnits, OldOrigUnitCost, OldOrigECM, OldOrigCost,
			OldRequisitionNum, RequisitionNum, PayType, PayCategory, Notes,
			INCo, JCCo, EMCo,  --DC #127019
			Supplier, SupplierGroup,  --DC #130833
			TaxRate, GSTRate,  --DC #122288
			SMCo, SMWorkOrder, SMScope,SMPhaseGroup,SMPhase,SMJCCostType,
			----TK
			OldOrigTax
		from bPOIB with (nolock)
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq

		open bcPOIB
		select @POIBopencursor = 1      -- set open cursor flag
    
         -- loop through all rows in PO Item Batch for the current PO
	POIB_loop:
		fetch next from bcPOIB into @poitem, @itemtranstype, @itemtype, @matlgroup, @material, @vendmatid,
			@itemdesc, @um, @recvyn, @posttoco, @loc, @job, @phasegroup, @phase, @jcctype, @equip, @comptype,
			@component, @emgroup, @costcode, @emctype, @wo, @woitem, @glco, @glacct, @reqdate, @taxgroup,
			@taxcode, @taxtype, @origunits, @origunitcost, @origecm, @origcost, @origtax, @oldorigunits,
			@oldorigunitcost, @oldorigecm, @oldorigcost, @oldreqnum, @reqnum, @paytype, @paycategory, @poibnotes,
			@incoitem, @jccoitem, @emcoitem,
			@supplier, @suppliergroup,  --DC #130833
			@taxrate, @gstrate,  --DC #122288
			@smco, @smworkorder, @smscope, @smphasegroup, @smphase,@smjccosttype,
			----TK-07439
			@OldOrigTax
		if @@fetch_status <> 0 goto POIB_end
		
		if @itemtranstype = 'A'    -- add new Item
			BEGIN
			insert bPOIT (POCo, PO, POItem, ItemType, MatlGroup, Material, VendMatId, Description,
				UM, RecvYN, PostToCo, Loc, Job, PhaseGroup, Phase, JCCType, Equip, CompType, Component,
				EMGroup, CostCode, EMCType, WO, WOItem, GLCo,GLAcct, ReqDate, TaxGroup, TaxCode, TaxType,
				OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax, CurUnits, CurUnitCost, CurECM,
				CurCost, CurTax, RecvdUnits, RecvdCost, BOUnits, BOCost, TotalUnits, TotalCost, TotalTax,
				InvUnits, InvCost, InvTax, RemUnits, RemCost, RemTax, PostedDate, Notes,
				RequisitionNum, AddedMth, AddedBatchID, PayType, PayCategory,
				INCo, JCCo, EMCo,  --DC #127019
				Supplier, SupplierGroup,  --DC #130833
				TaxRate, GSTRate, SMCo, SMWorkOrder, SMScope,SMPhaseGroup,SMPhase,SMJCCostType)  --DC #122288
				-- set Current, Backordered, Total, and Remaining equal to Orig values (BO Cost = 0 if unit based)
				-- set Received and Invoiced equal to 0.00
				-- insert trigger will recalculate Total and Remaining values
			select Co, @po, @poitem, ItemType, MatlGroup, Material, VendMatId, Description,
				UM, RecvYN, PostToCo, Loc, Job, PhaseGroup, Phase, JCCType, Equip, CompType, Component,  
				EMGroup, CostCode, EMCType, WO, WOItem, GLCo, GLAcct, ReqDate, TaxGroup, TaxCode, TaxType,
				OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax, OrigUnits, OrigUnitCost, OrigECM,
				OrigCost, OrigTax, 0, 0, OrigUnits, case UM when 'LS' then OrigCost else 0 end,
				OrigUnits, OrigCost, OrigTax, 0, 0, 0, OrigUnits, OrigCost, OrigTax, @dateposted, Notes,
				RequisitionNum, @mth, @batchid, @paytype, @paycategory,
				INCo, JCCo, EMCo, --DC #127019
				@supplier, @suppliergroup,  --DC #130833
				@taxrate, @gstrate,  --DC #122288
				@smco, @smworkorder, @smscope,@smphasegroup, @smphase,@smjccosttype
			from dbo.bPOIB with (nolock)
			where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and POItem = @poitem
			if @@rowcount <> 1
				BEGIN
				select @errmsg = @errorstart + ' - Unable to insert PO Item!', @rcode = 1
				goto po_posting_error
				END
			END

		if @itemtranstype = 'C'     -- update existing Item
			BEGIN
            -- get existing values from PO Item
            select  @poitcurunits = CurUnits, @poitcurunitcost = CurUnitCost, @poitcurecm = CurECM,
					@poitcurcost = CurCost, @poitbounits = BOUnits, @poitbocost = BOCost, @poitum = UM,
					@poitrecdunits = RecvdUnits, @poitrecdcost = RecvdCost, @poitorigcost=OrigCost,
					@poitorigunits = OrigUnits,
					----TK-07148 TK-07440 TK-07438
					@POITKeyID = KeyID, @POITCurTax = CurTax
            from dbo.bPOIT
            where POCo = @co and PO = @po and POItem = @poitem
            if @@rowcount = 0
                BEGIN
        		select @errmsg = @errorstart + ' - Invalid PO Item!', @rcode = 1
                goto po_posting_error
                END

			---- TK-07440 TK-07438 TK-07439
			--TFS  Task 43487 - Adding back this code block - DONOT REMOVE!
			/*Start:  This line of code needs to be here for PO Entry Line Item Distribution*/
			SELECT  @poitcurunits = CurUnits, @poitcurcost = CurCost,
					@poitbounits = BOUnits, @poitbocost = BOCost,
					@poitrecdunits = RecvdUnits, @poitrecdcost = RecvdCost,
					@POITCurTax = CurTax
			FROM dbo.vPOItemLine
			WHERE POITKeyID = @POITKeyID
				AND POItemLine = 1
            if @@rowcount = 0
                BEGIN
        		select @errmsg = @errorstart + ' - Invalid PO Item Line 1 !', @rcode = 1
                goto po_posting_error
                END
			/*End*/

            -- assign new current values
            if @um = 'LS'
                BEGIN
                SET @curunits = 0
                SET @curunitcost = 0
                SET @curecm = NULL
                SET @bounits = 0
                
                SET @curcost = @poitcurcost - @oldorigcost + @origcost
                ----select @curcost = @poitcurcost - @oldorigcost + @origcost
                
				if (@poitcurcost = 0 and @poitorigcost = 0) and @origcost > 0
					---- 19934 Change from Standing PO to Regular PO 
					BEGIN
					select @bocost = case @poitum when 'LS'
									 then ((@poitbocost - @oldorigcost + @origcost) -  @poitrecdcost)
									 else (@curcost - @poitrecdcost)
									 end
					END
				else 
					 BEGIN
					 -- #17965 u/m change to 'LS' must reset Backordered Cost
     				 select @bocost = case @poitum when 'LS'
     								  then @poitbocost - @oldorigcost + @origcost
									  else @curcost
									  end
					 END
				END
			else
                BEGIN
                SET @curunits = @poitcurunits - @oldorigunits + @origunits
                
                --select @curunits = @poitcurunits - @oldorigunits + @origunits   -- update by change in Orig Units
				if (@poitorigunits = 0 and @poitcurunits = 0) and @origunits > 0 -- 19934 Change from Standing PO to Regular PO
					BEGIN
					select @bounits = case @poitum when 'LS' then (@curunits - @poitrecdunits)
									else ((@poitbounits - @oldorigunits + @origunits) - @poitrecdunits)end, @bocost = 0
					END
				else
					BEGIN
					-- #17965 u/m change to 'unit based' must reset Backordered Units and Unit Cost
					select @bounits = case @poitum when 'LS' then @curunits
									else @poitbounits - @oldorigunits + @origunits end, @bocost = 0
					END
					
			 	select @curunitcost = @poitcurunitcost, @curecm = @poitcurecm   -- default to current Item values
                if (@poitcurunitcost = @oldorigunitcost and @poitcurecm = @oldorigecm and @poitum <> 'LS') or (@poitum = 'LS')
                    BEGIN
                    -- if Orig and Current Unit Costs are equal, use new Orig Unit Cost
                    select @curunitcost = @origunitcost, @curecm = @origecm
                    END
                select @factor = case @curecm when 'C' then 100 when 'M' then 1000 else 1 end
                select @curcost = (@curunits * @curunitcost) / @factor
                END
			
---- This code would fix Issue #131500 though, for the moment, the JCCmtdTax portion will be accomplished in the POIT triggers

			-- get Tax Rate based on PostedDate for an existing POItem returned to batch for change
			--select @taxrate = 0, @gstrate = 0, @pstrate = 0, @curtax = 0  'DC #122288
			select @pstrate = 0  --DC #122288
			if @taxcode is not null
				BEGIN				
				--DC #122288				
				exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @dateposted, @valueadd output, NULL, NULL, NULL, 
					NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output
					
				select @pstrate = (case when @gstrate = 0 then 0 else @taxrate - @gstrate end)
								
 				if @rcode <> 0
					BEGIN
					select @errmsg = @errorstart + ' - ' + isnull(@errmsg,'')
					goto po_posting_error
					END

				if @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
					BEGIN
					-- We have an Intl VAT code being used as a Single Level Code
					if (select GST from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
						BEGIN
						select @gstrate = @taxrate
						END
					END
				END	

			SELECT @curtax = @curcost * @taxrate		--Full TaxAmount:  This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only		1000 * .155 = 155
			
			UPDATE bPOIT
				set ItemType = @itemtype, MatlGroup = @matlgroup, Material = @material, VendMatId = @vendmatid,
					Description = @itemdesc, UM = @um, RecvYN = @recvyn, PostToCo = @posttoco, Loc = @loc,
					Job = @job, PhaseGroup = @phasegroup, Phase = @phase, JCCType = @jcctype, Equip = @equip,
					CompType = @comptype, Component = @component, EMGroup = @emgroup, CostCode = @costcode,
					EMCType = @emctype, WO = @wo, WOItem = @woitem, GLCo = @glco, GLAcct = @glacct,
					ReqDate = @reqdate, TaxGroup = @taxgroup, TaxCode = @taxcode, TaxType = @taxtype,
					OrigUnits = @origunits, OrigUnitCost = @origunitcost, OrigECM = @origecm,
					OrigCost = @origcost, OrigTax = @origtax, CurUnits = @curunits, CurUnitCost = @curunitcost,
					CurECM = @curecm, CurCost = @curcost, CurTax = @curtax, BOUnits = @bounits, BOCost = @bocost,
					InUseMth = null, InUseBatchId = null, PostedDate = @dateposted, RequisitionNum = @reqnum,
					PayType=@paytype, PayCategory=@paycategory, Notes=@poibnotes,	
					INCo = @incoitem, EMCo = @emcoitem, JCCo = @jccoitem,  --DC #127019
					--JCCmtdTax = @jccmtdtax,  --DC #120803
					Supplier = @supplier, SupplierGroup = @suppliergroup,  --DC #130833
					TaxRate = @taxrate, GSTRate = @gstrate,  --DC#122288
					SMCo = @smco, SMWorkOrder = @smworkorder, SMScope = @smscope, SMPhaseGroup=@smphasegroup,SMPhase=@smphase, SMJCCostType=@smjccosttype,
					----TK-11964
					AddedMth = @mth, AddedBatchID = @batchid
					-- update trigger will recalculate Total and Remaining values
			WHERE POCo = @co and PO = @po and POItem = @poitem
			if @@rowcount <> 1
				BEGIN
				select @errmsg = @errorstart + ' - Unable to update PO Item!', @rcode = 1
				goto po_posting_error
				END
            END

		----  remove delete Item
		if @itemtranstype = 'D'
			BEGIN
			---- TK-07438 PO Item Distribution Lines
			---- get the POIT keyid
			SELECT @POITKeyID = KeyID
			FROM dbo.bPOIT where POCo = @co and PO = @po and POItem = @poitem
			IF @@ROWCOUNT <> 1
				BEGIN
				SELECT @errmsg = @errorstart + ' - Unable to retrieve PO Item Key ID!', @rcode = 1
				GOTO po_posting_error
				END
			
			---- set the PO Item Line Purge flag to 'Y'
			UPDATE dbo.vPOItemLine SET PurgeYN = 'Y', PostedDate = @dateposted, JCMonth = @mth
			WHERE POITKeyID = @POITKeyID
			
			---- delete the PO Item Lines
			DELETE dbo.vPOItemLine WHERE POITKeyID = @POITKeyID
			
			---- delete the PO Item
			DELETE dbo.bPOIT WHERE KeyID = @POITKeyID
			if @@rowcount <> 1
				BEGIN
				select @errmsg = @errorstart + ' - Unable to delete PO Item!', @rcode = 1
				goto po_posting_error
				END
			END
      
   		---- update Interface date in PM if source is PM Intface
   		if @source = 'PM Intface' --or @transtype = 'C' -- issue #16614
   			BEGIN
   			-- -- -- update original records in PMMF, set interface date
   			update bPMMF set InterfaceDate = @dateposted
   			from bPMMF p join bPOIB s on p.POCo=s.Co and p.POItem=s.POItem
   			where p.POCo=@co and p.PO=@po and p.POItem=s.POItem
   				and s.Co=@co and s.Mth=@mth and s.BatchId=@batchid
   				and s.BatchSeq=@seq and p.InterfaceDate is null and p.SendFlag='Y'
   				AND POCONum IS NULL
   				----TK-18382
   				AND (p.RecordType='O' OR (p.RecordType = 'C' AND (p.ACO IS NOT NULL OR p.PCO IS NOT NULL)))
   				----AND (p.RecordType='O' OR (p.RecordType='C' AND p.ACO is NOT NULL)) ----TK-06796
   			
   			---- update change order records in PMMF, set interface date
   			update bPMMF set InterfaceDate=@dateposted, IntFlag=Null
   			from bPMMF p join bPOIB s on p.POCo=s.Co and p.POItem=s.POItem
   			where p.POCo=@co and p.PO=@po and p.POItem=s.POItem
   				and s.Co=@co and s.Mth=@mth and s.BatchId=@batchid
   				and s.BatchSeq=@seq and p.InterfaceDate is null and p.SendFlag='Y'
   				and p.IntFlag='I'
   				AND POCONum IS NOT NULL ----TK-06515
   			END

        /* update user memo in line item for BatchUserMemoUpdate */
		if @itemtranstype <> 'D'
        	BEGIN
            exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'PO Entry Items', @errmsg output
            if @rcode <> 0 goto po_posting_error
            END
    
		-- delete Item Batch entry for the current Batch Seq
		delete from bPOIB
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and POItem = @poitem

		goto POIB_loop     -- get next Item
    
	POIB_end:       -- finished with Items on the current PO
		close bcPOIB
		deallocate bcPOIB
		select @POIBopencursor = 0
    
    	if @transtype = 'D'	    -- PO flagged for deletion - all Items should have already been removed
    		BEGIN
    		-- remove PO Header
    		delete from bPOHD where POCo = @co and PO = @po
    		if @@rowcount <> 1
    			BEGIN
    			select @errmsg = @errorstart + ' - Unable to delete PO!', @rcode = 1
    			goto po_posting_error
    			END
    
    		-- delete all the associated attachments
    		--DC #133438
    		--if @guid is not null delete bHQAT where UniqueAttchID = @guid
    		END
        	
    	-- delete current PO Header Batch entry
    	delete bPOHB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    	
		COMMIT TRANSACTION
   
   		--issue 18616
   		if @transtype in ('A','C')
   			BEGIN
   			if @guid is not null
   				BEGIN
   				exec @rcode = bspHQRefreshIndexes null, null, @guid, null
   			END
   		END
   
    	goto POHB_loop    -- next PO Header Batch entry
    
    po_posting_error:		-- error occured within transaction - rollback any updates and continue
        ROLLBACK TRANSACTION
    	select @rcode = 1
        goto bspexit
    
     po_posting_end:			-- no more rows to process
		close bcPOHB
		deallocate bcPOHB
		select @POHBopencursor = 0
    
     --update JC using entries from bPOIA
     jc_update:
             
-- create a cursor to process JC Distributions
declare bcPOIA cursor local fast_forward for
/* Old cursor select ****************************************************
select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, POItem, OldNew, PO, VendorGroup, Vendor,
	MatlGroup, Material, Description, UM, CurrentUnits, JCUM, CmtdUnits, CmtdCost
from bPOIA with (nolock)
where POCo = @co and Mth = @mth and BatchId = @batchid
***********************************************************************/
-- ES 04/07/04 - Issue 23819
select a.JCCo, a.Job, a.PhaseGroup, a.Phase, a.JCCType, a.BatchSeq, a.POItem, a.OldNew, a.PO, a.VendorGroup, a.Vendor,
	a.MatlGroup, a.Material, a.Description, a.UM, a.CurrentUnits,a.RemUnits, a.JCUM, a.CmtdUnits, a.CmtdCost,a.RemCmtdUnits,
	a.RemCost, d.OrderDate,
	a.TotalCmtdTax, a.RemCmtdTax  --DC #122288
from bPOIA a with (nolock) LEFT JOIN bPOHD d with (nolock) on a.POCo = d.POCo and a.PO = d.PO
where a.POCo = @co and a.Mth = @mth and a.BatchId = @batchid
   
open bcPOIA
select @POIAopencursor = 1
    
-- loop through all rows in this batch
jc_posting_loop:
fetch next from bcPOIA into @jcco, @job, @phasegroup, @phase, @jcctype, @seq, @poitem,@oldnew, @po, @vendorgroup, @vendor,
	@matlgroup, @material, @itemdesc, @um, @curunits,@remunits,@jcum, @cmtdunits, @cmtdcost,@remcmtdunits,
	@remcmtdcost, @orddate, 
	@totalcmtdtax, @remcmtdtax  --DC #122288
    
	if @@fetch_status <> 0 goto jc_posting_end
    
	select @errorstart = 'Job: ' + isnull(@job,'') + ' Phase: ' + isnull(@phase,'') + ' CostType: ' + convert(varchar(3),isnull(@jcctype,0)) + ' '
	BEGIN TRANSACTION
    
    ----TK-07030
	-- insert JC Cost Detail
	--if @cmtdunits <> 0 or @cmtdcost <> 0
	--	BEGIN
	--	-- get next available transaction # for JCCD
	--	exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
	--	if @jctrans = 0 
	--		BEGIN
	--		select @rcode = 1
	--		goto jc_posting_error
	--		END
                     
	--	insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
	--		ActualDate, JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, 
	--		PostTotCmUnits, PostRemCmUnits, UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits,
	--		RemainCmtdCost, VendorGroup, Vendor, APCo, PO, POItem, MatlGroup, Material,
	--		TotalCmtdTax, RemCmtdTax)  --DC #122288
	--	values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted,
	--		isnull(@orddate, @dateposted), 'PO', @source, @itemdesc, @batchid, @um, 0, 
	--		@curunits,@remunits, @jcum, @cmtdunits, @cmtdcost,@remcmtdunits, @remcmtdcost, --#25606			
	--		@vendorgroup, @vendor, @co, @po, @poitem, @matlgroup, @material,
	--		@totalcmtdtax, @remcmtdtax)  --DC #122288
	--	if @@rowcount = 0
	--		BEGIN
	--		select @errmsg = @errorstart + ' - Error inserting JC Cost Detail.', @rcode = 1
	--		goto jc_posting_error
	--		END
	--	END
				
	-- delete current entry from JC Distribution table
	delete from bPOIA
	where POCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job and
		PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype and BatchSeq = @seq and
		POItem = @poitem and OldNew = @oldnew
    
	COMMIT TRANSACTION
	goto jc_posting_loop
    
	jc_posting_error:
	ROLLBACK TRANSACTION
	select @rcode = 1
	goto bspexit
    
	jc_posting_end:
	close  bcPOIA
	deallocate  bcPOIA
	select @POIAopencursor = 0
    
	--update IN using entries from bPOII
    
in_update:
-- create a cursor to process JC Distributions
declare bcPOII cursor for
select INCo, Loc, MatlGroup, Material, BatchSeq, POItem, OldNew, OnOrder
from bPOII with (nolock)
where POCo = @co and Mth = @mth and BatchId = @batchid
    
open bcPOII
select @POIIopencursor = 1

-- loop through all rows in this batch
in_posting_loop:
fetch next from bcPOII into @inco, @loc, @matlgroup, @material, @seq, @poitem, @oldnew, @onorder
    
	if @@fetch_status <> 0 goto in_posting_end

	BEGIN TRANSACTION
    
    ---- TK-07440 TK-11964 do INMT ONOrder Here because we do not have Material in the PO Item Line table
	---- update OnOrder quantity in Location Material
	update bINMT
	set OnOrder = OnOrder + @onorder, AuditYN = 'N'
	where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
	if @@rowcount = 0
		BEGIN
		select @errmsg = @errorstart + ' - Unable to update Inventory On Order quantity!'
		goto in_posting_error
		END

	-- reset audit flag in INMT
	update bINMT set AuditYN = 'Y'
	from bINMT a where a.INCo=@inco and a.Loc=@loc and a.MatlGroup=@matlgroup and a.Material=@material

	-- delete current entry from IN Distribution table
	delete from bPOII
	where POCo = @co and Mth = @mth and BatchId = @batchid and INCo = @inco and Loc = @loc and
		MatlGroup = @matlgroup and Material = @material and BatchSeq = @seq and
		POItem = @poitem and OldNew = @oldnew
    
	COMMIT TRANSACTION
	goto in_posting_loop
    
	in_posting_error:
	ROLLBACK TRANSACTION
	select @rcode = 1
	goto bspexit
    
	in_posting_end:
	close  bcPOII
	deallocate  bcPOII
	select @POIIopencursor = 0
    
-- make sure PO Header batch is empty
if exists(select 1 from bPOHB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
	BEGIN
	select @errmsg = 'Not all PO Header entries were posted - unable to complete update!', @rcode = 1
	goto bspexit
	END
-- make sure PO Items batch is empty
if exists(select 1 from bPOIB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
	BEGIN
	select @errmsg = 'Not all PO Item entries were posted - unable to complete update!', @rcode = 1
	goto bspexit
	END
-- make all JC Distirbutions have been posted
if exists(select 1 from bPOIA with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
	BEGIN
	select @errmsg = 'Not all Job Cost distributions were posted - unable to close batch!', @rcode = 1
	goto bspexit
	END
-- make all IN Distirbutions have been posted
if exists(select 1 from bPOII with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
	BEGIN
	select @errmsg = 'Not all Inventory distributions were posted - unable to close batch!', @rcode = 1
	goto bspexit
	END

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
    
/* delete HQ Close Control entries */
delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

/* set HQ Batch status to 5 (posted) */
update bHQBC
set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	BEGIN
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	END
    
bspexit:
	if @POHBopencursor = 1
		BEGIN
		close bcPOHB
		deallocate bcPOHB
		END
	if @POIBopencursor = 1
		BEGIN
		close bcPOIB
		deallocate bcPOIB
		END
	if @POIAopencursor = 1
		BEGIN
		close bcPOIA
		deallocate bcPOIA
		END
	if @POIIopencursor = 1
  		BEGIN
  		close bcPOII
  		deallocate bcPOII
  		END

if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[bspPOHBPost]'
return @rcode


GO

GRANT EXECUTE ON  [dbo].[bspPOHBPost] TO [public]
GO
