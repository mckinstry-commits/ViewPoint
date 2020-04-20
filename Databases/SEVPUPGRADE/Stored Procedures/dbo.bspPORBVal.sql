SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspPORBVal    Script Date: 8/28/99 9:36:29 AM ******/
CREATE      procedure [dbo].[bspPORBVal]
/************************************************************************
* Created: ??
* Modified by: kb 1/8/99
*		GG 11/12/99 - Cleanup
*		kb 12/5/99 - Issue #5671
*		DANF 1/29/2000 adding Receipt #
*		DANF 09/26/2000 - change conv's from bUnits to bUnitCost
*		DANF 04/18/2001 - Added Distribution tables for expense posting
*		TV   04/18/01 - Change INMT OnOrder update to = BOUnits
*		DANF 07/31/02 - Issue 18148 - Change INMT OnOrder update for Delete entries.
*		DANF 09/05/02 - 17738 Added phase group bspJobTypeVal
*		RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
*		DC 08/27/08 - #128289 PO International Sales Tax
*		TJL 04/21/09 - Issue #131487, Correct PO International Sales Tax problems for including/excluding GST
*		DC 12/07/09 - #122288 - Store Tax Rate in POIT
*		GF 12/09/2010 - issue #141031
*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*		GF 08/21/2011 TK-07879 PO Item Line work
*		JVH 9/1/11 - TK-08138 Capture SM GL distributions
*		GF 06/13/2012 TK-15622 JC RNI should not have GST included
*		JB 12/10/12 - Fix to support SM PO receiving
*       EricV 01/10/13 - TK-20694 - Checks the related SM Work Completed record and returns an error if the Provisional flag is set.
*
*
* Called by PO Batch Process program to validates a PO Receipts Batch
*
* Errors in batch added to bHQBE using bspHQBEInsert
*
* JC distributions added to bPORA
* IN distributions added to bPORI
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

declare @rcode int, @opencursor tinyint, @errorstart varchar(60), @errortext varchar(255),
	@hqmatl char(1), @stdum bUM, @umconv bUnitCost, @jcum bUM, @jcumconv bUnitCost, @taxrate bRate,
	@taxphase bPhase, @taxjcct bJCCType, @receiptupdate bYN

-- PO Receipt Batch declares
declare @seq int, @transtype char(1), @potrans bTrans, @po varchar(30), @poitem bItem, @recvddate bDate,
	@recvdby varchar(10), @description bDesc, @recvdunits bUnits, @recvdcost bDollar, @bounits bUnits,
	@bocost bDollar, @oldpo varchar(30), @oldpoitem bItem, @oldrecvddate bDate, @oldrecvdby varchar(10),
	@olddesc bDesc, @oldrecvdunits bUnits, @oldrecvdcost bDollar, @oldbounits bUnits, @oldbocost bDollar,
	@Receiver# varchar(20), @OldReceiver# varchar(20)
   
-- PO Header declares
declare @status tinyint, @inusemth bMonth, @inusebatchid bBatchID, @VendorGroup bGroup, @Vendor bVendor
   
-- PO Item declares
declare @itemtype tinyint, @matlgroup bGroup, @material bMatl, @um bUM, @recvyn bYN, @posttoco bCompany,
	@loc bLoc, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @glco bCompany, @taxgroup bGroup,
	@taxcode bTaxCode, @poitcurunitcost bUnitCost, @poitcurecm bECM, @glacct bGLAcct
   
-- PO JC declares
declare @porarnicost bDollar, @poracmtdcost bDollar, @factor smallint, @porarnitax bDollar, @poracmtdtax bDollar
   
-- PO Receipt Detail declares
declare @pordpo varchar(30), @pordpoitem bItem,  @pordrecvddate bDate, @pordrecvdby varchar(10), @porddescription bDesc,
	@pordrecvdunits bUnits, @pordrecvdcost bDollar, @pocdecm bECM, @pordbounits bUnits, @pordbocost bDollar
	
--Tax declares  --DC #128289
declare @dateposted bDate, @valueadd char(1), @gstrate bRate, @pstrate bRate, @HQTXdebtGLAcct bGLAcct, 
	@oldtaxrate bRate, @oldgstrate bRate, @oldpstrate bRate, @oldHQTXdebtGLAcct bGLAcct,
	@rnitaxbasis bDollar, @rnipsttaxbasis bDollar, @rnigsttaxbasis bDollar, @rnitaxamt bDollar, @rnipsttaxamt bDollar, @rnigsttaxamt bDollar, 
	@oldrnitaxbasis bDollar, @oldrnipsttaxbasis bDollar, @oldrnigsttaxbasis bDollar, @oldrnitaxamt bDollar, @oldrnipsttaxamt bDollar, @oldrnigsttaxamt bDollar, 
	@cmtdtaxbasis bDollar, @cmtdpsttaxbasis bDollar, @cmtdgsttaxbasis bDollar, @cmtdtaxamt bDollar, @cmtdpsttaxamt bDollar, @cmtdgsttaxamt bDollar, 
	@oldcmtdtaxbasis bDollar, @oldcmtdpsttaxbasis bDollar, @oldcmtdgsttaxbasis bDollar,
	@oldcmtdtaxamt bDollar, @oldcmtdpsttaxamt bDollar, @oldcmtdgsttaxamt bDollar,
	----TK-07879
	@OldPOItemLine INT, @POItemLine INT, @PORDPOItemLine INT, @PORARemCmtdTax bDollar, @TaxType TINYINT

-- SM Declares
DECLARE @Provisional bit, @SMCo bCompany, @SMWorkOrder int, @SMScope int

DECLARE @HQBatchDistributionID bigint
	
select @dateposted = dbo.vfDateOnly(),
	@rnitaxbasis = 0, @rnitaxamt = 0, @rnigsttaxamt = 0, @rnipsttaxamt = 0,
	@oldrnitaxbasis = 0, @oldrnitaxamt = 0, @oldrnigsttaxamt = 0, @oldrnipsttaxamt = 0,
  	@cmtdtaxbasis = 0, @cmtdtaxamt = 0, @cmtdgsttaxamt = 0, @cmtdpsttaxamt = 0,
	@oldcmtdtaxbasis = 0, @oldcmtdtaxamt = 0, @oldcmtdgsttaxamt = 0, @oldcmtdpsttaxamt = 0

	--Verify that the batch can be validated, set the batch status to validating and delete generic distributions
	EXEC @rcode = dbo.vspHQBatchValidating @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @Source = @source, @TableName = 'PORB', @HQBatchDistributionID = @HQBatchDistributionID OUTPUT, @msg = @errmsg OUTPUT
	IF @rcode <> 0 RETURN @rcode



/* clear PO JC Distribution Audit */
delete bPORA where POCo = @co and Mth = @mth and BatchId = @batchid
/* clear PO IN Distribution Audit */
delete bPORI where POCo = @co and Mth = @mth and BatchId = @batchid
/* clear PO JC Distribution Audit */
delete bPORJ where POCo = @co and Mth = @mth and BatchId = @batchid
/* clear PO GL Distribution Audit */
delete bPORG where POCo = @co and Mth = @mth and BatchId = @batchid
/* clear PO EM Distribution Audit */
delete bPORE where POCo = @co and Mth = @mth and BatchId = @batchid
/* clear PO IN Distribution Audit */
delete bPORN where POCo = @co and Mth = @mth and BatchId = @batchid

