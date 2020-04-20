SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Stored Procedure dbo.bspPOCBInsertExistingTrans    Script Date: 8/28/99 9:35:24 AM ******/
     CREATE        procedure [dbo].[bspPOCBInsertExistingTrans]
     /************************************************************************
     * Created: ??
     * Modified: GG 6/23/99
     * Modified: kb 12/29/99 - InUse by check was using the current batch month to display source etc instead of the inusemth
     *           GR 08/24/00 - Added notes to insert inot bPOCB table
     *           MV 07/03/01 - Issue 12769 BatchUserMemoInsertExisting
     *           kb 8/9/1 - issue #14296
     *           allenn 09/27/01 - Issue 13708 Remmed out code and inserted new code for checking if PO in use by another batch.  Allow current user and same program to add PO's
     *           kb 1/8/2 - Issue #15771
     *           TV 05/28/02 - insert UniqueAttchID into batch table
     *			  MV 05/21/03 - #21243 check if trans already in current batch
     *			  MV 10/14/03 - #22320 - insert ChgTotCost into bPOCB from bPOCD
     *			  RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
	*			DC 04/29/08 -	#120634 - Add a column to POCD for ChgToTax
	*			DC 12/01/08 - #131271 - Can't delete PO Change Order when POCD.Description>30 characters
	*			DAN SO 04/01/2011 - TK-03816 - New POCONum field added (PO Change Order Number -> link to PM PO Change Order)
     *			TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
	 *
     * This procedure is used by the PO Change Order program to pull existing
     * transactions from bPOCD into bPOCB for editing.
     *
     * Checks batch info in bHQBC, and transaction info in bPOCD.
     * Adds entry to next available Seq# in bPOCB.
     *
     * POCB insert trigger will update InUseBatchId in bPOCD
     *
     * pass in Co, Mth, BatchId, and PO Trans#
   
     * returns 0 if successfull
     * returns 1 and error msg if failed
     *
     *************************************************************************/
   
     	@co bCompany, @mth bMonth, @batchid bBatchID,
     	@potrans bTrans, @errmsg varchar(150) output
   
     as
     set nocount on
     declare @rcode int, @source bSource, @tablename char(20), @inuseby bVPUserName, @status tinyint,
     	@adj bYN, @dtsource bSource, @po varchar(30), @poitem bItem, @changeorder varchar(10),
     	@actdate bDate, @description bItemDesc,  --DC #131271 
     	@um bUM, @changecurunits bUnits,
     	@curunitcost bUnitCost, @ecm bECM, @changecurcost bDollar, @changebounits bUnits,
     	@changebocost bDollar, @postedmth bMonth, @inusebatchid bBatchID, @seq int, @inusemth bMonth, @valmsg varchar(200),
       @uniqueattchid uniqueidentifier, @chgtotcost bDollar,
		@chgtotax bDollar,  --DC #120634
		@POCONum smallint  --TK-03816
   
     select @rcode = 0
   
     /* validate HQ Batch */
     select @source = Source, @tablename = TableName, @inuseby = InUseBy,
     	@status = Status, @adj = Adjust
     	from bHQBC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
     if @@rowcount = 0
     	begin
     	select @errmsg = 'Invalid Batch - missing from HQ Batch Control!', @rcode = 1
     	goto bspexit
     	end
     if @source <> 'PO Change'
     	begin
     	select @errmsg = 'Invalid Batch source - must be (PO Change)!', @rcode = 1
     	goto bspexit
     	end
     if @tablename <> 'POCB'
     	begin
     	select
     @errmsg = 'Invalid Batch table name - must be (bPOCB)!', @rcode = 1
     	goto bspexit
     	end
     /*if @inuseby <> SUSER_SNAME()
     	begin
     	select @errmsg = 'Batch already in use by ' + @inuseby, @rcode = 1
     	goto bspexit
     	end*/
     if @status <> 0
     	begin
     	select @errmsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
     	goto bspexit
     	end
   
   
     /* validate existing PO Change Order Trans */
     select @po=T.PO, @poitem=T.POItem, @actdate=T.ActDate, @changeorder=T.ChangeOrder, @description=T.Description,
     	@um=T.UM, @changecurunits=T.ChangeCurUnits, @curunitcost=T.CurUnitCost, @ecm=ECM, @changecurcost=T.ChangeCurCost,
     	@changebounits=T.ChangeBOUnits, @changebocost=T.ChangeBOCost, @inusebatchid=T.InUseBatchId, @uniqueattchid = T.UniqueAttchID,
   	@chgtotcost=T.ChgTotCost,
	@chgtotax = T.ChgToTax,  --DC #120634
	@POCONum = T.POCONum  --TK-03816
     	from bPOCD T with (nolock)
      inner join bPOIT R with (nolock) on T.POCo=R.POCo and T.PO=R.PO and T.POItem=R.POItem
     	where T.POTrans=@potrans and T.Mth=@mth and T.POCo=@co
   
     if @@rowcount = 0
   
     	begin
     	select @errmsg = 'PO transaction #' + isnull(convert(varchar(6),@potrans),'') + ' not found!', @rcode = 1
     	goto bspexit
   
     	end
   
   /*Issue 13708*/
   
   exec @rcode = bspPOHDInUseValidation @co, @mth,  @po, @inusebatchid output, @inusemth output, @valmsg output
   if @inusebatchid is null or (@inusebatchid = @batchid and @inusemth = @mth)
       begin
           select @rcode = 0
       end
   else
       begin
           select @errmsg = @valmsg
           goto bspexit
       end
   
   /* Issue 21243*/
   if exists (select 1 from bPOCB with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid
   	and POTrans=@potrans)
   	begin
     	select @errmsg = 'PO transaction #' + isnull(convert(varchar(6),@potrans),'') + ' already in this batch!', @rcode = 1
     	goto bspexit
     	end
   
   
   /*
     if @inusebatchid is not null
     	begin
     	select @source=Source
     	       from HQBC
     	       where Co=@co and BatchId=@inusebatchid and Mth=@mth
   
     	    if @@rowcount<>0
     	       begin
   
     		select @errmsg = 'PO transaction already in use by ' +
     		      convert(varchar(2),DATEPART(month, @mth)) + '/' +
     		      substring(convert(varchar(4),DATEPART(year, @mth)),3,4) +
     			' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
   
     		goto bspexit
     	       end
     	    else
     	       begin
     		select @errmsg='PO transaction already in use by another batch!', @rcode=1
     		goto bspexit
     	       end
     	end
    */
     if substring(@dtsource,1,2) <> 'PO'
     	begin
     	select @errmsg = 'This PO transaction was created with a ' + @dtsource + ' source!', @rcode = 1
     	goto bspexit
     	end
   
     /* check whether PO Item is already in use by another batch */
     select @inusemth = InUseMth, @inusebatchid=InUseBatchId
     from bPOIT with (nolock) where POCo=@co and PO = @po and POItem = @poitem
   
     if (isnull(@inusebatchid,0) <> @batchid or isnull(@inusemth,'') <> @mth)
         and @inusebatchid is not null and @inusemth is not null
     	begin
     	select @source=Source
       from bHQBC with (nolock)
     	       where Co=@co and BatchId=@inusebatchid and Mth=@inusemth
   
     	    if @@rowcount<>0
     	       begin
     		select @errmsg = 'PO Item already in use by ' +
     		      convert(varchar(2),DATEPART(month, @inusemth)) + '/' +
     		      substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) +
     			' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
   		select @errmsg = isnull(@errmsg, 'PO Item already in use by another batch!')
     		goto bspexit
     	       end
     	    else
     	       begin
     		select @errmsg='PO Item already in use by another batch!', @rcode=1
     		goto bspexit
     	       end
     	end
       select @inusemth = Mth, @inusebatchid=InUseBatchId
     from bPOCD with (nolock) where POCo=@co and PO = @po and POItem = @poitem
   
     if (isnull(@inusebatchid,0) <> @batchid or isnull(@inusemth,'') <> @mth)
         and @inusebatchid is not null and @inusemth is not null
     	begin
     	select @source=Source
       from bHQBC with (nolock)
     	       where Co=@co and BatchId=@inusebatchid and Mth=@inusemth
   
     	    if @@rowcount<>0
     	       begin
     		select @errmsg = 'PO Item already in use by ' +
     		      convert(varchar(2),DATEPART(month, @inusemth)) + '/' +
     		      substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) +
     			' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
   		select @errmsg = isnull(@errmsg, 'PO Item already in use by another batch!')
     		goto bspexit
     	       end
     	    else
     	       begin
     		select @errmsg='PO Item already in use by another batch!', @rcode=1
     		goto bspexit
     	       end
     	end
     /* check whether PO is already in use by another batch */
     select @inusemth = InUseMth, @inusebatchid=InUseBatchId
     from bPOHD with (nolock) where POCo=@co and PO = @po
   
     if (isnull(@inusebatchid,0) <> @batchid or isnull(@inusemth,'') <> @mth)
         and @inusebatchid is not null and @inusemth is not null
     	begin
     	select @source=Source
     	       from bHQBC with (nolock)
     	       where Co=@co and BatchId=@inusebatchid and Mth=@inusemth
   
     	    if @@rowcount<>0
     	       begin
     		select @errmsg = 'PO already in use by ' +
     		      convert(varchar(2),DATEPART(month, @inusemth)) + '/' +
     		      substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) +
     			' Batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
   		select @errmsg = isnull(@errmsg, 'PO already in use by another batch!')
     		goto bspexit
     	       end
     	    else
     	       begin
     		select @errmsg='PO already in use by another batch!', @rcode=1
     		goto bspexit
     	       end
     	end
   
     if exists(select * from bPOHD with (nolock) where POCo = @co and PO = @po and Status = 2)
        begin
        select @errmsg = 'This PO is closed!', @rcode = 1
        goto bspexit
        end
   
   
   
     /* get next available sequence # for this batch */
     select @seq = isnull(max(BatchSeq),0)+1 from bPOCB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
   
   
     /* add PO change order transaction to batch */
     insert into bPOCB (Co, Mth, BatchId, BatchSeq, BatchTransType, POTrans, PO, POItem, ChangeOrder, ActDate, Description,
     	UM, ChangeCurUnits, CurUnitCost, ECM, ChangeCurCost, ChangeBOUnits, ChangeBOCost, OldPO, OldPOItem, OldChangeOrder,
     	OldActDate, OldDescription, OldUM, OldCurUnits, OldUnitCost, OldECM, OldCurCost, OldBOUnits, OldBOCost, Notes,
       UniqueAttchID,ChgTotCost, OldChgTotCost,
		ChgToTax,  --DC #120634
		POCONum)  --TK-03816
     select @co, @mth, @batchid, @seq, 'C', @potrans, @po, @poitem, @changeorder, @actdate, @description,
     	@um, @changecurunits, @curunitcost, @ecm, @changecurcost, @changebounits, @changebocost, @po, @poitem, @changeorder,
     	@actdate, @description, @um, @changecurunits, @curunitcost, @ecm, @changecurcost, @changebounits, @changebocost,
         T.Notes, @uniqueattchid, @chgtotcost, @chgtotcost,
		@chgtotax,  --DC #120634
		@POCONum  --TK-03816
         from bPOCD T with (nolock)
         inner join bPOIT R with (nolock) on T.POCo=R.POCo and T.PO=R.PO and T.POItem=R.POItem
     	where T.POTrans=@potrans and T.Mth=@mth and T.POCo=@co
     if @@rowcount <> 1
     	begin
     	select @errmsg = 'Unable to add entry to PO Change Order Batch!', @rcode = 1
   	goto bspexit
   
     	end
   
       /* BatchUserMemoInsertExisting - update the user memo in the batch record */
        exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'PO ChgOrder',
             0, @errmsg output
             if @rcode <> 0
             begin
               select @errmsg = isnull(@errmsg,'') + ' Unable to update User Memos in POCB', @rcode = 1
               goto bspexit
               end
   
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOCBInsertExistingTrans] TO [public]
GO
