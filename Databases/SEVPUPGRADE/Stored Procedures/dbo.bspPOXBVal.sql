SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspPOXBVal    Script Date: 8/28/99 9:36:30 AM ******/
CREATE procedure [dbo].[bspPOXBVal]
/************************************************************************
* Created by:
* Modified by: GR 10/11/99 - added a check to see whether Purchase Order exist in
*                            PO Change and Receipt Detail that has been posted to
*                            in a month later than the proposed close month
*		GG 11/12/99 - Cleanup
*		DANF 09/18/01 - Added PO Item Lump Sum validation.
*		DANF 09/05/02 - 17738 Added Phase Group to bspJobTypeVal
*		RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
*		DANF 10/13/2004 - #25532 Add HQ Material Conversion Validation 
*		DC 7/7/06 - Part of the 6.x recode.  There was some sloppy code in this sp that SQL 2000 
*					did not mind.  But SQL 2005 is a b!tch and won't stand for sloppy code.
*		DC 1/21/08 - #30039 - Rounding issues with PO leaving a penny or two of remaining in Job Cost
*		DC Late 08 - #128925 - International Sales Tax
*		TJL 04/24/09 - Issue #133421, International Sales Tax corrections
*		DC 06/16/10 - #139880 -  commited cost issue
*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				GF 09/06/2011 TK-08203 PO ITEM LINE ENHANCEMENT
*
*
*
* Validates each entry in bPOXB for a select batch - must be called
* prior to posting the batch.
*
* Clears and loads bPOXA (JC Distribution Audit) and bPOXI (IN Distribution Audit).
* Errors in batch added to bHQBE using bspHQBEInsert
*
* Input:
*  @co             PO Company
*  @mth            Batch Month
*  @batchid        Batch ID#
*  @source         Source - 'PO Close'
*
* Output:
*  @errmsg         Error message
*
* Return:
*  @rcode          0 = success, 1 = error
*************************************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @source bSource, @errmsg varchar(255) output
AS
SET NOCOUNT ON

declare @rcode tinyint, @status tinyint, @POXBopencursor tinyint, @seq int, @po varchar(30),
		@vendorgroup bGroup, @vendor bVendor, @closedate bDate, @errorstart varchar(30),
		@errortext varchar(255), @inusemth bMonth, @inusebatchid bBatchID, @POITopencursor tinyint,
		@hqmatl bYN, @stdum bUM, @umconv bUnitCost, @jcumconv bUnitCost, @jcum bUM, @taxrate bRate,
		@taxphase bPhase, @taxjcct bJCCType,
		@sumRemainCmtdCost bDollar --DC #30039
   
declare @poitem bItem, @itemtype tinyint, @matlgroup bGroup, @material bMatl, @description bDesc,
		@um bUM, @posttoco bCompany, @loc bLoc, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType,
		@glco bCompany, @taxgroup bGroup, @taxcode bTaxCode, @recvdunits bUnits, @recvdcost bDollar,
		@bounits bUnits, @bocost bDollar, @invcdunits bUnits, @invcdcost bDollar, @remunits bUnits,
		@remcost bDollar, @remtax bDollar, @origunits bUnits, @origunitcost bUnitCost,
		@curunits bUnits, @curunitcost bUnitCost, @jcremcmtdtax bDollar,
		----TK-08203
		@POItemLine INT, @POITKeyID BIGINT, @OpenLineCursor INT
   
SET @rcode = 0
SET	@sumRemainCmtdCost = 0
SET @POITopencursor = 0

/* validate HQ Batch */
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'POXB', @errmsg output, @status output
if @rcode <> 0 goto bspexit

if @status < 0 or @status > 3
	begin
	select @errmsg = 'Invalid Batch status!', @rcode = 1
	goto bspexit
	end
/* set HQ Batch status to 1 (validation in progress) */
update bHQBC
set Status = 1
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
	end

/* clear HQ Batch Errors */
delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
/* clear PO JC Distribution Audit */
delete bPOXA where POCo = @co and Mth = @mth and BatchId = @batchid
/* clear PO IN Distribution Audit */
delete bPOXI where POCo = @co and Mth = @mth and BatchId = @batchid
   
