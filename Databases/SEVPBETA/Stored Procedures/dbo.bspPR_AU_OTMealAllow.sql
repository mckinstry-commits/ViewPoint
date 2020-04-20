SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_AU_OTMealAllow]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_AU_OTMealAllow]
/********************************************************
* CREATED BY: 	EN 2/08/2010 #132653
* MODIFIED BY:  EN/KK 06/08/12 - D-05183 Modified to grab the craft/class template info to determine the totalposted vs totalallowance difference 
*
* USAGE:
* 	Computes Meal allowance when weekend time posted (subject hours) is over a certain
*	threshold.  Allowance is computed as an amount per day.
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
(@prco bCompany = NULL, 
 @earncode bEDLCode = NULL, 
 @addonYN bYN, 
 @prgroup bGroup, 
 @prenddate bDate,
 @employee bEmployee, 
 @payseq tinyint, 
 @craft bCraft, 
 @class bClass, 
 @template smallint, 
 @rate bUnitCost, 
 @amt bDollar OUTPUT, 
 @errmsg varchar(255) = NULL OUTPUT)

AS
SET NOCOUNT ON

	set datefirst 7 --Sets first day of week to Sunday in case user default language is set to something like British English
					-- in which case the first day defaults to Saturday.  Needed because this procedure checks weekday using
					-- datepart function to distinguish weekdays from weekend days.

	declare @rcode int, @totalearns bDollar, @oldrate bUnitCost, @newrate bUnitCost, @effectdate bDate, 
		@HoursThreshold bHrs, @lastpostseq smallint, @totalallowance bDollar, @totalposted bDollar,
		@postdate bDate
   
	select @rcode = 0, @amt = 0, @HoursThreshold = 9.5

	--create table variable for all posting dates and meal allowance for the day
	declare @PostDates table (PostDate bDate, AllowAmt bDollar)

	if @addonYN = 'Y'
		begin --compute as addon earnings and post distributions in bPRTA

		--get Craft Effective Date with possible override by Template
		select @effectdate = EffectiveDate from bPRCM where PRCo = @prco and Craft = @craft
		select @effectdate = EffectiveDate from bPRCT where PRCo = @prco and Craft = @craft
			and Template = @template and OverEffectDate = 'Y'

		--get Craft, Class Addon Rates with possible override by Template - lookup 0.00 Factor
		select @oldrate = 0.00, @newrate = 0.00
		select @oldrate = OldRate, @newrate = NewRate from bPRCI where PRCo = @prco
			and Craft = @craft and EDLType = 'E' and EDLCode = @earncode and Factor = 0.00
		select @oldrate = OldRate, @newrate = NewRate from bPRCF where PRCo = @prco
			and Craft = @craft and Class = @class and EarnCode = @earncode and Factor = 0.00
		select @oldrate = OldRate, @newrate = NewRate from bPRTI where PRCo = @prco
			and Craft = @craft and Template = @template and EDLType = 'E' and EDLCode = @earncode and Factor = 0.00
		select @oldrate = OldRate, @newrate = NewRate from bPRTF where PRCo = @prco
			and Craft = @craft and Class = @class and Template = @template and EarnCode = @earncode and Factor = 0.00

		--determine allowances at old rate
		insert @PostDates
		select h.PostDate, (case when sum(h.Hours) >= @HoursThreshold then @oldrate else 0 end)
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
			and h.PostDate < @effectdate
			and Datepart(weekday,h.PostDate) in (2,3,4,5,6)
		group by h.PostDate

		--determine allowances at new rate
		insert @PostDates
		select h.PostDate, (case when sum(h.Hours) >= @HoursThreshold then @newrate else 0 end)
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
			and h.PostDate >= @effectdate
			and Datepart(weekday,h.PostDate) in (2,3,4,5,6)
		group by h.PostDate

		select @postdate = min(PostDate) from @PostDates

		while @postdate is not null
			begin
			--get total allowance to post
			select @totalallowance = AllowAmt from @PostDates where PostDate = @postdate
			if @totalallowance <> 0
				begin
				-- get total daily earnings subject to addons 
				select @totalearns = sum(Amt)
				from dbo.bPRTH h (nolock)
				left outer join dbo.bJCJM j (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
				join dbo.bPREC e (nolock) on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
				where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
					and h.Employee = @employee and h.PaySeq = @payseq
					and h.PostDate = @postdate
					and h.Craft = @craft and h.Class = @class
					and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)
					and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
					or (j.CraftTemplate is null and @template is null))
					and e.SubjToAddOns = 'Y'

				-- distibute based on proportion of earnings to total daily earnings 
				insert bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
				select @prco, @prgroup, @prenddate, @employee, @payseq, PostSeq, @earncode, 0, round((Amt / @totalearns) * @totalallowance, 2)
				from dbo.bPRTH h (nolock)
				left outer join dbo.bJCJM j (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
				join dbo.bPREC e (nolock) on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
				where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
					and h.Employee = @employee and h.PaySeq = @payseq
					and h.PostDate = @postdate
					and h.Craft = @craft and h.Class = @class
					and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)
					and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
					or (j.CraftTemplate is null and @template is null))
					and e.SubjToAddOns = 'Y'
					and Datepart(weekday,h.PostDate) in (2,3,4,5,6)
				order by PostSeq

				end
			select @postdate = min(PostDate) from @PostDates where PostDate > @postdate
			end

			--compare total posted against allowance to determine need to update the difference 
			--D-05183 Modified the select statement to grab the craft/class template information
			SELECT @totalposted = SUM(a.Amt), @lastpostseq = MAX(a.PostSeq)  
			FROM dbo.bPRTA a (NOLOCK)
			JOIN dbo.bPRTH h (NOLOCK) ON h.PRCo = a.PRCo
										 AND h.PRGroup = a.PRGroup
										 AND h.PREndDate = a.PREndDate
										 AND h.Employee = a.Employee
										 AND h.PaySeq = a.PaySeq
										 AND h.PostSeq = a.PostSeq
			LEFT OUTER JOIN dbo.bJCJM j (nolock) on j.JCCo = h.JCCo and j.Job = h.Job
			WHERE a.PRCo = @prco 
				  AND a.PRGroup = @prgroup 
				  AND a.PREndDate = @prenddate 
				  AND a.Employee = @employee 
				  AND a.PaySeq = @payseq
				  AND a.EarnCode = @earncode
				  AND h.Craft = @craft 
				  AND h.Class = @class
				  AND (
					   (j.CraftTemplate = @template) 
					   OR (h.Job IS NULL AND @template IS NULL)
					   OR (j.CraftTemplate IS NULL AND @template IS NULL)
					  )

		select @totalallowance = sum(AllowAmt) from @PostDates
		
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
		--determine allowances at old rate
		insert @PostDates
		select h.PostDate, (case when sum(h.Hours) >= @HoursThreshold then @rate else 0 end)
		from dbo.bPRTH h (nolock)
		where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
			and h.Employee = @employee and h.PaySeq = @payseq
			and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)
			and Datepart(weekday,h.PostDate) in (2,3,4,5,6)
		group by h.PostDate

		select @amt = sum(AllowAmt) from @PostDates

		end


	bspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_OTMealAllow] TO [public]
GO
