SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_AU_OTCribAllow]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_AU_OTCribAllow]
   /********************************************************
   * CREATED BY: 	EN 3/03/2010 #132653
   * MODIFIED BY:  
   *
   * USAGE:
   * 	Computes Crib allowance when weekend time posted (subject hours) is over a certain
   *	threshold.  Allowance is computed at 20 minutes of doubletime.
   *	This routine may be called by either PR Auto Earnings or PR Payroll Processing.
   *	For auto earnings the total allowance amount will be returned and bspPRAutoEarnInit
   *	will handle the bPRTB posting.  For payroll processing, this routine will handle posting to the timecard
   *	addons table (bPRTA).  
   *
   * INPUT PARAMETERS:
   *	@prco		PR Company
   *	@earncode	Allowance earn code
   *	@addonYN	'Y' if computing as addon earn; 'N' if computing as auto earning
   *	@prgroup	PR Group
   *	@prenddate	Pay Period Ending Date
   *	@employee	Employee
   *	@payseq		Payment Sequence
   *	@craft		used if routine called from PR Process
   *	@class		used if routine called from PR Process
   *	@template	Job Template ... used if routine called from PR Process
   *	@rate		used if routine called from Auto Earn Init
   *
   * OUTPUT PARAMETERS:
   *	@amt		used if routine called from Auto Earn Init
   *	@errmsg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   	(@prco bCompany = null, @earncode bEDLCode = null, @addonYN bYN, @prgroup bGroup, @prenddate bDate, 
	@employee bEmployee, @payseq tinyint, @craft bCraft, @class bClass, @template smallint, 
	@rate bUnitCost, @amt bDollar output, @errmsg varchar(255) = null output)
	as
	set nocount on
	set datefirst 7 --Sets first day of week to Sunday in case user default language is set to something like British English
					-- in which case the first day defaults to Saturday.  Needed because this procedure checks weekday using
					-- datepart function to distinguish weekdays from weekend days.

	declare @rcode int, @totalearns bDollar, @WeekdayThreshold bHrs, @WeekendThreshold bHrs, 
		@lastpostseq smallint, @totalallowance bDollar, @totalposted bDollar, @postdate bDate, 
		@hoursposted bHrs, @workstate varchar(4), @shift tinyint, @PREHearncode bEDLCode,
		@emplrate bUnitCost, @VICWeekdayThreshold bHrs, @VICWeekendThreshold bHrs, @NSWWeekdayThreshold bHrs, 
		@NSWWeekendThreshold bHrs, @WAWeekdayThreshold bHrs, @WAWeekendThreshold bHrs

	select @rcode = 0, @amt = 0

	--define state overtime crib thresholds
	select @VICWeekdayThreshold = 10, @VICWeekendThreshold = 8
	select @NSWWeekdayThreshold = 99, @NSWWeekendThreshold = 4
	select @WAWeekdayThreshold = 10, @WAWeekendThreshold = 8
	
	if @addonYN = 'Y'
		begin --compute as addon earnings and post distributions in bPRTA

		--create table variable for all posting dates with data need to determine allowance eligibility
		declare @PostDates1 table (PostDate bDate, HoursPosted bHrs, WorkState varchar(4), 
									Shift tinyint, Allowance bDollar)

		--populate @PostDates1 with dates, daily total hours, and highest posting seq/Work State/Shift for each date
		insert @PostDates1
		select h.PostDate, sum(h.Hours), max(h.UnempState), max(h.Shift), 0
		from dbo.bPRTH h (nolock)
		left outer join dbo.bJCJM j (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
		join dbo.bPREC e (nolock) on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
		where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
			and h.Employee = @employee and h.PaySeq = @payseq
			and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)
			and h.Craft = @craft and h.Class = @class
			and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
			or (j.CraftTemplate is null and @template is null))
			and e.SubjToAddOns = 'Y'
		group by h.PostDate

		--lookup employee's regular earn code ... needed for looking up employee's regular pay rate
		select @PREHearncode = EarnCode from dbo.bPREH (nolock) where PRCo=@prco and Employee=@employee

		-- loop through PostDate in @PostDates1 and compute allowance per diem
		select @postdate = min(PostDate) from @PostDates1

		while @postdate is not null
			begin
			select @hoursposted=HoursPosted, @workstate=WorkState, @shift=Shift from @PostDates1 where PostDate = @postdate

			--default thresholds to unlimited to not apply threshold on unspecified states
			select @WeekdayThreshold = 99, @WeekendThreshold = 99
			--determine thresholds
			if @workstate = 'VIC' select @WeekdayThreshold = @VICWeekdayThreshold, @WeekendThreshold = @VICWeekendThreshold
			if @workstate = 'NSW' select @WeekdayThreshold = @NSWWeekdayThreshold, @WeekendThreshold = @NSWWeekendThreshold
			if @workstate = 'WA' select @WeekdayThreshold = @WAWeekdayThreshold, @WeekendThreshold = @WAWeekendThreshold

			--if threshold for weekday or weekend day is exceeded lookup employee's regular pay rate then compute the allowance
			-- and update it to @PostDates1
			if (datepart(weekday,@postdate) in (2,3,4,5,6) and @hoursposted >= @WeekdayThreshold) or
				(datepart(weekday,@postdate) in (1,7) and @hoursposted >= @WeekendThreshold)
				begin
				--lookup employee's regular pay rate
				EXEC @rcode = dbo.bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @template, @shift, 
						@earncode = @PREHearncode, @rate = @emplrate OUTPUT, @msg = @errmsg OUTPUT
				--compute allowance as 20 minutes at doubletime (doubletime for an hour divided by 3 is more accurate)
				update @PostDates1 set Allowance = (@emplrate * 2) / 3 where PostDate = @postdate
				end

			select @postdate = min(PostDate) from @PostDates1 where PostDate > @postdate
			end

		--distribute Allowance to earnings

		-- get total daily earnings subject to addons 
		select @totalearns = sum(Amt)
		from dbo.bPRTH h (nolock)
		left outer join dbo.bJCJM j (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
		join dbo.bPREC e (nolock) on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
		where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
			and h.Employee = @employee and h.PaySeq = @payseq
			and h.PostDate in (select PostDate from @PostDates1 where Allowance <> 0)
			and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)
			and h.Craft = @craft and h.Class = @class
			and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
			or (j.CraftTemplate is null and @template is null))
			and e.SubjToAddOns = 'Y'

		--get total allowance to post
		select @totalallowance = sum(Allowance) from @PostDates1

		-- distibute based on proportion of earnings to total daily earnings 
		insert bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
		select @prco, @prgroup, @prenddate, @employee, @payseq, PostSeq, @earncode, 0, round((Amt / @totalearns) * @totalallowance,2)
		from dbo.bPRTH h (nolock)
		left outer join dbo.bJCJM j (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
		join dbo.bPREC e (nolock) on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
		where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
			and h.Employee = @employee and h.PaySeq = @payseq
			and h.PostDate in (select PostDate from @PostDates1 where Allowance <> 0)
			and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)
			and h.Craft = @craft and h.Class = @class
			and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
			or (j.CraftTemplate is null and @template is null))
			and e.SubjToAddOns = 'Y'
		order by PostSeq

		--compare total posted against allowance to determine need to update the difference
		select @totalposted = sum(Amt), @lastpostseq = max(PostSeq) from dbo.bPRTA (nolock)
		where PRCo=@prco and PRGroup=@prgroup and PREndDate=@prenddate and Employee=@employee and PaySeq=@payseq
			and EarnCode=@earncode

		if @totalallowance <> @totalposted
			begin
			-- update difference to last entry for the day 
			update bPRTA set Amt = Amt + (@totalallowance - @totalposted)
			where  PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
			and Employee = @employee and PaySeq = @payseq and PostSeq = @lastpostseq and EarnCode = @earncode

			end

		end --when @addonYN = 'Y'

	else --when @addonYN = 'N'
		begin
		--create table variable for all posting dates with data need to determine allowance eligibility
		declare @PostDates2 table (PostDate bDate, HoursPosted bHrs, WorkState varchar(4), Allowance bDollar)

		--populate @PostDates2 with dates, daily total hours, and highest posting seq/Work State/Shift for each date
		insert @PostDates2
		select h.PostDate, sum(h.Hours), max(h.UnempState), 0
		from dbo.bPRTH h (nolock)
		where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
			and h.Employee = @employee and h.PaySeq = @payseq
			and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)
		group by h.PostDate

		-- loop through PostDate in @PostDates1 and compute allowance per diem
		select @postdate = min(PostDate) from @PostDates2

		while @postdate is not null
			begin
			select @hoursposted = HoursPosted, @workstate = WorkState from @PostDates2 where PostDate = @postdate

			--default thresholds to unlimited to not apply threshold on unspecified states
			select @WeekdayThreshold = 99, @WeekendThreshold = 99
			--determine thresholds
			if @workstate = 'VIC' select @WeekdayThreshold = @VICWeekdayThreshold, @WeekendThreshold = @VICWeekendThreshold
			if @workstate = 'NSW' select @WeekdayThreshold = @NSWWeekdayThreshold, @WeekendThreshold = @NSWWeekendThreshold
			if @workstate = 'WA' select @WeekdayThreshold = @WAWeekdayThreshold, @WeekendThreshold = @WAWeekendThreshold

			--if threshold for weekday or weekend day is exceeded lookup employee's regular pay rate then compute the allowance
			-- and update it to @PostDates2
			if (datepart(weekday,@postdate) in (2,3,4,5,6) and @hoursposted >= @WeekdayThreshold) or
				(datepart(weekday,@postdate) in (1,7) and @hoursposted >= @WeekendThreshold)
				begin
				--compute allowance as 20 minutes at doubletime (doubletime for an hour divided by 3 is more accurate)
				update @PostDates2 set Allowance = (@rate * 2) / 3 where PostDate = @postdate
				end

			select @postdate = min(PostDate) from @PostDates2 where PostDate > @postdate
			end

		select @amt = sum(Allowance) from @PostDates2

		end


	bspexit:

   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_OTCribAllow] TO [public]
GO
