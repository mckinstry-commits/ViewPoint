SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            proc [dbo].[bspPRTSSendCancel]
     /****************************************************************************
      * CREATED BY: EN 7/24/03
      * MODIFIED By : mh 5/25/07 - Recode issue 28074 - Throwing error is @sendseq is null.
	  *				  mh 01/12/2009 - Issue 131479.  Remove InUseBy references.
	  *				  mh 06/16/2009 - Issue 133863.  See comments below and in bspPRTSSend.
      *
      * USAGE:
      * Clears entry in bPRTS for this user, reports on any batches that were
      * created during the aborted send and removes InUseBy from those batches.
      * 
      *  INPUT PARAMETERS
      *	 @co		PR Company
      *	 @user		User ID of user performing the send
      *	 @sendseq	Send Sequence of aborted send
      *	 @prgroup	PR Group of aborted send
      *
      * OUTPUT PARAMETERS
      *   @msg      	batch report or error message if error occurs 
      *
      * RETURN VALUE
      *   0         success
      *   1         Failure
      ****************************************************************************/ 
	(@co bCompany, @user bVPUserName, @sendseq int, @prgroup bGroup, @msg varchar(1000) output)
	as

	set nocount on

	declare @rcode int, @batchmodule char(2), @batchmonth bMonth, @batchid bBatchID, 
	@source bSource, @tablename varchar(20)
     
	select @rcode = 0

	-- validate UserID
	if @user is null
	begin
		select @msg = 'Missing User ID', @rcode = 1
		goto bspexit
	end

	if @sendseq is null
	begin
		select @msg = 'Missing Send Sequence', @rcode = 1
		goto bspexit
	end
     
   /*  --clear inuseby in batches
     declare bcPRTT cursor for select Module, Co, BatchMth, BatchId from PRTT where UserId=@user and SendSeq=@sendseq
     open bcPRTT
     
     fetch next from bcPRTT into @batchmodule, @co, @batchmonth, @batchid
     while @@fetch_status = 0
     	begin 
     	if @batchmodule='PR' select @source = 'PR Entry', @tablename = 'PRTZGrid'
     	if @batchmodule='EM' select @source = 'EMRev', @tablename = 'EMBF'
     	if @batchmodule='JC' select @source = 'JC Progres', @tablename = 'JCPP'
     	exec @rcode = bspHQBCExitCheck @co, @batchmonth, @batchid, @source, @tablename, @msg output
     	fetch next from bcPRTT into @batchmodule, @co, @batchmonth, @batchid
     	end
     
     close bcPRTT
     deallocate bcPRTT*/
    
	--clear & cancel batches
	declare bcTCBatches cursor local fast_forward for 
	select a.Co, a.Mth, a.BatchId, a.Source, b.Module
	from HQBC (nolock) a
	join PRTT (nolock) b on a.Co=b.Co and a.Mth=b.BatchMth and a.BatchId=b.BatchId
	where b.UserId=@user and b.SendSeq=@sendseq
   
    open bcTCBatches
   
	fetch next from bcTCBatches into @co, @batchmonth, @batchid, @source, @batchmodule
	while @@fetch_status = 0
   	begin
   		if @batchmodule <> ''
   		begin

   			if @batchmodule='PR'
   			begin
   	  			exec @rcode = bspPRBatchClear @co, @batchmonth, @batchid, @msg output
   				select @tablename='PRTB'
   	  			exec @rcode = bspHQBCExitCheck @co, @batchmonth, @batchid, @source, @tablename, @msg output
   			end

   			if @batchmodule='EM'
   			begin
   	  			exec @rcode = bspEMBatchDelete @co, @batchmonth, @batchid, 6, @msg output
   			end

   			if @batchmodule='JC'
   			begin
   	  			exec @rcode = bspJCPPBatchDelete @co, @batchmonth, @batchid, @msg output
   				select @tablename='JCPP'
   	  			exec @rcode = bspHQBCExitCheck @co, @batchmonth, @batchid, @source, @tablename, @msg output
   			end
   
			--133863 Uncommenting the following code.  At this point we should be done with bPRTT 
			--and can delete the entries from it.  resend will not come into play here...user will 
			--be starting the send process over.  Prior to fix this would not have worked as we 
			--were clearing out send seq when updating Status to 4.  See notes in bspPRTSSend 
			--under issue 133863
			delete from bPRTT 
   			where UserId=@user and SendSeq=@sendseq and Module=@batchmodule and Co=@co and 
   				BatchMth=@batchmonth and BatchId=@batchid

   		end
		--133863 This was within the if statement for @batchmodule <> ''.  You could create
		--an infinite loop if @batchmodule indeed equaled ''.
		fetch next from bcTCBatches into @co, @batchmonth, @batchid, @source, @batchmodule

   	end
   
     close bcTCBatches
     deallocate bcTCBatches
   
     --clear send seq, pr batch month, and pr batch id and reset Status to 2 for timesheets of aborted send
     update bPRRH set Status=2, /*InUseBy=null,*/ SendSeq=null, PRBatchMth=null, PRBatchId=null
     where PRCo=@co and PRGroup=@prgroup and SendSeq=@sendseq
   
   /*  -- prepare batch report and unlock batches
     if (select count(*) from PRTT where UserId=@user and SendSeq=@sendseq) > 0
     	begin
     	--prepare batch list to return
     	select @msg = 'Check the following batches for timesheets posted successfully before the Send was aborted.' + char(13)
     
     	declare bcPRTT cursor for select Module, Co, BatchMth, BatchId from PRTT where UserId=@user and SendSeq=@sendseq
     	open bcPRTT
     
     	fetch next from bcPRTT into @batchmodule, @co, @batchmonth, @batchid
     	while @@fetch_status = 0
     		begin 
     		select @msg = @msg + @batchmodule + ' company: ' + convert(varchar(3),@co)
    		select @msg = @msg + '   Month: ' + convert(char(2),@batchmonth,1) + '/' + convert(char(2),@batchmonth,2)
    		select @msg = @msg + '   Batch#: ' + convert(varchar(6),@batchid) + char(13)
    
     		fetch next from bcPRTT into @batchmodule, @co, @batchmonth, @batchid
     		end
     	
     	close bcPRTT
     	deallocate bcPRTT
     	end*/
    
     -- clear bPRTS entry
     delete from bPRTS where UserId=@user
     
     bspexit:
     	if @rcode=1 select @msg = @msg + ' - Cancel Aborted' --+ char(13) + char(10) + '[bspPRTSSendCancel]'
     
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTSSendCancel] TO [public]
GO
