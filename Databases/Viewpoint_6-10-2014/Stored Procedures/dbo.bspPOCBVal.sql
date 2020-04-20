SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------------------------------------
/****** Object:  Stored Procedure dbo.bspPOCBVal    Script Date: 8/28/99 9:36:27 AM ******/
CREATE procedure [dbo].[bspPOCBVal]
/************************************************************************
* Created: ???
* Modified by: danf 9/9/99
*              GG 11/12/99 - Cleanup  *	
*				SR ISSUE 11657 - do not allow user to delete or change a change order if a later ones exists		
*             DANF 09/05/02 - 17738 Added phase group to bspJobTypeVal	
*				MV 08/28/03 - #22205 - Break out orig units and change in units for bPOCA calculations on existing chg order.
*				RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
*				DC 01/24/08 - #121529 - Increase the description to 60.
*				DC 08/20/08 - #128925 - International Sales Tax Mods
*		TJL 04/09/09 - Issue #133188, Replaces 6.1.1 issue #128925 for QA Intl Testing purposes.  Added notes and minor code that 
*					has NO affect on the operation of this procedure at this time.
*				DC 10/6/2009 - #122288 - Store Tax rate in PO Item
*				DAN SO 04/01/2011 - TK-03816 - New POCONum field added (PO Change Order Number -> link to PM PO Change Order)
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				GF 08/09/2011 - TK-07438 TK-07439 TK-07440
*				GF 10/01/2011 TK-08565 Changing blanket to regular PO
*				TL  07/10/2012 TK-16261  Adapt procedure to update SM Work Orders with Jobs
*
*
* Validates each entry in bPOCB for a select batch - must be called
* prior to posting the batch.
*
* After initial Batch and PO checks, bHQBC Status set to 1 (validation in progress)
*
* bHQBE (Batch Errors), and bPOCA (JC Distribution Audit),
* and bPOCI (IN Distribution Audit) entries are deleted.
*
* Creates a cursor on bPOCB to validate each entry individually.
*
* Errors in batch added to bHQBE using bspHQBEInsert
*
* JC distributions added to bPOCA
* IN distributions added to bPOCI
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
*
* INPUT:
*  @co             PO Company
*  @mth            Batch month
*  @batchid        Batch ID
*  @source         Batch source - PO Change
*
* OUTPUT:
*  @errmsg         Error message
*
* RETURN:
*  @rcode          0 = success, 1 = failure
*
*************************************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @source bSource, @errmsg varchar(255) output
   
as
set nocount on
   
DECLARE @rcode int, @opencursor tinyint, @errorstart varchar(60), @errortext varchar(250),
    @hqmatl char(1), @stdum bUM, @umconv bUnitCost, @jcum bUM, @jcumconv bUnitCost, @taxrate bRate,
    @taxphase bPhase, @taxjcct bJCCType ,@ThisCOSeq int, @COSeq int, @COSeqmth bMonth, @COSeqtrans bTrans,
    @prevchangedcost bDollar
   
-- PO Change Batch declares
DECLARE @seq int, @transtype char(1), @potrans bTrans, @po varchar(30), @poitem bItem, @actdate bDate,
    @description bItemDesc, @um bUM, @changecurunits bUnits, @curunitcost bUnitCost, @curecm bECM, @changebounits bUnits, @changebocost bDollar,
    @oldpo varchar(30), @oldpoitem bItem, @oldchangeorder varchar(10), @oldactdate bDate, @olddescription bItemDesc,
    @oldum bUM, @oldcurunits bUnits, @oldunitcost bUnitCost, @oldecm bECM, @oldcurcost bDollar, @oldbounits bUnits,
    @oldbocost bDollar, @POCONum smallint --TK-03816
   
-- PO Header declares
DECLARE @vendorgroup bGroup, @vendor bVendor, @status tinyint, @inusemth bMonth, @inusebatchid bBatchID

-- PO Item declares
DECLARE @itemtype tinyint, @matlgroup bGroup, @material bMatl, @posttoco bCompany, @loc bLoc,
    @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @glco bCompany, @taxgroup bGroup,
    @taxcode bTaxCode, @poitcurunits bUnits, @poitcurunitcost bUnitCost, @poitcurecm bECM, @poitrecvdunits bUnits,
    @poittotunits bUnits, @poittotcost bDollar, @poitinvunits bUnits, @poitremunits bUnits, @poitremcost bDollar,
    @smco bCompany, @smworkorder int, @smscope int, @smphasegroup bGroup, @smphase bPhase, @smjccosttype bJCCType
   
-- PO JC declares
DECLARE @pocatotcmtdcost bDollar, @pocaremcmtdcost bDollar, @pocarnicost bDollar, @totalunits bUnits, @remunits bUnits,
    @newcurunitcost bUnitCost, @factor smallint, @rnicost bDollar, @pocatottax bDollar, @pocaremtax bDollar,
    @totalunits2 int, @remunits2 int, @newcurunitcost2 bDollar, @pocatotcmtdcost2 bDollar,@pocaremcmtdcost2 bDollar
   
-- PO Change Detail declares
DECLARE @pocdpo varchar(30), @pocdpoitem bItem, @pocdchangeorder varchar(10), @pocdactdate bDate, @pocddescription bItemDesc,
    @pocdum bUM, @pocdcurunits bUnits, @pocdunitcost bUnitCost, @pocdecm bECM, @pocdcurcost bDollar,
    @pocdbounits bUnits, @pocdbocost bDollar
    
--International Sales Tax  --DC #128435
DECLARE @gstrate bRate, @pstrate bRate, @HQTXdebtGLAcct bGLAcct, @valueadd bYN

---- TK-07438 TK-07439 TK-07440
DECLARE @POITKeyID BIGINT, @LineItemsExist CHAR(1),
		----TK-08565
		@RecvYN CHAR(1), @POITInvCost bDollar, @POITInvTax bDollar, @POITCurCost bDollar


-- validate HQ Batch
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'POCB', @errmsg output, @status output
IF @rcode <> 0 goto bspexit
   
IF @status < 0 or @status > 3
	BEGIN
	select @errmsg = 'Invalid Batch status!', @rcode = 1
	goto bspexit
	END

/* set HQ Batch status to 1 (validation in progress) */
update bHQBC
set Status = 1
where Co = @co and Mth = @mth and BatchId = @batchid
IF @@rowcount = 0
	BEGIN
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
	END

