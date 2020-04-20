SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Stored Procedure dbo.bspPOXBPost    Script Date: 8/28/99 9:36:30 AM ******/
CREATE    procedure [dbo].[bspPOXBPost]
/************************************************************************
* Created: ??
* Modified by: kb 12/7/98
*               GG 11/12/99 - Cleanup
*              DANF 05/30/01 - Added check for inserted detail.
*              CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*				GG 06/11/02 - #17565 - update bJCCD.PostedUnits = 0
*				SR 06/18/02 (Issue 11657) - get the next Seq number from POCD
*				GF - 02/03/2003 - issue #20058 need to set INMT.AuditYN back to INCO.AuditMatl
*				RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
*				MV 09/20/05 - #29827 - Update ChgTotCost in POCD.
*				MV 08/04/06 - #122076 - insert ECM in POCD.
*				DC 1/2/08 - #30039 - Rounding issues with PO leaving a penny or two of remaining in Job Cost
*				DC 04/30/08 - #127181 - Store the batch ID of the PO Close batch in the POHD table
*				DC 10/22/08 - #128052 - Remove CmtdDetailToJC flag
*				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*				DC 1/26/09 - #131970 - RemainCmtdCost null value not handled.
*				DC 06/16/10 - #139880 -  commited cost issue
*				GF 07/30/2011 - TK-07143 PO expanded
*				GF 09/06/2011 TK-08203 PO ITEM LINE ENHANCEMENT
*				GF 11/30/2011 TK-10478 need to skip rounding adjustment if missing POItemLine in JCCD for PO
*				GF 01/12/2012 TK-11711 added APCo, JCCo to where clause for JCCD
*				GF 01/22/2012 TK-11964 #145600 removed TK-11711 performance problem
*
*
* Posts a validated PO Close batch.  Deletes successfully posted bPOXB,
* bPOXA, and bPOXI entries when complete
*
* Inputs:
*   @co             PO Company
*   @mth            Batch month
*   @batchid        Batch ID
*   @dateposted     Posting Date
*   @source         Source - 'PO Close'
*
* returns 1 and message if error
************************************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null,
 @source bSource, @errmsg varchar(255) output)
AS
SET NOCOUNT ON

declare @rcode int, @status tinyint, --@cmtddetailtojc bYN, DC #128052
		@POXBopencursor tinyint, @POITopencursor tinyint,
		@seq int, @po VARCHAR(30), @closedate bDate, @errorstart varchar(30), @poitem bItem,
		@um bUM, @bounits bUnits, @bocost bDollar, @potrans bTrans, @POXAopencursor tinyint,
		@jctrans bTrans, @POXIopencursor tinyint, @COSeq int, @pocurunitcost bUnitCost,
		----DC #30039
		@pocurecm bECM, @factor int, @sumRemainCmtdCost bDollar

-- POXA declares
declare @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @Notes VARCHAR(MAX),
		@jcctype bJCCType, @vendorgroup bGroup, @vendor bVendor, @matlgroup bGroup,
		@material bMatl, @description bDesc, @pounits bUnits, @jcum bUM, @cmtdunits bUnits,
		@cmtdcost bDollar, @actdate bDate
----TK-10478
DECLARE @JCCD_Count AS INT

-- POXI delcares
declare @inco bCompany, @loc bLoc, @onorder bUnits

----TK-08203
DECLARE @POITKeyID BIGINT, @POItemLine INT, @sumRemainCmtdTax bDollar, @OpenLineCursor INT,
		@KeyID BIGINT

SET @rcode = 0
SET @POITopencursor = 0
SET @POXBopencursor = 0
SET @POXIopencursor = 0
SET @OpenLineCursor = 0

---- check for date posted
if @dateposted is null
	begin
	select @errmsg = 'Missing posting date!', @rcode = 1
	goto bspexit
	end

---- validate HQ Batch
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'POXB', @errmsg output, @status output
if @rcode <> 0 goto bspexit
if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
	begin
	select @errmsg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''!', @rcode = 1
	goto bspexit
	end

---- set HQ Batch status to 4 (posting in progress)
UPDATE dbo.bHQBC
	SET Status = 4, DatePosted = @dateposted
WHERE Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end


---- use a cursor to process PO Close batch entries
DECLARE bcPOXB CURSOR FOR SELECT BatchSeq, PO, CloseDate
FROM dbo.bPOXB
WHERE Co = @co
	AND Mth = @mth
	AND BatchId = @batchid

open bcPOXB
select @POXBopencursor = 1      -- set open cursor flag

POXB_loop:      -- process each PO to be closed
fetch next from bcPOXB into @seq, @po, @closedate

if @@fetch_status <> 0 goto POXB_end

select @errorstart = 'PO Close Batch Seq# ' + convert(varchar(6),@seq)


BEGIN TRANSACTION
---- TK-08203 new for this enhancement
---- create a cursor for all item lines on the PO with remaining units or costs
---- received equal invoiced, so back ordered will equal remaining
---- we will set the BOUnits or Cost to zero for the line and create
---- a POCD record for the item. Check Back ordered later, possible
---- that POItemLine triggers have updated line one
DECLARE bcPOItemLine CURSOR FOR SELECT KeyID, POITKeyID, POItemLine
FROM dbo.vPOItemLine
WHERE POCo = @co
	AND PO = @po
ORDER BY POITKeyID ASC, POItemLine DESC, KeyID
	
---- open cursor
OPEN bcPOItemLine
SET @OpenLineCursor = 1

POItemLine_Loop:
FETCH NEXT FROM bcPOItemLine INTO @KeyID, @POITKeyID, @POItemLine

IF @@FETCH_STATUS <> 0 GOTO POItemLine_End


---- get POIT info
SELECT @poitem=POItem, @um=UM, @pocurunitcost = CurUnitCost, @pocurecm = CurECM
FROM dbo.bPOIT
WHERE KeyID = @POITKeyID
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @errmsg = @errorstart + ' - PO Item: ' + dbo.vfToString(@poitem) + ' error retrieving needed information.', @rcode = 1
    GOTO POXB_posting_error
   	END

---- get PO Item Line Backordered units and cost
SELECT @bounits = BOUnits, @bocost = BOCost
FROM dbo.vPOItemLine
WHERE KeyID = @KeyID
---- skip if problem locating record
IF @@ROWCOUNT = 0 GOTO POItemLine_Loop

---- check backordered, skip if all zeros
IF @bounits = 0 AND @bocost = 0 GOTO POItemLine_Loop


---- a Change Detail entry is made for each Item line with Remaining Units or Costs
---- get next available transaction # for bPOCD
exec @potrans = bspHQTCNextTrans 'bPOCD', @co, @mth, @errmsg output
if @potrans = 0
    begin
    select @errmsg = @errorstart + ' - ' + isnull(@errmsg,''), @rcode = 1
    goto POXB_posting_error
   	end

---- get sequence
SELECT @COSeq = isnull(MAX(Seq),0)
FROM dbo.bPOCD
WHERE POCo = @co
	AND PO = @po
	AND POItem = @poitem
	
SET @COSeq=@COSeq + 1

---- calculate ChgTotCost for units based POs
IF @bounits <> 0 
	BEGIN
	SELECT @factor = CASE @pocurecm WHEN 'C' THEN 100 WHEN 'M' THEN 1000 ELSE 1 END
	SELECT @bocost = (@bounits * @pocurunitcost) / @factor
	END

---- add PO Change Detail for change to Backordered Units or Costs
INSERT dbo.bPOCD (POCo, Mth, POTrans, PO, POItem, ActDate, Description, UM, ChangeCurUnits,
		CurUnitCost, ECM, ChangeCurCost, ChangeBOUnits, ChangeBOCost,ChgTotCost, PostedDate,
		BatchId, InUseBatchId, Seq)
VALUES (@co, @mth, @potrans, @po, @poitem, @closedate, 'PO Close for PO Item Line: ' + dbo.vfToString(@POItemLine), @um, 0, 0,
		CASE @um WHEN 'LS' THEN NULL ELSE @pocurecm END,
		0, -(@bounits),
		CASE @um WHEN 'LS' THEN -(@bocost) ELSE 0 END,
		-(@bocost), @dateposted, @batchid, null, @COSeq)
if @@rowcount <> 1
	begin
	select @errmsg = @errorstart + ' - Unable to insert PO Item Line values!', @rcode = 1
	goto POXB_posting_error
	end

---- update line one for item
UPDATE dbo.vPOItemLine
		SET BOUnits = 0,
			BOCost  = 0,
			PostedDate = @dateposted
WHERE POITKeyID = @POITKeyID
	AND POItemLine = @POItemLine
if @@ROWCOUNT <> 1
	BEGIN
	SELECT @errmsg = @errorstart + ' - Unable to update PO Item line values!', @rcode = 1
	GOTO POXB_posting_error
	END

---- next line
GOTO POItemLine_Loop

---- end deallocate cursor
POItemLine_End:
    CLOSE bcPOItemLine
    DEALLOCATE bcPOItemLine
    SET @OpenLineCursor = 0


---- update PO Header as Closed
UPDATE dbo.bPOHD
		SET Status = 2,
			MthClosed = @mth,
			InUseMth = null,
			InUseBatchId = null,
			POCloseBatchID = @batchid  --DC #127181				
WHERE POCo = @co
	AND PO = @po
if @@rowcount <> 1
   begin
   select @errmsg = @errorstart + ' - Unable to update PO Header values!', @rcode = 1
   goto POXB_posting_error
   end

---- delete current PO from Close Batch
DELETE dbo.bPOXB
WHERE Co = @co
	AND Mth = @mth
	AND BatchId = @batchid
	AND BatchSeq = @seq
if @@ROWCOUNT <> 1
   BEGIN
   SELECT @errmsg = @errorstart + ' - Error removing entry from batch.', @rcode = 1
   GOTO POXB_posting_error
   END

---- commit transaction
commit transaction
GOTO POXB_loop      -- next batch entry


POXB_posting_error:
	rollback transaction
	goto bspexit

POXB_end:   -- finished with PO Close Batch entries
    close bcPOXB
    deallocate bcPOXB
    SET @POXBopencursor = 0



---- create a cursor on PO Close JC Distribution Batch for posting TK-08203
DECLARE bcPOXA CURSOR FOR SELECT JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
		PO, POItem, VendorGroup, Vendor, MatlGroup, Material, Description,
		UM, POUnits, JCUM, CmtdUnits, CmtdCost, ActDate, POItemLine
from dbo.bPOXA 
where POCo = @co
	AND Mth = @mth
	AND BatchId = @batchid

open bcPOXA
SET @POXAopencursor = 1      -- set open cursor flag
   
---- process each PO JC Distribution entry TK-08203
POXA_loop:
FETCH NEXT FROM bcPOXA INTO @jcco, @job, @phasegroup, @phase, @jcctype, @seq,
		@po, @poitem, @vendorgroup, @vendor, @matlgroup, @material, @description,
		@um, @pounits, @jcum, @cmtdunits, @cmtdcost, @actdate, @POItemLine

if @@fetch_status <> 0 goto POXA_end

select @errorstart = 'PO JC Distribution Seq# ' + dbo.vfToString(@seq)

---- TK-10478 check if all PO records in JCCD have a POItemLine assigned
---- GF - Backed out check - causing performance problems checking JCCD.
---- I changed the script that updates JCCD with POItemLine = 1 to do a better job.
SET @JCCD_Count = 0
----SELECT @JCCD_Count = COUNT(*)
----FROM dbo.bJCCD
-------- TK-11711
----WHERE JCCo = @jcco
----	AND APCo = @co
----	AND PO = @po
----	AND POItemLine IS NULL
		
		
begin transaction

if @pounits <> 0 or @cmtdunits <> 0 or @cmtdcost <> 0
	begin
	----  get next available transaction # for JCCD
	exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
	if @jctrans = 0
		begin
		select @errmsg = @errorstart + ' - ' + isnull(@errmsg,''), @rcode = 1
		goto POXA_posting_error
		end


	---- insert JC Detail TK-08203
	insert dbo.bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
			JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, PostTotCmUnits,
			PostRemCmUnits, UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost,
			VendorGroup, Vendor, APCo, PO, POItem, MatlGroup, Material, POItemLine)
	values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @actdate,
			'PO', @source, @description, @batchid, @um, 0, @pounits,
			@pounits, @jcum, @cmtdunits, @cmtdcost, @cmtdunits, @cmtdcost,
			@vendorgroup, @vendor, @co, @po, @poitem, @matlgroup, @material, @POItemLine)
	if @@rowcount <> 1
		begin
		select @errmsg = @errorstart + ' - Error inserting JC Detail.', @rcode = 1
		goto POXA_posting_error
		end
	
	----TK-10478
	IF @JCCD_Count = 0
		BEGIN
		SELECT @sumRemainCmtdCost  = sum(isnull(RemainCmtdCost, 0)) 
		FROM dbo.bJCCD 
		WHERE JCCo = @jcco 
			AND Job = @job 
			AND Phase = @phase
			AND CostType = @jcctype
			AND PO = @po 
			AND POItem = @poitem
			----TK-08203
			AND POItemLine = @POItemLine
			----DC #139880
			AND APCo = @co 

		----DC #131970
		IF isnull(@sumRemainCmtdCost,0) <> 0
			BEGIN
			SET @sumRemainCmtdCost = @sumRemainCmtdCost * -1

			--  get next available transaction # for JCCD
			exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
			if @jctrans = 0
				begin
				select @errmsg = @errorstart + ' - ' + isnull(@errmsg,''), @rcode = 1
				goto POXA_posting_error
				end

			----TK-08203
			INSERT dbo.bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
					JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, PostTotCmUnits,
					PostRemCmUnits, UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost,
					VendorGroup, Vendor, APCo, PO, POItem, MatlGroup, Material, POItemLine)
			VALUES (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @actdate,
					'PO', @source, 'Remain Committed Cost adjustment for zero remain cost',
					@batchid, @um, 0, 0, 0, @jcum, 0, @sumRemainCmtdCost, 0, @sumRemainCmtdCost,
					@vendorgroup, @vendor, @co, @po, @poitem, @matlgroup, @material, @POItemLine)
			IF @@rowcount <> 1
				BEGIN
				select @errmsg = @errorstart + ' - Error inserting JC Detail.', @rcode = 1
				goto POXA_posting_error
				END
			END
		END
	END


----TK-10478
IF @JCCD_Count > 0 GOTO DELETE_POXA

----DC #30039
----If the POUnits, CmtdUnits, CmtdCost are all zero there could still be RemainCmtdCost
----Check the RemainCmtdCost to see if there is anything remaining.  There are times 
----when you close out a PO that there will be a few cents remaining because of rounding 
----issues. if there is anything remaining then we will insert a negative for that same 
----amount to zero out any RemainCmtdCost.
---- TK-08203 DEFECT SETUP TO ZERO OUT REMAIN COMMITTED TAX
SET @sumRemainCmtdTax = 0
SET @sumRemainCmtdCost = 0
SELECT  @sumRemainCmtdCost  = sum(isnull(RemainCmtdCost,0))
		,@sumRemainCmtdTax	= SUM(ISNULL(RemCmtdTax,0))
FROM dbo.bJCCD 
WHERE JCCo = @jcco 
	AND Job = @job 
	AND Phase = @phase
	AND CostType = @jcctype
	AND PO = @po 
	AND POItem = @poitem
	----TK-08203
	AND POItemLine = @POItemLine
	----DC #139880
	AND APCo = @co

---- created final JCCD adjustment for PO Item Line
IF ISNULL(@sumRemainCmtdCost, 0) <> 0 ----OR ISNULL(@sumRemainCmtdTax,0) <> 0
	BEGIN
	SET @sumRemainCmtdCost = @sumRemainCmtdCost * -1
	SET @sumRemainCmtdTax  = @sumRemainCmtdTax * -1
	
--SELECT @errmsg = 'Final Adjustment: ' + dbo.vfToString(@phase) + ',' + dbo.vfToString(@jcctype) + ',' + dbo.vfToString(@sumRemainCmtdCost) + ', ' + dbo.vfToString(@sumRemainCmtdTax)
--SET @rcode = 1
--goto POXA_posting_error

	----  get next available transaction # for JCCD
	exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
	if @jctrans = 0
		begin
		select @errmsg = @errorstart + ' - ' + isnull(@errmsg,''), @rcode = 1
		goto POXA_posting_error
		end
	
	---- TK-08203
	INSERT dbo.bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
			JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, PostTotCmUnits, PostRemCmUnits,
			UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost, VendorGroup, Vendor, APCo,
			PO, POItem, MatlGroup, Material, TotalCmtdTax, RemCmtdTax, POItemLine)
	VALUES (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @actdate,
			'PO', @source, 'Remain Committed Cost adjustment for zero remain costs final',
			@batchid, @um, 0, 0, 0, @jcum, 0, 0, 0, @sumRemainCmtdCost,
			@vendorgroup, @vendor, @co, @po, @poitem, @matlgroup, @material,
			0, @sumRemainCmtdTax, @POItemLine)
	IF @@rowcount <> 1
		BEGIN
		select @errmsg = @errorstart + ' - Error inserting JC Detail.', @rcode = 1
		goto POXA_posting_error
		END
	END


DELETE_POXA:
---- delete current PO JC Distribution entry TK-08203
delete dbo.bPOXA
where POCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
    and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype
    and BatchSeq = @seq and POItem = @poitem
    AND POItemLine = @POItemLine
if @@rowcount <> 1
    BEGIN	
    SELECT @errmsg = @errorstart + ' - Error removing entry from batch.', @rcode = 1
    GOTO POXA_posting_error
    END
   
COMMIT TRANSACTION


---- next PO Job distribution entry
GOTO POXA_loop


POXA_posting_error:
	rollback transaction
	GOTO bspexit


POXA_end:
	CLOSE bcPOXA
	DEALLOCATE bcPOXA
	SET @POXAopencursor = 0
   
   
   
---- create a cursor on PO Change IN Distribution Batch for posting TK-08203
DECLARE bcPOXI CURSOR FOR SELECT INCo, Loc, MatlGroup, Material, BatchSeq, POItem, OnOrder, POItemLine
FROM dbo.bPOXI 
WHERE POCo = @co
	AND Mth = @mth
	AND BatchId = @batchid

OPEN bcPOXI
SET @POXIopencursor = 1
   
-- process each PO IN Distribution entry
POXI_loop:
FETCH NEXT FROM bcPOXI INTO @inco, @loc, @matlgroup, @material, @seq, @poitem, @onorder, @POItemLine

if @@fetch_status <> 0 goto POXI_end

select @errorstart = 'PO IN Distribution Seq# ' + convert(varchar(6),@seq)

begin transaction

---- if we have on order update inventory
IF @onorder <> 0
	BEGIN
	UPDATE dbo.bINMT
		SET OnOrder = OnOrder + @onorder, AuditYN = 'N'
	WHERE INCo = @inco
		AND Loc = @loc
		AND MatlGroup = @matlgroup
		AND Material = @material
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @errmsg = @errorstart + ' - Unable to update values for IN Material!', @rcode = 1
		GOTO POXI_posting_error
		END
		
	-- reset audit flag in INMT
	UPDATE dbo.bINMT
		SET AuditYN = 'Y'
	WHERE INCo=@inco
		AND Loc=@loc
		AND MatlGroup=@matlgroup
		AND Material=@material
	end

-- delete current PO IN Distribution entry TK-08203
DELETE dbo.bPOXI
WHERE POCo = @co and Mth = @mth and BatchId = @batchid and INCo = @inco and Loc = @loc
    and MatlGroup = @matlgroup and Material = @material and BatchSeq = @seq
    and POItem = @poitem AND POItemLine = @POItemLine	
IF @@ROWCOUNT <> 1
    BEGIN
    SELECT	@errmsg = @errorstart + ' - Error removing entry from batch.', @rcode = 1
    GOTO POXI_posting_error
    END

commit transaction
GOTO POXI_loop      -- next PO IN distribution entry


POXI_posting_error:
    rollback transaction
    goto bspexit

POXI_end:
    close bcPOXI
    deallocate bcPOXI
    SET @POXIopencursor = 0


-- make sure batch tables are empty
if exists(select * from bPOXB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all PO Close Batch entries were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end
if exists(select * from bPOXA with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all JC Distributions were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end
if exists(select * from bPOXI with (nolock) where POCo = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @errmsg = 'Not all IN Distributions were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end









---- set interface levels note string
select @Notes=Notes
FROM dbo.bHQBC
where Co = @co and Mth = @mth and BatchId = @batchid
if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
select @Notes=@Notes +
   'EM Interface Level set at: ' + convert(char(1), a.RecEMInterfacelvl) + char(13) + char(10) +
   'GL Exp Interface Level set at: ' + convert(char(1), a.GLRecExpInterfacelvl) + char(13) + char(10) +
   'IN Interface Level set at: ' + convert(char(1), a.RecINInterfacelvl) + char(13) + char(10) +
   'JC Interface Level set at: ' + convert(char(1), a.RecJCInterfacelvl) + char(13) + char(10)
from dbo.bPOCO a where POCo=@co

---- delete HQ Close Control entries
delete dbo.bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

---- update HQ Batch status to 5 (posted)
UPDATE dbo.bHQBC
		SET Status = 5,
			DateClosed = getdate(),
			Notes = convert(varchar(max),@Notes)
WHERE Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	BEGIN
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	END



bspexit:
	if @POXBopencursor = 1
		begin
		close bcPOXB
		deallocate bcPOXB
		END
	
	IF @OpenLineCursor = 1
		BEGIN
		CLOSE bcPOItemLine
		DEALLOCATE bcPOItemLine
		END
		
    if @POITopencursor = 1
		begin
		close bcPOIT
		deallocate bcPOIT
		END
		
	if @POXAopencursor = 1
		begin
		close bcPOXA
		deallocate bcPOXA
		END
		
    if @POXIopencursor = 1
		begin
		close bcPOXI
		deallocate bcPOXI
		end

	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPOXBPost] TO [public]
GO