DELETE vGLEntry
FROM dbo.vGLEntryBatch
	INNER JOIN dbo.vGLEntry ON vGLEntryBatch.GLEntryID = vGLEntry.GLEntryID
WHERE vGLEntryBatch.Co = @co AND vGLEntryBatch.Mth = @mth AND vGLEntryBatch.BatchId = @batchid

-- Set the Receipt Update flag...
select @receiptupdate=ReceiptUpdate from bPOCO with (nolock)
where POCo = @co
   
-- create cursor on PO Receipts Batch for validation
declare bcPORB cursor for
select  BatchSeq, BatchTransType, POTrans, PO, POItem, RecvdDate, RecvdBy,
		Description, RecvdUnits, RecvdCost, BOUnits, BOCost, OldPO, OldPOItem,
		OldRecvdDate, OldRecvdBy, OldDesc, OldRecvdUnits, OldRecvdCost,
		OldBOUnits, OldBOCost, Receiver#, OldReceiver#,
		----TK-07879
		POItemLine, OldPOItemLine
from bPORB with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
   
open bcPORB
select @opencursor = 1  -- set open cursor flag

PORB_loop:      -- process each entry
fetch next from bcPORB into @seq, @transtype, @potrans, @po, @poitem, @recvddate, @recvdby,
		@description, @recvdunits, @recvdcost, @bounits, @bocost, @oldpo,
		@oldpoitem, @oldrecvddate, @oldrecvdby, @olddesc, @oldrecvdunits,
		@oldrecvdcost, @oldbounits, @oldbocost, @Receiver#, @OldReceiver#,
		----TK-07879
		@POItemLine, @OldPOItemLine
   
if @@fetch_status <> 0 goto PORB_end

select @errorstart = 'Seq#' + convert(varchar(6),@seq)
   
-- validate transaction type
if @transtype not in ('A','C','D')
	begin
	select @errortext = @errorstart + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto PORB_loop
	end