/* clear HQ Batch Errors */
delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
/* clear PO JC Distribution Audit */
delete bPOCA where POCo = @co and Mth = @mth and BatchId = @batchid
/* clear PO IN Distribution Audit */
delete bPOCI where POCo = @co and Mth = @mth and BatchId = @batchid
   
-- create cursor on PO Change Order Batch for validation
DECLARE bcPOCB cursor for
select BatchSeq, BatchTransType, POTrans, PO, POItem, ActDate, Description, UM,
    ChangeCurUnits, CurUnitCost, ECM, ChangeBOUnits, ChangeBOCost, OldPO, OldPOItem,
    OldChangeOrder, OldActDate, OldDescription, OldUM, OldCurUnits, OldUnitCost, OldECM,
    OldCurCost, OldBOUnits, OldBOCost, POCONum --TK-03816
from bPOCB with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
   
open bcPOCB
select @opencursor = 1

POCB_loop:  -- cycle through each batch entry
    fetch next from bcPOCB into @seq, @transtype, @potrans, @po, @poitem, @actdate, @description,
        @um, @changecurunits, @curunitcost, @curecm, @changebounits, @changebocost, @oldpo, @oldpoitem,
        @oldchangeorder, @oldactdate, @olddescription, @oldum, @oldcurunits, @oldunitcost, @oldecm,
	    @oldcurcost, @oldbounits, @oldbocost, @POCONum --TK-03816
   
    IF @@fetch_status <> 0 goto POCB_end

	select @errorstart = 'Seq#' + convert(varchar(6),@seq)

	--DC #128925
	-- validate Item and get current values
	select @taxgroup = TaxGroup, @taxcode = TaxCode, 
			@phasegroup = PhaseGroup, @phase = Phase, @jcctype = JCCType,
			@taxrate = TaxRate, @gstrate = GSTRate --DC #122288
	from bPOIT with (nolock)
	where POCo = @co and PO = @po and POItem = @poitem
	IF @@rowcount = 0 
		BEGIN
		select @errortext = @errorstart + ' - Invalid PO Item.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		IF @rcode <> 0 goto bspexit
		goto POCB_loop
		END
		
		
