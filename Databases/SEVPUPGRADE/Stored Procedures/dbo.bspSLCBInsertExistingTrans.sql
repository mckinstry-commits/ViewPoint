SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLCBInsertExistingTrans    Script Date: 8/28/99 9:35:45 AM ******/
    CREATE         procedure [dbo].[bspSLCBInsertExistingTrans]
    /************************************************************************
    * Modified by: GG 6/8/99, GR 6/23/99
    *              EN 5/1/00 - modified Subcontract not found message to format SL# to 10 characters rather than 6
    *              GR 08/18/00 - added notes field issue# 9470
    *              BC 02/06/01 - uncommented (@inusemth = R.InUseMth) in line# 82 - issue# 11828
    *	            TV 03/19/01 -  making Error more verbouse
    *              MV 07/09/01 - Issue 12769 BatchUserMemoInsertExisting
    *              GF 07/09/2001 - Fix for getting notes, problem in join clause.
    *              TV 05/28/02 insert UniqueAttchID into batch table
    *				RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
    *				MV 09/07/04 - #25400 - change datatype to bitemdesc for @description
    *				DC 6/24/10 - #135813  - expand subcontract number
    *
    * This procedure is used by the SL Change Order program to pull existing
    * transactions from bSLCD into bSLCB for editing.
    *
    * Checks batch info in bHQBC, and transaction info in bSLCD.
    * Adds entry to next available Seq# in bSLCB.
    *
    * SLCB insert trigger will update InUseBatchId in bSLCD
    *
    * pass in Co, Mth, BatchId, and SL Trans#
    * returns 0 if successfull
    * returns 1 and error msg if failed
    *
    *************************************************************************/   
    @co bCompany, @mth bMonth, @batchid bBatchID, @sltrans bTrans, @errmsg varchar(100) output
   
    as
    set nocount on
    declare @rcode int, @source bSource, @tablename char(20), @inuseby bVPUserName, @status tinyint,
    	@adj bYN, @dtsource bSource, @sl VARCHAR(30), --bSL, DC #135813
    	@slitem bItem, @slchangeorder smallint,
    	@appchangeorder varchar(10), @actdate bDate, @description bItemDesc, @um bUM, @changecurunits bUnits,
    	@changecurunitcost bUnitCost,@changecurcost bDollar, @postedmth bMonth, @inusebatchid bBatchID,
    	@seq int, @itemtype tinyint, @inusemth bMonth, @uniqueattchid uniqueidentifier
   
    select @rcode = 0
   
    /* validate HQ Batch */
    select @source = Source, @tablename = TableName, @inuseby = InUseBy,
    	@status = Status, @adj = Adjust
    	from bHQBC where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Invalid Batch - missing from HQ Batch Control!', @rcode = 1
    	goto bspexit
    	end
    if @source <> 'SL Change'
    	begin
    	select @errmsg = 'Invalid Batch source - must be (SL Change)!', @rcode = 1
    	goto bspexit
    	end
    if @tablename <> 'SLCB'
    	begin
    	select
		@errmsg = 'Invalid Batch table name - must be (SLCB)!', @rcode = 1
    	goto bspexit
    	end
    if @inuseby <> SUSER_SNAME()
    	begin
    	select @errmsg = 'Batch already in use by ' + isnull(@inuseby,'NULL'), @rcode = 1
    	goto bspexit
    	end
    if @status <> 0
    	begin
    	select @errmsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
    	goto bspexit
    	end
   
   
    /* validate existing SL Change Order Trans */
    select @sl=T.SL, @slitem=T.SLItem, @actdate=T.ActDate, @slchangeorder=T.SLChangeOrder, @appchangeorder=T.AppChangeOrder,
    	@description=T.Description, @um=T.UM, @changecurunits=T.ChangeCurUnits, @changecurunitcost=T.ChangeCurUnitCost,
    	@changecurcost=T.ChangeCurCost, @itemtype=R.ItemType, @inusebatchid=T.InUseBatchId, @inusemth = R.InUseMth,
       @uniqueattchid = T.UniqueAttchID
    	from bSLCD T inner join bSLIT R on T.SLCo=R.SLCo and T.SL=R.SL and T.SLItem=R.SLItem
    	where T.SLTrans=@sltrans and T.SLCo=@co and T.Mth=@mth
   
    if @@rowcount = 0   
    	begin
    	select @errmsg = 'SL transaction #' + convert(varchar(10),@sltrans) + ' not found!', @rcode = 1
    	goto bspexit   
    	end
    if @inusebatchid is not null
    	begin
    	select @source=Source
    	from HQBC
    	where Co=@co and BatchId=@inusebatchid and Mth=@inusemth
    	if @@rowcount<>0
    		begin
    		select @errmsg = 'SL Transaction already in use by ' +
    		      isnull(convert(varchar(2),DATEPART(month, @mth)) + '/' +
    		      substring(convert(varchar(4),DATEPART(year, @mth)),3,4), '') +
    			' batch # ' + convert(varchar(6),isnull(@inusebatchid,'NULL')) + ' - ' + 'Batch Source: ' + isnull(@source,'NULL') + 'By: ' + isnull(@source,'NULL') , @rcode = 1
    		goto bspexit
    	    end
    	else
    	    begin
    		select @errmsg='SL Transaction already in use by another batch!', @rcode=1
    		goto bspexit
    	    end
    	end
    if substring(@dtsource,1,2) <> 'SL'
    	begin   
    	select @errmsg = 'This SL transaction was created with a ' + isnull(@dtsource,'NULL') + ' source!', @rcode = 1
    	goto bspexit
    	end
      
    /* check for SL in use here*/   
    select @inusemth = InUseMth, @inusebatchid=InUseBatchId
    from bSLHD where SLCo=@co and SL = @sl
   
    if (isnull(@inusebatchid,0) <> @batchid or isnull(@inusemth,'') <> @mth)
        and @inusebatchid is not null and @inusemth is not null
    	begin
    	select @source=Source
    	from HQBC
    	where Co=@co and BatchId=@inusebatchid and Mth=@mth
   
    	if @@rowcount<>0
    		begin
    		select @errmsg = 'SL already in use by ' +
    		      isnull(convert(varchar(2),DATEPART(month, @inusemth)) + '/' +
    		      substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4), '') +
    			' Batch # ' + convert(varchar(6),isnull(@inusebatchid,'NULL')) + ' - ' + 'Batch Source: ' + isnull(@source,'NULL'), @rcode = 1   
    		goto bspexit
    	    end
    	else
    	    begin
    		select @errmsg='SL already in use by another batch!', @rcode=1
    		goto bspexit
    	    end
    	end
   
    /* check for SL Item in use here*/   
    select @inusemth = InUseMth, @inusebatchid=InUseBatchId
    from bSLIT where SLCo=@co and SL = @sl and SLItem = @slitem
   
    if (isnull(@inusebatchid,0) <> @batchid or isnull(@inusemth,'') <> @mth)
        and @inusebatchid is not null and @inusemth is not null
    	begin
    	select @source=Source
    	from HQBC
    	where Co=@co and BatchId=@inusebatchid and Mth=@mth
   
    	if @@rowcount<>0
    		begin
    		select @errmsg = 'SL Item already in use by ' +
    		      isnull(convert(varchar(2),DATEPART(month, @inusemth)) + '/' +
    		      substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4),'') +
    			' batch # ' + convert(varchar(6),isnull(@inusebatchid,'NULL')) + ' - ' + 'Batch Source: ' + isnull(@source,'NULL'), @rcode = 1   
    		goto bspexit
    	    end
    	else
    	    begin
    		select @errmsg='SL Item already in use by another batch!', @rcode=1
    		goto bspexit
    	    end
    	end
   
    /* get next available sequence # for this batch */
    select @seq = isnull(max(BatchSeq),0)+1 from bSLCB where Co = @co and Mth = @mth and BatchId = @batchid
      
    /* add SL change order transaction to batch */
   --Current cost should be set to 0, or the total will be off 07/12/01 TV
    insert into bSLCB (Co, Mth, BatchId, BatchSeq, BatchTransType, SLTrans, SL, SLItem, SLChangeOrder,
    	AppChangeOrder, ActDate, Description, UM, ChangeCurUnits, CurUnitCost, ChangeCurCost,
    	OldSL, OldSLItem, OldSLChangeOrder, OldAppChangeOrder, OldActDate, OldDescription, OldUM,
    	OldCurUnits, OldUnitCost, OldCurCost, UniqueAttchID)
    values (@co, @mth, @batchid, @seq, 'C', @sltrans, @sl, @slitem, @slchangeorder, @appchangeorder, @actdate,
    	@description, @um, @changecurunits, @changecurunitcost, @changecurcost, @sl, @slitem, @slchangeorder,
    	@appchangeorder, @actdate, @description, @um, @changecurunits, @changecurunitcost, @changecurcost, @uniqueattchid)
    if @@rowcount <> 1
    	begin
    	select @errmsg = 'Unable to add entry to SL Change Order Batch!', @rcode = 1
    	goto bspexit
    	end
   
	--update notes seperately, added as per issue# 9470
    update bSLCB 
    set Notes = d.Notes
    from bSLCB b
    join bSLCD d on d.SLCo=b.Co and d.Mth=b.Mth and d.SLTrans=b.SLTrans
    where d.SLCo=@co and d.Mth=@mth and d.SLTrans=@sltrans
   
    /* update user memo to SLCB batch table- BatchUserMemoInsertExisting */
    exec @rcode = bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'SL ChgOrder', 0, @errmsg output
    if @rcode <> 0
		begin
   		select @errmsg = 'Unable to update user memo to SL Change Order Batch!', @rcode = 1
   		goto bspexit
   		end
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLCBInsertExistingTrans] TO [public]
GO