if @transtype in ('A','C')       -- validation specific to 'add' and 'change' entries
	begin
    if @transtype = 'A' and @potrans is not null
		begin
        select @errortext = @errorstart + ' -  PO Change Transaction must be null for ''add'' entries.'
 		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 		if @rcode <> 0 goto bspexit
        goto PORB_loop
 		end
        -- validate PO#
 	    select @status = Status, @inusemth = InUseMth, @inusebatchid = InUseBatchId, @VendorGroup = VendorGroup, @Vendor = Vendor
        from bPOHD with (nolock) where POCo = @co and PO = @po
 	    if @@rowcount = 0
 			begin
 		    select @errortext = @errorstart + ' - Invalid PO.'
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 		    if @rcode <> 0 goto bspexit
            goto PORB_loop
 		    end
        if @status <> 0
			begin
 		    select @errortext = @errorstart + ' - PO must be ''open''.'
 		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 		    if @rcode <> 0 goto bspexit
            goto PORB_loop
 		    end
        if @inusemth is null or @inusebatchid is null
            begin
            select @errortext = @errorstart + ' - PO Header has not been flagged as ''In Use'' by this batch.'
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 		    if @rcode <> 0 goto bspexit
            goto PORB_loop
 		    end
        if @inusemth <> @mth or @inusebatchid <> @batchid
            begin
            select @errortext = @errorstart + ' - PO Header ''In Use'' by another batch.'
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 		    if @rcode <> 0 goto bspexit
            goto PORB_loop
 		    END
 		    
 	    -- validate Item and get current values
 	    ----TK-07879
 	    select  @matlgroup = MatlGroup, @material = Material,
 				@um = UM, @recvyn = RecvYN, @poitcurunitcost = CurUnitCost, @poitcurecm = CurECM
				 --@posttoco = PostToCo, @loc = Loc, @job = Job, @phasegroup = PhaseGroup, @phase = Phase,
				 --@jcctype = JCCType, @glco = GLCo, @taxgroup = TaxGroup, @taxcode = TaxCode,
				 --@poitcurunitcost = CurUnitCost, @poitcurecm = CurECM, @glacct = GLAcct,
				 --@taxrate = TaxRate, @gstrate = GSTRate, @itemtype = ItemType   --DC #122288
 	    from dbo.bPOIT with (nolock)
        where POCo = @co and PO = @po and POItem = @poitem
 	    if @@rowcount = 0
 			begin
 		    select @errortext = @errorstart + ' - Invalid PO Item.'
 		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 		    if @rcode <> 0 goto bspexit
            goto PORB_loop
 		    end
        -- check Receiving flag
        if @recvyn = 'N'
			begin
 		    select @errortext = @errorstart + ' - PO Item is not flagged for receiving.'
 		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 		    if @rcode <> 0 goto bspexit
            goto PORB_loop
 		    end

		---- validate PO Item line and get current values TK-07879
		SELECT  @itemtype = vPOItemLine.ItemType, @posttoco = vPOItemLine.PostToCo, @loc = vPOItemLine.Loc, @job = vPOItemLine.Job,
				@phasegroup = vPOItemLine.PhaseGroup, @phase = vPOItemLine.Phase, @jcctype = vPOItemLine.JCCType,
				@taxgroup = vPOItemLine.TaxGroup, @taxcode = vPOItemLine.TaxCode, @glco = vPOItemLine.GLCo, 
				@glacct = vPOItemLine.GLAcct, @taxrate = vPOItemLine.TaxRate, @gstrate = vPOItemLine.GSTRate,
				@TaxType = vPOItemLine.TaxType, 
				@Provisional = ISNULL(vSMWorkCompleted.Provisional,0),
				@SMCo = vSMWorkCompleted.SMCo, 
				@SMWorkOrder = vSMWorkCompleted.WorkOrder,
				@SMScope = vSMWorkCompletedDetail.Scope
		FROM dbo.vPOItemLine
		LEFT JOIN dbo.vSMWorkCompleted 
			ON vSMWorkCompleted.SMCo = vPOItemLine.SMCo
			AND vSMWorkCompleted.WorkOrder = vPOItemLine.SMWorkOrder
			AND vSMWorkCompleted.WorkCompleted = vPOItemLine.SMWorkCompleted
		LEFT JOIN dbo.vSMWorkCompletedDetail 
			ON vSMWorkCompleted.SMCo = vSMWorkCompletedDetail.SMCo
			AND vSMWorkCompleted.WorkOrder = vSMWorkCompletedDetail.WorkOrder
			AND vSMWorkCompleted.WorkCompleted = vSMWorkCompletedDetail.WorkCompleted
		WHERE POCo = @co
			AND PO = @po
			AND POItem = @poitem
			AND POItemLine = @POItemLine
 	    if @@rowcount = 0
 			begin
 		    select @errortext = @errorstart + ' - Invalid PO Item Line.'
 		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 		    if @rcode <> 0 goto bspexit
            goto PORB_loop
 		    end
		-- Check to see if a related SM Work Completed record is Provisional
		IF @Provisional=1
		BEGIN
 		    select @errortext = @errorstart + ' - SMCo: '+dbo.vfToString(@SMCo)+' Work Order: '+dbo.vfToString(@SMWorkOrder)+' Scope: '+dbo.vfToString(@SMScope)+' is missing Call Type and/or Rate template.'
 		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 		    if @rcode <> 0 goto bspexit
            goto PORB_loop		
		END
		
		-- init material defaults
        select @hqmatl = 'N', @stdum = null, @umconv = 0

        -- check for Material in HQ
        select @stdum = StdUM
        from bHQMT with (nolock)
        where MatlGroup = @matlgroup and Material = @material
        if @@rowcount = 1
			begin
            select @hqmatl = 'Y'    -- setup in HQ Materials
            if @stdum = @um select @umconv = 1
            end
        -- if HQ Material, validate UM and get unit of measure conversion
        if @hqmatl = 'Y' and @um <> @stdum
			begin
            select @umconv = Conversion
            from bHQMU with (nolock)
            where MatlGroup = @matlgroup and Material = @material and UM = @um
            if @@rowcount = 0
				begin
 		        select @errortext = @errorstart + ' - Invalid unit of measure for this Material.'
 		        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 		        if @rcode <> 0 goto bspexit
                goto PORB_loop
 		        end
            end
   
        if @itemtype = 1   -- Job type
			begin
 		    exec @rcode = bspJobTypeVal @posttoco, @phasegroup, @job, @phase, @jcctype, @jcum output, @errmsg output
 		    if @rcode <> 0
				begin
 		        select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
 		        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 		        if @rcode <> 0 goto bspexit
                goto PORB_loop
 		        end

            -- determine conversion factor from posted UM to JC UM
            select @jcumconv = 0
            if isnull(@jcum,'') = @um select @jcumconv = 1

            if @hqmatl = 'Y' and isnull(@jcum,'') <> @um
				begin
                exec @rcode = bspHQStdUMGet @matlgroup, @material, @jcum, @jcumconv output, @stdum output, @errmsg output
                if @rcode <> 0
					begin
                    select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                    if @rcode <> 0 goto bspexit
                    goto PORB_loop
                    end
				if @jcumconv <> 0 select @jcumconv = @umconv / @jcumconv
				end
   
            -- get Tax Rate, Phase, and Cost Type
            if @taxcode is not null
				begin
				--select @taxrate = 0  DC #122288
				select @pstrate = 0  --DC #122288

				-- DC  #128925  --START
				-- need to calculate orig tax for existing item when tax code was null now not null
				-- if @reqdate is null use today's date
				if isnull(@recvddate,'') = '' select @recvddate = @dateposted
				-- get Tax Rate
				--DC #122288
				exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @recvddate, @valueadd output, NULL, @taxphase output, @taxjcct output, 
					NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output				
 		        /*exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @recvddate, null, @taxphase output,
                     @taxjcct output, @errmsg output */                                          
 		        if @rcode <> 0
					begin
                    select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
 			        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                    if @rcode <> 0 goto bspexit
                    goto PORB_loop
                    end 
                
                ----TK-15622
                SET @pstrate = @taxrate - @gstrate
				----select @pstrate = (case when @HQTXdebtGLAcct is null then 0 else @taxrate - @gstrate end) -- (case when @gstrate = 0 then 0 else @taxrate - @gstrate end)	

				if @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
					begin
					-- We have an Intl VAT code being used as a Single Level Code
					if (select GST from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
						begin
						select @gstrate = @taxrate
						end
					end
				
				-- Tax Amounts get determined below
														
                end
   
            -- set Tax Phase and Cost Type
 		    if @taxphase is null select @taxphase = @phase
 		    if @taxjcct is null select @taxjcct = @jcctype
   
            -- validate Mth in GL Company
            exec @rcode = bspHQBatchMonthVal @glco, @mth, 'PO', @errmsg output
            if @rcode <> 0
				begin
   	            select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
    	        goto PORB_loop
   	            end
   
            -- calculate the change to JC RecvdNInvcd and Committed Costs - result used for 'new' entry in PORA
            if @um = 'LS'
				begin
				-- change to RecvdNInvcd Cost equal to change in Received Cost
                select @porarnicost = @recvdcost
                -- change to Total and Remaining Committed Cost equal to sum of changes to Received plus Backordered
                select @poracmtdcost = @recvdcost + @bocost
                end
            if @um <> 'LS'
				begin
                select @factor = case @poitcurecm when 'C' then 100 when 'M' then 1000 else 1 end
                -- change to RecvdNInvcd Cost equal to change in Received Units times Current Unit Cost
                select @porarnicost = (@recvdunits * @poitcurunitcost) / @factor
                -- change to Total and Remmaining Committed Cost equal to sum of changes to Received plus Backordered
                -- units times Current Unit Cost
                select @poracmtdcost = ((@recvdunits + @bounits) * @poitcurunitcost) / @factor
                end

            --select @porarnitax = @porarnicost * @taxrate    -- may be redirected, keep separate
            --select @poracmtdtax = @poracmtdcost * @taxrate
   
			if @taxcode is not null
				begin
				select @rnitaxbasis = @porarnicost, @porarnitax = @rnitaxbasis * @taxrate					--Full TaxAmount based upon combined TaxRate	1000 * .155 = 155
				select @rnigsttaxamt = case when @taxrate = 0 then 0 else
					case @valueadd when 'Y' then (@porarnitax * @gstrate) / @taxrate else 0 end end		--GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
				----TK-15622
				select @rnipsttaxamt = case @valueadd when 'Y' then @porarnitax - @rnigsttaxamt else 0 end	--PST Tax Amount.  (Rounding errors to PST)		155 - 50 = 105

				select @cmtdtaxbasis = @poracmtdcost, @poracmtdtax = @cmtdtaxbasis * @taxrate							
				select @cmtdgsttaxamt = case when @taxrate = 0 then 0 else
					case @valueadd when 'Y' then (@poracmtdtax * @gstrate) / @taxrate else 0 end end	
				select @cmtdpsttaxamt = case @valueadd when 'Y' then @poracmtdtax - @cmtdgsttaxamt else 0 end			

				if @taxphase = @phase and @taxjcct = @jcctype
					BEGIN
					----TK-15622
					SET @porarnicost = @porarnicost + @porarnitax - @rnigsttaxamt
					SET @poracmtdcost = @poracmtdcost + @poracmtdtax - @cmtdgsttaxamt
					--select @porarnicost = @porarnicost + case when @HQTXdebtGLAcct is null then @porarnitax else @porarnitax - @rnigsttaxamt end
					--select @poracmtdcost = @poracmtdcost + case when @HQTXdebtGLAcct is null then @poracmtdtax else @poracmtdtax - @cmtdgsttaxamt end
					end
                end


IF ISNULL(@taxcode ,'') = ''
	BEGIN
	SET @taxphase = @phase
	SET @taxjcct = @jcctype
	SET @poracmtdtax = 0
	SET @PORARemCmtdTax = 0
	END
ELSE
	BEGIN
	----TK-15622
	SET @PORARemCmtdTax = @poracmtdtax - @cmtdgsttaxamt
	----SET @PORARemCmtdTax = case when @HQTXdebtGLAcct is null then @poracmtdtax ELSE @poracmtdtax - @cmtdgsttaxamt end
	END
	
--select @errmsg = 'Cost: ' + dbo.vfToString(@poracmtdcost)+ ', Tax: ' + dbo.vfToString(@poracmtdtax) + ',' + dbo.vfToString(@PORARemCmtdTax)
--SET @rcode = 1
--goto bspexit
			
---- update 'new' entry to JC Distribution Audit - PORA
if @recvdunits <> 0 or @bounits <> 0 or @porarnicost <> 0 or @poracmtdcost <> 0
	begin
    insert into dbo.bPORA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
			OldNew, PO, POItem, UM, RecvdUnits, BOUnits, JCUM, RNIUnits, RNICost, CmtdUnits,
			CmtdCost, VendorGroup, Vendor, Description, RecDate, MatlGroup, Material,
			GLCo, GLAcct, JCUnits, JCUnitCost, ECM, TotalCost, RemCmtdCost,
			----DC #122288 TK-07879
			TotalCmtdTax, RemCmtdTax, POItemLine, TaxGroup, TaxType, TaxCode)
	values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @phase, @jcctype, @seq,
			1, @po, @poitem, @um, @recvdunits, @bounits, @jcum, (@recvdunits * @jcumconv),
			@porarnicost, ((@recvdunits + @bounits) * @jcumconv), @poracmtdcost,
			@VendorGroup, @Vendor, @description, @recvddate, @matlgroup, @material,
			@glco, @glacct, 0, 0, Null, 0, 0,
			----DC #122288 TK-07879
			----0, 0, @POItemLine)
			CASE WHEN (@taxphase = @phase AND @taxjcct = @jcctype) THEN @PORARemCmtdTax ELSE 0 END,
			CASE WHEN (@taxphase = @phase AND @taxjcct = @jcctype) THEN @PORARemCmtdTax ELSE 0 END,
			@POItemLine, @taxgroup, @TaxType, @taxcode)
    end