--DC #122288	
	-- need to calculate orig tax for existing item when tax code was null now not null
	IF isnull(@taxcode,'') <> ''			
		BEGIN
		-- get Tax Rate
		select @pstrate = 0  --DC #122288

		--DC #122288
		exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @actdate, @valueadd output, NULL, @taxphase output, @taxjcct output, 
			NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output
				
		select @pstrate = (case when @gstrate = 0 then 0 else @taxrate - @gstrate end)

		-- set Tax Phase and Cost Type
		IF @taxphase is null select @taxphase = @phase
		IF @taxjcct is null select @taxjcct = @jcctype
				
		IF @rcode <> 0
			BEGIN
			select @errortext = @errorstart + ' - ' + @errmsg
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			IF @rcode <> 0 goto bspexit
			goto POCB_loop
			END

		IF @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
			BEGIN
			-- We have an Intl VAT code being used as a Single Level Code
			IF (select GST from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
				BEGIN
				select @gstrate = @taxrate
				END
			END
		END /* tax code validation*/
   
	-- validate transaction type
	IF @transtype not in ('A','C','D')
		BEGIN
		select @errortext = @errorstart + ' -  Invalid transaction type, must be (A, C, or D).'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		IF @rcode <> 0 goto bspexit
        goto POCB_loop
		END
   
    IF @transtype in ('A','C')  -- validation specific to 'add' and 'change' entries
        BEGIN
        IF @transtype = 'A' and @potrans is not null
            BEGIN
            select @errortext = @errorstart + ' -  PO Change Transaction must be null for ''add'' entries.'
		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		    IF @rcode <> 0 goto bspexit
            goto POCB_loop
		    END

        -- validate PO#
	    select @vendor = Vendor, @vendorgroup = VendorGroup, @status = Status,
            @inusemth = InUseMth, @inusebatchid = InUseBatchId
        from bPOHD with (nolock) where POCo = @co and PO = @po
	    IF @@rowcount = 0
		    BEGIN
		    select @errortext = @errorstart + ' - Invalid PO.'
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		    IF @rcode <> 0 goto bspexit
            goto POCB_loop
		    END
        IF @status not in (0,3)
            BEGIN
		    select @errortext = @errorstart + ' - PO must be ''open'' or ''pending''.'
		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		    IF @rcode <> 0 goto bspexit
            goto POCB_loop
		    END
		IF @source <> 'PM Intface'
			BEGIN
			IF @inusemth is null or @inusebatchid is null
				BEGIN
				select @errortext = @errorstart + ' - PO Header has not been flagged as ''In Use'' by this batch.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				IF @rcode <> 0 goto bspexit
				goto POCB_loop
				END
			IF @inusemth <> @mth or @inusebatchid <> @batchid
				BEGIN
				select @errortext = @errorstart + ' - PO Header ''In Use'' by another batch.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				IF @rcode <> 0 goto bspexit
				goto POCB_loop
				END
			END

		-- validate Item and get current values
		select @itemtype = ItemType, @matlgroup = MatlGroup, @material = Material, @um = UM,
				@posttoco = PostToCo, @loc = Loc, @job = Job, @phasegroup = PhaseGroup, @phase = Phase,
				@jcctype = JCCType, @glco = GLCo, @taxgroup = TaxGroup, @taxcode = TaxCode,
  				@poitcurunitcost = CurUnitCost, @poitcurecm = CurECM, @poitrecvdunits = RecvdUnits,
				@poittotunits = TotalUnits, @poittotcost = TotalCost, @poitinvunits = InvUnits,
				@poitremunits = RemUnits, @poitremcost = RemCost, @poitcurunits = CurUnits,
				----TK-07438 TK-07439 TK-07440
				@POITKeyID = KeyID, 
				@smco=SMCo, @smworkorder=SMWorkOrder,@smscope=SMScope,
				@smphasegroup=SMPhaseGroup,@smphase=SMPhase,@smjccosttype=SMJCCostType
		from bPOIT with (nolock)
		where POCo = @co and PO = @po and POItem = @poitem
		IF @@rowcount = 0
			BEGIN
			select @errortext = @errorstart + ' - Invalid PO Item.'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			IF @rcode <> 0 goto bspexit
			goto POCB_loop
			END
      
		/*SMJCCostType only has value when SM Work Order has a job
		Use regular JC posting procedures for SM Work Orders with JC Jobs*/
		IF @itemtype=6 AND @smjccosttype IS NOT NULL
		BEGIN
			SELECT @posttoco = JCCo, @job = Job, 
			@phasegroup = @smphasegroup, @phase = @smphase, @jcctype=@smjccosttype
			FROM dbo.SMWorkOrderScope
			WHERE SMCo=@smco AND WorkOrder=@smworkorder and Scope=@smscope
		END 

        ---- TK-07440 TK-07438 TK-07439
        ---- get PO Item Line one current values also set flag when lines exist
		SET @LineItemsExist = 'N'
		IF EXISTS(SELECT 1 FROM dbo.vPOItemLine WHERE POITKeyID = @POITKeyID AND POItemLine = 1)
			BEGIN
			SELECT  @poitrecvdunits = RecvdUnits, @poittotunits = TotalUnits, @poittotcost = TotalCost,
		  			@poitinvunits = InvUnits, @poitremunits = RemUnits, @poitremcost = RemCost,
		  			----TK-08565
		  			@poitcurunits = CurUnits, @POITInvCost = InvCost, @POITInvTax = InvTax,
		  			@POITCurCost = CurCost
			FROM dbo.vPOItemLine
			WHERE POITKeyID = @POITKeyID
				AND POItemLine = 1
			END
		IF EXISTS(SELECT 1 FROM dbo.vPOItemLine WHERE POITKeyID = @POITKeyID AND POItemLine > 1)
			BEGIN
			SET @LineItemsExist = 'Y'
			END
		
		
		-- init material defaults
        select @hqmatl = 'N', @stdum = null, @umconv = 0

        -- check for Material in HQ
        select @stdum = StdUM
        from bHQMT with (nolock)
        where MatlGroup = @matlgroup and Material = @material
        IF @@rowcount = 1
            BEGIN
            select @hqmatl = 'Y'    -- setup in HQ Materials
            IF @stdum = @um select @umconv = 1
            END

        -- if HQ Material, validate UM and get unit of measure conversion
        IF @hqmatl = 'Y' and @um <> @stdum
            BEGIN
            select @umconv = Conversion
            from bHQMU with (nolock)
            where MatlGroup = @matlgroup and Material = @material and UM = @um
            IF @@rowcount = 0
                BEGIN
		        select @errortext = @errorstart + ' - Invalid unit of measure for this Material.'
		        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		        IF @rcode <> 0 goto bspexit
                goto POCB_loop
		        END
            END
   
        IF @itemtype = 1/*Job type*/ OR (@itemtype=6 AND @smjccosttype IS NOT NULL)/*SM Work Order w/Job*/
            BEGIN
		    exec @rcode = bspJobTypeVal @posttoco, @phasegroup, @job, @phase, @jcctype, @jcum output, @errmsg output
		    IF @rcode <> 0
                BEGIN
		        select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
		        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		        IF @rcode <> 0 goto bspexit
                goto POCB_loop
		        END
			IF @taxphase <> @phase OR @taxjcct <> @jcctype
				BEGIN
					exec @rcode = bspJobTypeVal @posttoco, @phasegroup, @job, @taxphase, @taxjcct, @jcum output, @errmsg output
					IF @rcode <> 0
						BEGIN
						select @errortext = @errorstart + ' - Tax Redirect - ' + isnull(@errmsg,'')
						exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
						IF @rcode <> 0 goto bspexit
						goto POCB_loop
						END
				END
            -- determine conversion factor from posted UM to JC UM
            select @jcumconv = 0
            IF isnull(@jcum,'') = @um select @jcumconv = 1

            IF @hqmatl = 'Y' and isnull(@jcum,'') <> @um
                BEGIN
                exec @rcode = bspHQStdUMGet @matlgroup, @material, @jcum, @jcumconv output, @stdum output, @errmsg output
                IF @rcode <> 0
                    BEGIN
                    select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                    IF @rcode <> 0 goto bspexit
                    goto POCB_loop
                    END
                IF @jcumconv <> 0 select @jcumconv = @umconv / @jcumconv
                END
      
			-- validate Mth in GL Company
            exec @rcode = bspHQBatchMonthVal @glco, @mth, 'PO', @errmsg output
            IF @rcode <> 0
                BEGIN
  	            select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
      			goto POCB_loop
	            END
   
            -- calculate the change to JC committed units and costs based on current POIT values
            -- and the changes stored in POCB - result used for 'new' entry in POCA
            IF @um = 'LS'
                BEGIN
                -- change to Total and Remaining Cmtd Costs are equal to change in BO Cost on 'LS' Items
                select @pocatotcmtdcost = @changebocost, @pocaremcmtdcost = @changebocost
                -- change to RecvdNInvcd is 0.00 on 'LS' Items
                select @pocarnicost = 0
                END

			IF @um <> 'LS'
				BEGIN
				IF @transtype = 'A'
					 BEGIN
					 -- update Total and Remaining units by change to BO units
					 select @totalunits = @poittotunits + @changebounits
					 select @remunits = @poitremunits + @changebounits
        			 -- update Currrent Unit Cost by change
					 select @newcurunitcost = @poitcurunitcost + @curunitcost
					 select @factor = case @poitcurecm when 'C' then 100 when 'M' then 1000 else 1 end
					 -- calculate change to Total and Remaining Cmtd Cost
					 select @pocatotcmtdcost = ((@totalunits * @newcurunitcost) / @factor) - @poittotcost
					 select @pocaremcmtdcost = ((@remunits * @newcurunitcost) / @factor) - @poitremcost
					 -- received n/invoiced - only affected by unit cost change
					 select @rnicost = ((@poitrecvdunits - @poitinvunits) * @poitcurunitcost) / @factor
					 select @pocarnicost = (((@poitrecvdunits - @poitinvunits) * @newcurunitcost) / @factor) - @rnicost
					 END
					 ---- update Total and Remaining units by change to BO units
					 ---- receiving TK-08565
					-- IF @RecvYN <> 'N'
					--	BEGIN
					--	--select @totalunits = @poittotunits + @changebounits
					--	--select @remunits = @poitremunits + @changebounits
					--	-- update Total and Remaining units by change to BO units
					--	select @totalunits = @poittotunits + @changebounits
					--	select @remunits = @poitremunits + @changebounits
     --   				-- update Currrent Unit Cost by change
					--	select @newcurunitcost = @poitcurunitcost + @curunitcost
					--	select @factor = case @poitcurecm when 'C' then 100 when 'M' then 1000 else 1 end
					--	-- calculate change to Total and Remaining Cmtd Cost
					--	select @pocatotcmtdcost = ((@totalunits * @newcurunitcost) / @factor) - @poittotcost
					--	select @pocaremcmtdcost = ((@remunits * @newcurunitcost) / @factor) - @poitremcost
					--	-- received n/invoiced - only affected by unit cost change
					--	select @rnicost = ((@poitrecvdunits - @poitinvunits) * @poitcurunitcost) / @factor
					--	select @pocarnicost = (((@poitrecvdunits - @poitinvunits) * @newcurunitcost) / @factor) - @rnicost
					--	END
					--ELSE
					--	BEGIN
					--	---- when not receiving and we are changing a blanket PO to a regular PO
					--	---- we need to back out the invoiced cost
					--	---- unit cost set, units set, or amount set
					--	IF @changebounits <> 0 AND
					--		((@curunitcost <> 0 AND @oldunitcost = 0)
					--		OR (@poitcurunits <> 0 AND @oldcurunits = 0))
					--		BEGIN
					--		select @pocatotcmtdcost = ((@totalunits * @newcurunitcost) / @factor) - @poittotcost - @POITInvCost
					--		select @pocaremcmtdcost = ((@remunits * @newcurunitcost) / @factor) - @poitremcost
					--		END
					--	ELSE
					--		BEGIN
					--		select @pocatotcmtdcost = ((@totalunits * @newcurunitcost) / @factor) - @poittotcost
					--		select @pocaremcmtdcost = ((@remunits * @newcurunitcost) / @factor) - @poitremcost
					--		END
					--	END
					---- update Currrent Unit Cost by change
					-- select @newcurunitcost = @poitcurunitcost + @curunitcost
					-- select @factor = case @poitcurecm when 'C' then 100 when 'M' then 1000 else 1 end
					-- -- calculate change to Total and Remaining Cmtd Cost
					-- select @pocatotcmtdcost = ((@totalunits * @newcurunitcost) / @factor) - @poittotcost
					-- select @pocaremcmtdcost = ((@remunits * @newcurunitcost) / @factor) - @poitremcost
					-- -- received n/invoiced - only affected by unit cost change
					-- select @rnicost = ((@poitrecvdunits - @poitinvunits) * @poitcurunitcost) / @factor
					-- select @pocarnicost = (((@poitrecvdunits - @poitinvunits) * @newcurunitcost) / @factor) - @rnicost
					-- END

				 IF @transtype = 'C'	-- #22205
					 BEGIN
					 --update total and remaining units by change to BO units
					 select @totalunits = (@poittotunits - @oldbounits)	-- orig units
					 select @totalunits2 = @changebounits -- chg units
					 select @remunits = (@poittotunits - @oldbounits) 	-- orig rem units
					 select @remunits2 = @changebounits -- chg rem units
					 -- update current unit cost by change
					 select @newcurunitcost = @curunitcost	-- new unit cost for orig units
					 select @newcurunitcost2 = (@poitcurunitcost + (@curunitcost - @oldunitcost)) -- new unit cost for chg units
					 select @factor = case @poitcurecm when 'C' then 100 when 'M' then 1000 else 1 end
					 -- calculate change to total and remaining cmtd cost
					 select @pocatotcmtdcost = (@totalunits * @newcurunitcost) / @factor -- calc change to orig
					 select @pocatotcmtdcost2 = (@totalunits2 * @newcurunitcost2)/ @factor -- calc change to chg
					 select @pocatotcmtdcost = @pocatotcmtdcost + @pocatotcmtdcost2 -- add the totals
					 select @pocaremcmtdcost = (@remunits * @newcurunitcost) / @factor	-- calc change to orig
					 select @pocaremcmtdcost2 = (@remunits2 * @newcurunitcost2) / @factor	-- calc change to chg
					 select @pocaremcmtdcost = @pocaremcmtdcost + @pocaremcmtdcost2	-- add the rem totals
					 -- received n/invoiced - only affected by unit cost change
					 select @rnicost = ((@poitrecvdunits - @poitinvunits) * @poitcurunitcost) / @factor
					 select @pocarnicost = (((@poitrecvdunits - @poitinvunits) * @newcurunitcost) / @factor) /*- @rnicost*/
					 END
                END

			IF @HQTXdebtGLAcct is null
				BEGIN
				/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
				   In any case:
				   a)  @taxrate is the correct value.  
				   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
				   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
				select @pocatottax = @pocatotcmtdcost * @taxrate    -- may be redirected, keep separate
				select @pocaremtax = @pocaremcmtdcost * @taxrate					
				END
			else
				BEGIN
				/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
				IF @taxrate <> 0
					BEGIN
					select @pocatottax = @pocatotcmtdcost * @pstrate    -- may be redirected, keep separate
					select @pocaremtax = @pocaremcmtdcost * @pstrate
					END
				END
                      
			IF @taxphase = @phase and @taxjcct = @jcctype
				BEGIN
				-- include tax with posted phase/cost type
				select @pocatotcmtdcost = @pocatotcmtdcost + @pocatottax
				select @pocaremcmtdcost = @pocaremcmtdcost + @pocaremtax

			   -- update 'new' entry to JC Distribution Audit - POCA
			   IF @changebounits <> 0 or @pocatotcmtdcost <> 0 or @pocaremcmtdcost <> 0 or @pocarnicost <> 0
					BEGIN
					insert into bPOCA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
						OldNew, PO, POItem, VendorGroup, Vendor, MatlGroup, Material, Description, ActDate,
						UM, POUnits, JCUM, CmtdUnits, TotalCmtdCost, RemainCmtdCost, RecvdNInvd,
						TotalCmtdTax, RemCmtdTax)  --DC #122288
					values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @phase, @jcctype, @seq,
						1, @po, @poitem, @vendorgroup, @vendor, @matlgroup, @material, @description, @actdate,
						@um, @changebounits, @jcum, (@changebounits * @jcumconv), ISNULL(@pocatotcmtdcost,0),
						ISNULL(@pocaremcmtdcost,0), ISNULL(@pocarnicost,0),
						ISNULL(@pocatottax,0), ISNULL(@pocaremtax,0)) --DC #122288
					END				
				END
			ELSE
				BEGIN
				-- update 'new' entry to JC Distribution Audit - POCA
				IF @changebounits <> 0 or @pocatotcmtdcost <> 0 or @pocaremcmtdcost <> 0 or @pocarnicost <> 0
					BEGIN
					insert into bPOCA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
						OldNew, PO, POItem, VendorGroup, Vendor, MatlGroup, Material, Description, ActDate,
						UM, POUnits, JCUM, CmtdUnits, TotalCmtdCost, RemainCmtdCost, RecvdNInvd,
						TotalCmtdTax, RemCmtdTax)  --DC #122288
					values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @phase, @jcctype, @seq,
						1, @po, @poitem, @vendorgroup, @vendor, @matlgroup, @material, @description, @actdate,
						@um, @changebounits, @jcum, (@changebounits * @jcumconv), ISNULL(@pocatotcmtdcost,0),
						ISNULL(@pocaremcmtdcost,0), ISNULL(@pocarnicost,0),
						0, 0) --DC #122288
					END
					
			   -- update 'new' entry to JC Distribution Audit - POCA (if Tax is redirected)
			   IF @pocatottax <> 0  or @pocaremtax <> 0
					BEGIN
					insert into bPOCA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
						OldNew, PO, POItem, VendorGroup, Vendor, MatlGroup, Material, Description, ActDate,
						UM, POUnits, JCUM, CmtdUnits, TotalCmtdCost, RemainCmtdCost, RecvdNInvd,
						TotalCmtdTax, RemCmtdTax)  --DC #122288                    
					values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @taxphase, @taxjcct, @seq,
						1, @po, @poitem, @vendorgroup, @vendor, @matlgroup, @material, @description, @actdate,
						@um, 0, @jcum, 0, ISNULL(@pocatottax,0), ISNULL(@pocaremtax,0), 0,
						ISNULL(@pocatottax,0), ISNULL(@pocaremtax,0)) --DC #122288
					END					
				END   
		   END
   
        IF @itemtype = 2    -- Inventory type
            BEGIN
            -- check for Location conversion
            IF @um <> @stdum
				BEGIN
                select @umconv = Conversion
                from bINMU with (nolock)
                where INCo = @posttoco and Loc = @loc and MatlGroup = @matlgroup
					and Material = @material and UM = @um
                IF @@rowcount = 0
                    BEGIN
                    select @errortext = @errorstart + ' - Invalid Location, Material, and UM combination. '
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                    IF @rcode <> 0 goto bspexit
                    goto POCB_loop
                    END
                END
   
            -- change to On Order will equal change to Backorder units - converted to Std UM
			IF @changebounits <> 0
                BEGIN
                insert into bPOCI (POCo, Mth, BatchId, INCo, Loc, MatlGroup, Material, BatchSeq, OldNew,
                    PO, POItem, VendorGroup, Vendor, UM, POUnits, StdUM, OnOrder)
                values (@co, @mth, @batchid, @posttoco, @loc, @matlgroup, @material, @seq, 1,
                    @po, @poitem, @vendorgroup, @vendor, @um, @changebounits, @stdum, (@changebounits * @umconv))
                END
            END
        END  --END if @transtype in ('A','C')
   
    IF @transtype in ('C','D')  -- validation specific to 'change' and 'delete' entries
        BEGIN
        select @pocdpo = PO, @pocdpoitem = POItem, @pocdchangeorder = ChangeOrder, @pocdactdate = ActDate,
            @pocddescription = Description, @pocdum = UM, @pocdcurunits = ChangeCurUnits, @pocdunitcost = CurUnitCost,
            @pocdecm = ECM, @pocdcurcost = ChangeCurCost, @pocdbounits = ChangeBOUnits, @pocdbocost = ChangeBOCost
        from bPOCD with (nolock)
        where POCo = @co and Mth = @mth and POTrans = @potrans
        IF @@rowcount = 0
            BEGIN
            select @errortext = @errorstart + ' - Invalid PO Change Transaction!'
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
            IF @rcode <> 0 goto bspexit
            goto POCB_loop
            END
        IF @pocdpo <> @oldpo or @pocdpoitem <> @oldpoitem or isnull(@pocdchangeorder,'') <> isnull(@oldchangeorder,'')
            or @pocdactdate <> @oldactdate or isnull(@pocddescription,'') <> isnull(@olddescription,'')
            or @pocdum <> @oldum or @pocdcurunits <> @oldcurunits or @pocdunitcost <> @oldunitcost
            or isnull(@pocdecm,'') <> isnull(@oldecm,'') or @pocdcurcost <> @oldcurcost
            or @pocdbounits <> @oldbounits or @pocdbocost <> @oldbocost
            BEGIN
            select @errortext = @errorstart + ' - (Old) batch values do not match current Transaction values!'
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
            IF @rcode <> 0 goto bspexit
            goto POCB_loop
            END
   
        -- get 'old' info needed for update to POCA and POCI
        -- validate old PO#
	    select @vendor = Vendor, @vendorgroup = VendorGroup, @status = Status
        from bPOHD with (nolock) where POCo = @co and PO = @oldpo
	    IF @@rowcount = 0
		    BEGIN
		    select @errortext = @errorstart + ' - Invalid PO.'
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		    IF @rcode <> 0 goto bspexit
            goto POCB_loop
		    END
        IF @status <> 0 and @status <> 3
            BEGIN
		    select @errortext = @errorstart + ' - PO must be ''open'' or ''pending''.'
		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		    IF @rcode <> 0 goto bspexit
            goto POCB_loop
		    END
    		    
	    -- validate old Item and get current values
	    select @itemtype = ItemType, @matlgroup = MatlGroup, @material = Material, @um = UM,
            @posttoco = PostToCo, @loc = Loc, @job = Job, @phasegroup = PhaseGroup, @phase = Phase,
            @jcctype = JCCType, @glco = GLCo, @taxgroup = TaxGroup, @taxcode = TaxCode,
			@poitcurunitcost = CurUnitCost, @poitcurecm = CurECM, @poitrecvdunits = RecvdUnits,
            @poittotunits = TotalUnits, @poittotcost = TotalCost, @poitinvunits = InvUnits,
            @poitremunits = RemUnits, @poitremcost = RemCost
	    from bPOIT with (nolock)
        where POCo = @co and PO = @oldpo and POItem = @oldpoitem
	    IF @@rowcount = 0
		    BEGIN
		    select @errortext = @errorstart + ' - Invalid PO Item.'
		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		    IF @rcode <> 0 goto bspexit
            goto POCB_loop
		    END
   
        -- init material defaults
        select @hqmatl = 'N', @stdum = null, @umconv = 0
   
        -- check for Material in HQ
        select @stdum = StdUM
        from bHQMT with (nolock)
		where MatlGroup = @matlgroup and Material = @material
        IF @@rowcount = 1
            BEGIN
            select @hqmatl = 'Y'    -- setup in HQ Materials
            IF @stdum = @um select @umconv = 1
            END

        -- if HQ Material, validate UM and get unit of measure conversion
        IF @hqmatl = 'Y' and @um <> @stdum
            BEGIN
            select @umconv = Conversion
            from bHQMU with (nolock)
            where MatlGroup = @matlgroup and Material = @material and UM = @um
            IF @@rowcount = 0
                BEGIN
		        select @errortext = @errorstart + ' - Invalid unit of measure for this Material.'
		        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		        IF @rcode <> 0 goto bspexit
                goto POCB_loop
		        END   
            END      
   
        IF @itemtype = 1/*Job type*/ OR (@itemtype=6 AND @smjccosttype IS NOT NULL)/*SM Work Order w/Job*/
            BEGIN
		    exec @rcode = bspJobTypeVal @posttoco, @phasegroup, @job, @phase, @jcctype, @jcum output, @errmsg output
		    IF @rcode <> 0
                BEGIN
		        select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
		        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		        IF @rcode <> 0 goto bspexit
                goto POCB_loop
		        END

            -- determine conversion factor from posted UM to JC UM
            select @jcumconv = 0
            IF isnull(@jcum,'') = @um select @jcumconv = 1
   
            IF @hqmatl = 'Y' and isnull(@jcum,'') <> @um
                BEGIN
				exec @rcode = bspHQStdUMGet @matlgroup, @material, @jcum, @jcumconv output, @stdum output, @errmsg output
                IF @rcode <> 0
                    BEGIN
                    select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                    IF @rcode <> 0 goto bspexit
                    goto POCB_loop
                    END
                IF @jcumconv <> 0 select @jcumconv = @umconv / @jcumconv
                END   
            -- validate Mth in GL Company
            exec @rcode = bspHQBatchMonthVal @glco, @mth, 'PO', @errmsg output
            IF @rcode <> 0
                BEGIN
  				select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
   				goto POCB_loop
  	            END
   
			--ISSUE 11657 ----------------
			If @transtype='D'
				BEGIN
				select @COSeq=isnull(Max(Seq),0) from POCD with (nolock) where POCo=@co and PO=@po and POItem=@poitem
				select @prevchangedcost=CurUnitCost from POCD with (nolock) where POCo=@co and PO=@po and POItem=@poitem and Seq=@COSeq
				select @ThisCOSeq=Seq from POCD with (nolock) where POCo=@co and PO=@po and POItem=@poitem and Mth=@mth and POTrans=@potrans	
				IF @ThisCOSeq<@COSeq and @prevchangedcost<>0
					BEGIN 
					select @COSeqmth = Mth, @COSeqtrans=POTrans
					from POCD with (nolock) where POCo=@co and PO=@po and POItem=@poitem and Seq=@COSeq		
					select @errmsg= @errorstart +' - You cannot delete this Change Order because unit cost was changed in Mth=' + convert(varchar(10),@COSeqmth,1) + ' for POTrans=' + convert(varchar(10), @COSeqtrans)
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errmsg, @errmsg output
					IF @rcode <> 0 goto bspexit
    				goto POCB_loop					    			  
					END						
				END	
			--END OF ISSUE 11657
      
            -- calculate the change to JC committed units and costs based on current POIT values
            -- and the old changes stored in POCB - result used for 'old' entry in POCA
            IF @um = 'LS'
				BEGIN
                -- change to Total and Remaining Cmtd Costs will affected equally
				select @pocatotcmtdcost = -(@oldbocost) , @pocaremcmtdcost = -(@oldbocost)   -- back out 'old' change
                -- change to RecvdNInvcd is 0.00 on 'LS' Items
                select @pocarnicost = 0
                END
            IF @um <> 'LS'
                BEGIN
                -- update Total and Remaining units by change to BO units
                select @totalunits = @poittotunits - @oldbounits            -- back out 'old' change
                select @remunits = @poitremunits - @oldbounits
                -- update Currrent Unit Cost by change
                select @newcurunitcost = @poitcurunitcost - @oldunitcost    -- back out 'old' change
                select @factor = case @poitcurecm when 'C' then 100 when 'M' then 1000 else 1 end
                -- calculate change to Total and REmaining Cmtd Cost
                select @pocatotcmtdcost = ((@totalunits * @newcurunitcost) / @factor) - @poittotcost
    			 select @pocaremcmtdcost = ((@remunits * @newcurunitcost) / @factor) - @poitremcost
                -- received n/invoiced - only affected by unit cost change
                select @rnicost = ((@poitrecvdunits - @poitinvunits) * @poitcurunitcost) / @factor
                select @pocarnicost = (((@poitrecvdunits - @poitinvunits) * @newcurunitcost) / @factor) - @rnicost
                END
 
			--DC #128435
			IF @HQTXdebtGLAcct is null
				BEGIN
				--DC #122288
				select @pocatottax = @pocatotcmtdcost * @taxrate    -- may be redirected, keep separate
				select @pocaremtax = @pocaremcmtdcost * @taxrate
				END
			else
				BEGIN
				/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
				--DC #122288
				IF @taxrate <> 0
					BEGIN
					select @pocatottax = @pocatotcmtdcost * @pstrate    -- may be redirected, keep separate
					select @pocaremtax = @pocaremcmtdcost * @pstrate
					END
				END		 
                                           
			IF @taxphase = @phase and @taxjcct = @jcctype
				BEGIN
				-- include tax with posted phase/cost type
				select @pocatotcmtdcost = @pocatotcmtdcost + @pocatottax
				select @pocaremcmtdcost = @pocaremcmtdcost + @pocaremtax
				-- update 'old' entry to JC Distribution Audit - POCA
				IF @oldbounits <> 0 or @pocatotcmtdcost <> 0 or @pocaremcmtdcost <> 0 or @pocarnicost <> 0
					BEGIN
					insert into bPOCA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
						OldNew, PO, POItem, VendorGroup, Vendor, MatlGroup, Material, Description, ActDate,
						UM, POUnits, JCUM, CmtdUnits, TotalCmtdCost, RemainCmtdCost, RecvdNInvd,
						TotalCmtdTax, RemCmtdTax)  --DC #122288
					values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @phase, @jcctype, @seq,
						0, @oldpo, @oldpoitem, @vendorgroup, @vendor, @matlgroup, @material, @description, @oldactdate,
						@um, -(@oldbounits), @jcum, -(@oldbounits * @jcumconv), ISNULL(@pocatotcmtdcost,0),
						ISNULL(@pocaremcmtdcost,0), ISNULL(@pocarnicost,0),
						ISNULL(@pocatottax,0), ISNULL(@pocaremtax,0)) --DC #122288
					END								
				END
			ELSE
				BEGIN
				-- update 'old' entry to JC Distribution Audit - POCA
				IF @oldbounits <> 0 or @pocatotcmtdcost <> 0 or @pocaremcmtdcost <> 0 or @pocarnicost <> 0
					BEGIN
					insert into bPOCA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
						OldNew, PO, POItem, VendorGroup, Vendor, MatlGroup, Material, Description, ActDate,
						UM, POUnits, JCUM, CmtdUnits, TotalCmtdCost, RemainCmtdCost, RecvdNInvd,
						TotalCmtdTax, RemCmtdTax)  --DC #122288
					values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @phase, @jcctype, @seq,
						0, @oldpo, @oldpoitem, @vendorgroup, @vendor, @matlgroup, @material, @description, @oldactdate,
						@um, -(@oldbounits), @jcum, -(@oldbounits * @jcumconv), ISNULL(@pocatotcmtdcost,0),
						ISNULL(@pocaremcmtdcost,0), ISNULL(@pocarnicost,0),
						0, 0) --DC #122288
					END
				-- update 'old' entry to JC Distribution Audit - POCA (if Tax is redirected)
				IF @pocatottax <> 0 or @pocaremtax <> 0
					BEGIN
					insert into bPOCA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
						OldNew, PO, POItem, VendorGroup, Vendor, MatlGroup, Material, Description, ActDate,
						UM, POUnits, JCUM, CmtdUnits, TotalCmtdCost, RemainCmtdCost, RecvdNInvd,
						TotalCmtdTax, RemCmtdTax)  --DC #122288
					values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @taxphase, @taxjcct, @seq,
						0, @oldpo, @oldpoitem, @vendorgroup, @vendor, @matlgroup, @material, @description, @oldactdate,
						@um, 0, @jcum, 0, ISNULL(@pocatottax,0), ISNULL(@pocaremtax,0), 0,
						ISNULL(@pocatottax,0), ISNULL(@pocaremtax,0)) --DC #122288
					END				
				END
			END
   
        IF @itemtype = 2    -- Inventory type
			BEGIN
			-- check for Location conversion
			IF @um <> @stdum
                BEGIN
                select @umconv = Conversion
                from bINMU with (nolock)
                where INCo = @posttoco and Loc = @loc and MatlGroup = @matlgroup
				and Material = @material and UM = @um
				IF @@rowcount = 0
					BEGIN
                    select @errortext = @errorstart + ' - Invalid Location, Material, and UM combination. '
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                    IF @rcode <> 0 goto bspexit
                    goto POCB_loop
                    END
                END
   
			-- change to On Order will equal change to Backorder units - converted to Std UM
			IF @oldbounits <> 0
                BEGIN
                insert into bPOCI (POCo, Mth, BatchId, INCo, Loc, MatlGroup, Material, BatchSeq, OldNew,
                    PO, POItem, VendorGroup, Vendor, UM, POUnits, StdUM, OnOrder)
                values (@co, @mth, @batchid, @posttoco, @loc, @matlgroup, @material, @seq, 0,
                    @oldpo, @oldpoitem, @vendorgroup, @vendor, @um, -(@oldbounits), @stdum, -(@oldbounits * @umconv))
                END
            END
		END  --END if @transtype in ('C','D')
   
goto POCB_loop
   
    POCB_end:
        close bcPOCB
    	deallocate bcPOCB
        select @opencursor = 0
   
    /* check HQ Batch Errors and update HQ Batch Control status */
    select @status = 3	/* valid - ok to post */
    IF exists(select * from bHQBE with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
    	BEGIN
    	select @status = 2	/* validation errors */
    	END
    update bHQBC
    set Status = @status
    where Co = @co and Mth = @mth and BatchId = @batchid
    IF @@rowcount <> 1
    	BEGIN
    	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
    	goto bspexit
    	END
   
    bspexit:
    	IF @opencursor = 1
    		BEGIN
    		close bcPOCB
    		deallocate bcPOCB
    		END
    		
    return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspPOCBVal] TO [public]
GO
