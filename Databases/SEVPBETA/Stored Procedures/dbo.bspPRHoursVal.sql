SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRHoursVal    Script Date: 8/28/99 9:36:32 AM ******/
   
    CREATE   proc [dbo].[bspPRHoursVal]
    /************************************************************************************
     * CREATED BY: kb 3/26/98
     * MODIFIED By : kb 11/19/98
     * MODIFIED By : EN 12/05/99 - fixed to get ot schedule from JCJM for craft or job postings
     * MODIFIED By : EN 12/10/99 - reviewed and made various fixes for issues 4336, 4650 and 4667
     * MODIFIED By : EN 12/31/99 - if ot is by craft/job, skip ot check on non-craft/job entries
     *               EN 3/16/00 - wasn't including last day of week when checking for overtime on bi-weekly period
     *               EN 1/3/01 - issue #11401 - skip validate if posted to earn code is not regular time
     *                             and check for bPREC_OTCalcs flag = 'Y' when add up daily hours
     *               EN 6/1/01 - issue 11870 (add 2 more levels to OT Schedule plus Schedule by Shift)
     *               EN 6/1/01 - issue 11871 (check for craft holidays)
     *               EN 6/1/01 - issue 13647
     *					EN 10/8/02 - issue 18877 change double quotes to single
     *					EN 7/7/05 - issue 29170 add validation for unassigned OT schedule
	 *				 EN 11/04/2009 #136378 to resolve this overtime warning issue, used isnull(varchar,-1) on level 1-3 earn codes to adjust for setting ansi nulls on
     *
     * USAGE:
     * Called by PR Timecard Entry to check for overtime warning.
     *
     * INPUT PARAMETERS
     *  @co         PR Company #
     *  @prgroup    PR Group
     *  @prenddate  PR Ending Date
     *  @employee   Employee #
     *  @postdate   Posted date on timecard
     *  @craft      Posted craft on timecard
     *  @jcco       Posted JC company on timecard
     *  @job        Posted job on timecard
     *  @ec         Earnings Code
     *  @hours      Posted hours on timecard
     *  @batchmth   Month of batch being posted
     *  @batchid    ID of batch being posted
     *  @batchseq   Current sequence number within batch
     *  @begindate  Beginning date of period
     *  @shift      Posted shift on timecard
     *  @payseq     Payment sequence for posting
     *
     * OUTPUT PARAMETERS
     *  @msg        warning message if maximun regular hours exceeded
     *
     * RETURN VALUE
     *  0           success
     *  1           failure
     ************************************************************************************/
   
        (@co bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee,
        @postdate bDate, @craft bCraft = null, @jcco bCompany = null, @job bJob = null, @ec bEDLCode,
        @hours bHrs, @batchmth bMonth, @batchid bBatchID, @batchseq smallint, @begindate bDate,
        @shift tinyint, @payseq tinyint, @msg varchar(255) output)
   
    as
   
    set nocount on
   
    declare @rcode int, @otopt char(1), @totdailyhrs bHrs, @otsched tinyint, @lvl1hrs bHrs,
    @lvl1earncode bEDLCode, @lvl2hrs bHrs, @lvl2earncode bEDLCode, @lvl3hrs bHrs,
    @lvl3earncode bEDLCode, @payfreq char(1), @emplweekhrs bHrs, @prco_regearncode bEDLCode,
    @beginweekdate bDate, @endweekdate bDate, @mth bMonth, @autoot bYN, @byshift char(1)
   
    select @rcode = 0
   
    -- get Auto Overtime option from PR Company
    select @autoot = AutoOT
    from bPRCO where PRCo = @co
    if @@rowcount = 0
        begin
        select @msg = 'Invalid PR Company #', @rcode = 1
        goto bspexit
        end
    -- skip if PR Company is using Auto Overtime
    if @autoot = 'Y' goto bspexit
   
    -- get Payment Frequency for the PR Group
    select @payfreq = PayFreq
    from bPRGR
    where PRCo = @co and PRGroup = @prgroup
    if @@rowcount = 0
        begin
        select @msg = 'Invalid PR Group.', @rcode = 1
        goto bspexit
        end
    -- skip if not paid weekly or bi-weekly
    if @payfreq not in ('W','B') goto bspexit
   
    -- get Overtime information for the Employee
    select @otopt = OTOpt, @otsched = OTSched
    from bPREH
    where PRCo = @co and Employee = @employee
    if @@rowcount = 0
        begin
        select @msg = 'Invalid Employee.', @rcode = 1
        goto bspexit
        end
    if @otsched is null and @otopt='D'
   	 begin
   	 select @msg = 'Missing OT schedule for this Employee.  Unable to evaluate hours for overtime warning.', @rcode = 1
   	 goto bspexit
   	 end
    -- skip if exempt from overtime
    if @otopt = 'N' goto bspexit
   
    -- if ot is by craft, skip non-craft entries
    if @otopt = 'C' and @craft is null goto bspexit
   
    -- if ot is by job, skip non-job entries
    if @otopt = 'J' and @job is null goto bspexit
   
    -- if craft was posted get ot schedule from PRCM
    if @otopt = 'C'
       begin
       select @otsched = OTSched
       from bPRCM
       where PRCo = @co and Craft = @craft
       if @@rowcount = 0
           begin
           select @msg = 'Invalid Craft.', @rcode = 1
           goto bspexit
           end
   	if @otsched is null
   		begin
   		select @msg = 'Missing OT schedule for Craft ' + @craft + '.  Unable to evaluate hours for overtime warning.', @rcode = 1
   		goto bspexit
   		end
       end
   
    -- if job posting get ot schedule from JCJM
    if @otopt = 'J'
       begin
       select @otsched = OTSched
       from bJCJM
       where JCCo = @jcco and Job = @job
       if @@rowcount = 0
           begin
           select @msg = 'Invalid Job.', @rcode = 1
           goto bspexit
           end
   	if @otsched is null
   		begin
   		select @msg = 'Missing OT schedule for Job ' + @job + '.  Unable to evaluate hours for overtime warning.', @rcode = 1
   		goto bspexit
   		end
       end
   
   
    -- Daily / Craft / Job
    if @otopt = 'D' or @otopt = 'C' or @otopt = 'J'
       begin
       -- get info from OT schedule
       -- issues 11870 and 11871 - pass shift and craft into bspPROTIntoGet
       exec @rcode=bspPROTInfoGet @co, @prgroup, @prenddate, @otsched, @shift, @craft, @postdate,
           @lvl1hrs output, @lvl1earncode output, @lvl2hrs output, @lvl2earncode output, @lvl3hrs output,
           @lvl3earncode output, @byshift output, @msg output
       if @rcode <> 0 goto bspexit
   
       -- if OT Sched is not by shift, ignore shift when compute total daily hrs
       if @byshift = 'N' select @shift = null
   
       -- skip Daily OT check if OT schedule level 1 not initialized
       if @lvl1earncode is null
           goto WeeklyOT
   
       -- skip if earnings code posted is not flagged as regular time or in OTCalc schedule levels
       if (select OTCalcs from bPREC where PRCo=@co and EarnCode=@ec) <> 'Y'
           begin
           if (@ec=isnull(@lvl1earncode,-1) and @lvl2earncode is null) or (@ec=isnull(@lvl2earncode,-1) and @lvl3earncode is null)
                   or @ec=isnull(@lvl3earncode,-1)
               goto bspexit
           end
   
       -- get daily total from Timecards
       if @otopt = 'D'
           select @totdailyhrs = isnull(@hours,0) + isnull(sum(h.Hours),0)
           from bPRTH h
           join bPREC e on e.PRCo = h.PRCo and e.EarnCode = h.EarnCode
           where h.PRCo = @co and h.PRGroup = @prgroup and h.PREndDate = @prenddate
           and h.Employee = @employee and h.PaySeq = @payseq and h.PostDate = @postdate
           and h.Shift = isnull(@shift,h.Shift) and h.InUseBatchId is null
           and (e.OTCalcs='Y' or (h.EarnCode=isnull(@lvl1earncode,-1) and @lvl2earncode is not null) or
           (h.EarnCode=isnull(@lvl2earncode,-1) and @lvl3earncode is not null))
       if @otopt = 'C'
       	select @totdailyhrs = isnull(@hours,0) + isnull(sum(h.Hours),0)
           from bPRTH h
           join bPREC e on e.PRCo = h.PRCo and e.EarnCode = h.EarnCode
           where h.PRCo = @co and h.PRGroup = @prgroup and h.PREndDate = @prenddate
           and h.Employee = @employee and h.PaySeq = @payseq and h.PostDate = @postdate
           and h.Craft = @craft and h.Shift = isnull(@shift,h.Shift) and h.InUseBatchId is null
           and (e.OTCalcs='Y' or (h.EarnCode=isnull(@lvl1earncode,-1) and @lvl2earncode is not null) or
           (h.EarnCode=isnull(@lvl2earncode,-1) and @lvl3earncode is not null))
       if @otopt = 'J'
       	select @totdailyhrs = isnull(@hours,0) + isnull(sum(h.Hours),0)
           from bPRTH h
           join bPREC e on e.PRCo = h.PRCo and e.EarnCode = h.EarnCode
           where h.PRCo = @co and h.PRGroup = @prgroup and h.PREndDate = @prenddate
           and h.Employee = @employee and h.PaySeq = @payseq and h.PostDate = @postdate
           and h.Shift = isnull(@shift,h.Shift) and h.JCCo = @jcco and h.Job = @job and h.InUseBatchId is null
           and (e.OTCalcs='Y' or (h.EarnCode=isnull(@lvl1earncode,-1) and @lvl2earncode is not null) or
           (h.EarnCode=isnull(@lvl2earncode,-1) and @lvl3earncode is not null))
   
       -- get daily total from current batch
       if @otopt = 'D'
       	select @totdailyhrs = @totdailyhrs + isnull(sum(Hours),0)
           from bPRTB b
           join bPREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
           join bHQBC c on c.Co = b.Co and c.Mth = b.Mth and c.BatchId = b.BatchId
          	where b.Co = @co and c.PRGroup = @prgroup and c.PREndDate = @prenddate
           and b.Employee = @employee and b.PaySeq = @payseq and b.PostDate = @postdate
           and b.Shift = isnull(@shift,b.Shift) and not (b.Mth = @batchmth and b.BatchId = @batchid
           and b.BatchSeq = @batchseq) and (b.BatchTransType='A' or b.BatchTransType='C')
          and (e.OTCalcs='Y' or (b.EarnCode=isnull(@lvl1earncode,-1) and @lvl2earncode is not null) or
           (b.EarnCode=isnull(@lvl2earncode,-1) and @lvl3earncode is not null))
       if @otopt = 'C'
       	select @totdailyhrs = @totdailyhrs + isnull(sum(Hours),0)
           from bPRTB b
           join bPREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
           join bHQBC c on c.Co = b.Co and c.Mth = b.Mth and c.BatchId = b.BatchId
          	where b.Co = @co and c.PRGroup = @prgroup and c.PREndDate = @prenddate
           and b.Employee = @employee and b.PaySeq = @payseq and b.PostDate = @postdate
           and b.Craft = @craft and b.Shift = isnull(@shift,b.Shift)
           and not (b.Mth = @batchmth and b.BatchId = @batchid and b.BatchSeq = @batchseq)
           and (b.BatchTransType='A' or b.BatchTransType='C')
           and (e.OTCalcs='Y' or (b.EarnCode=isnull(@lvl1earncode,-1) and @lvl2earncode is not null) or
           (b.EarnCode=isnull(@lvl2earncode,-1) and @lvl3earncode is not null))
       if @otopt = 'J'
       	select @totdailyhrs = @totdailyhrs + isnull(sum(Hours),0)
           from bPRTB b
           join bPREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
           join bHQBC c on c.Co = b.Co and c.Mth = b.Mth and c.BatchId = b.BatchId
          	where b.Co = @co and c.PRGroup = @prgroup and c.PREndDate = @prenddate
           and b.Employee = @employee and b.PaySeq = @payseq and b.PostDate = @postdate
           and b.Shift = isnull(@shift,b.Shift) and b.JCCo = @jcco and b.Job = @job
           and not (b.Mth = @batchmth and b.BatchId = @batchid and b.BatchSeq = @batchseq)
           and (b.BatchTransType='A' or b.BatchTransType='C')
           and (e.OTCalcs='Y' or (b.EarnCode=isnull(@lvl1earncode,-1) and @lvl2earncode is not null) or
           (b.EarnCode=isnull(@lvl2earncode,-1) and @lvl3earncode is not null))
   
       -- generate warnings
       if @ec = isnull(@lvl2earncode,-1) and @totdailyhrs > @lvl3hrs
           begin
           if @totdailyhrs - @lvl3hrs < @hours
               select @msg = 'Overtime limit exceeded by ' + convert(varchar(6),@totdailyhrs - @lvl3hrs) + ' hour(s).'
           else
               select @msg = 'Overtime limit has been exceeded.'
           select @rcode = 1
           goto bspexit
           end
       if @ec = isnull(@lvl1earncode,-1) and @totdailyhrs > @lvl2hrs
           begin
           if @totdailyhrs - @lvl2hrs < @hours
               select @msg = 'Overtime limit exceeded by ' + convert(varchar(6),@totdailyhrs - @lvl2hrs) + ' hour(s).'
           else
               select @msg = 'Overtime limit has been exceeded.'
           select @rcode = 1
           goto bspexit
           end
       if (@ec <> isnull(@lvl3earncode,-1) and @ec <> isnull(@lvl2earncode,-1) and @ec <> isnull(@lvl1earncode,-1)) and @totdailyhrs > @lvl1hrs
           begin
           if @totdailyhrs - @lvl1hrs < @hours
               select @msg = 'Overtime limit exceeded by ' + convert(varchar(6),@totdailyhrs - @lvl1hrs) + ' hour(s).'
           else
               select @msg = 'Overtime limit has been exceeded.'
           select @rcode = 1
           goto bspexit
           end
       end
   
    if @otopt = 'W'
       begin
       -- skip if earnings code posted is not flagged as regular time or in OTCalc schedule levels
       if (select OTCalcs from bPREC where PRCo=@co and EarnCode=@ec) <> 'Y'
           goto bspexit
       end
   
    -- weekly (including daily / craft / job)
    WeeklyOT:
    if @otopt = 'W' or @otopt = 'D' or @otopt = 'C' or @otopt = 'J'
   	begin
   
   	/*select @endweekdate=DateAdd(day,6,@prenddate)*/
   
   	select @beginweekdate = @begindate, @endweekdate = @prenddate
       if @payfreq = 'B' select @endweekdate = DateAdd(day, 6, @begindate)
   
   	WeekLoop: /*repeated for bi-weekly periods*/
   	if @payfreq = 'W' or (@payfreq = 'B' and @postdate <= @endweekdate)
      		begin
           -- get daily total from Timecards
           if @otopt = 'D' or @otopt = 'W'
   
   	        select @emplweekhrs=isnull(@hours,0)+isnull(sum(h.Hours),0)
    			from PRTH h
               join PREC e on e.PRCo = h.PRCo and e.EarnCode = h.EarnCode
    			where h.PRCo=@co and h.PRGroup=@prgroup and h.PREndDate=@prenddate
               and h.Employee=@employee and h.PaySeq = @payseq and e.OTCalcs='Y'
        		and h.PostDate>=@beginweekdate and h.PostDate<=@endweekdate and h.InUseBatchId is null
           if @otopt = 'C'
   	        select @emplweekhrs=isnull(@hours,0)+isnull(sum(h.Hours),0)
    			from PRTH h
               join PREC e on e.PRCo = h.PRCo and e.EarnCode = h.EarnCode
    			where h.PRCo=@co and h.PRGroup=@prgroup and h.PREndDate=@prenddate
               and h.Employee=@employee and h.PaySeq = @payseq and e.OTCalcs='Y'
        		and h.PostDate>=@beginweekdate and h.PostDate<=@endweekdate and h.Craft = @craft
               and h.InUseBatchId is null
           if @otopt = 'J'
   	        select @emplweekhrs=isnull(@hours,0)+isnull(sum(h.Hours),0)
    			from PRTH h
               join PREC e on e.PRCo = h.PRCo and e.EarnCode = h.EarnCode
    			where h.PRCo=@co and h.PRGroup=@prgroup and h.PREndDate=@prenddate
               and h.Employee=@employee and h.PaySeq = @payseq and e.OTCalcs='Y'
        		and h.PostDate>=@beginweekdate and h.PostDate<=@endweekdate
               and h.JCCo = @jcco and h.Job = @job and h.InUseBatchId is null
   
           -- get daily total from current batch
           if @otopt = 'D' or @otopt = 'W'
    	        select @emplweekhrs=@emplweekhrs+isnull(sum(b.Hours),0)
    			from PRTB b
               join bPREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
               join bHQBC c on c.Co = b.Co and c.Mth = b.Mth and c.BatchId = b.BatchId
    			where b.Co=@co and c.PRGroup=@prgroup and c.PREndDate=@prenddate
               and b.Employee=@employee and b.PaySeq = @payseq and e.OTCalcs='Y'
       		and b.PostDate>=@beginweekdate and b.PostDate<=@endweekdate
               and not (b.Mth = @batchmth and b.BatchId = @batchid and b.BatchSeq = @batchseq)
               and (b.BatchTransType='A' or b.BatchTransType='C')
           if @otopt = 'C'
    	        select @emplweekhrs=@emplweekhrs+isnull(sum(b.Hours),0)
    			from PRTB b
               join bPREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
               join bHQBC c on c.Co = b.Co and c.Mth = b.Mth and c.BatchId = b.BatchId
    			where b.Co=@co and c.PRGroup=@prgroup and c.PREndDate=@prenddate
               and b.Employee=@employee and b.PaySeq = @payseq and e.OTCalcs='Y'
       		and b.PostDate>=@beginweekdate and b.PostDate<=@endweekdate and b.Craft = @craft
               and not (b.Mth = @batchmth and b.BatchId = @batchid and b.BatchSeq = @batchseq)
               and (b.BatchTransType='A' or b.BatchTransType='C')
           if @otopt = 'J'
    	        select @emplweekhrs=@emplweekhrs+isnull(sum(b.Hours),0)
    			from PRTB b
               join bPREC e on e.PRCo = b.Co and e.EarnCode = b.EarnCode
               join bHQBC c on c.Co = b.Co and c.Mth = b.Mth and c.BatchId = b.BatchId
    			where b.Co=@co and c.PRGroup=@prgroup and c.PREndDate=@prenddate
               and b.Employee=@employee and b.PaySeq = @payseq and e.OTCalcs='Y'
       		and b.PostDate>=@beginweekdate and b.PostDate<=@endweekdate
               and b.JCCo = @jcco and b.Job = @job
               and not (b.Mth = @batchmth and b.BatchId = @batchid and b.BatchSeq = @batchseq)
               and (b.BatchTransType='A' or b.BatchTransType='C')
   
      		if @emplweekhrs>40
      			begin
      			    select @msg='Over the standard 40 hours per week.', @rcode=1
       			goto bspexit
       		end
   
      		end
   
       if @payfreq = 'B'
           begin
           if @endweekdate <> @prenddate
               begin
               select @beginweekdate = DateAdd(Day, 1, @endweekdate), @endweekdate = @prenddate
               goto WeekLoop
               end
           end
       end
   
          	/*if @payfreq = 'B'
          		begin
          		if @postdate>@endweekdate
          			begin
                   -- get daily total from Timecards
                   if @otopt = 'D'
              			select @emplweekhrs=isnull(@hours,0)+isnull(sum(Hours),0)
   
            			from PRTH, PREC
            			where PREC.PRCo = PRTH.PRCo and PREC.EarnCode = PRTH.EarnCode
              			and PRTH.PRCo=@co and PRGroup=@prgroup
               		and PREndDate=@prenddate and Employee=@employee and PREC.OTCalcs='Y'
               		and PostDate>@endweekdate and PostDate<=@prenddate and InUseBatchId is null
                   if @otopt = 'C'
              			select @emplweekhrs=isnull(@hours,0)+isnull(sum(Hours),0)
            			from PRTH, PREC
            			where PREC.PRCo = PRTH.PRCo and PREC.EarnCode = PRTH.EarnCode
              			and PRTH.PRCo=@co and PRGroup=@prgroup
            		and PREndDate=@prenddate and Employee=@employee and PREC.OTCalcs='Y'
               		and PostDate>@endweekdate and PostDate<=@prenddate and Craft = @craft
                       and InUseBatchId is null
                   if @otopt = 'J'
     			select @emplweekhrs=isnull(@hours,0)+isnull(sum(Hours),0)
            			from PRTH, PREC
            			where PREC.PRCo = PRTH.PRCo and PREC.EarnCode = PRTH.EarnCode
              			and PRTH.PRCo=@co and PRGroup=@prgroup
               		and PREndDate=@prenddate and Employee=@employee and PREC.OTCalcs='Y'
               		and PostDate>@endweekdate and PostDate<=@prenddate
                       and JCCo = @jcco and Job = @job and InUseBatchId is null
   
                   -- get daily total from current batch
                   if @otopt = 'D'
              	 		select @emplweekhrs=@emplweekhrs+isnull(sum(Hours),0)
            			from PRTB, PREC, HQBC
            			where PREC.PRCo = PRTB.Co and PREC.EarnCode = PRTB.EarnCode and HQBC.Co=PRTB.Co
               		and HQBC.Mth=PRTB.Mth and HQBC.BatchId=PRTB.BatchId and PRTB.Co=@co
                       and	PRGroup=@prgroup and PREndDate=@prenddate and Employee=@employee and PREC.OTCalcs='Y'
              			and PostDate>@endweekdate and PostDate<=@prenddate
                       and not (PRTB.Mth = @batchmth and PRTB.BatchId = @batchid and PRTB.BatchSeq = @batchseq)
                       and (PRTB.BatchTransType='A' or PRTB.BatchTransType='C')
                   if @otopt = 'C'
              	 		select @emplweekhrs=@emplweekhrs+isnull(sum(Hours),0)
            			from PRTB, PREC, HQBC
            			where PREC.PRCo = PRTB.Co and PREC.EarnCode = PRTB.EarnCode and HQBC.Co=PRTB.Co
               		and HQBC.Mth=PRTB.Mth and HQBC.BatchId=PRTB.BatchId and PRTB.Co=@co
                       and PRGroup=@prgroup and PREndDate=@prenddate and Employee=@employee and PREC.OTCalcs='Y'
              			and PostDate>@endweekdate and PostDate<=@prenddate and Craft = @craft
                       and not (PRTB.Mth = @batchmth and PRTB.BatchId = @batchid and PRTB.BatchSeq = @batchseq)
                       and (PRTB.BatchTransType='A' or PRTB.BatchTransType='C')
                   if @otopt = 'J'
              	 		select @emplweekhrs=@emplweekhrs+isnull(sum(Hours),0)
            			from PRTB, PREC, HQBC
            			where PREC.PRCo = PRTB.Co and PREC.EarnCode = PRTB.EarnCode and HQBC.Co=PRTB.Co
               		and HQBC.Mth=PRTB.Mth and HQBC.BatchId=PRTB.BatchId and PRTB.Co=@co
                       and PRGroup=@prgroup and PREndDate=@prenddate and Employee=@employee and PREC.OTCalcs='Y'
              			and PostDate>@endweekdate and PostDate<=@prenddate
                       and JCCo = @jcco and Job = @job
                       and not (PRTB.Mth = @batchmth and PRTB.BatchId = @batchid and PRTB.BatchSeq = @batchseq)
                       and (PRTB.BatchTransType='A' or PRTB.BatchTransType='C')
   
          			if @emplweekhrs>40
          				begin
       			    select @msg='Over the standard 40 hours per week.', @rcode=1
       				goto bspexit
       				end
           			end
          		end*/
       	/*weekloop_end:
   
       	if @emplweekhrs>40
       		begin
       		select @msg='Over the standard 40 hours per week.', @rcode=1
       		goto bspexit
       		end*/
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRHoursVal] TO [public]
GO