-- update 'new' entry to JC Distribution Audit for Tax (if redirected)
if @taxcode is not null and (@taxphase <> @phase or @taxjcct <> @jcctype) and (@porarnitax <> 0  or @poracmtdtax <> 0)
    begin
	insert into dbo.bPORA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
			OldNew, PO, POItem, UM, RecvdUnits, BOUnits, JCUM, RNIUnits, RNICost, CmtdUnits,
			CmtdCost, VendorGroup, Vendor, Description, RecDate, MatlGroup, Material,
			GLCo, GLAcct, JCUnits, JCUnitCost, ECM, TotalCost, RemCmtdCost,
			----DC #122288 TK-07879
			TotalCmtdTax, RemCmtdTax, POItemLine, TaxGroup, TaxType, TaxCode)
	values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @taxphase, @taxjcct, @seq,
            1, @po, @poitem, @um, 0, 0, @jcum, 0
            ----TK-15622
            ,@porarnitax - @rnigsttaxamt
            ,0 
			,@poracmtdtax - @cmtdgsttaxamt
			--case when @HQTXdebtGLAcct is null then @porarnitax else @porarnitax - @rnigsttaxamt end, 0, 
			--case when @HQTXdebtGLAcct is null then @poracmtdtax else @poracmtdtax - @cmtdgsttaxamt end,
            ,@VendorGroup, @Vendor, @description, @recvddate, @matlgroup, @material,
            @glco, @glacct, 0, 0, Null, 0, 0,
            ----DC #122288 TK-07879
            ---- 0, 0, @POItemLine)
            @PORARemCmtdTax, @PORARemCmtdTax, @POItemLine, @taxgroup, @TaxType, @taxcode)
     end
