
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPORSVal    Script Date: 8/28/99 9:36:29 AM ******/
CREATE       procedure [dbo].[bspPORSVal]
/************************************************************************
* Created: DANF 05/23/01
* Modified by: DANF 02/11/02 Correct debug statements.
*              DANF 0905/02 - 17738 Added Phase Group to bspJobTypeVal
*			   DANF 06//06/03 - 21376 Corrected Setting of Receipt interface levels from batch tabel PORH
*			   RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
*				GF 12/09/2010 - issue #141031
*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				GF 08/23/2011 TK-07879 PO ITEM LINE
*				JB 12/10/12 Modified out of necessity to support added param to bspPORBExpVal
*				JVH 7/23/13 Modified to support SM lines
*
*
* Called by PO Batch Process program to validates a PO Expense Receipts Initialized Batch
*
* Errors in batch added to bHQBE using bspHQBEInsert
*
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
--#142350 - renaming @receiptupdate
declare @rcode int, @opencursor tinyint, @errorstart varchar(60), @errortext varchar(60),
		@hqmatl char(1), @stdum bUM, @umconv bUnitCost, @jcum bUM, @jcumconv bUnitCost, @taxrate bRate,
		@taxphase bPhase, @taxjcct bJCCType, @ReceiptUpd bYN, @poinusebatch bBatchID, @poinusemth bMonth

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

-- PO Receipt Header decalres
declare @ReceiptUpdate bYN, @GLAccrualAcct bGLAcct, @GLRecExpInterfacelvl tinyint, @RecJCInterfacelvl tinyint, 
		@RecEMInterfacelvl tinyint, @RecINInterfacelvl tinyint, @OldReceiptUpdate bYN, @OldGLRecExpInterfacelvl tinyint,
		@OldRecJCInterfacelvl tinyint, @OldRecEMInterfacelvl tinyint, @OldRecINInterfacelvl tinyint

----TK-07879
DECLARE @POItemLine INT, @OldPOItemLine INT, @PORDPOItemLine INT, @HQBatchDistributionID bigint

--Verify that the batch can be validated, set the batch status to validating and delete generic distributions
EXEC @rcode = dbo.vspHQBatchValidating @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @Source = @source, @TableName = 'PORS', @HQBatchDistributionID = @HQBatchDistributionID OUTPUT, @msg = @errmsg OUTPUT
IF @rcode <> 0 RETURN @rcode
   
-- Set the Receipt Update flag...
select 	@ReceiptUpdate  = isnull(ReceiptUpdate,''), @GLRecExpInterfacelvl = isnull(GLRecExpInterfacelvl,99), 
		@RecJCInterfacelvl = isnull(RecJCInterfacelvl,99), @RecEMInterfacelvl = isnull(RecEMInterfacelvl,99),
		@RecINInterfacelvl = isnull(RecINInterfacelvl,99),	@OldReceiptUpdate = isnull(OldReceiptUpdate,''), 
		@OldGLRecExpInterfacelvl = isnull(OldGLRecExpInterfacelvl,99), @OldRecJCInterfacelvl = isnull(OldRecJCInterfacelvl,99),
		@OldRecEMInterfacelvl = isnull(OldRecEMInterfacelvl,99), @OldRecINInterfacelvl  = isnull(OldRecINInterfacelvl,99)
from bPORH with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
begin
select @errmsg = 'Missing Receipt Header', @rcode = 1
goto bspexit
end
   
      /* clear HQ Batch Errors */
      delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
      /* clear PO JC Distribution Audit */
      delete bPORJ where POCo = @co and Mth = @mth and BatchId = @batchid
      /* clear PO GL Distribution Audit */
      delete bPORG where POCo = @co and Mth = @mth and BatchId = @batchid
      /* clear PO EM Distribution Audit */
      delete bPORE where POCo = @co and Mth = @mth and BatchId = @batchid
      /* clear PO IN Distribution Audit */
      delete bPORN where POCo = @co and Mth = @mth and BatchId = @batchid
   
      -- Set the Receipt Update flag...
      select @ReceiptUpd=ReceiptUpdate from bPOCO with (nolock)
      where POCo = @co
   
   
-- create cursor on PO Receipts Batch for validation
----TK-07879
declare bcPORS cursor for
select BatchSeq, PO, POItem, RecvdUnits, RecvdCost, POItemLine
from dbo.bPORS with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid

open bcPORS
select @opencursor = 1  -- set open cursor flag

PORS_loop:      -- process each entry
  fetch next from bcPORS into @seq, @po, @poitem, @recvdunits, @recvdcost, @POItemLine

  if @@fetch_status <> 0 goto PORS_end

----#141031 TK-07879
SET @transtype = 'A'
SET @potrans = NULL
SET @recvddate = dbo.vfDateOnly()
SET @recvdby = null
select @description = 'Receipt Expense Initialize'
SET @bounits=0
SET @bocost=0
SET @oldpo = null
SET @oldpoitem = null
SET @oldrecvddate= null
SET @oldrecvdby= NULL
SET @olddesc= NULL
SET @oldrecvdunits= null
SET @oldrecvdcost = NULL
SET @oldbounits = NULL
SET @oldbocost = NULL
SET @Receiver# = NULL
SET @OldReceiver# = NULL
SET @OldPOItemLine = NULL


select @errorstart = 'Seq#' + convert(varchar(6),@seq)

--- Update Batch in use flag if null in POHD
select @poinusebatch = InUseBatchId, @poinusemth = InUseMth
from dbo.bPOHD with (nolock) where POCo=@co  and PO=@po
If @@rowcount <> 0 and isnull(@poinusebatch,'') = '' and isnull(@poinusemth,'') = ''
	begin
	update dbo.bPOHD
	set InUseBatchId=@batchid, InUseMth=@mth
	where POCo=@co  and PO=@po
	end

--- Update Batch in use flag if null in POIT
select @poinusebatch = InUseBatchId, @poinusemth = InUseMth
from dbo.bPOIT with (nolock) where POCo=@co  and PO=@po and POItem = @poitem
If @@rowcount <> 0 and isnull(@poinusebatch,'') = '' and isnull(@poinusemth,'') = ''
	begin
	update dbo.bPOIT
	set InUseBatchId=@batchid, InUseMth=@mth
	where POCo=@co  and PO=@po and POItem = @poitem
	END
	
--- Update Batch in use flag if null in POItemLine TK-07879
SELECT @poinusebatch = InUseBatchId, @poinusemth = InUseMth
FROM dbo.vPOItemLine
WHERE POCo=@co AND PO=@po
	AND POItem = @poitem
	AND POItemLine = @POItemLine
If @@rowcount <> 0 and isnull(@poinusebatch,'') = '' and isnull(@poinusemth,'') = ''
	BEGIN
	UPDATE dbo.vPOItemLine
			SET InUseBatchId=@batchid, InUseMth=@mth
	WHERE POCo=@co AND PO=@po
		AND POItem = @poitem
		AND POItemLine = @POItemLine
	END



-- validate transaction type
if @transtype not in ('A','C','D')
	begin
	select @errortext = @errorstart + ' -  Invalid transaction type, must be (A, C, or D).'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto PORS_loop
	end
 
