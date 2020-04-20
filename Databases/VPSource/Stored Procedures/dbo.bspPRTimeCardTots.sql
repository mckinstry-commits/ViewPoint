SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspPRTimeCardTots]
    /***********************************************************
     * CREATED BY: kb 6/23/98
     * MODIFIED By : EN 6/5/99
     *               JRE 5/15/00 - used ANSI SQL to speed up query
     *				 GG 12/28/01 - cleanup
     *				EN 1/19/04 issue 19694 do not error out if posting date is null, just don't get date totals
     *									   also reorganized code to make sure all totals except for specified timecard sequence are are returned
     *				GF 07/19/2004 - issue #25093 - changed to use base tables and consolidated some of the query statements into one.
	 *				EN 1/18/07 - issue 27864  added code to retrieve doubletime hours and amounts
	 *				EN 2/15/07 - 6x recode - fixed to ignore only the current timecard, not all timecards in the current batch
     *				EN 2/19/07 - issue 27864  removed code to retrieve dbltime -- going back to just reg and ot
     *
     * Usage:
     *	Called by PR Timecard Entry form to get hours and earnings totals.
     *	Includes unposted timecard entries from all batches.
     *
     * Input params:
     *	@prco		PR company
     *	@empl		Employee number
     *	@mth		Timecard Batch Month
     *	@batchid	Timecard Batch ID
     *	@postdate	Timecard date for daily totals
     *	@postjcco	JC Co# for job totals
     *	@postjob	Job 
     *	@prenddate	PR Ending Date for Pay Pd totals
     *	@tcseq		Current timcard sequence to exclude from totals
     *
     * Output params:
     *	@datereghrs		Regular hours for the employee and day
     *	@dateregamt		Regular earnings for the employee and day
     *	@dateothrs		Overtime hours for the employee and day
     *	@dateotamt		Overtime earnings for the employee and day
     *	@periodreghrs	Regular hours for the employee and pay period
     *	@periodregamt	Regular earnings for the employee and pay period
     *	@periodothrs	Overtime hours for the employee and pay period
     *	@periodotamt	Overtime earnings for the employee and pay period
     *	@jobreghrs		Regular hours for the job and pay period - all employees
     *	@jobregamt		Regular earnings for the job and pay period
     *	@jobothrs		Overtime hours for the job and pay period
	 *	@msg			Error message 
     *
     * Return code:
     *	0 = success, 1 = failure
     ************************************************************/
    	(@prco bCompany = null, @empl bEmployee = null, @mth bMonth = null, @batchid bBatchID = null,
    	 @postdate bDate = null, @postjcco bCompany = null, @postjob bJob = null, @prenddate bDate,
    	 @tcseq int = null, @datereghrs bHrs output, @dateregamt bDollar output, @dateothrs bHrs output,
     	 @dateotamt bDollar output, @periodreghrs bDollar output, @periodregamt bDollar output,
     	 @periodothrs bHrs output, @periodotamt bDollar output, @jobreghrs bHrs output,
     	 @jobregamt bDollar output, @jobothrs bHrs output, @jobotamt bDollar output,
     	 @msg varchar(255) output)
    
    as
    
    set nocount on
    
    declare @rcode int
    
    -- initialize totals
    select @rcode = 0, @datereghrs=0, @dateregamt=0, @dateothrs=0, @dateotamt=0, @periodregamt=0,
     	@periodothrs=0, @periodotamt=0, @jobreghrs=0, @jobregamt=0, @jobothrs=0, @jobotamt=0,
     	@periodreghrs=0
    
    if @tcseq is null select @tcseq = 0	-- default batchseq #
    
    if @prco is null or @empl is null or @mth is null or @batchid is null
    	begin
    	select @msg = 'Missing required information, PR Co#, Employee, Month, or Batch ID#.', @rcode = 1
    	goto bspexit
    	end
    
    if @postdate is not null
    	begin
    	-- accumulate daily totals from existing timecards in PRTH
    	select @datereghrs = isnull(sum(case when e.Factor = 1 then t.Hours else 0 end),0),
    		@dateregamt = isnull(sum(case when e.Factor = 1 then t.Amt else 0 end),0),
    		@dateothrs = isnull(sum(case when e.Factor <> 1 then t.Hours else 0 end),0),
    		@dateotamt = isnull(sum(case when e.Factor <> 1 then t.Amt else 0 end),0)
    	from bPRTH t with (nolock)
    	join bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
    	where t.PRCo = @prco and t.Employee = @empl and t.PostDate = @postdate
    		and t.InUseBatchId is null	-- exlcude timecards in a batch
    
    	-- adjust daily totals for timecard batches, excluding current timecard
    	select @datereghrs = @datereghrs + isnull(sum(case when e.Factor = 1 then b.Hours else 0 end),0),
    	       @dateregamt = @dateregamt + isnull(sum(case when e.Factor = 1 then b.Amt else 0 end),0),
    	       @dateothrs = @dateothrs + isnull(sum(case when e.Factor <> 1 then b.Hours else 0 end),0),
    	       @dateotamt = @dateotamt + isnull(sum(case when e.Factor <> 1 then b.Amt else 0 end),0)
    	from bPRTB b with (nolock)
    	join bPREC e with (nolock) on e.PRCo = b.Co and e.EarnCode = b.EarnCode
    	where b.Co = @prco and b.Employee = @empl and b.PostDate = @postdate and b.BatchTransType <> 'D' and
    		--(b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))
			not (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @tcseq)

   -- -- --  	select @datereghrs = @datereghrs + isnull(sum(case when e.Factor = 1 then b.Hours else 0 end),0),
   -- -- --  	       @dateregamt = @dateregamt + isnull(sum(case when e.Factor=1 then b.Amt else 0 end),0),
   -- -- --  	       @dateothrs = @dateothrs + isnull(sum(case when e.Factor <> 1 then b.Hours else 0 end),0),
   -- -- --  	       @dateotamt = @dateotamt + isnull(sum(case when e.Factor <> 1 then b.Amt else 0 end),0)
   -- -- --  	from bPRTB b
   -- -- --  	join bPREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
   -- -- --  	where b.Co = @prco and b.Employee = @empl and b.PostDate = @postdate and b.BatchTransType = 'A' and
   -- -- --  		(b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))
   -- -- --  
   -- -- --  	select @datereghrs = @datereghrs + isnull(sum(case when e.Factor = 1 then b.Hours else 0 end),0),
   -- -- --  	       @dateregamt = @dateregamt + isnull(sum(case when e.Factor=1 then b.Amt else 0 end),0),
   -- -- --  	       @dateothrs = @dateothrs + isnull(sum(case when e.Factor <> 1 then b.Hours else 0 end),0),
   -- -- --  	       @dateotamt = @dateotamt + isnull(sum(case when e.Factor <> 1 then b.Amt else 0 end),0)
   -- -- --  	from bPRTB b
   -- -- --  	join bPREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
   -- -- --  	where b.Co = @prco and b.Employee = @empl and b.PostDate = @postdate and b.BatchTransType = 'C' and
   -- -- --  		(b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))
   
    	/*select @datereghrs = @datereghrs + isnull(sum(case when e.Factor = 1 then -b.Hours else 0 end),0),
    	       @dateregamt = @dateregamt + isnull(sum(case when e.Factor=1 then -b.Amt else 0 end),0),
    	       @dateothrs = @dateothrs + isnull(sum(case when e.Factor <> 1 then -b.Hours else 0 end),0),
    	       @dateotamt = @dateotamt + isnull(sum(case when e.Factor <> 1 then -b.Amt else 0 end),0)
    	from PRTB b
    	join PREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
    	where b.Co = @prco and b.Employee = @empl and b.PostDate = @postdate and b.BatchTransType = 'D' and
    		(b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))*/
   
    	end
    
    -- accumulate pay period totals with existing timecards
    select @periodreghrs = isnull(sum(case when e.Factor = 1 then t.Hours else 0 end),0),
    	@periodregamt = isnull(sum(case when e.Factor = 1 then t.Amt else 0 end),0),
    	@periodothrs = isnull(sum(case when e.Factor <> 1 then t.Hours else 0 end),0),
    	@periodotamt = isnull(sum(case when e.Factor <> 1 then t.Amt else 0 end),0)   
    from bPRTH t with (nolock)
    join bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
    where t.PRCo = @prco and t.Employee = @empl and t.PREndDate = @prenddate
     	and t.InUseBatchId is null	-- exlcude timecards in a batch
    
   -- adjust pay period totals for timecard batches, excluding current timecard
   select @periodreghrs = @periodreghrs + isnull(sum(case when e.Factor = 1 then b.Hours else 0 end),0),
           @periodregamt = @periodregamt + isnull(sum(case when e.Factor = 1 then b.Amt else 0 end),0),
           @periodothrs = @periodothrs + isnull(sum(case when e.Factor <> 1 then b.Hours else 0 end),0),
           @periodotamt = @periodotamt + isnull(sum(case when e.Factor <> 1 then b.Amt else 0 end),0)
    from bPRTB b with (nolock)
    join bPREC e with (nolock) on e.PRCo = b.Co and e.EarnCode = b.EarnCode
    join HQBC h with (nolock) on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId
    where b.Co = @prco and b.Employee = @empl and h.PREndDate = @prenddate and b.BatchTransType <> 'D' and
    	--(b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))
		not (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @tcseq)
   
   -- -- --  select @periodreghrs = @periodreghrs + isnull(sum(case when e.Factor = 1 then b.Hours else 0 end),0),
   -- -- --         @periodregamt = @periodregamt + isnull(sum(case when e.Factor = 1 then b.Amt else 0 end),0),
   -- -- --         @periodothrs = @periodothrs + isnull(sum(case when e.Factor <> 1 then b.Hours else 0 end),0),
   -- -- --         @periodotamt = @periodotamt + isnull(sum(case when e.Factor <> 1 then b.Amt else 0 end),0)
   -- -- --  from bPRTB b
   -- -- --  join bPREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
   -- -- --  join HQBC h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId
   -- -- --  where b.Co = @prco and b.Employee = @empl and h.PREndDate = @prenddate and b.BatchTransType = 'A' and
   -- -- --  	(b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))
   -- -- --  
   -- -- --  select @periodreghrs = @periodreghrs + isnull(sum(case when e.Factor = 1 then b.Hours else 0 end),0),
   -- -- --         @periodregamt = @periodregamt + isnull(sum(case when e.Factor = 1 then b.Amt else 0 end),0),
   -- -- --         @periodothrs = @periodothrs + isnull(sum(case when e.Factor <> 1 then b.Hours else 0 end),0),
   -- -- --         @periodotamt = @periodotamt + isnull(sum(case when e.Factor <> 1 then b.Amt else 0 end),0)
   -- -- --  from bPRTB b
   -- -- --  join bPREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
   -- -- --  join HQBC h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId
   -- -- --  where b.Co = @prco and b.Employee = @empl and h.PREndDate = @prenddate and b.BatchTransType = 'C' and
   -- -- --  	(b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))
   
    /*select @periodreghrs = @periodreghrs + isnull(sum(case when e.Factor = 1 then -b.Hours else 0 end),0),
           @periodregamt = @periodregamt + isnull(sum(case when e.Factor = 1 then -b.Amt else 0 end),0),
           @periodothrs = @periodothrs + isnull(sum(case when e.Factor <> 1 then -b.Hours else 0 end),0),
           @periodotamt = @periodotamt + isnull(sum(case when e.Factor <> 1 then -b.Amt else 0 end),0)
    from PRTB b
    join PREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
    join HQBC h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId
    where b.Co = @prco and b.Employee = @empl and h.PREndDate = @prenddate and b.BatchTransType = 'D' and
    	(b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))*/
    
    -- if no job, null job totals and exit
    if @postjcco is null or @postjob is null
     	begin
     	select @jobreghrs = null, @jobothrs = null, @jobregamt = null, @jobotamt = null
     	goto bspexit
     	end
    
    -- accumulate job totals with existing timecards 
    select @jobreghrs = isnull(sum(case when e.Factor = 1 then t.Hours else 0 end),0),
    	@jobregamt = isnull(sum(case when e.Factor = 1 then t.Amt else 0 end),0),
    	@jobothrs = isnull(sum(case when e.Factor <> 1 then t.Hours else 0 end),0),
    	@jobotamt = isnull(sum(case when e.Factor <> 1 then t.Amt else 0 end),0)
    from bPRTH t with (nolock) 
    join bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
    where t.PRCo = @prco and t.JCCo = @postjcco and t.Job = @postjob and t.PREndDate = @prenddate
    	and t.InUseBatchId is null 	-- exlcude timecards in a batch
    
    -- adjust job totals for timecard batches
    select @jobreghrs = @jobreghrs + isnull(sum(case when e.Factor = 1 then b.Hours else 0 end),0),
           @jobregamt = @jobregamt + isnull(sum(case when e.Factor = 1 then b.Amt else 0 end),0),
            @jobothrs = @jobothrs + isnull(sum(case when e.Factor <> 1 then  b.Hours else 0 end),0),
            @jobotamt = @jobotamt + isnull(sum(case when e.Factor <> 1 then b.Amt else 0 end),0)
    from bPRTB b with (nolock) 
    join bPREC e with (nolock)  on e.PRCo = b.Co and e.EarnCode = b.EarnCode
    join HQBC h with (nolock)  on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId
    where b.Co = @prco  and b.JCCo = @postjcco and b.Job = @postjob 
    	and h.PREndDate = @prenddate and b.BatchTransType <> 'D' and
    	--(b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))
		not (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @tcseq)
   
   
   -- -- --  select @jobreghrs = @jobreghrs + isnull(sum(case when e.Factor = 1 then b.Hours else 0 end),0),
   -- -- --         @jobregamt = @jobregamt + isnull(sum(case when e.Factor = 1 then b.Amt else 0 end),0),
   -- -- --          @jobothrs = @jobothrs + isnull(sum(case when e.Factor <> 1 then  b.Hours else 0 end),0),
   -- -- --          @jobotamt = @jobotamt + isnull(sum(case when e.Factor <> 1 then b.Amt else 0 end),0)
   -- -- --  from bPRTB b
   -- -- --  join bPREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
   -- -- --  join HQBC h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId
   -- -- --  where b.Co = @prco  and b.JCCo = @postjcco and b.Job = @postjob 
   -- -- --  	and h.PREndDate = @prenddate and b.BatchTransType ='A'
   -- -- --  	and (b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))
   -- -- --  
   -- -- --  select @jobreghrs = @jobreghrs + isnull(sum(case when e.Factor = 1 then b.Hours else 0 end),0),
   -- -- --         @jobregamt = @jobregamt + isnull(sum(case when e.Factor = 1 then b.Amt else 0 end),0),
   -- -- --          @jobothrs = @jobothrs + isnull(sum(case when e.Factor <> 1 then b.Hours else 0 end),0),
   -- -- --          @jobotamt = @jobotamt + isnull(sum(case when e.Factor <> 1 then b.Amt else 0 end),0)
   -- -- --  from bPRTB b
   -- -- --  join bPREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
   -- -- --  join HQBC h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId
   -- -- --  where b.Co = @prco  and b.JCCo = @postjcco and b.Job = @postjob 
   -- -- --  	and h.PREndDate = @prenddate and b.BatchTransType = 'C'
   -- -- --  	and (b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))
    
    /*select @jobreghrs = @jobreghrs + isnull(sum(case when e.Factor = 1 then -b.Hours else 0 end),0),
           @jobregamt = @jobregamt + isnull(sum(case when e.Factor = 1 then -b.Amt else 0 end),0),
            @jobothrs = @jobothrs + isnull(sum(case when e.Factor <> 1 then -b.Hours else 0 end),0),
            @jobotamt = @jobotamt + isnull(sum(case when e.Factor <> 1 then -b.Amt else 0 end),0)
    from PRTB b
    join PREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
    join HQBC h on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId
    where b.Co = @prco  and b.JCCo = @postjcco and b.Job = @postjob 
    	and h.PREndDate = @prenddate and b.BatchTransType ='D'
    	and (b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))*/
   
   
   
   
   bspexit:
    	--if @rcode <> 0 select @msg = @msg + char(13) + char(10) + '[bspPRTimeCardTots]'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTimeCardTots] TO [public]
GO
