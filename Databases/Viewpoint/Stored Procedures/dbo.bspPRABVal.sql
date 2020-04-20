SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRABVal    Script Date: 8/28/99 9:36:31 AM ******/
CREATE           procedure [dbo].[bspPRABVal]
     /************************************************************************
      * CREATED BY: EN 1/16/98
      * MODIFIED By : 	EN 6/17/99
      *               	EN 2/1/00 - modified to accomodate breaking the return of PREL accums and other info into separate bsp's
      *               	EN 2/17/00 - modified so that bspPRELAmtsGet can use the reset dates returned by bspPRELStatsGet in order to get the most up-to-date and accurate amounts
      *			EN 4/2/02 issue 15978  Fix error list description for over-the-limit errors
      *               	EN 4/3/02 - Issue 15788 Adjust for renamed bPRAB fields,and allow for Type 'R', adjust for 
      *				    change to bspPRELAmtsGet which returns bucket and batch amts in separate params
      *			EN 4/25/02 - issue 16904 employee and leave code being validated a second time in bspPREmplLeaveVal so removed extra validation code
      *			EN 9/4/02 - issue 18461 wasn't reading Type when checking for exceeded limits so wasn't working correctly
      *			EN 10/7/02 - issue 18877 change double quotes to single
      *			GH 2/24/03 - issue 20503 invalid Employee/Leave combo not returning to error list, hanging batch
      *			EN 12/03/03 - issue 23061  added isnull check, with (nolock), and dbo
      *    		  DANF 03/15/05 - #27294 - Remove scrollable cursor.
	  *			mh 01/07/09 - #131422  Need to call vspPRLeaveCodeValforEntry in batch validation.  This will catch
	  *							entries made through Auto Use/Accrual.  Also expanded @errmsg variable to varchar(100).  Was 60.
	  *			EN 11/09/2009 #131962  Corrected to use tables as opposed to views for security clearance on employees
	  *			EN/KK 7/26/2011 D-02430 #144223 Added validation to throw error when activity date is <= reset dates for accum1, accum2, and avail bal
      *
      * USAGE:
      * Validates each entry in bPRAB for a select batch - must be called
    
      * prior to posting the batch.
      *
      * After initial Batch check, bHQBC Status set to 1 (validation in progress)
      *
      * bHQBE (Batch Errors) entries are deleted.
      *
      * Creates a cursor on bPRAB to validate each entry individually.
      *
      * Errors in batch added to bHQBE using bspHQBEInsert
      *
      * bHQBC Status updated to 2 if errors found, or 3 if OK to post
      *
      *  INPUT PARAMETERS
      *   @co	PR company number
      *   @mth	month
      *   @batchid	batch identification
      *   @source	'PR Leave'
      *
      * OUTPUT PARAMETERS
      *   @errmsg      error message if error occurs
      *
      * RETURN VALUE
      *   0   success
      *   1   fail
      *
      *************************************************************************/
    
     	@co bCompany, @mth bMonth, @batchid bBatchID, @source bSource,
    
     	@errmsg varchar(100) output
    
    
     as
     set nocount on
    
     declare @opencursor1 tinyint, @opencursor2 tinyint, @rcode tinyint, @errortext varchar(255),
     	@status tinyint, @seq int, @transtype char(1), @trans bTrans, @employee bEmployee,
     	@leavecode bLeaveCode, @actdate bDate, @type varchar(1), @amt bHrs, @availbaladj bHrs,
     	@oldemployee bEmployee, @oldleavecode bLeaveCode, @oldactdate bDate,
     	@oldtype varchar(1), @oldamt bHrs, @oldaccum1adj bHrs, @oldaccum2adj bHrs,
     	@oldavailbaladj bHrs, @olddesc bDesc, @oldprgroup bGroup, @oldprenddate bDate,
     	@oldpayseq tinyint, @errorhdr varchar(30), @dovalidation int
    
     declare @curraccum1 bHrs, @curraccum2 bHrs, @curravailbal bHrs, @cap1max bHrs, @cap1date bDate,
     	@cap2max bHrs, @cap2date bDate, @availbalmax bHrs, @availbaldate bDate, @cap1freq bFreq,
     	@cap2freq bFreq, @availbalfreq bFreq, @accum1 bHrs, @accum2 bHrs, @availbal bHrs, @prevemplleave varchar(16) --issue 18461

	declare	@um bUM, @accum1Limit bHrs, @accum2Limit bHrs, @accum1Freq bFreq, @accum2Freq bFreq,
		@accum1Date bDate, @accum2Date bDate
    
     /* set open cursor flag to false */
     select @opencursor1 = 0, @opencursor2 = 0, @dovalidation = 1
    
     /* validate HQ Batch */
     exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'PRAB', @errmsg output, @status output
    
     if @rcode <> 0
     	begin
         	select @errmsg = @errmsg, @rcode = 1
         	goto bspexit
        	end
    
     if @status < 0 or @status > 3
     	begin
     	select @errmsg = 'Invalid Batch status!', @rcode = 1
     	goto bspexit
 
     	end
    
     /* set HQ Batch status to 1 (validation in progress) */
     update dbo.bHQBC
     	set Status = 1
     	where Co = @co and Mth = @mth and BatchId = @batchid
     if @@rowcount = 0
      	begin
     	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
     	goto bspexit
     	end
    
     /* clear HQ Batch Errors */
     delete dbo.bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
    
     /* declare cursor on PR Leave Batch for validation */
     declare bcPRAB cursor local fast_forward for select BatchSeq, BatchTransType, Trans, Employee, LeaveCode,
     			ActDate, Type, Amt, AvailBalAdj, OldEmployee, OldLeaveCode, OldActDate,
     			OldType, OldAmt, OldAccum1Adj, OldAccum2Adj, OldAvailBalAdj,
     			OldDesc, OldPRGroup, OldPREndDate, OldPaySeq
     	from dbo.bPRAB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
    
    
     /* open cursor */
     open bcPRAB
    
     /* set open cursor flag to true */
     select @opencursor1 = 1
    
     /* get first row */
     fetch next from bcPRAB into @seq, @transtype, @trans, @employee, @leavecode, @actdate, @type,
     			@amt, @availbaladj, @oldemployee, @oldleavecode, @oldactdate,
     			@oldtype, @oldamt, @oldaccum1adj, @oldaccum2adj, @oldavailbaladj,
     			@olddesc, @oldprgroup, @oldprenddate, @oldpayseq
    
     /* loop through all rows */
     while (@@fetch_status = 0)
     	begin
     	select @dovalidation = 1
     	/* validate PR Leave Accrual Batch info for each entry */
     	select @errorhdr = 'Seq#' + convert(varchar(6),@seq)
    
     	/* validate transaction type */
     	if @transtype <> 'A' and @transtype <> 'C' and @transtype <> 'D'
     		begin
     		select @errortext = isnull(@errorhdr,'') + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
     		end
    
    --issue 16904 commented out validate employee and leave code because that's done in bspPREmplLeaveVal
    -- 	/* validate employee */
    -- 	if @employee is null
    -- 		begin
    -- 		select @errortext = @errorhdr + ' - employee # is missing!'
    -- 		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    -- 		select @dovalidation=0
    -- 		if @rcode <> 0 goto bspexit
    -- 		end
    -- 	if not exists(select * from PREH where PRCo=@co and Employee=@employee)
    -- 		begin
    -- 		select @errortext = @errorhdr + ' - Invalid employee #.'
    -- 		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    -- 		if @rcode <> 0 goto bspexit
    -- 		end
    --
    -- 	/* validate leave code */
    -- 	if @leavecode is null
    -- 		begin
    -- 		select @errortext = @errorhdr + ' - leave code is missing!'
    -- 		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    -- 		select @dovalidation=0
    -- 		if @rcode <> 0 goto bspexit
    -- 		end
    -- 	if not exists(select * from bPRLV where PRCo=@co and LeaveCode=@leavecode)
    -- 		begin
    -- 		select @errortext = @errorhdr + ' - Invalid leave code.'
    -- 		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    -- 		if @rcode <> 0 goto bspexit
    -- 		end
    
     	/* validate employee/leave code combination */
		if @type = 'R'
		begin
			exec @rcode = bspPREmplLeaveVal @co, @employee, @leavecode, @errmsg output
		end
		else
		begin
			--For Accrual and Usage types we want to check for resets if there are limits.  Use the
			--the procedure used by PR Leave Entry.  Auto Leave Accrual/Usage does not make this check
			--so we need to do it in the batch validation.  mh 01/07/09 - 131422
			exec @rcode = vspPRLeaveCodeValforEntry @co, @leavecode, @batchid, @employee, 
			@um output, @accum1Limit output, @accum2Limit output, @availbalmax output,
			@accum1Freq output, @accum2Freq output, @availbalfreq output,
			@accum1Date output, @accum2Date output, @availbaldate output,
			@accum1 output, @accum2 output, @availbal output, @errmsg  output
		end

     	if @rcode<>0
     		begin
     		select @errortext = isnull(@errorhdr,'') + ' - ' + isnull(@errmsg,'')
             	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
     		end
    
     	/* validate activity date */
     	if @actdate is null
     		begin
     		select @errortext = isnull(@errorhdr,'') + ' - activity date is missing!'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		select @dovalidation=0
     		if @rcode <> 0 goto bspexit
     		end
     	ELSE
     	BEGIN
     		IF @actdate <= @accum1Date OR @actdate <= @accum2Date OR @actdate <= @availbaldate
     		BEGIN
     			SELECT @errortext = ISNULL(@errorhdr,'') + ' - activity date should be later than reset dates!'
     			EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
   				IF @rcode <> 0 GOTO bspexit
   			END
   		END
    
     	/* validate type */
     	if @type <> 'A' and @type <> 'U' and @type <> 'R'
     		begin
     		select @errortext = isnull(@errorhdr,'') + ' - type must be ''A'', ''U'' or ''R''!'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		select @dovalidation=0
     		if @rcode <> 0 goto bspexit
     		end
    
     	/* validate amount */
     	if @amt is null
     		begin
     		select @errortext = isnull(@errorhdr,'') + ' - amount is missing!'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		select @dovalidation=0
     		if @rcode <> 0 goto bspexit
     		end
    
     	/* validate old items for 'Changed' transactions */
     	if @transtype='C'
     	       begin
     		/* validate old employee */
     		if @oldemployee is null
     			begin
     			select @errortext = isnull(@errorhdr,'') + ' - old employee # is missing!'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			select @dovalidation=0
     			if @rcode <> 0 goto bspexit
     			end
     		if not exists(select * from dbo.bPREH with (nolock) where PRCo=@co and Employee=@oldemployee)
     			begin
     			select @errortext = isnull(@errorhdr,'') + ' - Invalid old employee #.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
     			end
    
     		/* validate old leave code */
     		if @oldleavecode is null
     			begin
     			select @errortext = isnull(@errorhdr,'') + ' - old leave code is missing!'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			select @dovalidation=0
     			if @rcode <> 0 goto bspexit
     			end
     		if not exists(select * from dbo.bPRLV with (nolock) where PRCo=@co and LeaveCode=@oldleavecode)
     			begin
     			select @errortext = isnull(@errorhdr,'') + ' - Invalid old leave code.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
     			end
    
     		/* validate old employee/leave code combination */
            exec @rcode = bspPREmplLeaveVal @co, @oldemployee, @oldleavecode, @errmsg output
     	    if @rcode<>0
     		    begin
     		    select @errortext = isnull(@errorhdr,'') + ' - ' + isnull(@errmsg,'')
                	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		    if @rcode <> 0 goto bspexit
     		    end
    
     		/* validate old activity date */
     		if @oldactdate is null
     			begin
     			select @errortext = isnull(@errorhdr,'') + ' - activity date is missing!'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			select @dovalidation=0
     			if @rcode <> 0 goto bspexit
     			end
    
     		/* validate old type */
     		if @oldtype <> 'A' and @oldtype <> 'U'
     			begin
     			select @errortext = isnull(@errorhdr,'') + ' - type must be ''A'' or ''U''!'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			select @dovalidation=0
     			if @rcode <> 0 goto bspexit
     			end
    
     		/* validate old amount */
     		if @oldamt is null
     			begin
     			select @errortext = isnull(@errorhdr,'') + ' - amount is missing!'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			select @dovalidation=0
     			if @rcode <> 0 goto bspexit
     			end
    
     	       end
    
     	/* validation for Add types */
     	if @transtype = 'A'
     		begin
     		/* check Trans# */
    
     		if @trans is not null
     			begin
     			select @errortext = isnull(@errorhdr,'') + ' - ''New'' entries may not reference a Transaction #.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
     			end
    
     		/* all old values should be null */
    
     		if @oldemployee is not null or @oldleavecode is not null or @oldactdate is not null
     			or @oldtype is not null or @oldamt is not null or @oldaccum1adj is not null
     			or @oldaccum2adj is not null or @oldavailbaladj is not null or @olddesc is not null
     			or @oldprgroup is not null or @oldprenddate is not null or @oldpayseq is not null
     			begin
     			select @errortext = isnull(@errorhdr,'') + ' - Old info in batch must be ''null'' for ''Add'' entries.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
     			end
     		end
    
     	/* validation for Change and Delete types */
     	if @transtype = 'C' or @transtype = 'D'
     		begin
     		/* get existing values from PRLH */
     		if not exists(select * from dbo.bPRLH with (nolock) where PRCo = @co and Mth = @mth and Trans = @trans)
     			begin
     			select @errortext = isnull(@errorhdr,'') + ' - Missing PR Leave Transaction.'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			if @rcode <> 0 goto bspexit
     			end
     		end
    
     	fetch next from bcPRAB into @seq, @transtype, @trans, @employee, @leavecode, @actdate,
     			@type, @amt, @availbaladj, @oldemployee, @oldleavecode, @oldactdate,
     			@oldtype, @oldamt, @oldaccum1adj, @oldaccum2adj, @oldavailbaladj,
     			@olddesc, @oldprgroup, @oldprenddate, @oldpayseq
    
     	end
    
     /* declare cursor on PR Leave Batch for validating employee/leave accums and available balance */
     declare bcPRABbyEmployee cursor local fast_forward for select Employee, LeaveCode, Type --issue 18461
     	from dbo.bPRAB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
     	group by Employee, LeaveCode, Type --issue 18461
    
     /* open cursor */
     open bcPRABbyEmployee
    
     /* set open cursor flag to true */
     select @opencursor2 = 1
    
     /* get first row */
     fetch next from bcPRABbyEmployee into @employee, @leavecode, @type --issue 18461
   
     select @prevemplleave = '' --issue 18461
    
     /* loop through all rows */
     while (@@fetch_status = 0)
     	begin
     	select @errorhdr = 'Empl ' + convert(varchar(6),@employee) + ', LeaveCode ' + convert(varchar(10),@leavecode) --issue 15978
    
   	if @prevemplleave <> convert(varchar(6),@employee) + convert(varchar(10),@leavecode) --issue 18461 added condition
   		begin
   	  	 /* get accumulator & available balance amounts */
   	  	 exec @rcode = bspPRELStatsGet @co, @employee, @leavecode,
   	  	 	@cap1max output, @cap2max output, @availbalmax output,
   	         	@cap1freq output, @cap2freq output, @availbalfreq output,
   	        	@cap1date output, @cap2date output, @availbaldate output, @errmsg output
   	  	 if @rcode<>0
   	  		begin
   			 select @errortext = isnull(@errorhdr,'') + ' - ' + isnull(@errmsg,'')
   	  		 exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			 if @rcode <> 0 goto bspexit
   	  		end
   	  	 exec @rcode = bspPRELAmtsGet @co, @mth, @batchid, null, @employee, @leavecode,
   	         @cap1date, @cap2date, @availbaldate, @accum1 output, @accum2 output, @availbal output,
   	 		@curraccum1 output, @curraccum2 output, @curravailbal output,
   	         @errmsg output
   	  	 if @rcode<>0
   	  		begin
   	  		 select @errortext = isnull(@errorhdr,'') + ' - ' + isnull(@errmsg,'')
   	  		 exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
      			 if @rcode <> 0 goto bspexit
   	  		end
   		end
    
     	 if @type = 'A'
     		begin
      		 if @cap1max <> 0 and @accum1 + @curraccum1 > @cap1max
      		 	begin
     			 select @errortext = isnull(@errorhdr,'') + ' - Accrual accumulator #1 limit exceeded.'
     			 exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			 if @rcode <> 0 goto bspexit
      		 	end
    
     		 if @cap2max <> 0 and @accum2 + @curraccum2 > @cap2max
     	 		begin
     			 select @errortext = isnull(@errorhdr,'') + ' - Accrual accumulator #2 limit exceeded.'
     			 exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			 if @rcode <> 0 goto bspexit
     		 	end
    
     	 	 if @availbalmax <> 0 and @availbal + @curravailbal > @availbalmax
     			begin
     			 select @errortext = isnull(@errorhdr,'') + ' - Available balance limit exceeded.'
     			 exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			 if @rcode <> 0 goto bspexit
     	 		end
     		end
    
     	 select @prevemplleave = convert(varchar(6),@employee) + convert(varchar(10),@leavecode) --issue 18461
   
     	 fetch next from bcPRABbyEmployee into @employee, @leavecode, @type --issue 18461
    
     	end
    
    
     /* check HQ Batch Errors and update HQ Batch Control status */
     select @status = 3	/* valid - ok to post */
     if exists(select * from dbo.bHQBE with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
     	begin
     	select @status = 2	/* validation errors */
     	end
     update dbo.bHQBC
     	set Status = @status
     	where Co = @co and Mth = @mth and BatchId = @batchid
     if @@rowcount <> 1
     	begin
     	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
     	goto bspexit
     	end
    
    
     bspexit:
     	if @opencursor1 = 1
     		begin
     		close bcPRAB
     		deallocate bcPRAB
     		end
     	if @opencursor2 = 1
     		begin
     		close bcPRABbyEmployee
    
     		deallocate bcPRABbyEmployee
     		end
     	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRABVal] TO [public]
GO
