SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspEMBatchDelete    Script Date: 8/28/99 9:34:25 AM ******/
CREATE        proc [dbo].[bspEMBatchDelete]
/***********************************************************
* CREATED BY: 	JM 5/8/99
* MODIFIED By:  bc 06/30/99
*				JM 8/4/99 - Added @newstatus parameter with
*				TV 02/11/04 - 23061 added isnulls
*				TV 06/02/04 24659 - EM Batch clear does not clear all necessary distribution tables
*				TV 03/13/05 26995 - We set the EMCO.DeprLstMnthCalc value even if batch is cleared
*				GF 01/25/2008 - issue #126860 remove reference to 'EMBZGrid'
*				GF 01/22/2013 TK-20889 clear EMBC when source is usage posting
*
*
*
*  ability to retain as open batch rather than canceled. If
*  retained as Open, deletes any batch errors logged to bHQBE.
*
*	RM 05/14/01 - Replace LastDates in EMAH with PrevDates in EMAH
*
* USAGE:
* 	Deletes records in EM Batch table and sets
*	Batch Status in bHQBC to 0 (Open) or 6 (Canceled).
*
* INPUT PARAMETERS
*	EMCo		Valid EM Company
*	Month		Valid Batch Month
*	BatchId		Valid Batch ID
*  NewStatus   0 for Open or 6 for Canceled
*
* OUTPUT PARAMETERS
*	@msg      error message if error occurs
*
* RETURN VALUE
*	0         Success
*	1         Failure
*****************************************************/
    (@co bCompany,
    @mth bMonth,
    @batchid bBatchID,
    @newstatus tinyint,
    @errmsg varchar(60) output)
    as
    set nocount on
    
    declare @rcode int,
        @tablename char(20),
        @inuseby bVPUserName,
        @currentstatus tinyint,
        @alloccode tinyint,
   	  @source varchar(10)
    
    select @rcode = 0
    
    /* Verify all params passed. */
    if @co is null
    	begin
    	select @errmsg = 'Missing EM Company!', @rcode = 1
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
    if @newstatus is null
    	begin
    	select @errmsg = 'Missing New Status!', @rcode = 1
    	goto bspexit
    	end
    
    /* Validate BatchId and make sure it isnt in process of being validated or posted. */
    select @currentstatus=Status, @inuseby=InUseBy, @tablename=TableName
    from bHQBC
    where Co=@co and Mth=@mth and BatchId=@batchid
    if @@rowcount=0
    	begin
    	select @errmsg='Invalid batch.', @rcode=1
    	goto bspexit
    	end
    if @currentstatus=1 /* Validation in progress. */
    	begin
    	select @errmsg='Cannot clear - Batch Validation in progress!', @rcode=1
    	goto bspexit
    	end
    if @currentstatus=4 /* Posting in progress. */
    	begin
    	select @errmsg='Cannot clear, Batch Posting in progress!', @rcode=1
    	goto bspexit
    	end
    
    if @inuseby<>SUSER_SNAME()
     	begin
     	select @errmsg='Batch is already in use by @inuseby ' + isnull(@inuseby,'') + '!', @rcode=1
     	goto bspexit
     	end
    
   /* Delete from EM batch table bEMBF. */
   if @tablename = 'EMBF'
   	begin
   	--First reset the AllocCode processed dates to previous values
   	select @alloccode = AllocCode, @source = Source from bEMBF where Co = @co and Mth = @mth and BatchId = @batchid
   	if @alloccode is not null
   		begin
   		update bEMAH set LastPosted = PrevPosted,LastMonth = PrevMonth,LastBeginDate = PrevBeginDate,LastEndDate = PrevEndDate,
   			PrevPosted = null,PrevMonth = null,PrevBeginDate = null,PrevEndDate = null
   		where EMCo = @co and AllocCode = @alloccode
   		end
   	if @source = 'EMDepr'-- TV 03/13/05 26995 - We set the EMCO.DeprLstMnthCalc value even if batch is cleared
   		begin
   		Exec @rcode = bspEMDepLastDate @co, @mth, @batchid, @errmsg output
   		if @rcode = 1 goto bspexit
   		end
   	delete bEMBF where Co=@co and Mth=@mth and BatchId=@batchid
   	if exists(select 1 from EMBC where EMCo = @co and Mth = @mth and BatchId = @batchid)
   		delete bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid
   	end
    
    
   /* Location transfer batch */
   if @tablename = 'EMLB'
    	delete from bEMLB where Co=@co and Mth=@mth and BatchId=@batchid
   
   /* Miles By State Batch (Header-Detail) */
   if @tablename = 'EMMH'
   	begin
   	delete from bEMML where Co = @co and Mth = @mth and BatchId = @batchid
   	delete from bEMMH where Co = @co and Mth = @mth and BatchId = @batchid
   	end
   
   -- TV 06/02/04 24659 - EM Batch clear does not clear all necessary distribution tables
   /* clear GL Distributions Audit */
   delete bEMGL where EMCo = @co and Mth = @mth and BatchId = @batchid
     
   /* clear Job Cost Distributions Audit */
   delete bEMJC where EMCo = @co and Mth = @mth and BatchId = @batchid
   
   /* clear Revenue Breakdown Audit */
   delete bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid
   
   /* Clear bEMIN. */
   delete bEMIN where EMCo = @co and Mth = @mth and BatchId = @batchid
   
	---- TK-20889 clear EMBC - usage posting breakdown codes
	IF @source = 'EMRev'
		BEGIN
		delete dbo.bEMBC where EMCo = @co and Mth = @mth and BatchId = @batchid
		END


   /* Reset flag in bHQBC based on @newstatus: 6 = Canceled, 0 = Open */
   update bHQBC  set Status = @newstatus  where Co=@co and Mth=@mth and BatchId=@batchid
    
   /* If @newstatus = Open, set bHQBC.InUseBy to Null and delete prior batch errors from bHQBE. */
   if @newstatus = 0
   	begin
   	--update bHQBC set InUseBy = null where Co=@co and Mth=@mth and BatchId=@batchid
   	delete bHQBE where Co = @co and Mth = @mth and BatchId=@batchid
   	end



bspexit:
	if @rcode<>0 select @errmsg=isnull(@errmsg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMBatchDelete] TO [public]
GO