-- create a cursor on PO Close Batch for validation
declare bcPOXB cursor for
select BatchSeq, PO, VendorGroup, Vendor, CloseDate
from bPOXB with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid

open bcPOXB
SET @POXBopencursor = 1      -- set open cursor flag

POXB_loop:  -- process each PO in Close Batch
fetch next from bcPOXB into @seq, @po, @vendorgroup, @vendor, @closedate

if @@fetch_status <> 0 goto POXB_end

select @errorstart = 'Seq# ' + convert(varchar(6),@seq)

-- validate PO#
select @status = Status, @inusemth = InUseMth, @inusebatchid = InUseBatchId
from bPOHD with (nolock) where POCo = @co and PO = @po
if @@rowcount = 0
	begin
	select @errortext = @errorstart + ' - Invalid PO#.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    if @rcode <> 0 goto bspexit
    goto POXB_loop
	end
if @status not in ('0','1')    -- 'open' or 'complete'
    begin
	select @errortext = @errorstart + ' - Invalid PO status, must be (open) or (complete).'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
    goto POXB_loop
	end
if @inusemth is null or @inusebatchid is null
    begin
    select @errortext = @errorstart + ' - PO Header has not been flagged as (In Use) by this batch.'
    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
    goto POXB_loop
	end
if @inusemth <> @mth or @inusebatchid <> @batchid
    begin
    select @errortext = @errorstart + ' - PO Header (In Use) by another batch.'
    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
    goto POXB_loop
	end
-- check that no AP Transactions exist in a month later than the Close Month
if exists(select * from bAPTL with (nolock) where APCo = @co and Mth > @mth and PO = @po)
    begin
    select @errortext = @errorstart + ' - PO#: ' + @po + ' has AP Transactions posted later than Close Month.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
    goto POXB_loop
    end

-- check that no PO Change Order Detail exist in a month later than the Close Month
if exists(select * from bPOCD with (nolock) where POCo = @co and Mth > @mth and PO = @po)
    begin
    select @errortext = @errorstart + ' - PO#: ' + @po + ' has PO Change Detail posted later than Close Month.'
    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    if @rcode <> 0 goto bspexit
    goto POXB_loop
    end
--check that no PO Receipt Detail exist in a month later than the close month
if exists(select * from bPORD with (nolock) where POCo = @co and Mth > @mth and PO = @po)
    begin
    select @errortext = @errorstart + ' - PO#: ' + @po + ' has PO Receipt Detail posted later than Close Month.'
    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    if @rcode <> 0 goto bspexit
    goto POXB_loop
    end
   
---- create cursor to process each PO Item Line TK-08203
DECLARE bcPOItemLine CURSOR FOR SELECT POItem, POItemLine, ItemType, PostToCo, Loc, Job,
			PhaseGroup, Phase, JCCType, GLCo, TaxGroup, TaxCode, RecvdUnits,
			RecvdCost, BOUnits, BOCost, InvUnits, InvCost, RemUnits,
			RemCost, RemTax, OrigUnits, CurUnits, JCRemCmtdTax, POITKeyID
FROM dbo.vPOItemLine
WHERE POCo = @co
	AND PO = @po

open bcPOItemLine
---- set open cursor flag
SET @OpenLineCursor = 1

POItemLine_loop:
---- process each Item
FETCH NEXT FROM bcPOItemLine INTO @poitem, @POItemLine, @itemtype, @posttoco, @loc, @job,
			@phasegroup, @phase, @jcctype, @glco, @taxgroup, @taxcode, @recvdunits,
			@recvdcost, @bounits, @bocost, @invcdunits, @invcdcost, @remunits,
			@remcost, @remtax, @origunits, @curunits, @jcremcmtdtax, @POITKeyID

IF @@fetch_status <> 0 GOTO POIT_end

---- set error message
SELECT @errorstart = @errorstart + 'PO Item: ' + dbo.vfToString(@poitem) + ' Line: ' + dbo.vfToString(@POItemLine)

---- get POIT info
SELECT  @matlgroup=MatlGroup, @material=Material, @description=Description, 
		@um=UM, @taxgroup=TaxGroup, @origunitcost=OrigUnitCost,
		@curunitcost=CurUnitCost
