SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPORBInsertNew    Script Date: 8/28/99 9:35:27 AM ******/   
   CREATE   procedure [dbo].[bspPORBInsertNew]
   /***********************************************************
    * CREATED BY: KF 3/13/97
    * MODIFIED By : KF 3/13/97
    *               DANF 01/20/2000
    *               DANF 03/02/2000 - ISSUE 6525
    *               DANF 07/09/2001 - Added check to see if PO and Item have already been Intialized.
    *               DANF 12/06/2001 - Allow multiple entries to the same PO and Item...
	*			DC 1/27/09 -  #130559 - open notes field in PO Init and move to PO Receipts Entry
    *			TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *			GF 08/22/2011 TK-07879 PO ITEM LINE
    *
    * USAGE:
    * This procedure is used by the PO Intialize Receipts entries to pull PO items
    * from bPOIT into bPORB for editing.
    *
    * Checks batch info in bHQBC, and transaction info in bPOIT.
    * Adds entry to next available Seq# in bPORB
    *
    * PORB insert trigger will update InUseBatchId in bPOIT
    *
    * INPUT PARAMETERS
    *   POCo	PO Co to Validate
    *   Mth        Month of batch
    *   BatchId    Batch ID to insert transaction into
    *   PO		PO to be received
    *   POItem	PO receiving item to add to batch.
    *   Recvdate	Date that item was received
    *   Recvdby	Received by
    *   RecvdUnits	Number of units received for items NOT 'LS'
    *   RecvdCost  Amt of received items that are 'LS'
    *   BOUnits	Backordered units for items NOT'LS'
    *   BOCost 	Backordered amt of items that are 'LS'
    * OUTPUT PARAMETERS
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID,
 @PO varchar(30), @POItem bItem, @RecvdDate bDate, @RecvdBy char(10),
 @RecvdUnits bUnits, @RecvdCost bDollar, @BOUnits bUnits, @BOCost bDollar,
 @Receiver# varchar(20), @notes varchar(max), @POItemLine INT,
 @errmsg varchar(200) OUTPUT)

AS
SET NOCOUNT ON
   
declare @rcode int, @tablename char(20), @inuseby bVPUserName, @dtsource bSource,
		@inusebatchid bBatchID, @seq int, @ECM bECM, @UnitCost bUnitCost,
		@Description bDesc, @POTrans bTrans, @source bSource, @status tinyint,
		@UM bUM, @ECMValue int, @OldPO varchar(30), @OldPOItem bItem, @OldREcvdDate bDate,
		@OldRecvdBy varchar(10), @OldDesc bDesc, @OldUnitCost bUnitCost,
		@OldECM bECM, @OldRecvdUnits bUnits, @OldRecvdCost bDollar,
		@OldBOUnits bUnits, @OldBOCost bDollar, @OldReceiver# varchar(20),
		----TK-07879 
		@OldPOItemLine INT, @ItemType TINYINT

SET	@rcode = 0

if @RecvdUnits=0 and @RecvdCost=0 and @BOUnits=0 and @BOCost=0
	begin
	goto bspexit
	end
   
   /* validate HQ Batch */
   select @source = Source, @tablename = TableName, @inuseby = InUseBy,
   	@status = Status
   	from bHQBC where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid Batch - missing from HQ Batch Control!', @rcode = 1
   	goto bspexit
   	end
   if @source <> 'PO Receipt'
   	begin
   	select @errmsg = 'Invalid Batch source - must be (PO Receipt)!', @rcode = 1
   	goto bspexit
   	end
   if @tablename <> 'PORB'
   	begin
   	select @errmsg = 'Invalid Batch table name - must be (PORB)!', @rcode = 1
   	goto bspexit
   	end
   
   if @inuseby <> SUSER_SNAME()
   	begin
   	select @errmsg = 'Batch already in use by ' + @inuseby, @rcode = 1
   	goto bspexit
   	end
   if @status <> 0
   	begin
   	select @errmsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
   	goto bspexit
   	end
   
   
   
/* validate existing PO Receipt Item*/
select  @inusebatchid = InUseBatchId
from bPOHD where POCo= @co and PO= @PO
if @@rowcount = 0
	begin
	select @errmsg = 'PO #' + convert(varchar(10),@PO) + ' not found!', @rcode = 1
	goto bspexit
	end
   
select  @inusebatchid = InUseBatchId, @Description = Description,
		@UnitCost=CurUnitCost, @ECM=CurECM, @UM=UM