end
   
if @itemtype = 2    -- Inventory type
	begin
    -- check for Location conversion
    if @um <> @stdum
		begin
        select @umconv = Conversion
        from bINMU with (nolock)
        where INCo = @posttoco and Loc = @loc and MatlGroup = @matlgroup
			and Material = @material and UM = @um
		if @@rowcount = 0
			begin
            select @errortext = @errorstart + ' - Invalid Location ' + @loc + ', Material ' + convert(varchar(20),@material) + ', and UM combination. '
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
            if @rcode <> 0 goto bspexit
            goto PORB_loop
            end
        end

	-- change to RecvdNInvcd will equal change to Received units - converted to Std UM
    -- change to On Order will equal sum of change to Received plus Backorder units - converted to Std UM
    if @recvdunits <> 0 or @bounits <> 0
		begin
        insert into bPORI (POCo, Mth, BatchId, INCo, Loc, MatlGroup, Material, BatchSeq, OldNew,
            PO, POItem, UM, RecvdUnits, BOUnits, StdUM, RecvdNInvcd, OnOrder)
        values (@co, @mth, @batchid, @posttoco, @loc, @matlgroup, @material, @seq, 1,
            @po, @poitem, @um, @recvdunits, @bounits, @stdum, (@recvdunits * @umconv),
             (@bounits * @umconv))
        end
    end
end
   