FROM dbo.bPOIT
WHERE KeyID = @POITKeyID
IF @@ROWCOUNT = 0
	BEGIN
    SELECT @errortext = 'Error retrieving PO Item Information for Item: ' + dbo.vfToString(@poitem)
	EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    IF @rcode <>0 GOTO bspexit
    GOTO POItemLine_loop
    END

---- make sure Received equals Invoiced
if (@um = 'LS' and @recvdcost <> @invcdcost) or (@um <> 'LS' and @recvdunits <> @invcdunits)
    begin
    select @errortext = @errorstart + ' - Received and Invoiced are not equal.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    if @rcode <>0 GOTO bspexit
    GOTO POItemLine_loop
    end

---- since Received and Invoviced must be equal, Remaining will equal Backordered
if (@um = 'LS' and @bocost <> @remcost) or (@um <> 'LS' and @bounits <> @remunits)
    begin
    select @errortext = @errorstart + ' - Backordered and Remaining are not equal.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    if @rcode <>0 GOTO bspexit
    GOTO POItemLine_loop
    end

---- make sure 'LS' Item lines have 0.00 units and unit costs
if (@um = 'LS' and (@origunits <> 0 or @origunitcost <> 0 or @curunits <> 0 or @curunitcost <> 0
			or @recvdunits <> 0 or @bounits <> 0 or @invcdunits <> 0))
    begin
	select @errortext = @errorstart + ' - Lump sum PO Items must have 0.00 Units and Unit Costs.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <>0 goto bspexit
    GOTO POItemLine_loop
    end

---- DC 30039
SELECT @sumRemainCmtdCost  = SUM(ISNULL(RemainCmtdCost, 0)) 
FROM dbo.bJCCD 
WHERE JCCo = @posttoco 
	AND Job = @job 
	AND Phase = @phase
	AND CostType = @jcctype
	AND PO = @po 
	AND POItem = @poitem
	----TK-08203
	AND POItemLine = @POItemLine
	----DC #139880
	AND APCo = @co

---- if no Remaining Units or Costs or Remaining Committed Cost,
---- then no update to JC, IN, or Change Detail will be needed
if @remunits = 0 and @remcost = 0 and @sumRemainCmtdCost = 0 GOTO POItemLine_loop


----DECLARE bcPOIT CURSOR FOR SELECT POItem, ItemType, MatlGroup, Material, Description,
----			UM, PostToCo, Loc, Job, PhaseGroup, Phase, JCCType, GLCo, TaxGroup,
----			TaxCode, RecvdUnits, RecvdCost, BOUnits, BOCost, InvUnits, InvCost,
----			RemUnits, RemCost, RemTax, OrigUnits, OrigUnitCost, CurUnits, CurUnitCost,
----			JCRemCmtdTax
----from bPOIT with (nolock)
----where POCo = @co and PO = @po

----open bcPOIT
----SET @POITopencursor = 1     -- set open cursor flag

----POIT_loop:  -- process each Item
----fetch next from bcPOIT into @poitem, @itemtype, @matlgroup, @material, @description, @um,
----        @posttoco, @loc, @job, @phasegroup, @phase, @jcctype, @glco, @taxgroup, @taxcode,
----        @recvdunits, @recvdcost, @bounits, @bocost, @invcdunits, @invcdcost, @remunits,
----        @remcost, @remtax, @origunits, @origunitcost, @curunits, @curunitcost, @jcremcmtdtax

----if @@fetch_status <> 0 goto POIT_end

-------- set error message
----select @errorstart = @errorstart + 'PO Item# ' + convert(varchar(6),@poitem)

------ make sure Received equals Invoiced
----if (@um = 'LS' and @recvdcost <> @invcdcost) or (@um <> 'LS' and @recvdunits <> @invcdunits)
----    begin
----    select @errortext = @errorstart + ' - Received and Invoiced are not equal.'
----	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
----    if @rcode <>0 goto bspexit
----    goto POIT_loop
----    end

