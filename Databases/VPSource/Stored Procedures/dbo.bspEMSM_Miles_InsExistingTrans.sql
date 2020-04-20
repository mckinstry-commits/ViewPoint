SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                procedure [dbo].[bspEMSM_Miles_InsExistingTrans]
    /***********************************************************
    * CREATED BY: JM 8/12/02 - Adapted from bspEMBM_Miles_InsExistingTrans for 
    *	new tables bEMMH, bEMML and bEMMS.
    *	JM 08/14/02 - Disabled user memos
    *	JM 8/15/02 - Revised to return all lines associated with the selected transaction's batchseq
    *	JM 8/15/02 - Added bEMMS.BatchSeq column; this proc will return all lines associated with
    *		selected transaction's BatchId and BatchSeq
    *	RM 10/23/02 - Rewritten for new table structure
    *  TV 02/11/04 - 23061 added isnulls
    *	TV 06/16/05 - 27334 update oldtrans in EMML
    *	TJL 08/03/07 - Issue #27792, fix Header Notes & UniqueAttchID were not being added back into batch for change.
	*
    * MODIFIED By : 
    *
    * USAGE:
    *	This procedure pulls existing transactions from bEMMS into bEMMH\bEMML for editing
    *
    *	Checks batch info in bHQBC, and transaction info in bEMMS.
    *	Adds entry to next available Seq# in bEMMH\bEMML.
    *
    *	bEMMH insert trigger will update InUseBatchId in bEMMS.
    *
    * INPUT PARAMETERS
    *	Co         EM Co to pull from
    *	Mth        Month of batch
    *	BatchId    Batch ID to insert transaction into
    *	EMTrans    EM Trans to Pull
    *	Source     EM Source
    *
    * OUTPUT PARAMETERS
    *
    * RETURN VALUE
    *	0   Success
    *	1   Failure
    *****************************************************/
    @co bCompany,
    @mth bMonth,
    @batchid bBatchID,
    @emtrans bTrans,
    @source bSource,
    @errmsg varchar(255) output
    
    as
    
    set nocount on
    
    declare @addemtrans bTrans, 
    	@batchseq int,
    	@emtranstype varchar(10),
    	@errtext varchar(60),
    	@glco bCompany,
    	@hqbcsource bSource,
    	@inusebatchid bBatchID,
       @inusemth	bMonth,
    	@inuseby bVPUserName,
    	@nextbatchseq int,
    	@nextline int, 
    	@postedmth bMonth,
    	@rcode int,
    	@seqlines int,
    	@status tinyint
    
    select @rcode = 0
    
    /* Validate all params passed. */
    if @co is null
    	begin
    	select @errmsg = 'Missing Batch Company!', @rcode = 1
    	goto bspexit
    	end
    if @mth is null
    	begin
    	select @errmsg = 'Missing Batch Month!', @rcode = 1
    	goto bspexit
    	end
    if @batchid is null
    	begin
    	select @errmsg = 'Missing Batch ID!', @rcode = 1
    	goto bspexit
    	end
    if @emtrans is null
    	begin
    	select @errmsg = 'Missing Batch Transaction!', @rcode = 1
    	goto bspexit
    	end
    if @source is null
    	begin
    	select @errmsg = 'Missing Batch Source!', @rcode = 1
    	goto bspexit
    	end
    
    /* Validate Source. */
    if @source <> 'EMMiles'
    	begin
    	select @errmsg = @source + ' is an invalid Source', @rcode = 1
    	goto bspexit
    	end
    
    /* Validate HQ Batch. */
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'EMMH', @errtext output, @status output
    if @rcode <> 0
    	begin
    	select @errmsg = @errtext, @rcode = 1
    	goto bspexit
    	end
    if @status <> 0
    	begin
    	select @errmsg = 'Invalid Batch status - must be Open!', @rcode = 1
    	goto bspexit
    	end
    
    /* All Transactions can be pulled into a batch as long as its InUseFlag is set to null and Month is same as current */
    select @inusebatchid = InUseBatchId, @inusemth=InUseMth,@postedmth=Mth from bEMSM where Co=@co and Mth = @mth and EMTrans=@emtrans
    if @@rowcount = 0
    	begin
    	select @errmsg = 'EMTrans :' + isnull(convert(varchar(10),@emtrans),'') + ' cannot be found.' , @rcode = 1
    	goto bspexit
    	end
    
    if @inusebatchid is not null
    	begin
    	select @hqbcsource=Source from HQBC where Co=@co and BatchId=@inusebatchid and Mth=@inusemth
    	if @@rowcount<>0
    		begin
    		select @errmsg = 'Transaction already in use by ' + isnull(convert(varchar(2),DATEPART(month, @inusemth)),'') + '/' +
    			isnull(substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4),'') + ' batch # ' + isnull(convert(varchar(6),@inusebatchid),'') + 
    			' - Batch Source: ' + isnull(@hqbcsource,''), @rcode = 1
    		goto bspexit
    		end
    	else
    		begin
    		select @errmsg='Transaction already in use by another batch!', @rcode=1
    		goto bspexit
    		end
    	end
    
    if @postedmth <> @mth
    	begin
    	select @errmsg = 'Cannot edit! EM transaction posted in prior month: ' +
    	isnull(convert(varchar(60),@postedmth),'') + ',' + isnull(convert(varchar(60),@mth),''), @rcode = 1
    	goto bspexit
    	end
    
    /* get GLCo from bEMCo - needed for btEMMSi trigger's insertion into bHQCC where that column can't be null */
    select @glco = GLCo from bEMCO where EMCo = @co
    
    /* get BatchSeq for this @emtrans
    select @batchseq = BatchSeq from bEMSM where EMCo = @co and Mth = @mth and EMTrans = @emtrans
    */
   
    /* get next available sequence # for this batch */
    select @nextbatchseq = isnull(max(BatchSeq),0)+1 from bEMMH where Co = @co and Mth = @mth and BatchId = @batchid
    
    /* Add header record back to EMMH if it hasn't already been added for another detail line */
    if not exists (select * from bEMMH where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @nextbatchseq)
   	begin
   	 	insert into bEMMH (Co, Mth, BatchId, BatchSeq,EMTrans,BatchTransType, Equipment, ReadingDate, BeginOdo, EndOdo, Notes,
   	 		UniqueAttchID, OldEquipment, OldReadingDate, OldBeginOdo, OldEndOdo)
   	 	select @co, @mth, @batchid, @nextbatchseq,EMTrans,'C', Equipment, ReadingDate, BeginOdo, EndOdo, Notes,
   	 		UniqueAttchID, Equipment, ReadingDate, BeginOdo, EndOdo
   	 	from bEMSM where Co=@co and Mth = @mth and EMTrans=@emtrans
   		
   		update bEMSM set InUseMth=@mth,InUseBatchId=@batchid where Co=@co and Mth = @mth and EMTrans=@emtrans
   
   	end
    else
   	begin
   		select @errmsg = 'Unable to add Header to EM Batch table!', @rcode = 1
    		goto bspexit
   	end
    
    	
    	/* Add Lines back to EMML */
    	insert into bEMML (Co, Mth, BatchId, BatchSeq, Line, BatchTransType, EMTrans, UsageDate, State, OnRoadLoaded, OnRoadUnLoaded, OffRoad, Notes,
    		  OldTrans,OldUsageDate, OldState, OldOnRoadLoaded, OldOnRoadUnLoaded, OldOffRoad)	
    	select @co, @mth, @batchid, @nextbatchseq, Line, 'C', EMTrans, UsageDate, State, OnRoadLoaded, OnRoadUnLoaded, OffRoad, Notes,
    		 @emtrans, UsageDate, State, OnRoadLoaded, OnRoadUnLoaded, OffRoad
    	from bEMSD where Co=@co and Mth = @mth and EMTrans=@emtrans
   
    	if @@error <> 0
    		begin
    		select @errmsg = 'Unable to add Lines to EM Batch table!', @rcode = 1
    		goto bspexit
    		end
   	else
   		begin
   			update bEMSD set InUseMth=@mth,InUseBatchId=@batchid where Co=@co and Mth = @mth and EMTrans=@emtrans
   		end
    
    	
    /* BatchUserMemoInsertExisting - update the user memo in the batch record */
    exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @nextbatchseq, 'EM MilesByState', 0, @errmsg output
    if @rcode <> 0
    	begin
    	select @errmsg = 'Unable to update User Memos in EMMH', @rcode = 1
    	goto bspexit
    	end
    
   
    exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @nextbatchseq, 'EM MilesByState Lines', 0, @errmsg output
    if @rcode <> 0
    	begin
    	select @errmsg = 'Unable to update User Memos in EMML', @rcode = 1
    	goto bspexit
    	end
   
    bspexit:
    if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMSM_Miles_InsExistingTrans]'
    return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMSM_Miles_InsExistingTrans] TO [public]
GO