from dbo.bPOIT where POCo= @co and PO= @PO and POItem= @POItem
if @@rowcount = 0
	begin
	select @errmsg = 'PO Item #' + convert(varchar(6),@POItem) + ' not found!', @rcode = 1
	goto bspexit
	END
	
if @inusebatchid is not null and @inusebatchid <> @batchid
	begin
	select @source=Source
	from HQBC
	where Co=@co and BatchId=@inusebatchid and Mth=@mth
	if @@rowcount <> 0
		begin
		select @errmsg = 'PO Item already in use by ' +
		convert(varchar(2),DATEPART(month, @mth)) + '/' +
		substring(convert(varchar(4),DATEPART(year, @mth)),3,4) +
		' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1

		goto bspexit
		end
	else
		begin
		select @errmsg='PO Item already in use by another batch!', @rcode=1
		goto bspexit
		end
	end

---- check PO Item Line TK-07879
SELECT @inusebatchid=InUseBatchId, @ItemType=ItemType
FROM dbo.vPOItemLine
WHERE POCo=@co
	AND PO=@PO
	AND POItem=@POItem
	AND POItemLine=@POItemLine
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @errmsg = 'PO Item Line:' + dbo.vfToString(@POItemLine) + ' not found!', @rcode = 1
	GOTO bspexit
	END

----TK-07879
IF @inusebatchid IS NOT NULL AND @inusebatchid <> @batchid
	BEGIN
	SELECT @source=Source
	from dbo.bHQBC
	WHERE Co=@co
		AND BatchId=@inusebatchid
		AND Mth=@mth
	IF @@ROWCOUNT <> 0
		BEGIN
		select @errmsg = 'PO Item Line already in use by ' + 
			convert(varchar(2),DATEPART(month, @mth)) + '/' +
			substring(convert(varchar(4),DATEPART(year, @mth)),3,4) +
			' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' +
			@source, @rcode = 1
		GOTO bspexit
		END
	ELSE
		BEGIN
		SELECT @errmsg='PO Item already in use by another batch!', @rcode=1
		GOTO bspexit
		END
	END

---- TK-07879 item type 6 - SM work order not valid for receiving
IF @ItemType = 6
	BEGIN
	SELECT @errmsg = 'PO Item Line :' + dbo.vfToString(@POItemLine) + ' Type is 6 - SM Work Order, not valid!', @rcode = 1
	GOTO bspexit
	END
	

   
if @UM<>'LS'
	begin
	if @ECM='E' select @ECMValue=1
	if @ECM='C' select @ECMValue=100
	if @ECM='M' select @ECMValue=1000
	select @RecvdCost=(@RecvdUnits*@UnitCost)/@ECMValue, @BOCost=(@BOUnits*@UnitCost)/@ECMValue
	END
	
/* get next available sequence # for this batch */
select @seq = isnull(max(BatchSeq),0)+1
from dbo.bPORB where Co = @co and Mth = @mth AND BatchId = @batchid
	
/* add PO item to batch */
insert into bPORB(Co, Mth, BatchId, BatchSeq, BatchTransType, POTrans, PO, POItem,
		RecvdDate, RecvdBy, Description, ECM, UnitCost, RecvdUnits, RecvdCost,
		BOUnits, BOCost, OldPO, OldPOItem, OldRecvdDate, OldRecvdBy, OldDesc,
		OldUnitCost, OldECM, OldRecvdUnits, OldRecvdCost, OldBOUnits,
		OldBOCost, Receiver#, OldReceiver#, Notes,
		----TK-07879
		POItemLine, OldPOItemLine)
values (@co, @mth, @batchid, @seq, 'A', @POTrans, @PO, @POItem, @RecvdDate, @RecvdBy,
	   @Description, @ECM, @UnitCost, @RecvdUnits, @RecvdCost, @BOUnits, @BOCost,
	   @OldPO, @OldPOItem, @OldREcvdDate, @OldRecvdBy, @OldDesc, @OldUnitCost,
	   @OldECM, @OldRecvdUnits, @OldRecvdCost, @OldBOUnits, @OldBOCost, @Receiver#,
	   @OldReceiver#, @notes,
	   ----TK-07879
	   @POItemLine, @OldPOItemLine)
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to add entry to PO Receiving Batch!', @rcode = 1
	goto bspexit
	end


bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPORBInsertNew] TO [public]
GO