------ since Received and Invoviced must be equal, Remaining will equal Backordered
----if (@um = 'LS' and @bocost <> @remcost) or (@um <> 'LS' and @bounits <> @remunits)
----    begin
----    select @errortext = @errorstart + ' - Backordered and Remaining are not equal.'
----	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
----    if @rcode <>0 goto bspexit
----    goto POIT_loop
----    end

------ make sure 'LS' Items have 0.00 units and unit costs
----if (@um = 'LS' and (@origunits <> 0 or @origunitcost <> 0 or @curunits <> 0 or @curunitcost <> 0
----	or @recvdunits <> 0 or @bounits <> 0 or @invcdunits <> 0))
----    begin
----	select @errortext = @errorstart + ' - Lump sum PO Items must have 0.00 Units and Unit Costs.'
----	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
----	if @rcode <>0 goto bspexit
----	goto POIT_loop
----    end

------DC 30039
----SELECT @sumRemainCmtdCost  = sum(isnull(RemainCmtdCost,0)) 
----FROM bJCCD 
----WHERE JCCo = @posttoco 
----	AND Job = @job 
----	AND Phase = @phase
----	AND CostType = @jcctype
----	AND PO = @po 
----	AND POItem = @poitem
----	AND APCo = @co  --DC #139880

------ if no Remaining Units or Costs or Remaining Committed Cost, then no update to JC, IN, or Change Detail will be needed
----if @remunits = 0 and @remcost = 0 and @sumRemainCmtdCost = 0 goto POIT_loop

---- init material defaults
SET @hqmatl = 'N'
SET @stdum = NULL
SET @umconv = 0

---- check for Material in HQ
select @stdum = StdUM
from dbo.bHQMT
where MatlGroup = @matlgroup
	AND Material = @material
if @@rowcount = 1
    begin
    select @hqmatl = 'Y'    -- setup in HQ Materials
    if @stdum = @um SET @umconv = 1
    END
    
---- if HQ Material, validate UM and get unit of measure conversion
if @hqmatl = 'Y' AND @um <> @stdum
    begin
    select @umconv = Conversion
    from dbo.bHQMU
    where MatlGroup = @matlgroup
		AND Material = @material
		AND UM = @um
    if @@rowcount = 0
        begin
        select @errortext = @errorstart + ' - Invalid unit of measure for this Material.'
        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        if @rcode <> 0 goto bspexit
        GOTO POItemLine_loop
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
        GOTO POItemLine_loop
        end

    ---- determine conversion factor from posted UM to JC UM
    SET @jcumconv = 0
    if isnull(@jcum,'') = @um select @jcumconv = 1

    if @hqmatl = 'Y' and isnull(@jcum,'') <> @um
        begin
        exec @rcode = bspHQStdUMGet @matlgroup, @material, @jcum, @jcumconv output, @stdum output, @errmsg output
        if @rcode <> 0
            begin
            select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
            if @rcode <> 0 goto bspexit
            GOTO POItemLine_loop
            END
            
        if @jcumconv <> 0 select @jcumconv = @umconv / @jcumconv
        end

    ---- get Tax Phase, and Cost Type
    SET @taxrate = 0
    SET @taxphase = NULL
    SET	@taxjcct = NULL
    if @taxcode is not null
        begin
        exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @closedate, @taxrate output,
					@taxphase output, @taxjcct output, @errmsg output
        if @rcode <> 0
            begin
            select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
            if @rcode <> 0 goto bspexit
            GOTO POItemLine_loop
            end
        end

    ---- set Tax Phase and Cost Type
    if @taxphase IS NULL select @taxphase = @phase
    if @taxjcct IS NULL select @taxjcct = @jcctype

	---- include tax if not redirected POIT.RemCost + POIT.JCRemCmtdTax (GST already removed as appropriate)
	if @taxphase = @phase and @taxjcct = @jcctype SET @remcost = @remcost + @jcremcmtdtax	

    ---- validate Mth in GL Company
    exec @rcode = bspHQBatchMonthVal @glco, @mth, 'PO', @errmsg output
    if @rcode <> 0
        begin
        select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
        GOTO POItemLine_loop
        end
   
    ---- add JC Distribution - POXA
    if @remunits <> 0 or @remcost <> 0 or @sumRemainCmtdCost <> 0
		begin
		insert dbo.bPOXA(POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
				POItem, PO, VendorGroup, Vendor, MatlGroup, Material, Description, ActDate,
				UM, POUnits, JCUM, CmtdUnits, CmtdCost,
				----TK-08203
				POItemLine)
		values(@co, @mth, @batchid, @posttoco, @job, @phasegroup, @phase, @jcctype, @seq,
				@poitem, @po, @vendorgroup, @vendor, @matlgroup, @material, @description,
				@closedate, @um, -(@remunits), @jcum, -(@remunits * @jcumconv), -(@remcost),
				----TK-08203
				@POItemLine)
       end

	---- add JC Distribution - if Tax is redirected
	if @jcremcmtdtax <> 0 and (@taxphase <> @phase or @taxjcct <> @jcctype)
      	begin
		insert INTO dbo.bPOXA(POCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
			POItem, PO, VendorGroup, Vendor, MatlGroup, Material, Description, ActDate,
			UM, POUnits, JCUM, CmtdUnits, CmtdCost,
			----TK-08203
			POItemLine)
		values(@co, @mth, @batchid, @posttoco, @job, @phasegroup, @taxphase, @taxjcct, @seq,
			@poitem, @po, @vendorgroup, @vendor, @matlgroup, @material, @description,
			@closedate, @um, 0, @jcum, 0, -(@jcremcmtdtax),
			----TK-08203
            @POItemLine)
		end
	end

