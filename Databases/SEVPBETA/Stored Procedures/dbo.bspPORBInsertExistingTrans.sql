SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Stored Procedure dbo.bspPORBInsertExistingTrans    Script Date: 8/28/99 9:35:26 AM ******/
     CREATE       procedure [dbo].[bspPORBInsertExistingTrans]
     /************************************************************************
     * MODIFIED : DANF 02/11/2000 - ADDED RECEIVER# AND INVOICED FLAG
     * This procedure is used by the PO Receipts program to pull existing
     * transactions from bPORD into bPORB for editing.
     * MODIFIED : DANF 03/02/2000
     *          : DANF 09/06/2000 Add Notes.
     *          : MV   07/06/01 - #12769 BatchUserMemoInsertExisting
     *            kb 8/9/1 - issue #14296
     *            allenn 09/27/01 - Issue 13708 Remmed out code and inserted
     *           new code for checking if PO in use by another batch.
     *		 Allow current user and same program to add PO's
     *          TV 05/28/02 Insert UniqueAttchID into batch table
     *		  MV 05/20/03 - #21243 check if trans already in current batch
	 *		 MV 02/12/09 - #123778 - insert Invoice info into bPORB
	 *		 JVH	12/24/09 - #134748 - added some parameters that default to null
	 *			and provide some functionality needed by connects
     *			Checks batch info in bHQBC, and transaction info in bPORD.
	*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
	*		GF 08/21/2011 TK-07879 PO ITEM LINES
	*		JVH 12/13/12 TK-19985 Modified to allow receiving SM lines
	*
	*
     * Adds entry to next available Seq# in bPORB.
     *
     * PORB insert trigger will update InUseBatchId in bPORD
     *
     * pass in Co, Mth, BatchId, and PO Trans#
     * returns 0 if successfull
     * returns 1 and error msg if failed
     *
     *************************************************************************/
    
@co bCompany, @mth bMonth, @batchid bBatchID,
@potrans bTrans, @errmsg varchar(100) output,
@currentUser bVPUserName = NULL, @seq int = NULL OUTPUT

as
set nocount on
declare @rcode int, @source bSource, @tablename char(20), @inuseby bVPUserName, @status tinyint,
		@adj bYN, @dtsource bSource, @actdate bDate,
		@desc bDesc, @amt bDollar, @dtadj bYN, @inusebatchid bBatchID, @po varchar(30), @poitem bItem,
		@recvddate bDate, @recvdby char(10), @description bDesc, @recvdunits bUnits, @recvdcost bDollar,
		@bounits bUnits, @bocost bDollar, @unitcost bUnitCost, @ecm bECM, @postedmth bMonth, @um bUM,
		@Receiver# varchar(20), @InvdFlag bYN, @valmsg varchar(200), @uniqueattchid uniqueidentifier,
		@apmth bMonth, @aptrans bTrans, @apline int, @uimth bMonth, @uiseq int, @uiline INT,
		----TK-07879
		@POItemLine INT, @ItemType TINYINT
		

select @rcode = 0

IF @currentUser IS NULL
BEGIN
SET @currentUser = SUSER_SNAME()
END
    
 /* validate HQ Batch */
 select @source = Source, @tablename = TableName, @inuseby = InUseBy,

 	@status = Status, @adj = Adjust
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
 	select
 @errmsg = 'Invalid Batch table name - must be (bPORB)!', @rcode = 1
 	goto bspexit
 	end
 if @inuseby <> @currentUser
 	begin
 	select @errmsg = 'Batch already in use by ' + @inuseby, @rcode = 1
 	goto bspexit
 	end
 if @status <> 0
 	begin
 	select @errmsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
 	goto bspexit
 	end
    
    
/* validate existing PO Receipts Trans */ ----TK-07879
select @po=T.PO, @poitem=T.POItem, @um=R.UM, @recvddate=T.RecvdDate, @recvdby=T.RecvdBy,
		@description=T.Description, @recvdunits=T.RecvdUnits, @recvdcost=T.RecvdCost,
		@bounits=T.BOUnits, @bocost=T.BOCost, @postedmth=Mth, @unitcost=R.CurUnitCost,
		@ecm=R.CurECM, @inusebatchid=T.InUseBatchId, @Receiver#=T.Receiver#,
		@InvdFlag=T.InvdFlag, @uniqueattchid = T.UniqueAttchID, @apmth=T.APMth,
		@aptrans = T.APTrans, @apline = T.APLine, @uimth = T.UIMth, @uiseq=T.UISeq,
		@uiline=T.UILine,
		----TK-07879
		@POItemLine=T.POItemLine, @ItemType=L.ItemType