if @transtype in ('C','D')  -- validation specific to 'change' and 'delete' entries
	begin
    select @pordpo = PO, @pordpoitem = POItem, @pordrecvddate = RecvdDate,
			@pordrecvdby = RecvdBy, @porddescription = Description,
			@pordrecvdunits = RecvdUnits, @pordrecvdcost = RecvdCost,
			@pordbounits = BOUnits, @pordbocost = BOCost,
			----TK-07879
			@PORDPOItemLine = POItemLine
	from bPORD with (nolock)
    where POCo = @co and Mth = @mth and POTrans = @potrans
    if @@rowcount = 0
		begin
        select @errortext = @errorstart + ' - Invalid PO Receipts Transaction!'
        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        if @rcode <> 0 goto bspexit
        goto PORB_loop
        end
	----TK-07879
    if @pordpo <> @oldpo
		or @pordpoitem <> @oldpoitem
		or @PORDPOItemLine <> @OldPOItemLine
		or @pordrecvddate <> @oldrecvddate
		or isnull(@pordrecvdby,'') <> isnull(@oldrecvdby,'')
        or isnull(@porddescription,'') <> isnull(@olddesc,'')
        or @pordrecvdunits <> @oldrecvdunits or @pordrecvdcost <> @oldrecvdcost
        or @pordbounits <> @oldbounits or @pordbocost <> @oldbocost
        begin
        select @errortext = @errorstart + ' - ''Old'' batch values do not match current Transaction values!'
        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        if @rcode <> 0 goto bspexit
        goto PORB_loop
        END

	-- get 'old' info needed for update to PORA and PORI
	-- validate old PO#
	select @status = Status
	from bPOHD with (nolock) where POCo = @co and PO = @oldpo
	if @@rowcount = 0
		begin
		select @errortext = @errorstart + ' - Invalid PO.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto PORB_loop
		end
	if @status <> 0
		begin
		select @errortext = @errorstart + ' - PO must be ''open''.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto PORB_loop
		END
	    
    -- validate old Item and get current values TK-07879
    select @matlgroup = MatlGroup, @material = Material, @um = UM,
			@poitcurunitcost = CurUnitCost, @poitcurecm = CurECM
         --@posttoco = PostToCo, @loc = Loc, @job = Job, @phasegroup = PhaseGroup, @phase = Phase,
         --@jcctype = JCCType, @glco = GLCo, @taxgroup = TaxGroup, @taxcode = TaxCode,
         --@oldtaxrate = TaxRate, @oldgstrate = GSTRate, @itemtype = ItemType  --DC #122288
    from bPOIT with (nolock)
    where POCo = @co and PO = @oldpo and POItem = @oldpoitem
    if @@rowcount = 0
		begin
	    select @errortext = @errorstart + ' - Invalid PO Item.'
	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	    if @rcode <> 0 goto bspexit
        goto PORB_loop
	    end

	---- validate OLD PO Item line and get current values TK-07879
	SELECT  @itemtype = ItemType, @posttoco = PostToCo, @loc = Loc, @job = Job,
			@phasegroup = PhaseGroup, @phase = Phase, @jcctype = JCCType,
			@taxgroup = TaxGroup, @taxcode = TaxCode, @glco = GLCo, 
			@glacct = GLAcct, @oldtaxrate = TaxRate, @oldgstrate = GSTRate,
			@TaxType = TaxType
	FROM dbo.vPOItemLine
	WHERE POCo = @co
		AND PO = @oldpo
		AND POItem = @oldpoitem
		AND POItemLine = @OldPOItemLine
    if @@rowcount = 0
		begin
	    select @errortext = @errorstart + ' - Invalid PO Item Line.'
	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	    if @rcode <> 0 goto bspexit
        goto PORB_loop
	    end

	-- init material defaults
    select @hqmatl = 'N', @stdum = null, @umconv = 0

    -- check for Material in HQ
    select @stdum = StdUM
	from bHQMT with (nolock)
    where MatlGroup = @matlgroup and Material = @material
    if @@rowcount = 1
		begin
        select @hqmatl = 'Y'    -- setup in HQ Materials
        if @stdum = @um select @umconv = 1
        end
    -- if HQ Material, validate UM and get unit of measure conversion
    if @hqmatl = 'Y' and @um <> @stdum
		begin
        select @umconv = Conversion
        from bHQMU with (nolock)
        where MatlGroup = @matlgroup and Material = @material and UM = @um
        if @@rowcount = 0
			begin
	        select @errortext = @errorstart + ' - Invalid unit of measure for this Material.'
	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	        if @rcode <> 0 goto bspexit
            goto PORB_loop
	        end
        end

    if @itemtype = 1   -- Job type
		begin
	    exec @rcode = bspJobTypeVal @posttoco, @phasegroup, @job, @phase, @jcctype, @jcum output, @errmsg output
	    if @rcode <> 0
			begin
	        select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	        if @rcode <> 0 goto bspexit
            goto PORB_loop
	        end

        -- determine conversion factor from posted UM to JC UM
        select @jcumconv = 0
        if isnull(@jcum,'') = @um select @jcumconv = 1

        if @hqmatl = 'Y' and isnull(@jcum,'') <> @um
			begin
            exec @rcode = bspHQStdUMGet @matlgroup, @material, @jcum, @jcumconv output, @stdum output, @errmsg output
            if @rcode <> 0
				begin
                select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
                exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto PORB_loop
                end
            if @jcumconv <> 0 select @jcumconv = @umconv / @jcumconv
            end
   
        -- get Tax Rate, Phase, and Cost Type
        if ISNULL(@taxcode,'') <> ''
			begin	
			-- select @oldtaxrate = 0  DC #122288
			select @oldpstrate = 0 --DC #122288				
			
			-- DC  #128925  --START
			-- need to calculate orig tax for existing item when tax code was null now not null
			-- if @reqdate is null use today's date
			if isnull(@oldrecvddate,'') = '' select @oldrecvddate = @dateposted
			-- get Tax Rate
			--DC #122288
			exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @oldrecvddate, @valueadd output, NULL, @taxphase output, @taxjcct output, 
				NULL, NULL, NULL, NULL, @oldHQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output				
	        /*exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @oldrecvddate, null, @taxphase output,
                 @taxjcct output, @errmsg output */
	        if @rcode <> 0
				begin
                select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
		        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto PORB_loop
                end

			----TK-15622
			SET @oldpstrate = @oldtaxrate - @oldgstrate
			--select @oldpstrate = (case when @oldHQTXdebtGLAcct is null then 0 else @oldtaxrate - @oldgstrate end) --(case when @oldgstrate = 0 then 0 else @oldtaxrate - @oldgstrate end)  --DC #122288

			if @oldgstrate = 0 and @oldpstrate = 0 and @valueadd = 'Y'
				begin
				-- We have an Intl VAT code being used as a Single Level Code
				if (select GST from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
					begin
					select @oldgstrate = @oldtaxrate
					end
				end

			end
   
        -- set Tax Phase and Cost Type
	    if @taxphase is null select @taxphase = @phase
	    if @taxjcct is null select @taxjcct = @jcctype

        -- validate Mth in GL Company
        exec @rcode = bspHQBatchMonthVal @glco, @mth, 'PO', @errmsg output
        if @rcode <> 0
			begin
            select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
	        goto PORB_loop
            end

        -- calculate the change to JC RecvdNInvcd and Committed Costs - result used for 'old' entry in PORA
        if @um = 'LS'
			begin
            -- change to RecvdNInvcd Cost equal to change in Received Cost
            select @porarnicost = -(@oldrecvdcost)      -- back out 'old' change
            -- change to Total and Remaining Committed Cost equal to sum of changes to Received plus Backordered
            select @poracmtdcost = -(@oldrecvdcost + @oldbocost)      -- back out 'old' change
			end
        if @um <> 'LS'
            begin
			select @factor = case @poitcurecm when 'C' then 100 when 'M' then 1000 else 1 end
			-- change to RecvdNInvcd Cost equal to change in Received Units times Current Unit Cost
            select @porarnicost = -(@oldrecvdunits * @poitcurunitcost) / @factor       -- back out 'old' change
            -- change to Total and Remmaining Committed Cost equal to sum or changes to Received plus Backordered
            -- units times Current Unit Cost
            select @poracmtdcost = (-(@oldrecvdunits + @oldbounits) * @poitcurunitcost) / @factor     -- back out 'old'
            END


		if ISNULL(@taxcode,'') <> ''
			begin
			select @oldrnitaxbasis = @porarnicost, @porarnitax = @oldrnitaxbasis * @oldtaxrate						--Full TaxAmount based upon combined TaxRate	1000 * .155 = 155
			select @oldrnigsttaxamt = case when @oldtaxrate = 0 then 0 else
				case @valueadd when 'Y' then (@porarnitax * @oldgstrate) / @oldtaxrate else 0 end end			--GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
			select @oldrnipsttaxamt = case @valueadd when 'Y' then @porarnitax - @oldrnigsttaxamt else 0 end		--PST Tax Amount.  (Rounding errors to PST)		155 - 50 = 105

			select @oldcmtdtaxbasis = @poracmtdcost, @poracmtdtax = @oldcmtdtaxbasis * @oldtaxrate							
			select @oldcmtdgsttaxamt = case when @oldtaxrate = 0 then 0 else
				case @valueadd when 'Y' then (@poracmtdtax * @oldgstrate) / @oldtaxrate else 0 end end	
			select @oldcmtdpsttaxamt = case @valueadd when 'Y' then @poracmtdtax - @oldcmtdgsttaxamt else 0 end	
   
			if @taxphase = @phase and @taxjcct = @jcctype
				BEGIN
				----TK-15622
				SET @porarnicost = @porarnicost + @porarnitax - @oldrnigsttaxamt
				set @poracmtdcost = @poracmtdcost + @poracmtdtax - @oldcmtdgsttaxamt
				--select @porarnicost = @porarnicost + case when @oldHQTXdebtGLAcct is null then @porarnitax else @porarnitax - @oldrnigsttaxamt end
				--select @poracmtdcost = @poracmtdcost + case when @oldHQTXdebtGLAcct is null then @poracmtdtax else @poracmtdtax - @oldcmtdgsttaxamt end
				end
			END
			
		----TK-07879	
		IF ISNULL(@taxcode ,'') = ''
			BEGIN
			SET @taxphase = @phase
			SET @taxjcct = @jcctype
			SET @poracmtdtax = 0
			SET @PORARemCmtdTax = 0
			END
		ELSE
			BEGIN
			----TK-15622
			SET @PORARemCmtdTax = @poracmtdtax - @oldcmtdgsttaxamt
			--SET @PORARemCmtdTax = case when @oldHQTXdebtGLAcct is null then @poracmtdtax ELSE @poracmtdtax - @oldcmtdgsttaxamt end
			END
	
        -- update 'old' entry to JC Distribution Audit - PORA
		-- issue #5671, was writing out PORA records with OldNew = 1 instead of 0 fixed here and below.
        if @oldrecvdunits <> 0 or @oldbounits <> 0 or @porarnicost <> 0 or @poracmtdcost <> 0
			BEGIN
            insert into bPORA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
				OldNew, PO, POItem, UM, RecvdUnits, BOUnits, JCUM, RNIUnits, RNICost, CmtdUnits, CmtdCost,
                VendorGroup, Vendor, Description, RecDate, MatlGroup, Material, GLCo, GLAcct, JCUnits,
                JCUnitCost, ECM, TotalCost, RemCmtdCost,
                ----DC #122288 TK-07879
                TotalCmtdTax, RemCmtdTax, POItemLine, TaxGroup, TaxType, TaxCode)
			values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @phase, @jcctype, @seq,
                 0, @po, @poitem, @um, -(@oldrecvdunits), -(@oldbounits), @jcum, -(@oldrecvdunits * @jcumconv),
                 @porarnicost, (-(@oldrecvdunits + @oldbounits) * @jcumconv), @poracmtdcost,
                 @VendorGroup, @Vendor, @description, @recvddate, @matlgroup, @material, @glco, @glacct, 0,
                 0, Null, 0, 0,
                 ----DC #122288 TK-07879
                 ----0, 0, @POItemLine)
				CASE WHEN (@taxphase = @phase AND @taxjcct = @jcctype) THEN @PORARemCmtdTax ELSE 0 END,
				CASE WHEN (@taxphase = @phase AND @taxjcct = @jcctype) THEN @PORARemCmtdTax ELSE 0 END,
				@POItemLine, @taxgroup, @TaxType, @taxcode)
            end
  
        -- update 'old entry to JC Distribution Audit for Tax (if redirected)
        if @taxcode is not null and (@taxphase <> @phase or @taxjcct <> @jcctype) and (@porarnitax <> 0  or @poracmtdtax <> 0)
			begin
			insert into bPORA (POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
				OldNew, PO, POItem, UM, RecvdUnits, BOUnits, JCUM, RNIUnits, RNICost, CmtdUnits, CmtdCost,
                VendorGroup, Vendor, Description, RecDate, MatlGroup, Material, GLCo, GLAcct, JCUnits,
                JCUnitCost, ECM, TotalCost, RemCmtdCost,
                ----DC #122288 TK-07879
                TotalCmtdTax, RemCmtdTax, POItemLine, TaxGroup, TaxType, TaxCode)
			values (@co, @mth, @batchid, @posttoco, @job, @phasegroup, @taxphase, @taxjcct, @seq,
				0, @po, @poitem, @um, 0, 0, @jcum, 0
				----TK-15622
				,@porarnitax - @oldrnigsttaxamt
				,0
				,@poracmtdtax - @oldcmtdgsttaxamt
				--case when @oldHQTXdebtGLAcct is null then @porarnitax else @porarnitax - @oldrnigsttaxamt end, 0,
				--case when @oldHQTXdebtGLAcct is null then @poracmtdtax else @poracmtdtax - @oldcmtdgsttaxamt end,
				,@VendorGroup, @Vendor, @description, @recvddate, @matlgroup, @material, @glco, @glacct, 0,
				0, Null, 0, 0,
				----DC #122288 tk-07879
				---- 0, 0, @POItemLine)
				@PORARemCmtdTax, @PORARemCmtdTax, @POItemLine, @taxgroup, @TaxType, @taxcode)
            end
	    end

		if @itemtype = 2    -- Inventory type
			begin
            -- check for Location conversion
            if @um <> @stdum
				begin
                select @umconv = Conversion
                from bINMU with (nolock)
                where INCo = @posttoco and Loc = @loc and MatlGroup = @matlgroup
					and Material = @material and UM = @um
                if @@rowcount = 0
					begin
                    select @errortext = @errorstart + ' - Invalid Location, Material, and UM combination. '
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                    if @rcode <> 0 goto bspexit
                    goto PORB_loop
					end
                end
   
				-- change to RecvdNInvcd will equal change to Received units - converted to Std UM
				-- change to On Order will equal sum of change to Received plus Backorder units - converted to Std UM
				if @oldrecvdunits <> 0 or @oldbounits <> 0
					begin
					insert into bPORI (POCo, Mth, BatchId, INCo, Loc, MatlGroup, Material, BatchSeq, OldNew,
						PO, POItem, UM, RecvdUnits, BOUnits, StdUM, RecvdNInvcd, OnOrder)
					values (@co, @mth, @batchid, @posttoco, @loc, @matlgroup, @material, @seq, 0,
						@po, @poitem, @um, -(@oldrecvdunits), -(@oldbounits), @stdum, -(@oldrecvdunits * @umconv),
						(/*-(@oldrecvdunits + @oldbounits) * @umconv)*/ -(@oldbounits) * @umconv))
					end
			end
        end

	----receipts update
	if @receiptupdate = 'Y'
		begin
        -- This Will Update Expense for Receipts Posted..
        exec @rcode = dbo.bspPORBExpVal @co, @mth, @batchid, @seq, 1, @transtype, @potrans,
									@po, @poitem, @recvddate, @recvdby, @description,
									@recvdunits, @recvdcost, @bounits, @bocost, @Receiver#,
									@oldpo, @oldpoitem, @oldrecvddate, @oldrecvdby, @olddesc,
									@oldrecvdunits, @oldrecvdcost, @oldbounits, @oldbocost,
									@OldReceiver#,
									----TK-07879
									@POItemLine, @OldPOItemLine, @HQBatchDistributionID, @errmsg output
   
        if @rcode <>0
			begin
 		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 		    if @rcode <> 0 goto bspexit
            goto PORB_loop
            end
         end
   
	goto PORB_loop
   
PORB_end:
    close bcPORB
 	deallocate bcPORB
    select @opencursor = 0
   
   
-- make sure debits and credits balance
if @receiptupdate = 'Y'
	begin
    select @glco = GLCo
    from bPORG with (nolock)
    where POCo = @co and Mth = @mth and BatchId = @batchid
    group by GLCo
    having isnull(sum(TotalCost),0) <> 0
    if @@rowcount <> 0
		begin
        select @errortext =  'GL Company ' + convert(varchar(3), @glco) + ' entries do not balance!'
        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        if @rcode <> 0 goto bspexit
        end
	end --  @receiptupdate
   
/* check HQ Batch Errors and update HQ Batch Control status */
select @status = 3	/* valid - ok to post */
if exists(select * from bHQBE with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @status = 2	/* validation errors */
	end

update bHQBC
set Status = @status
where Co = @co and Mth = @mth and BatchId = @batchid
   
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
	end
   
bspexit:
if @opencursor = 1
	begin
	close bcPORB
	deallocate bcPORB
	end
return @rcode






GO
GRANT EXECUTE ON  [dbo].[bspPORBVal] TO [public]
GO