---- Inventory type
if @itemtype = 2 
	begin
	---- check for Location conversion
	if @um <> @stdum
		begin
		select @umconv = Conversion
		from dbo.bINMU
		where INCo = @posttoco
			AND Loc = @loc
			AND MatlGroup = @matlgroup
			AND Material = @material
			AND UM = @um
		if @@rowcount = 0
			begin
			select @umconv = Conversion
			from dbo.bHQMU
			where MatlGroup = @matlgroup
				AND Material = @material
				AND UM = @um
			if @@rowcount=0
   				begin
    			select @errortext = @errorstart + ' - UM:  ' + @um + ' is not setup for Material: ' + @material
   		 		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
    			GOTO POItemLine_loop
    			End
			end
		end

    ---- On Order will be reduced by Remaining Units - converted to Std UM
    if @remunits <> 0
        begin
        insert INTO dbo.bPOXI (POCo, Mth, BatchId, INCo, Loc, MatlGroup, Material, BatchSeq,
				POItem, PO, VendorGroup, Vendor, UM, POUnits, StdUM, OnOrder,
				----TK-08203
				POItemLine)
        values (@co, @mth, @batchid, @posttoco, @loc, @matlgroup, @material, @seq,
				@poitem, @po, @vendorgroup, @vendor, @um, -(@remunits), @stdum, -(@remunits * @umconv),
				----TK-08203
				@POItemLine)
        end
    end
   
---- next PO Item Line
GOTO POItemLine_loop


POIT_end:   -- finished with Items on this PO
	CLOSE bcPOItemLine
	DEALLOCATE bcPOItemLine
	SET @OpenLineCursor = 0
	GOTO POXB_loop


POXB_end:   -- finished with POs in Close Batch
	CLOSE bcPOXB
	DEALLOCATE bcPOXB
	SET @POXBopencursor = 0
   
   
   
/* check HQ Batch Errors and update HQ Batch Control status */
select @status = 3	/* valid - ok to post */
if exists(select 1 from dbo.bHQBE WHERE	Co = @co AND Mth = @mth AND BatchId = @batchid)
	BEGIN
	SELECT @status = 2	/* validation errors */
	END
UPDATE bHQBC SET Status = @status
WHERE Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount <> 1
	BEGIN
	SELECT @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	GOTO bspexit
	END
   
   
bspexit:
	if @OpenLineCursor = 1
		BEGIN
		CLOSE bcPOItemLine
		DEALLOCATE bcPOItemLine
		END
		
	if @POXBopencursor = 1
		BEGIN
		CLOSE bcPOXB
		DEALLOCATE bcPOXB
		END
		
	RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[bspPOXBVal] TO [public]
GO