from dbo.bPORD T
INNER JOIN dbo.vPOItemLine L ON L.POCo=T.POCo AND L.PO=T.PO AND L.POItem=T.POItem AND L.POItemLine=T.POItemLine
inner join dbo.bPOIT R on T.POCo=R.POCo and T.PO=R.PO AND T.POItem=R.POItem
where T.POTrans=@potrans and T.POCo=@co and T.Mth=@mth
if @@rowcount = 0
	begin
	select @errmsg = 'PO transaction #' + convert(varchar(6),@potrans) + ' not found!', @rcode = 1
	goto bspexit
	end
    
/*Issue 13708*/
exec @rcode = bspPOHDInUseValidation @co, @mth,  @po, @inusebatchid output, @postedmth output, @valmsg output
if @inusebatchid is null or (@inusebatchid = @batchid and @mth = @postedmth)
	begin
		select @rcode = 0
		end
	else
		begin
		select @errmsg = @valmsg
		goto bspexit
	end
    
/* Issue 21243*/
if exists (select 1 from bPORB where Co=@co and Mth=@mth and BatchId=@batchid and POTrans=@potrans)
	begin
	select @errmsg = 'PO transaction #' + convert(varchar(6),@potrans) + ' already in this batch!', @rcode = 1
	goto bspexit
	end

 if substring(@dtsource,1,2) <> 'PO'
 	begin
 	select @errmsg = 'This PO transaction was created with a ' + @dtsource + ' source!', @rcode = 1
 	goto bspexit
 	end

 if @postedmth<>@mth
 	begin
 	select @errmsg = 'This PO transaction was posted to a different month.', @rcode = 1
 	goto bspexit
 	end

 if exists(select * from bPOHD where POCo = @co and PO = @po and Status = 2)
    begin
    select @errmsg = 'This PO is closed!', @rcode = 1
    goto bspexit
    end



/* get next available sequence # for this batch */
select @seq = isnull(max(BatchSeq),0)+1
from dbo.bPORB where Co = @co and Mth = @mth and BatchId = @batchid

/* add PO receipts transaction to batch */
INSERT INTO dbo.bPORB (Co, Mth, BatchId, BatchSeq, BatchTransType, POTrans, PO, POItem, RecvdDate,
		RecvdBy, Description, UnitCost, ECM, RecvdUnits, RecvdCost, BOUnits, BOCost, OldPO, OldPOItem,
		OldRecvdDate, OldRecvdBy, OldDesc, OldUnitCost, OldECM, OldRecvdUnits, OldRecvdCost,
		OldBOUnits, OldBOCost, Receiver#, OldReceiver#, InvdFlag, OldInvdFlag, Notes,
		UniqueAttchID,APMth,APTrans, APLine, UIMth, UISeq, UILine, OldPOItemLine, POItemLine)
select @co, @mth, @batchid, @seq, 'C', @potrans, @po, @poitem, @recvddate, @recvdby,
		@description, @unitcost, @ecm, @recvdunits,@recvdcost, @bounits, @bocost, @po, @poitem,
		@recvddate, @recvdby, @description, @unitcost, @ecm, @recvdunits, @recvdcost, @bounits,
		@bocost, @Receiver#, @Receiver#, @InvdFlag, @InvdFlag, Notes, @uniqueattchid,
		@apmth, @aptrans, @apline, @uimth, @uiseq, @uiline, @POItemLine, @POItemLine 
from bPORD where POCo = @co and Mth = @mth and POTrans = @potrans
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to add entry to PO Receiving Batch!', @rcode = 1
	goto bspexit
	end



/* update user memo to PORB batch table- BatchUserMemoInsertExisting */
exec @rcode = bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'PO Receipts', 0, @errmsg output
 if @rcode <> 0
	 begin
	 select @errmsg = 'Unable to update user memo to PO Receipts Batch!', @rcode = 1
	 goto bspexit
	 end



bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPORBInsertExistingTrans] TO [public]
GO
