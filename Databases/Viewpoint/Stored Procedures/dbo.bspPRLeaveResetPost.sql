SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRLeaveResetPost    Script Date: 8/28/99 9:35:32 AM ******/
    CREATE                 procedure [dbo].[bspPRLeaveResetPost]
    /***********************************************************
     * CREATED BY: EN 1/20/00
     * MODIFIED By : EN 1/20/00
     *               EN 1/31/00 - fixed error caused by trying to set AvailBalAmt in bPRAB to null when CarryOver is null
     *               EN 2/18/00 - fixed to get reset dates and accum/avail bal amounts which reflect current entries in bPRAB for use in computing postings to make in bPRAB
     *               EN 2/22/00 - modify to check for reset date overrides in bPRAB
     *               EN 2/28/01 - issue #12476 - fixed to correctly retrieve carryover default from bPRLV
     *				  EN 3/29/02 - issue 16395  Add Leave Code as parameter in reset
     *               EN 4/3/02 - Issue 15788 Adjust for renamed bPRAB fields,
     *									and write 'R' to Type to designate reset,
     *									and add feature to delete previous reset transactions made to @resetdate,
     *                                 and adjust for change to bspPRELAmtsGet which returns bucket and batch amts in separate params.
     *				  EN 4/25/02 - issue 15775 carry over negative avail bal amts
     *				  EN 4/25/02 - issue 16940 don't add reset trans for inactive employees
     *				  EN 8/5/02 - issue 17217 add reset entries when requested so that last reset date gets updated even if there is nothing to reset
     *				EN 10/8/02 - issue 18877 change double quotes to single
     *
     * USAGE:
     * Posts entries to batch which will reset accrual accumulators
     * and/or available balance in PREL.
     *
     * INPUT PARAMETERS
     *   @co		    Company
     *   @mth           Month associated with batch
     *   @batchid       Batch ID
     *   @resetaccums	'Y' to reset accumulators #1 and #2
     *   @resetavailbal	'Y' to reset available balance
     *   @resetdate		Date to use as reset cutoff
     *   @frequency		Indicates which buckets to reset (null to reset all)
     *	  @leavecd		Specific leave code to reset (optional)
     *	  @deltrans	'Y' to delete reset transactions previously posted to actdate specified by @resetdate
     *
     * OUTPUT PARAMETERS
     *   @errmsg     if something went wrong
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
   
    	(@co bCompany, @mth bMonth, @batchid bBatchID, @resetaccums bYN,
         @resetavailbal bYN, @resetdate bDate, @frequency bFreq, @leavecd bLeaveCode,
         @deltrans bYN, @errmsg varchar(60) output)
    as
    set nocount on
	declare @rcode int, @opencursor tinyint, @employee bEmployee, @leavecode bLeaveCode,
	@cap1freq bFreq, @cap1max bHrs, @cap2freq bFreq, @cap2max bHrs, @availbalfreq bFreq,
	@availbalmax bHrs, @futureaccrual bHrs, @futurebal bHrs, @trueavailbal bHrs, @seq int,
	@curraccum1 bHrs, @curraccum2 bHrs, @curravailbal bHrs, @carryover bHrs,
	@cap1adjust bHrs, @cap2adjust bHrs, @availbaladjust bHrs, @PRABadded char(1),
	@description bDesc, @cap1date bDate, @cap2date bDate, @availbaldate bDate, @prlhtrans bTrans,
	@postamt bHrs, @accum1 bHrs, @accum2 bHrs, @availbal bHrs, @accum1adj bHrs, @accum2adj bHrs, 
	@availbaladj bHrs
   
    select @rcode = 0, @PRABadded = 'N'
   
    /* set open cursor flags to false */
    select @opencursor = 0
   
    /* initialize cursor to find PREL entries */
	declare bcPREL cursor local fast_forward for 
	select l.Employee, l.LeaveCode, case when l.CarryOver is not null then l.CarryOver else v.CarryOver end
	from dbo.bPREL l (nolock)
	join dbo.bPRLV v (nolock) on l.PRCo=v.PRCo and l.LeaveCode=v.LeaveCode
	join dbo.bPREH h (nolock) on l.PRCo=h.PRCo and l.Employee=h.Employee
	where l.PRCo=@co and l.LeaveCode=isnull(@leavecd,l.LeaveCode) --issue 16395
	and h.ActiveYN='Y' --issue 16940
   
    /* open cursor */
    open bcPREL
   
    /* set open cursor flag to true */
    select @opencursor = 1
   
    /* loop through cursor */
    PREL_loop:
    fetch next from bcPREL into @employee, @leavecode, @carryover
    if @@fetch_status <> 0
    	goto PREL_loop_end
   
		/* delete previously posted reset transactions (if any) */
		if @deltrans = 'Y'
		begin
	   		if exists (select 1 from dbo.bPRLH (nolock) where PRCo = @co and Mth = @mth and
    	 	    	Employee = @employee and LeaveCode = @leavecode and ActDate = @resetdate and
    	 	    	Type = 'R')
   
   			begin

   				BEGIN TRANSACTION
   
   	 			SELECT @prlhtrans = min(Trans) from dbo.bPRLH h (nolock) where PRCo = @co and Mth = @mth
   				and Employee = @employee and LeaveCode = @leavecode and ActDate = @resetdate and Type = 'R'
   	 	   		and not exists (select 1 from dbo.bPRAB (nolock) where PRCo = @co and Mth = @mth and 
				Trans = h.Trans and BatchTransType = 'D')

   	 			WHILE @prlhtrans is not null
   				BEGIN
   			   		/* read transaction detail */
   			   		select @postamt = Amt, @accum1adj = Accum1Adj, @accum2adj = Accum2Adj, 
					@availbaladj = AvailBalAdj, @description = [Description]
   					from dbo.bPRLH (nolock) where PRCo = @co and Mth = @mth and Trans = @prlhtrans
   
   			   		/* get next available sequence # for this batch */
   		 	   		select @seq = isnull(max(BatchSeq),0)+1 from dbo.bPRAB (nolock)
   			   		where Co = @co and Mth = @mth and BatchId = @batchid
   
   		 			/* add Transaction to PRAB */
   		 			insert into bPRAB (Co, Mth, BatchId, BatchSeq, BatchTransType, Trans, Employee, LeaveCode,
   					ActDate, Type, Amt, Accum1Adj, Accum2Adj, AvailBalAdj, Description, PRGroup, PREndDate,
   					PaySeq, OldEmployee, OldLeaveCode, OldActDate, OldType, OldAmt, OldAccum1Adj, OldAccum2Adj,
   					OldAvailBalAdj, OldDesc, OldPRGroup, OldPREndDate, OldPaySeq)
   		 			values (@co, @mth, @batchid, @seq, 'D', @prlhtrans, @employee, @leavecode,
   					@resetdate, 'R', @postamt, @accum1adj, @accum2adj, @availbaladj, @description, null, null, 
   					null, @employee, @leavecode, @resetdate, 'R', @postamt, @accum1adj, @accum2adj, 
   					@availbaladj, @description, null, null, null)

	   		 	    if @@rowcount <> 1
   					begin
   						select @errmsg = 'Unable to add entry to PR Leave Entry Batch!', @rcode = 1
   						goto bsperror
   					end
   		 		    else
					begin
   		 				select @PRABadded = 'Y'
					end
   
   		 			SELECT @prlhtrans = min(Trans) 
					from dbo.bPRLH (nolock) where PRCo = @co and Mth = @mth
   					and Employee = @employee and LeaveCode = @leavecode and 
					ActDate = @resetdate and [Type] = 'R' and Trans > @prlhtrans
   			    END

	   			COMMIT TRANSACTION
   			end
   		end
   
    	if @deltrans <> 'Y'
    	begin
   			BEGIN TRANSACTION

	   		/* get Employee Leave info needed to find accumulator and avail bal amounts */
   			exec @rcode = bspPRELStatsGet @co, @employee, @leavecode,
   			@cap1max output, @cap2max output, @availbalmax output,
   		    @cap1freq output, @cap2freq output, @availbalfreq output,
   		    @cap1date output, @cap2date output, @availbaldate output, @errmsg output
   			
			if @rcode<>0
   			begin
   		 		select @errmsg = 'Error getting Employee Leave Stats.', @rcode = 1
   		 		goto bsperror
   		 	end
   	
   			/* check in bPRAB for reset dates which may override ones in bPREL */
   			select @cap1date = max(CASE WHEN b.Accum1Adj <> 0 THEN b.ActDate ELSE l.Cap1Date END),
   			@cap2date = max(CASE WHEN b.Accum2Adj <> 0 THEN b.ActDate ELSE l.Cap2Date END),
   		    @availbaldate = max(CASE WHEN b.AvailBalAdj <> 0 THEN b.ActDate ELSE l.AvailBalDate END)
   			from dbo.bPREL l (nolock)
   			left outer join dbo.bPRAB b (nolock) on b.Co = l.PRCo and b.Employee = l.Employee and b.LeaveCode = l.LeaveCode
   			where l.PRCo = @co and l.Employee = @employee and l.LeaveCode = @leavecode
   	
   		/* get accumulator & available balance amounts */
   		exec @rcode = bspPRELAmtsGet @co, @mth, @batchid, null, @employee, @leavecode,
   		    @cap1date, @cap2date, @availbaldate, @accum1 output, @accum2 output, @availbal output,
   	        @curraccum1 output, @curraccum2 output, @curravailbal output, @errmsg output
   		if @rcode<>0
   		 	begin
   		 	select @errmsg = 'Error getting Employee Leave Accumulations and available balance', @rcode = 1
   		 	goto bsperror
   		 	end
   	
   		select @cap1adjust = null, @cap2adjust = null, @availbaladjust = null --issue 17217
   		if @carryover is null select @carryover = 0
   	
   		if @resetaccums = 'Y'
   		 	begin
   		 	/* calculate accumulator #1 reset amount */
   		 	if @frequency is null or (@frequency is not null and @frequency = @cap1freq)
   		 		begin
   		 		select @futureaccrual = (select sum(Amt) from bPRLH where PRCo=@co
   		 		 	and Employee=@employee and LeaveCode=@leavecode and ActDate>@resetdate
   		 		 	and Type='A')
   	
   	
   		 		if @futureaccrual > @cap1max and @cap1max <> 0 select @futureaccrual = @cap1max
   	
   		 		if @futureaccrual is null select @futureaccrual = 0
   	
   				select @cap1adjust = @futureaccrual - (@accum1 + @curraccum1)
   		 		end
   	
   	
   	
   		 	/* calculate accumulator #2 reset amount */
   		 	if @frequency is null or (@frequency is not null and @frequency = @cap2freq)
   		 		begin
   		 		select @futureaccrual = (select sum(Amt) from bPRLH where PRCo=@co
   		 		 	and Employee=@employee and LeaveCode=@leavecode and ActDate>@resetdate
   		 		 	and Type='A')
   	
   				if @futureaccrual > @cap2max and @cap2max <> 0 select @futureaccrual = @cap2max
   	
   		 		if @futureaccrual is null select @futureaccrual = 0
   	
   				select @cap2adjust = @futureaccrual - (@accum2 + @curraccum2)
   		 	 	end
   		 	end
   	
   		if @resetavailbal = 'Y'
   		 	begin
   		    /* calculate available balance reset amount */
   		 	if @frequency is null or (@frequency is not null and @frequency = @availbalfreq)
   		 		begin
   		        -- calculate balance amount past reset date
   		 		select @futurebal = isnull((select sum(Amt) from bPRLH where PRCo=@co and Employee=@employee
   		        	and LeaveCode=@leavecode and ActDate>@resetdate and Type='A'),0)
   		            - isnull((select sum(Amt) from bPRLH where PRCo=@co and Employee=@employee
   		            and LeaveCode=@leavecode and ActDate>@resetdate and Type='U'),0)
   	
   		 		if @futurebal > @availbalmax and @availbalmax <> 0 select @futurebal = @availbalmax
   		 		if @futurebal is null select @futurebal = 0
   	
   		        /* adjust carryover amount based on amount available to carry over */
   		        if @carryover <> 0
   		        	begin
   		            select @trueavailbal = (@availbal + @curravailbal) - @futurebal
   					--issue 15775 replaced previous code with this...
   		            if @trueavailbal = 0 select @carryover = 0 --if no balance, there is nothing to carry over
   					if (@trueavailbal > 0 and @trueavailbal < @carryover) or @trueavailbal < 0 
   						select @carryover = @trueavailbal --if balance is negative or a non-zero amount less than limit, carry over entire amount
   		            end
   	
   				select @availbaladjust = ((@availbal + @curravailbal) * -1) + @carryover + @futurebal
   		 		end
   			end
   	
   		if @cap1adjust is not null or @cap2adjust is not null or @availbaladjust is not null --issue 17217
   			begin
   		    /* get next available sequence # for this batch */
   		    select @seq = isnull(max(BatchSeq),0)+1 from bPRAB
   		    where Co = @co and Mth = @mth and BatchId = @batchid
   	
   		    /* create description */
   		    select @description = '**Reset '
   		    if @cap1adjust <> 0 or @cap2adjust <> 0
   		    	begin
   		        select @description = @description + 'Accrual'
   		        if @availbaladjust <> 0 select @description = @description + '/Avail Bal'
   		        end
   			else
   		    	if @availbaladjust <> 0 select @description = @description + 'Avail Bal'
   			if @leavecd is not null and @frequency is null select @description = @description + '-' + @leavecd
   		    if @leavecd is null and @frequency is not null select @description = @description + '-' + @frequency
   			if @leavecd is not null and @frequency is not null select @description = @description + '-' + @leavecd + '/' + @frequency
   	
   		    /* add Transaction to PRAB */
   		    insert into bPRAB (Co, Mth, BatchId, BatchSeq, BatchTransType, Trans, Employee, LeaveCode,
   		         ActDate, Type, Amt, Accum1Adj, Accum2Adj, AvailBalAdj, Description, PRGroup, PREndDate,
   		         PaySeq, OldEmployee, OldLeaveCode, OldActDate, OldType, OldAmt, OldAccum1Adj, OldAccum2Adj,
   		         OldAvailBalAdj, OldDesc, OldPRGroup, OldPREndDate, OldPaySeq)
   		         values (@co, @mth, @batchid, @seq, 'A', null, @employee, @leavecode, @resetdate, 'R',
   		         0, @cap1adjust, @cap2adjust, @availbaladjust, @description, null, null, null,
   		         null, null, null, null, null, null, null, null, null, null, null, null)
   		    if @@rowcount <> 1
   		         begin
   		         select @errmsg = 'Unable to add entry to PR Leave Entry Batch!', @rcode = 1
   		         goto bsperror
   		         end
   		    else
   		         select @PRABadded = 'Y'
   	     end
   	
   	     COMMIT TRANSACTION
   		 end
   
    goto PREL_loop
   
    PREL_loop_end:	/* no more PREL entries to process */
   
        goto bspexit
   
   
    bsperror:
   
    	ROLLBACK TRANSACTION
   
   
    bspexit:
    	if @opencursor=1
    	  begin
    	   close bcPREL
    	   deallocate bcPREL
    	   select @opencursor=0
    	  end
   
    	if @rcode=0 and @PRABadded = 'N' select @errmsg = 'Nothing to update.', @rcode = 5
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRLeaveResetPost] TO [public]
GO
