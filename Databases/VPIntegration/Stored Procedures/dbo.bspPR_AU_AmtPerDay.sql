SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_AU_AmtPerDay]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_AU_AmtPerDay]
/********************************************************
* CREATED BY: 	EN	02/08/2010	- #132653
* MODIFIED BY:	CHS	07/26/2011	- #144236 fixed rounding problem.
*				CHS	10/31/2011	- D-03193 
*
* USAGE:
* 	Calculates amount per day (based on each day subject earnings were posted or std days if Post To All
*	was checked) and posts to timecard addons table (bPRTA).  The amount is stored in craft/class/template 
*	pay rate tables.
*
* INPUT PARAMETERS:
*	@prco	PR Company
*	@earncode	Allowance earn code
*	@prgroup	PR Group
*	@prenddate	Pay Period Ending Date
*	@employee	Employee
*	@payseq		Payment Sequence
*	@craft		used if routine called from PR Process
*	@class		used if routine called from PR Process
*	@template	Job Template ... used if routine called from PR Process
*	@posttoall	earnings posted to all days - Y or N
*	@addonYN	'Y' if computing as addon earn; 'N' if computing as auto earning
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
   	(@prco bCompany = null, @earncode bEDLCode = null, @prgroup bGroup, @prenddate bDate, @employee bEmployee, 
	@payseq tinyint, @craft bCraft, @class bClass, @template smallint, @posttoall bYN, @addonYN bYN,
	@rate bUnitCost, @amt bDollar output, @errmsg varchar(255) = null output)
	as
	set nocount on

	declare @rcode int, @totalearns bDollar, @addonamt bDollar, @oldrate bUnitCost, @newrate bUnitCost, 
		@effectdate bDate, @stddays tinyint, @amtdist bDollar, @lastpostseq smallint, @postseq smallint,
		@distamt bDollar, @postdate bDate, @numdays tinyint, @totalallowance bDollar, @totalposted bDollar,
		@procname varchar(30)
   
	select @rcode = 0, @amt = 0, @procname = 'bspPR_AU_AmtPerDay'

	-- Earnings posted to all days - use Pay Periods standard # of days 
	if @posttoall = 'Y'
		-- Earnings posted to all days - use Pay Periods standard # of days
		begin --PostToAll

		-- get standard # of days from Pay Period Control
		select @stddays = Days from dbo.bPRPC with (nolock)
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
		if @@rowcount = 0
			begin
			select @errmsg = 'PR Group and Ending Date not setup in Pay Period Control!', @rcode = 1
			goto bspexit
			end

		if @addonYN = 'Y'
			begin --when @addonYN = 'Y' compute as addon earnings and post distributions in bPRTA

			/* get Craft Effective Date with possible override by Template */
			select @effectdate = EffectiveDate from bPRCM where PRCo = @prco and Craft = @craft
			select @effectdate = EffectiveDate from bPRCT where PRCo = @prco and Craft = @craft
				and Template = @template and OverEffectDate = 'Y'

			/* get Craft, Class Addon Rates with possible override by Template - lookup 0.00 Factor */
			select @oldrate = 0.00, @newrate = 0.00
			select @oldrate = OldRate, @newrate = NewRate from bPRCI where PRCo = @prco
				and Craft = @craft and EDLType = 'E' and EDLCode = @earncode and Factor = 0.00
			select @oldrate = OldRate, @newrate = NewRate from bPRCF where PRCo = @prco
				and Craft = @craft and Class = @class and EarnCode = @earncode and Factor = 0.00
			select @oldrate = OldRate, @newrate = NewRate from bPRTI where PRCo = @prco
				and Craft = @craft and Template = @template and EDLType = 'E' and EDLCode = @earncode and Factor = 0.00
			select @oldrate = OldRate, @newrate = NewRate from bPRTF where PRCo = @prco
				and Craft = @craft and Class = @class and Template = @template and EarnCode = @earncode and Factor = 0.00

			select @totalearns = isnull(sum(Amt),0.00)
			from bPRTH h
			left outer join bJCJM j on h.JCCo = j.JCCo and h.Job = j.Job
			join bPREC e on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
			where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
				and h.Employee = @employee and h.PaySeq = @payseq
				and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)
				and h.Craft = @craft and h.Class = @class
				and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
				or (j.CraftTemplate is null and @template is null))
				and e.SubjToAddOns = 'Y'

			if @totalearns <> 0 --continue if there was something to distribute
				begin --@totalearns <> 0
				-- calculate Addon amount using Pay Pd Ending Date to determine rate
				select @addonamt = @oldrate * @stddays
				if @prenddate >= @effectdate select @addonamt = @newrate * @stddays

				-- Distribute Addon amount proportionately to all subject earnings, requires total earnings
				-- used by Flat Amount, Rate of Gross, and Rate per Day when Posting to All = 'Y' 
				-- initialize amount distributed
				select @amtdist = 0.00, @lastpostseq = 0

				-- distibute addonamt based on proportion of earnings to total earnings
				insert bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
				select @prco, @prgroup, @prenddate, @employee, @payseq, PostSeq, @earncode, 0, (Amt / @totalearns) * @addonamt
				from bPRTH h
				left outer join bJCJM j on h.JCCo = j.JCCo and h.Job = j.Job
				join bPREC e on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
				where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
					and h.Employee = @employee and h.PaySeq = @payseq
					and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)
					and h.Craft = @craft and h.Class = @class
					and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
					or (j.CraftTemplate is null and @template is null))
					and e.SubjToAddOns = 'Y'
					and h.Amt <> 0 --do not distribute to postings with 0 amount
				order by PostSeq

				--compare total posted against allowance to determine need to update the difference
				select @totalposted = sum(Amt), @lastpostseq = max(PostSeq) from dbo.bPRTA (nolock)
				where PRCo=@prco and PRGroup=@prgroup and PREndDate=@prenddate and Employee=@employee and PaySeq=@payseq
					and EarnCode=@earncode
					
				-- determine # of days - #144236
				select @numdays = count(distinct(h.PostDate))
				from bPRTH h
	    		where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
					and h.Employee = @employee and h.PaySeq = @payseq
					and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)	
					
				set @totalallowance = @numdays * @addonamt						

				if @totalallowance <> @totalposted
					begin
					-- update difference to last entry 
					update bPRTA set Amt = Amt + (@totalallowance - @totalposted)
					where  PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
					and Employee = @employee and PaySeq = @payseq and PostSeq = @lastpostseq and EarnCode = @earncode

					end

				end --@totalearns <> 0
			end --when @addonYN = 'Y'
			
		else --when @addonYN = 'N'
			begin
			select @amt = @rate * @stddays
			end

		end --PostToAll

	else --when @posttoall <> 'Y'

		begin --hours by days worked

		if @addonYN = 'Y'
			begin --when @addonYN = 'Y' compute as addon earnings and post distributions in bPRTA

			/* get Craft Effective Date with possible override by Template */
			select @effectdate = EffectiveDate from bPRCM where PRCo = @prco and Craft = @craft
			select @effectdate = EffectiveDate from bPRCT where PRCo = @prco and Craft = @craft
				and Template = @template and OverEffectDate = 'Y'

			/* get Craft, Class Addon Rates with possible override by Template - lookup 0.00 Factor */
			select @oldrate = 0.00, @newrate = 0.00
			select @oldrate = OldRate, @newrate = NewRate from bPRCI where PRCo = @prco
				and Craft = @craft and EDLType = 'E' and EDLCode = @earncode and Factor = 0.00
			select @oldrate = OldRate, @newrate = NewRate from bPRCF where PRCo = @prco
				and Craft = @craft and Class = @class and EarnCode = @earncode and Factor = 0.00
			select @oldrate = OldRate, @newrate = NewRate from bPRTI where PRCo = @prco
				and Craft = @craft and Template = @template and EDLType = 'E' and EDLCode = @earncode and Factor = 0.00
			select @oldrate = OldRate, @newrate = NewRate from bPRTF where PRCo = @prco
				and Craft = @craft and Class = @class and Template = @template and EarnCode = @earncode and Factor = 0.00

			--create table variable for all posting dates
			declare @PostDates table (PostDate bDate, TotalEarns bDollar, AllowAmt bDollar)

			insert @PostDates
			select h.PostDate, sum(h.Amt), (case when h.PostDate < @effectdate then @oldrate else @newrate end)
			from bPRTH h
			left outer join bJCJM j on h.JCCo = j.JCCo and h.Job = j.Job
			join bPREC e on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
			where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
				and h.Employee = @employee and h.PaySeq = @payseq
				and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)
				and h.Craft = @craft and h.Class = @class
				and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
				or (j.CraftTemplate is null and @template is null))
				and e.SubjToAddOns = 'Y'
			group by h.PostDate

			select @postdate=min(PostDate) from @PostDates

			while @postdate is not null
				begin
				select @totalearns=TotalEarns, @addonamt=AllowAmt from @PostDates where PostDate=@postdate

                -- skip if no positive daily earnings were found
				if @totalearns > 0.00 and @addonamt <> 0.00
					begin

					-- initialize amount already distributed 
					select @amtdist = 0.00, @lastpostseq = 0

					-- distribute addon amount for all postings for the day 
	                insert bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
					select @prco, @prgroup, @prenddate, @employee, @payseq, PostSeq, @earncode, 0, round((Amt/@totalearns)*@addonamt,2)
					from bPRTH h
	        		left outer join bJCJM j on h.JCCo = j.JCCo and h.Job = j.Job
	        		join bPREC e on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
	        		where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
		        		and h.Employee = @employee and h.PaySeq = @payseq

		        		and h.PostDate = @postdate and h.Craft = @craft and h.Class = @class
						and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)
		        		and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
		        		or (j.CraftTemplate is null and @template is null))
		        		and e.SubjToAddOns = 'Y'
					order by PostSeq

					end					
					
				select @postdate=min(PostDate) from @PostDates where PostDate>@postdate

				end --while @postdate is not null

				--compare total posted against allowance to determine need to update the difference
				select @totalposted = sum(Amt), @lastpostseq = max(PostSeq) from dbo.bPRTA (nolock)
				where PRCo=@prco and PRGroup=@prgroup and PREndDate=@prenddate and Employee=@employee and PaySeq=@payseq
					and EarnCode=@earncode
					
				-- determine # of days - #144236
				select @numdays = count(distinct(h.PostDate))
				from bPRTH h
	    		where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
					and h.Employee = @employee and h.PaySeq = @payseq
					and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)	
					
				set @totalallowance = @numdays * @addonamt						

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
			-- determine # of days
			select @numdays = count(distinct(h.PostDate))
			from bPRTH h
	    	where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
			    and h.Employee = @employee and h.PaySeq = @payseq
				and h.EarnCode in (select SubjEarnCode from bPRES s (nolock) where s.PRCo=@prco and s.EarnCode=@earncode)

			select @amt = @rate * @numdays
			end

		end --hours by days worked


	bspexit:

   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_AmtPerDay] TO [public]
GO