if @transtype in ('A','C')       -- validation specific to 'add' and 'change' entries
	begin
	if @transtype = 'A' and @potrans is not null
		begin
		select @errortext = @errorstart + ' -  PO Change Transaction must be null for (add) entries.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto PORS_loop
		END

	-- validate PO#
	select  @status = Status, @inusemth = InUseMth, @inusebatchid = InUseBatchId,
			@VendorGroup = VendorGroup, @Vendor = Vendor
	from dbo.bPOHD with (nolock) where POCo = @co and PO = @po
	if @@rowcount = 0
		begin
		select @errortext = @errorstart + ' - Invalid PO.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto PORS_loop
		end
	if @status <> 0
		begin
		select @errortext = @errorstart + ' - PO must be (open).'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto PORS_loop
		end
	if @inusemth is null or @inusebatchid is null
		begin
		select @errortext = @errorstart + ' - PO Header has not been flagged as (In Use) by this batch.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto PORS_loop
		end
	if @inusemth <> @mth or @inusebatchid <> @batchid
		begin
		select @errortext = @errorstart + ' - PO Header (In Use) by batch ' + convert(varchar(6),@inusebatchid) + ' month ' + convert(varchar(20),@inusemth)
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto PORS_loop
		END
		
	---- validate Item and get current values TK-07879
	SELECT  @matlgroup = MatlGroup, @material = Material, @um = UM, @recvyn = RecvYN,
			@poitcurunitcost = CurUnitCost, @poitcurecm = CurECM
			--@itemtype = ItemType, @posttoco = PostToCo, @loc = Loc, @job = Job,
			--@phasegroup = PhaseGroup, @phase = Phase,
			--@jcctype = JCCType, @glco = GLCo, @taxgroup = TaxGroup, @taxcode = TaxCode,
			--@glacct = GLAcct
	from dbo.bPOIT
	where POCo = @co and PO = @po and POItem = @poitem
	if @@rowcount = 0
		begin
		select @errortext = @errorstart + ' - Invalid PO Item.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto PORS_loop
		END
		
	---- check Receiving flag
	if @recvyn = 'N'
		begin
		select @errortext = @errorstart + ' - PO Item is not flagged for receiving.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto PORS_loop
		end

	---- validate PO Item Line and get info TK-07879
	SELECT 	@itemtype = ItemType, @posttoco = PostToCo, @loc = Loc, @job = Job,
			@phasegroup = PhaseGroup, @phase = Phase, @jcctype = JCCType, @glco = GLCo,
			@taxgroup = TaxGroup, @taxcode = TaxCode, @glacct = GLAcct
	FROM dbo.vPOItemLine
	WHERE POCo = @co AND PO = @po
		AND POItem = @poitem
		AND POItemLine = @POItemLine
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @errortext = @errorstart + ' - Invalid PO Item Line.'
		EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		IF @rcode <> 0 GOTO bspexit
		GOTO PORS_loop
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
                      goto PORS_loop
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
                      goto PORS_loop
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
                          goto PORS_loop
                          end
                      if @jcumconv <> 0 select @jcumconv = @umconv / @jcumconv
                      end
   
			-- get Tax Rate, Phase, and Cost Type
			select @taxrate = 0
			if @taxcode is not null
				begin
				exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @recvddate, @taxrate output,
						@taxphase output, @taxjcct output, @errmsg output
				if @rcode <> 0
					begin
					select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto PORS_loop
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
         	            goto PORS_loop
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
                  select @porarnitax = @porarnicost * @taxrate    -- may be redirected, keep separate
                  select @poracmtdtax = @poracmtdcost * @taxrate
   
                  if @taxphase = @phase and @taxjcct = @jcctype
                     begin
                     select @porarnicost = @porarnicost + @porarnitax
   
                     select @poracmtdcost = @poracmtdcost + @poracmtdtax
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
                          goto PORS_loop
                          end
                      end
   
                  end
              end
   
		if @transtype in ('C','D')  -- validation specific to 'change' and 'delete' entries
			begin
			select  @pordpo = PO, @pordpoitem = POItem, @pordrecvddate = RecvdDate, @pordrecvdby = RecvdBy,
					@porddescription = Description, @pordrecvdunits = RecvdUnits, @pordrecvdcost = RecvdCost,
					@pordbounits = BOUnits, @pordbocost = BOCost,
					----TK-07879
					@PORDPOItemLine = POItemLine
			from dbo.bPORD with (nolock)
			where POCo = @co and Mth = @mth and POTrans = @potrans
			if @@rowcount = 0
				begin
				select @errortext = @errorstart + ' - Invalid PO Receipts Transaction!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto PORS_loop
				END
				
		----TK-07879
		if @pordpo <> @oldpo or @pordpoitem <> @oldpoitem
			OR @PORDPOItemLine <> @OldPOItemLine
			or @pordrecvddate <> @oldrecvddate
			or isnull(@pordrecvdby,'') <> isnull(@oldrecvdby,'')
			or isnull(@porddescription,'') <> isnull(@olddesc,'')
			or @pordrecvdunits <> @oldrecvdunits or @pordrecvdcost <> @oldrecvdcost
			or @pordbounits <> @oldbounits or @pordbocost <> @oldbocost
			begin
			select @errortext = @errorstart + ' - (Old) batch values do not match current Transaction values!'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto PORS_loop
			end

		-- get 'old' info needed for update to PORA and PORI
		-- validate old PO#
		select @status = Status
		from bPOHD with (nolock) where POCo = @co and PO = @oldpo
		if @@rowcount = 0
			begin
			select @errortext = @errorstart + ' - Invalid PO.'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto PORS_loop
			end
		if @status <> 0
			begin
			select @errortext = @errorstart + ' - PO must be (open).'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto PORS_loop
			END
      		    
      		    
		---- validate old Item and get current values TK-07879
		select  @matlgroup = MatlGroup, @material = Material, @um = UM,
				@poitcurunitcost = CurUnitCost, @poitcurecm = CurECM
				--@itemtype = ItemType, @posttoco = PostToCo, @loc = Loc, @job = Job,
				--@phasegroup = PhaseGroup, @phase = Phase,
				--@jcctype = JCCType, @glco = GLCo, @taxgroup = TaxGroup, @taxcode = TaxCode,
		from dbo.bPOIT
		where POCo = @co AND PO = @oldpo AND POItem = @oldpoitem
		if @@rowcount = 0
			begin
			select @errortext = @errorstart + ' - Invalid PO Item.'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto PORS_loop
			end

		---- validate old Item LINE and get info TK-07879
		SELECT  @itemtype = ItemType, @posttoco = PostToCo, @loc = Loc, @job = Job,
				@phasegroup = PhaseGroup, @phase = Phase, @jcctype = JCCType,
				@glco = GLCo, @taxgroup = TaxGroup, @taxcode = TaxCode
		FROM dbo.vPOItemLine
		WHERE POCo = @co AND PO = @oldpo
			AND POItem = @oldpoitem
			AND POItemLine = @OldPOItemLine
		IF @@ROWCOUNT = 0
			BEGIN
			SELECT @errortext = @errorstart + ' - Invalid PO Item Line.'
			EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			IF @rcode <> 0 GOTO bspexit
			GOTO PORS_loop
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
                      goto PORS_loop
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
                      goto PORS_loop
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
                          goto PORS_loop
                          end
                      if @jcumconv <> 0 select @jcumconv = @umconv / @jcumconv
                      end
   
                  -- get Tax Rate, Phase, and Cost Type
                  select @taxrate = 0
                  if @taxcode is not null
                      begin
      		        exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @oldrecvddate, @taxrate output, @taxphase output,
                          @taxjcct output, @errmsg output
      		        if @rcode <> 0
                          begin
                          select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
      			        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                          if @rcode <> 0 goto bspexit
                          goto PORS_loop
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
         	            goto PORS_loop
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
                      end
                  select @porarnitax = @porarnicost * @taxrate    -- may be redirected, keep separate
                  select @poracmtdtax = @poracmtdcost * @taxrate
   
                  if @taxphase = @phase and @taxjcct = @jcctype
                     begin
                     select @porarnicost = @porarnicost + @porarnitax
                     select @poracmtdcost = @poracmtdcost + @poracmtdtax
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
                          goto PORS_loop
						  end
                      end
   
                  end
              end
   
			--if @ReceiptUpd = 'Y'
			if (@ReceiptUpdate <> @OldReceiptUpdate) or 
				(@GLRecExpInterfacelvl <> @OldGLRecExpInterfacelvl) or
				(@RecJCInterfacelvl <> @OldRecJCInterfacelvl) or
				(@RecEMInterfacelvl <> @OldRecEMInterfacelvl) or
				(@RecINInterfacelvl <> @OldRecINInterfacelvl)
				BEGIN
				---- This Will Update Expense for Receipts Posted..
				exec @rcode = bspPORBExpVal @co, @mth, @batchid, @seq, 1, @transtype, @potrans,
							@po, @poitem, @recvddate, @recvdby, @description,
							@recvdunits, @recvdcost, @bounits,
							@bocost, @Receiver#,
							@oldpo, @oldpoitem, @oldrecvddate, @oldrecvdby, @olddesc,
							@oldrecvdunits, @oldrecvdcost,
							@oldbounits, @oldbocost, @OldReceiver#,
							----TK-07879
							@POItemLine, @OldPOItemLine,
							@HQBatchDistributionID, @errmsg output
				if @rcode <> 0
					BEGIN
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto PORS_loop
					END
				END
   
          goto PORS_loop
   
   
PORS_end:
	close bcPORS
	deallocate bcPORS
	select @opencursor = 0
   
   
   
/* check HQ Batch Errors and update HQ Batch Control status */
select @status = 3	/* valid - ok to post */
if exists(select * from bHQBE with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
	select @status = 2	/* validation errors */
	END
	
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
	close bcPORS
	deallocate bcPORS
	END
	
	return @rcode



GO

GRANT EXECUTE ON  [dbo].[bspPORSVal] TO [public]
GO
