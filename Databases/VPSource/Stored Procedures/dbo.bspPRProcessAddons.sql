SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRProcessAddons]
/***********************************************************
* CREATED BY: 	GG  01/21/1998
* MODIFIED BY:	GG  03/27/1999
*				GG	11/08/1999	- Fix for Variable Factored Addons
*				GG	03/15/2000	- fix to prevent old and new rates from reseting
*				GG	11/08/2001	- #15219 - exclude certain liabilities from capped rate total
*				GG	04/04/2002	- #16860 - pull std liab rate from bPRDL for capped codes
*				GG	08/07/2002	- #18235 - fix capped rate override
*				EN	10/09/2002	- issue 18877 change double quotes to single
*				GG	02/21/2003	- #20364 - don't include liabilities in Capped Basis if not setup with Craft or Employee
*				EN	11/20/2003	- 21846  do not include capped basis liabs in calculation where bPRED Frequency is not active for the Pay Period
*				GG	07/08/2004	- #25012 - fix capped code calcs 
*				GG	02/02/2005	- #27000 - another fix to capped code basis calculation
*				EN	08/09/2005	- #29488  fix addon earning rounding error by making sure @lastpostseq is set
*				EN	10/15/2008	- #130067  only distribute addon amounts to timecards with non-zero earnings
*				EN	03/11/2009	- #129888 add feature to execute routines using new "Routine" method for PR Earn Codes
*				EN	02/12/2010	- #132653 add ability to execute AUS AmtPerDay, OTMealAllow, OTCribAllow and OTWeekendCrib routines using specific parameters
*				EN	03/22/2010	- #128271 compute rate of gross using old and new rates based on Posted Date rather than PREndDate
*				CHS 10/15/2010	- #140541 - change bPRDB.EarnCode to EDLCode
*				CHS 10/22/2010	- #14478 Craft addon earnings
*				CHS	02/15/2011	- #142620 deal with divide by zero
*				EN	04/18/2011	- D01575 / #143739 modified to call new AllowRDO routine
*				KK/EN 06/09/2011	- TK-05849 Added code to handle CA AmtPerDay and ROSG routines
*				CHS 11/18/2011	- D-03149 correcting capped code when overtime and higher employee hourly rate.
*				CHS	01/13/2012	- D-04218 #145433 correcting capped code
*				GG/CHS	02/08/2012	- D-04493 / #145703 - allow fringe cap only
*				EN	05/15/2012	- D-04874 pass exempt limit and accumulated ytd subject amount into the bspPR_AU_ROSG routine 
*				CHS	05/16/2012	- B-09695 added calls to bspPR_AU_ROSG1 & bspPR_AU_ROSG2
*				CHS 06/05/2011	- #146557 TK-15385 D-05231
*				EN 06/05/2012 - D-05200/TK-152389/#146483 added call to bspPR_AU_AmountPerDiemAward
*				EN 08/29/2012 - D-05698/TK-17502 added params to bspPR_AU_ROSG routine call due to added feature ... 
*													routine can now be called to compute auto earnings
*				
* USAGE:
* Calculates and updates Craft/Class Addon Earnings for a selected Pay Period,
* Employee, and Payment Sequence.  Called from bspPRProcess.
*
* INPUT PARAMETERS
*   @prco	PR Company
*   @prgroup	PR Group
*   @prenddate	PR Ending Date
*   @employee	Employee to process
*   @payseq	Payment Sequence #
*   @stddays   standard # of days in Pay Period
*   @posttoall earnings posted to all days - Y or N
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
          @prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
          @stddays tinyint, @posttoall bYN, @errmsg varchar(255) output
      as
      set nocount on
      
      declare @rcode int, @craft bCraft, @class bClass, @template smallint, @addon bEDLCode,
      @addonmethod char(1), @addonamt bDollar, @newrate bUnitCost, @oldrate bUnitCost, @rate bUnitCost,
      @effectdate bDate, @postdate bDate, @totalearns bDollar, @amtdist bDollar, @distamt bDollar,
      @lastpostseq smallint, @postseq smallint, @hours bHrs, @factor bRate, @earncode bEDLCode,
      @amt bDollar, @postrate bUnitCost, @oldcap bDollar, @newcap bDollar, @cap bDollar,
      @eltype char(1), @elcode bEDLCode, @totalrate bUnitCost, @adjustrateby bUnitCost, @seq tinyint,
      @stdrate bUnitCost, @adjrate bUnitCost, @oldrate1 bUnitCost, @newrate1 bUnitCost,
	  @routine varchar(10), @procname varchar(30), --#129888
	  @StdPayOldRate bUnitCost, @StdPayNewRate bUnitCost, @StdPayRate bUnitCost,              -- CHS 11/18/2011 - D-03149
	  @PostedEarningsFactor bRate, @PrevWageAddOnRate bUnitCost, @TotalFringeRate bUnitCost,  -- CHS 11/18/2011 - D-03149
      @FactoredCapLimit bDollar, @CapBasis bDollar, @PrevailingFringe bUnitCost,              -- CHS 11/18/2011 - D-03149 CHS	01/13/2011	- D-04218
      @MiscAmt1 bDollar, @MiscAmt2 bDollar													  -- EN 6/5/2012- D-05200/TK-152389/#146483
      /* open cursor flags */
      declare @openTemplate tinyint, @openAddon tinyint, @openTimecard tinyint, @openDay tinyint, @openDistDay tinyint,
      @openDistAddon tinyint, @openBasis tinyint, @openCapSeq tinyint
      
      select @rcode = 0
      
      /* create cursor for all posted Craft, Class, and Template combinations - includes row for null Template */
      declare bcTemplate cursor for select distinct h.Craft, h.Class, j.CraftTemplate
      from bPRTH h
      left outer join bJCJM j on h.JCCo = j.JCCo and h.Job = j.Job
      where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate and h.Employee = @employee
      	and h.PaySeq = @payseq and h.Craft is not null and h.Class is not null
      
 
      /* open Template cursor */
      open bcTemplate
      select @openTemplate = 1
      
      /* loop through Template cursor */
      next_Template:
      	fetch next from bcTemplate into @craft, @class, @template
      	if @@fetch_status = -1 goto end_Template
      	if @@fetch_status <> 0 goto next_Template
      
          /* create cursor  with both std and override Addons for each Craft, Class, and Template */
      	declare bcAddon cursor for
      	select EarnCode = EDLCode
      	from bPRCI where PRCo = @prco and Craft = @craft and EDLType = 'E'
      	union
      	select EarnCode
      	from bPRCF where PRCo = @prco and Craft = @craft and Class = @class
      	union
      	select EarnCode = EDLCode
      	from bPRTI where PRCo = @prco and Craft = @craft and Template = @template and EDLType = 'E'
      	union
      	select EarnCode
      	from bPRTF where PRCo = @prco and Craft = @craft and Class = @class and Template = @template
      	order by EarnCode
      
      	/* open Addon cursor */
      	open bcAddon
      	select @openAddon = 1
      
      	/* loop through Addon cursor */
      	next_Addon:
      		fetch next from bcAddon into @addon
      		if @@fetch_status = -1 goto end_Addon
      		if @@fetch_status <> 0 goto next_Addon
      
            	/* get Addon Earnings Code info - skip if not found */
      		select @addonmethod = Method, @routine = Routine from bPREC where PRCo = @prco and EarnCode = @addon --#129888 read routine and factor
      		if @@rowcount = 0 goto next_Addon
      
      		/* get Craft Effective Date with possible override by Template */
      		select @effectdate = EffectiveDate from bPRCM where PRCo = @prco and Craft = @craft
      		select @effectdate = EffectiveDate from bPRCT where PRCo = @prco and Craft = @craft
      			and Template = @template and OverEffectDate = 'Y'
      
      		/* get Craft, Class Addon Rates with possible override by Template - lookup 0.00 Factor */
      		select @oldrate = 0.00, @newrate = 0.00
      		select @oldrate = OldRate, @newrate = NewRate from bPRCI where PRCo = @prco
      
      			and Craft = @craft and EDLType = 'E' and EDLCode = @addon and Factor = 0.00
      		select @oldrate = OldRate, @newrate = NewRate from bPRCF where PRCo = @prco
      			and Craft = @craft and Class = @class and EarnCode = @addon and Factor = 0.00
      		select @oldrate = OldRate, @newrate = NewRate from bPRTI where PRCo = @prco
      			and Craft = @craft and Template = @template and EDLType = 'E' and EDLCode = @addon and Factor = 0.00
      		select @oldrate = OldRate, @newrate = NewRate from bPRTF where PRCo = @prco
      
      			and Craft = @craft and Class = @class and Template = @template and EarnCode = @addon and Factor = 0.00
      
      		/* Flat Amount Addons */
      		if @addonmethod = 'A'
      			begin
      			-- get total earnings subject to addons - used for distribution only
              	      	select @totalearns = isnull(sum(Amt),0.00)
      			from bPRTH h
      			left outer join bJCJM j on h.JCCo = j.JCCo and h.Job = j.Job
      			join bPREC e on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
      			where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
      				and h.Employee = @employee and h.PaySeq = @payseq
      				and h.Craft = @craft and h.Class = @class
      				and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
      				or (j.CraftTemplate is null and @template is null))
      				and e.SubjToAddOns = 'Y'

      			/* use Pay Pd Ending Date to determine amount */
      			select @addonamt = @oldrate
      			if @prenddate >= @effectdate select @addonamt = @newrate
      			if @addonamt <> 0.00 goto dist_AddonAmt
      			end
      
      		/* Rate of Gross Addons */
      		else if @addonmethod = 'G'
				begin --#128271 code block replacement
				-- post addon at old rate to bPRTA 
				-- get total gross for old rate computation
				select @totalearns = isnull(sum(Amt),0.00)
					from dbo.bPRTH h (nolock)
					left outer join dbo.bJCJM j (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
					join dbo.bPREC e (nolock) on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
					where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
						and h.Employee = @employee and h.PaySeq = @payseq
							and h.Craft = @craft and h.Class = @class
						and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
							or (j.CraftTemplate is null and @template is null))
						and e.SubjToAddOns = 'Y'
						and h.PostDate < @effectdate
				if @totalearns <> 0
					begin
					-- post addon
					insert bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
					select @prco, @prgroup, @prenddate, @employee, @payseq, PostSeq, @addon, 0, round(@oldrate * Amt,2)
					from dbo.bPRTH h (nolock)
					left outer join dbo.bJCJM j (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
					join dbo.bPREC e (nolock) on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
					where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
						and h.Employee = @employee and h.PaySeq = @payseq
						and h.Craft = @craft and h.Class = @class
						and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
						or (j.CraftTemplate is null and @template is null))
						and e.SubjToAddOns = 'Y'
						and h.PostDate < @effectdate
					order by PostSeq

					-- correct for rounding error if any
					-- get amount posted at old rate and last post seq
					select @amtdist = sum(a.Amt), @lastpostseq = max(a.PostSeq) 
					from dbo.bPRTA a (nolock)	
					join dbo.bPRTH h (nolock) on h.PRCo = a.PRCo and h.PRGroup = a.PRGroup and h.PREndDate = a.PREndDate
						and h.Employee = a.Employee and h.PaySeq = a.PaySeq and h.PostSeq = a.PostSeq
					left outer join dbo.bJCJM j (nolock) on h.JCCo = j.JCCo and h.Job = j.Job --**							
					where a.PRCo=@prco and a.PRGroup=@prgroup and a.PREndDate=@prenddate and a.Employee=@employee 
						--#141478					
						and h.Craft = @craft and h.Class = @class
						and (( j.CraftTemplate = @template) or (h.Job is null and @template is null) --**
						or (j.CraftTemplate is null and @template is null)) --**
						and a.PaySeq=@payseq and a.EarnCode=@addon 
						and h.PostDate < @effectdate
						
					-- update difference, if any, to last entry
					if round((@oldrate * @totalearns),2) - @amtdist <> 0
						begin
						update bPRTA set Amt = Amt + (round((@oldrate * @totalearns),2) - @amtdist)
						where  PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
						and Employee = @employee and PaySeq = @payseq and PostSeq = @lastpostseq and EarnCode = @addon
						end
					end

				-- post addon at new rate to bPRTA 
				-- get total gross for new rate computation
				select @totalearns = isnull(sum(Amt),0.00)
					from dbo.bPRTH h (nolock)
					left outer join dbo.bJCJM j (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
					join dbo.bPREC e (nolock) on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
					where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
						and h.Employee = @employee and h.PaySeq = @payseq
							and h.Craft = @craft and h.Class = @class
						and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
							or (j.CraftTemplate is null and @template is null))
						and e.SubjToAddOns = 'Y'
						and h.PostDate >= @effectdate
				if @totalearns <> 0
					begin
					-- post addon 
					insert bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
					select @prco, @prgroup, @prenddate, @employee, @payseq, PostSeq, @addon, 0, round(@newrate * Amt,2)
					from dbo.bPRTH h (nolock)
					left outer join dbo.bJCJM j (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
					join dbo.bPREC e (nolock) on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
					where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
						and h.Employee = @employee and h.PaySeq = @payseq
						and h.Craft = @craft and h.Class = @class
						and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
						or (j.CraftTemplate is null and @template is null))
						and e.SubjToAddOns = 'Y'
						and h.PostDate >= @effectdate
					order by PostSeq

					-- correct for rounding error if any
					-- get amount posted at new rate and last post seq
					select @amtdist = sum(a.Amt), @lastpostseq = max(a.PostSeq) 
					from dbo.bPRTA a (nolock)
					join dbo.bPRTH h (nolock) on h.PRCo = a.PRCo and h.PRGroup = a.PRGroup and h.PREndDate = a.PREndDate
						and h.Employee = a.Employee and h.PaySeq = a.PaySeq and h.PostSeq = a.PostSeq
					left outer join dbo.bJCJM j (nolock) on h.JCCo = j.JCCo and h.Job = j.Job --**							
					where a.PRCo=@prco and a.PRGroup=@prgroup and a.PREndDate=@prenddate and a.Employee=@employee 
						--#141478
						and h.Craft = @craft and h.Class = @class
						and (( j.CraftTemplate = @template) or (h.Job is null and @template is null) --**
						or (j.CraftTemplate is null and @template is null)) --**						
						and a.PaySeq=@payseq and a.EarnCode=@addon 
						and h.PostDate >= @effectdate
						
					-- update difference, if any, to last entry
					if round((@newrate * @totalearns),2) - @amtdist <> 0
						begin
						update bPRTA set Amt = Amt + (round((@newrate * @totalearns),2) - @amtdist)
						where  PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
						and Employee = @employee and PaySeq = @payseq and PostSeq = @lastpostseq and EarnCode = @addon
						end
					end

				end --end #128271 code block replacement

    
      		/* Rate per Hour, Factored Rate per Hour, and Variable Rate per Hour */
      		else if @addonmethod in ('H', 'F', 'V')
      			BEGIN --addonmethod in H,F,V
      			
      			-- CHS 11/18/2011 - D-03149 
      			-- set our variables to 0 before starting
      			SELECT @StdPayRate = 0.00, @StdPayOldRate = 0.00, @StdPayNewRate = 0.00, 
      					@TotalFringeRate = 0.00, @FactoredCapLimit = 0.00, @PrevWageAddOnRate = 0.00
      					
      					
      			-- CHS 11/18/2011 - D-03149      			    			
      			-- need to get std pay rate for the craft,class, and template
      			-- bPRCP - PR Craft Classes -> Pay Rates tab
      			-- we'll grab the lowest priority from bPRCP first
      			SELECT top 1 @StdPayOldRate = OldRate, @StdPayNewRate = NewRate 
      			FROM bPRCP
      			WHERE PRCo = @prco
      				AND Craft = @craft 
      				AND Class = @class
      			ORDER BY PRCo, Craft, Class, Shift
      			
      			-- CHS 11/18/2011 - D-03149
      			-- bPRTP Craft Class Templates -> Pay Rates tab
      			-- if there is a pay rate defined in bPRTP it has higher priority
      			SELECT top 1 @StdPayOldRate = OldRate, @StdPayNewRate = NewRate 
      			FROM bPRTP
      			WHERE PRCo = @prco
					AND Craft = @craft 
					AND Class = @class 
					AND Template = @template 
      			ORDER BY PRCo, Craft, Class, Shift
   			
      			
				/* declare cursor on Timecards subject to Addon */
				DECLARE bcTimecard CURSOR FOR
				SELECT h.PostSeq, h.PostDate, h.EarnCode, h.Hours, h.Rate, 
				e.Factor -- added factor for hourly rate calculations CHS 11/18/2011 - D-03149
				FROM bPRTH h
					LEFT OUTER JOIN bJCJM j ON h.JCCo = j.JCCo AND h.Job = j.Job
					JOIN bPREC e ON h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
				WHERE h.PRCo = @prco 
					AND h.PRGroup = @prgroup 
					AND h.PREndDate = @prenddate
					AND h.Employee = @employee 
					AND h.PaySeq = @payseq
					AND h.Craft = @craft 
					AND h.Class = @class
					AND (( j.CraftTemplate = @template) OR (h.Job IS NULL AND @template IS NULL)
														OR (j.CraftTemplate IS NULL and @template IS NULL))
					AND e.SubjToAddOns = 'Y'
      
      			/* open Timecard cursor */
      			OPEN bcTimecard
      			SELECT @openTimecard = 1
      
      			/* loop through rows in Timecard cursor */
      			next_Timecard:
      				fetch next from bcTimecard into @postseq, @postdate, @earncode, @hours, @postrate, 
      						@PostedEarningsFactor -- added factor for hourly rate calculations CHS 11/18/2011 - D-03149

                    if @@fetch_status = -1 goto end_Timecard
      				if @@fetch_status <> 0 goto next_Timecard
      
      				/* Rate per Hour */
      				if @addonmethod = 'H'
      					begin --addonmethod H
                        select @rate = @oldrate
      					if @postdate >= @effectdate select @rate = @newrate
      					
      					
      					-- CHS 11/18/2011 - D-03149
      					-- select the appropriate rate (old vs new) depending on the effective date
						SELECT @StdPayRate = @StdPayOldRate
						IF @postdate >= @effectdate SELECT @StdPayRate = @StdPayNewRate
      					
                          /* check for capped code - may reduce addon rate */
      					if exists(select 1 from bPRCS where PRCo = @prco and Craft = @craft and ELType = 'E' and ELCode = @addon)
      						begin
      						/* check cap limit by Craft and Class - with possible override by Template */
      						select @oldcap = 0.00, @newcap = 0.00
      						select @oldcap = OldCapLimit, @newcap = NewCapLimit
      							from bPRCC where PRCo = @prco and Craft = @craft and Class = @class
      						select @oldcap = OldCapLimit, @newcap = NewCapLimit
      						from bPRTC
     						where PRCo = @prco and Craft = @craft and Class = @class and Template = @template
     							and OverCapLimit = 'Y'	-- #18235
      						select @cap = @oldcap
      						if @postdate >= @effectdate select @cap = @newcap
      						
    
    
							SELECT @PrevailingFringe = 0.00, @TotalFringeRate = 0.00, @PrevWageAddOnRate = 0.00  -- CHS 11/18/2011 - D-03149, CHS 01/13/2011	- D-04218
    
      						/* continue with capped code calcs if cap limit > 0 */
      						if @cap > 0.00
      							begin
      							/* use cursor to cycle through all basis earnings and liabs to accumulate total fringe and add-ons */
      							declare bcBasis cursor for
      							select ELType, ELCode from bPRCB where PRCo = @prco and Craft = @craft
      
      							open bcBasis
      							select @openBasis = 1, @totalrate = 0.00
      
      							/* loop through rows in Capped Code Basis cursor */
      							next_Basis:
      								fetch next from bcBasis into @eltype, @elcode
      								if @@fetch_status = -1 goto end_Basis
      								if @@fetch_status <> 0 goto next_Basis
      
      								-- skip liabilities that don't include the posted earnings in their basis
      								if @eltype = 'L' and
      									(select count(*) from bPRDB where PRCo = @prco and DLCode = @elcode and EDLCode = @earncode)= 0 goto next_Basis
      								

      								if @eltype = 'E'
      									BEGIN
      									
      										begin
      										/* must be an Addon - get rate */
      										select @oldrate1 = 0.00, @newrate1 = 0.00
      										
      										select @oldrate1 = OldRate, @newrate1 = NewRate 
      										from bPRCI 
      										where PRCo = @prco
      											and Craft = @craft 
      											and EDLType = 'E' 
      											and EDLCode = @elcode 
      											and Factor = 0.00      											
      										
      										-- check for override rates	
      										select @oldrate1 = OldRate, @newrate1 = NewRate 
      										from bPRCF 
      										where PRCo = @prco
      											and Craft = @craft 
      											and Class = @class 
      											and EarnCode = @elcode 
      											and Factor = 0.00
      											
      										select @oldrate1 = OldRate, @newrate1 = NewRate 
      										from bPRTI 
      										where PRCo = @prco
      											and Craft = @craft 
      											and Template = @template 
      											and EDLType = 'E'
      											and EDLCode = @elcode 
      											and Factor = 0.00 
      											     
      										select @oldrate1 = OldRate, @newrate1 = NewRate 
      										from bPRTF 
      										where PRCo = @prco
      											and Craft = @craft 
      											and Class = @class 
      											and Template = @template
      											and EarnCode = @elcode 
      											and Factor = 0.00
      											
      										/* accumulate total rate */
      										-- we need to sum up the add on rate for the prevailing in order to calculate the cap basis and the factored cap limit.
      										IF @postdate < @effectdate SELECT @PrevWageAddOnRate = @PrevWageAddOnRate + @oldrate1  -- CHS 11/18/2011 - D-03149
      										IF @postdate >= @effectdate SELECT @PrevWageAddOnRate = @PrevWageAddOnRate + @newrate1 -- CHS 11/18/2011 - D-03149
      										
      										end -- else
      										
      									end -- if @eltype = 'E'
      									
      								else
      									begin
      									/* must be a Liability  - get rate */
      									select @oldrate1 = 0.00, @newrate1 = 0.00
     								
     									-- #20364 - skip liabilities not setup with Craft or Employee
     									if not exists(select 1 from bPRCI      -- Craft Items
     							         			where PRCo = @prco and Craft = @craft and EDLType = 'L' and EDLCode = @elcode)
     									and not exists(select 1 from bPRED		-- Employee 
     							        			where PRCo = @prco and Employee = @employee and DLCode = @elcode) goto next_Basis
     
      									select @oldrate1 = RateAmt1, @newrate1 = RateAmt1
      									from bPRDL		-- DL master
     									where PRCo = @prco and DLCode = @elcode	-- std rate
      									select @oldrate1 = OldRate, @newrate1 = NewRate
     									from bPRCI		-- Craft Items
     									where PRCo = @prco and Craft = @craft and EDLType = 'L' and EDLCode = @elcode and Factor = 0.00
      									
     									select @oldrate1 = OldRate, @newrate1 = NewRate
     									from bPRCD		-- Class Dedns/Liabs
     									where PRCo = @prco and Craft = @craft and Class = @class and DLCode = @elcode and Factor = 0.00
      									select @oldrate1 = OldRate, @newrate1 = NewRate
     									from bPRTI		-- Template Items
     									where PRCo = @prco and Craft = @craft and Template = @template and EDLType = 'L'
      										and EDLCode = @elcode and Factor = 0.00
      									select @oldrate1 = OldRate, @newrate1 = NewRate
     									from bPRTD 		-- Template Dedns/Liabs
     									where PRCo = @prco and Craft = @craft and Class = @class and Template = @template
      										and DLCode = @elcode and Factor = 0.00
      
      									/* check for Employee override - use a single rate */
      									select @oldrate1 = e.RateAmt, @newrate1 = e.RateAmt
   										from bPRED e
     									where e.PRCo = @prco and e.Employee = @employee and e.DLCode = @elcode and 
     										e.OverCalcs = 'R' and
   										(e.EmplBased = 'N' or (e.EmplBased = 'Y' and 	-- #25012 fixed for Employee Based
     										exists (select top 1 1 from dbo.bPRAF a (nolock) where a.PRCo=e.PRCo and a.PRGroup=@prgroup and -- #27000 correct logic for employee based liabs
     												a.PREndDate=@prenddate and a.Frequency=e.Frequency))) -- issue 21846 add frequency check
     									
      									/* accumulate total rate */
        								if @postdate < @effectdate select @TotalFringeRate = @TotalFringeRate + @oldrate1  -- CHS 11/18/2011 - D-03149
      									if @postdate >= @effectdate select @TotalFringeRate = @TotalFringeRate + @newrate1 -- CHS 11/18/2011 - D-03149
    									
     
      									end
      								goto next_Basis
      							end_Basis:
      								close bcBasis
      								deallocate bcBasis
      								select @openBasis = 0
      								
      								
									-- #145703 - check for posted earnings code included in cap basis
      								IF EXISTS(SELECT 1 FROM dbo.bPRCB WHERE PRCo = @prco AND Craft = @craft AND ELType = 'E' AND ELCode = @earncode)
      									BEGIN
  										-- posted earnings code is included in cap basis, add-on adjustment will include posted earnings
  								  		SELECT @PrevailingFringe = @cap - @StdPayRate
  										-- CHS	01/13/2011	- D-04218
  										-- we need to factor the cap limit so we can get a cap limit when we have over time and double time pay.
  										SELECT @FactoredCapLimit = (@StdPayRate * @PostedEarningsFactor) + @PrevailingFringe
  										-- CHS	01/13/2011	- D-04218
  										-- we need to some the total earnings in order that we can compare it to the cap limit.
  										SELECT @CapBasis = @postrate + @TotalFringeRate + @PrevWageAddOnRate -- should include posted earnings CHS
  										-- CHS	01/13/2011	- D-04218
  										-- now that we have a cap basis, we can compare that to the limit and adjust the add on earnings accordingly. 								
										SELECT @adjustrateby =  @CapBasis - @FactoredCapLimit
										END	
									ELSE
										BEGIN
										-- posted earnings excluded from cap basis (and cap limit), no need to factor, add-on adjust based on fringes only
										SELECT @adjustrateby =  @TotalFringeRate + @PrevWageAddOnRate - @cap		
										END      								
									
			
      								if @adjustrateby > 0.00
      									begin
      									/* use a cursor to process capped codes in Sequence order */
      									declare bcCapSeq cursor for
      									select Seq, ELType, ELCode from bPRCS where PRCo = @prco and Craft = @craft
      									order by Seq
      									open bcCapSeq
      									select @openCapSeq = 1
      									next_CapSeq:
      										fetch next from bcCapSeq into @seq, @eltype, @elcode
      										if @@fetch_status = -1 goto end_CapSeq
      										if @@fetch_status <> 0 goto next_CapSeq
    										
      										if @eltype = 'E'
      											begin
      											/* get Addon rate */
      											select @oldrate1 = 0.00, @newrate1 = 0.00
      
      											select @oldrate1 = OldRate, @newrate1 = NewRate from bPRCI where PRCo = @prco
      												and Craft = @craft and EDLType = 'E' and EDLCode = @elcode and Factor = 0.00
      											select @oldrate1 = OldRate, @newrate1 = NewRate from bPRCF where PRCo = @prco
      												and Craft = @craft and Class = @class and EarnCode = @elcode and Factor = 0.00
      											select @oldrate1 = OldRate, @newrate1 = NewRate from bPRTI where PRCo = @prco
      												and Craft = @craft and Template = @template and EDLType = 'E'
      												and EDLCode = @elcode and Factor = 0.00
      											select @oldrate1 = OldRate, @newrate1 = NewRate from bPRTF where PRCo = @prco
      												and Craft = @craft and Class = @class and Template = @template
      												and EarnCode = @elcode and Factor = 0.00
      											end
      										else
      											begin
      											/* must be a Liability  - get rate */
      											select @oldrate1 = 0.00, @newrate1 = 0.00
      											select @oldrate1 = RateAmt1, @newrate1 = RateAmt1
      											from bPRDL where PRCo = @prco and DLCode = @elcode	-- std rate
      											select @oldrate1 = OldRate, @newrate1 = NewRate from bPRCI where PRCo = @prco
      												and Craft = @craft and EDLType = 'L' and EDLCode = @elcode and Factor = 0.00
      											select @oldrate1 = OldRate, @newrate1 = NewRate from bPRCD where PRCo = @prco
      												and Craft = @craft and Class = @class and DLCode = @elcode and Factor = 0.00
      											select @oldrate1 = OldRate, @newrate1 = NewRate from bPRTI where PRCo = @prco
      												and Craft = @craft and Template = @template and EDLType = 'L'
      												and EDLCode = @elcode and Factor = 0.00
      											select @oldrate1 = OldRate, @newrate1 = NewRate from bPRTD where PRCo = @prco
      												and Craft = @craft and Class = @class and Template = @template
      												and DLCode = @elcode and Factor = 0.00
      
      											/* check for Employee override - use a single rate */
      											select @oldrate1 = RateAmt, @newrate1 = RateAmt from bPRED where PRCo = @prco
      												and Employee = @employee and DLCode = @elcode and OverCalcs = 'R'
      											end
      
      										/* adjust capped code rate */
      										select @stdrate = @oldrate1
      										if @postdate >= @effectdate select @stdrate = @newrate1
      										
      										
      										
       										select @adjrate = @stdrate - @adjustrateby
      										if @adjrate < 0.00 select @adjrate = 0.00
      
      										/* if the adjusted code equals our current Addon, were done */
      										if @elcode = @addon
      											begin
      											select @rate = @adjrate
      											goto end_CapSeq
      											end
  
      										/* correct total rate and see if another capped code needs to be reduced */
      										select @adjustrateby = @adjustrateby - @stdrate			-- CHS 11/18/2011 - D-03149
      										
      										if @adjustrateby > 0.00 goto next_CapSeq        
      										
      
      									end_CapSeq:
      										close bcCapSeq
      										deallocate bcCapSeq
      										select @openCapSeq = 0
      									end
      							end
      						end
      					calc_RatePerHour:
      					
      						select @addonamt = @rate * @hours
					
			
                          end --addonmethod H
      				/* Factored Rate per Hour */
      				if @addonmethod = 'F'
      					begin --addonmethod F
      					/* get Factor for posted Earnings Code */
      					select @factor = 1.00
      					select @factor = Factor from bPREC where PRCo = @prco and EarnCode = @earncode
      
      					/* apply Factor to Rate and calculate Addon */
      					select @rate = @oldrate * @factor
      					if @postdate >= @effectdate select @rate = @newrate * @factor
      					select @addonamt = @rate * @hours
      					end --addonmethod F
      
      				/* Variable Rate per Hour */
      				if @addonmethod = 'V'
      					begin --addonmethod V
      					/* get Factor for posted Earnings Code */
      					select @factor = 1.00
      					select @factor = Factor from bPREC where PRCo = @prco and EarnCode = @earncode
      
      					/* get Craft, Class Addon Rate based on Factor with possible override by Template*/
      					select @oldrate = 0.00, @newrate = 0.00
                          select @oldrate = OldRate, @newrate = NewRate from bPRCI where PRCo = @prco
      						and Craft = @craft and EDLType = 'E' and EDLCode = @addon and Factor = @factor
      					select @oldrate = OldRate, @newrate = NewRate from bPRCF where PRCo = @prco
      						and Craft = @craft and Class = @class and EarnCode = @addon and Factor = @factor
                          select @oldrate = OldRate, @newrate = NewRate from bPRTI where PRCo = @prco
      						and Craft = @craft and Template = @template and EDLType = 'E' and EDLCode = @addon
                              and Factor = @factor
      					select @oldrate = OldRate, @newrate = NewRate from bPRTF where PRCo = @prco
      						and Craft = @craft and Class = @class and Template = @template
      						and EarnCode = @addon and Factor = @factor
      
      
      					/* apply Old or New Rate */
      					select @rate = @oldrate
      					if @postdate >= @effectdate select @rate = @newrate
      
      					select @addonamt = @rate * @hours
      					end --addonmethod V
      
      				/* add Timecard Addon entry */
      				if @addonamt <> 0.00
                        begin
      					insert bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
      					values (@prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @addon, @rate, @addonamt)
      					end
      				goto next_Timecard
      
      			end_Timecard:
      
      				close bcTimecard
      				deallocate bcTimecard
      				select @openTimecard = 0
                    goto next_Addon
      			end --addonmethod in H,F,V
      
      		/* Rate per Day */
      		else if @addonmethod = 'D'
      			begin --RateperDay
      			/* Earnings posted to all days - use Pay Periods standard # of days */
      			if @posttoall = 'Y'
      				begin --if posttoall
      				-- get total earnings subject to addons - used for distribution only
              	      		select @totalearns = isnull(sum(Amt),0.00)
      				from bPRTH h
      				left outer join bJCJM j on h.JCCo = j.JCCo and h.Job = j.Job
      				join bPREC e on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
      				where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
      					and h.Employee = @employee and h.PaySeq = @payseq
      					and h.Craft = @craft and h.Class = @class
      					and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
      					or (j.CraftTemplate is null and @template is null))
      					and e.SubjToAddOns = 'Y'

      				-- calculate Addon amount using Pay Pd Ending Date to determine rate
      				select @addonamt = @oldrate * @stddays
      				if @prenddate >= @effectdate select @addonamt = @newrate * @stddays
      				if @addonamt <> 0.00 goto dist_AddonAmt
      				end --if posttoall
      			else
      				/* use cursor to process each day worked */
      				begin --use cursor
                      		declare bcDay cursor for
      				select distinct(h.PostDate)
      				from bPRTH h
      			    	left outer join bJCJM j on h.JCCo = j.JCCo and h.Job = j.Job
      			    	join bPREC e on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
      			    	where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
      				    and h.Employee = @employee and h.PaySeq = @payseq
      				    and h.Craft = @craft and h.Class = @class
      					and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
      				    or (j.CraftTemplate is null and @template is null))
      				    and e.SubjToAddOns = 'Y'
      
                     	/* open Day cursor */
      				open bcDay
      				select @openDay = 1
      
      				/* loop through rows in Day cursor */
      				next_Day:
      					fetch next from bcDay into @postdate
      					if @@fetch_status = -1 goto end_Day
      					if @@fetch_status <> 0 goto next_Day
      
      					/* get daily earnings subject to addons */
                         	select @totalearns = isnull(sum(Amt),0.00)
      					from bPRTH h
      		        	left outer join bJCJM j on h.JCCo = j.JCCo and h.Job = j.Job
      		        	join bPREC e on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
      		        	where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
      			        	and h.Employee = @employee and h.PaySeq = @payseq
      			        	and h.PostDate = @postdate and h.Craft = @craft and h.Class = @class
      			        	and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
      			        	or (j.CraftTemplate is null and @template is null))
      			        	and e.SubjToAddOns = 'Y'
      
                          			/* skip if daily earnings are not positive */
      					if @totalearns <= 0.00 goto next_Day
      
      					/* use Post Date to determine rate/amt */
      					select @addonamt = @oldrate
      					if @postdate >= @effectdate select @addonamt = @newrate
      					if @addonamt = 0.00 goto next_Day
      
      					/* initialize amount distributed */
      					select @amtdist = 0.00, @lastpostseq = 0
      
      					/* distribute addon amount for the day */
                         			declare bcDistDay cursor for
      					select PostSeq, Amt
      					from bPRTH h
      		        	left outer join bJCJM j on h.JCCo = j.JCCo and h.Job = j.Job
      		        	join bPREC e on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
      		        	where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
      			        	and h.Employee = @employee and h.PaySeq = @payseq
      
      			        	and h.PostDate = @postdate and h.Craft = @craft and h.Class = @class
      			        	and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
      			        	or (j.CraftTemplate is null and @template is null))
      			        	and e.SubjToAddOns = 'Y'
   					order by PostSeq
      
                         			/* open DistDay cursor */
      					open bcDistDay
      					select @openDistDay = 1
      
      					/* loop through rows in DistDay cursor */
      					next_Seq:
      						fetch next from bcDistDay into @postseq, @amt
      						if @@fetch_status = -1 goto end_Seq
      						if @@fetch_status<> 0 goto next_Seq
      
      						/* distibute based on proportion of earnings to total daily earnings */
      						--#142620
      						--select @distamt = (@amt/@totalearns) * @addonamt
      						select @distamt = CASE WHEN @totalearns = 0.00 THEN 0.00
      									ELSE (@amt/@totalearns) * @addonamt END    						
      						
                             				insert bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
      						values (@prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @addon, 0, @distamt)
      
      						/* accumulate amount distributed and save last posting seq# */
      						select @amtdist = @amtdist + @distamt, @lastpostseq = @postseq --issue 29488
      						goto next_Seq
      
      					end_Seq:
      						/* update difference to last entry for the day */
      						update bPRTA set Amt = Amt + @addonamt - @amtdist
      						where  PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
      						and Employee = @employee and PaySeq = @payseq and PostSeq = @lastpostseq and EarnCode = @addon
      
      						/* finished with the day */
      						close bcDistDay
      						deallocate bcDistDay
      						select @openDistDay = 0
      						goto next_Day
      
      				end_Day:
      					begin --end_Day
      					close bcDay
      					deallocate bcDay
      					select @openDay = 0
      					end --end_Day
      				end --use cursor
      			end --RatePerDay

      		/* Routine - added for #129888 */
      		else if @addonmethod = 'R'
				begin --Routine
				if @routine is null
					begin
					select @errmsg = 'Missing Routine for earn code ' + convert(varchar(4),@addon), @rcode = 1
					goto bspexit
					end
 				-- get procedure name
 				select	@procname = ProcName, 
 						@MiscAmt1 = MiscAmt1,		-- EN 5/14/2012 D-04874
 						@MiscAmt2 = MiscAmt2		-- EN 6/5/2012- D-05200/TK-152389/#146483
 				from dbo.bPRRM with (nolock)
 				where PRCo = @prco and Routine = @routine
 				if @procname is null
 					begin
 					select @errmsg = 'Missing Routine procedure name for earn code ' + convert(varchar(4),@addon), @rcode = 1
 					goto bspexit
					end
				if not exists(select * from sysobjects where name = @procname and type = 'P')
					begin
					select @errmsg = 'Invalid Routine procedure - ' + @procname, @rcode = 1
					goto bspexit
					end

				select @rate = @newrate

				--call routine procedure to compute allowance (rate per hour) or leave loading (rate of gross) addon
				--these routines also post addon to bPRTA
				if @procname in ('bspPR_AU_AllowWithRDOFactor', 'bspPR_AU_AllowRDO36', 'bspPR_AU_AllowRDO38') --compute rate per hour allowance
					begin
    				exec @rcode = @procname @prco, @addon, @prgroup, @prenddate, @employee, @payseq, 
									@craft, @class, @template, @rate, @errmsg output
   					if @@error <> 0 select @rcode = 1
    				if @rcode <> 0 goto bspexit
					end

									
				-- EN 5/14/2012 D-04874 (split out calls to AUS and CA routines in order to pass additional info to AUS routine)
				ELSE IF @procname in ('bspPR_AU_ROSG') --compute rate of gross addon for Australia, eg. leave loading
				BEGIN
					--get accumulated YTD earnings for the earn code
					DECLARE @ytdearns bDollar
					EXEC	@rcode = [dbo].[vspPRProcessGetAccumSubjEarnAUS]
							@prco = @prco,
							@prgroup = @prgroup,
							@prenddate = @prenddate,
							@employee = @employee,
							@earncode = @addon,
							@payseq = @payseq,
							@ytdearns = @ytdearns OUTPUT,
							@errmsg = @errmsg OUTPUT
					--compute the addon and post to PRTA
    				EXEC @rcode = @procname @prco,
    										@earncode = @addon,
											@addonYN = 'Y',
											@prgroup = @prgroup,
											@prenddate = @prenddate, 
    										@employee = @employee,	
    										@payseq = @payseq,
    										@craft = @craft,			
    										@class = @class, 
    										@template = @template,	
    										@rate = @rate,		
    										@ytdearns = @ytdearns,		
    										@exemptamt = @MiscAmt1,
    										@amt = @amt OUTPUT, 
    										@errmsg = @errmsg OUTPUT
   					IF @@error <> 0 SELECT @rcode = 1
    				IF @rcode <> 0 GOTO bspexit
				END
				ELSE IF @procname = 'bspPR_CA_ROSG' --compute rate of gross addon for Canada
				BEGIN
    				EXEC @rcode = @procname @prco,		@addon,		@prgroup,		@prenddate, 
    										@employee,	@payseq,	@craft,			@class, 
    										@template,	@rate,
    										@errmsg OUTPUT
   					IF @@error <> 0 SELECT @rcode = 1
    				IF @rcode <> 0 GOTO bspexit
				END
				
				--#132653 added AUS AmtPerDay, OTMealAllow, OTCribAllow and OTWeekendCrib routine executes
				else if @procname IN ('bspPR_AU_AmtPerDay', 'bspPR_CA_AmtPerDay') --compute amount per day based on subject earnings, eg. Fare allow/1st aid/Travel allow
					begin
    				exec @rcode = @procname @prco, @earncode = @addon, @prgroup = @prgroup, @prenddate = @prenddate,
									@employee = @employee, @payseq = @payseq, @craft = @craft, @class = @class, 
									@template = @template, @posttoall = @posttoall, @addonYN = 'Y', @rate = 0, 
									@amt = @amt output, @errmsg = @errmsg output
   					if @@error <> 0 select @rcode = 1
    				if @rcode <> 0 goto bspexit
					end

				-- EN 06/05/2012	- D-05200/TK-152389/#146483
				ELSE IF @procname = 'bspPR_AU_AmountPerDiemAward' --compute amount per day award with hours thresholds from Routine Master
				BEGIN
					EXEC @rcode = @procname @prco,							--PR Company
											@earncode = @addon,				--Auto Earning Code
											@addonYN = 'Y',					--Flag indicating an amount is being computed for addon earning
											@prgroup = @prgroup,			--PR Group of pay period to which the auto earnings is being applied
											@prenddate = @prenddate,		--Pay Period Ending Date
											@employee = @employee,			--Employee
											@payseq = @payseq,				--Pay Sequence
											@weekdaythreshold = @MiscAmt1,	--hours threshold for weekdays
											@weekendthreshold = @MiscAmt2,	--hours threshold for weekends
											@craft = @craft,				--craft to use when determining days from timecards 
											@class = @class,				--class to use when determining days from timecards 
											@template = @template, 			--job template to use when determining days from timecards
											@rate = @rate,					--per day amount to compute
											@amt = @amt OUTPUT,				--amount of award
											@errmsg = @errmsg OUTPUT
					IF @@error <> 0 SELECT @rcode = 1
					IF @rcode <> 0 GOTO bspexit
				END

				-- CHS 06/05/2011	- #146557 TK-15385 D-05231					
				ELSE IF @procname IN ('bspPR_AU_Allowance')
					BEGIN
    				EXEC @rcode = @procname @prco, @earncode = @addon, @addonYN = 'Y', @prgroup = @prgroup, 
									@prenddate = @prenddate, @employee = @employee, @payseq = @payseq, 
									@craft = @craft, @class = @class, @template = @template, 
									@rate = @rate, @amt = @amt OUTPUT, @errmsg = @errmsg OUTPUT
   					IF @@error <> 0 SELECT @rcode = 1
    				IF @rcode <> 0 GOTO bspexit
					END					

				-- CHS 06/05/2011	- #146557 TK-15385 D-05231					
				ELSE IF @procname IN ('bspPR_AU_OTMealAllow', 'bspPR_AU_OTCribAllow', 'bspPR_AU_OTWeekendCrib')
					BEGIN
    				EXEC @rcode = @procname @prco, @earncode = @addon, @addonYN = 'Y', @prgroup = @prgroup, 
									@prenddate = @prenddate, @employee = @employee, @payseq = @payseq, 
									@craft = @craft, @class = @class, @template = @template, 
									@rate = 0, @amt = @amt OUTPUT, @errmsg = @errmsg OUTPUT
   					IF @@error <> 0 SELECT @rcode = 1
    				IF @rcode <> 0 GOTO bspexit
					END					


				end --Routine
      		goto next_Addon
      
      end_Addon:
      	close bcAddon
      	deallocate bcAddon
      	select @openAddon = 0
      	goto next_Template
      
      end_Template:
      	close bcTemplate
      	deallocate bcTemplate
      	select @openTemplate = 0
          	goto bspexit
      
      /* Distribute Addon amount proportionately to all subject earnings, requires total earnings
       - used by Flat Amount, Rate of Gross, and Rate per Day when Posting to All = 'Y' */
      dist_AddonAmt:
      	-- initialize amount distributed
      	select @amtdist = 0.00, @lastpostseq = 0
      
      	-- create a cursor with Posted Earnings using Timecards
          	declare bcDistAddon cursor for
      	select PostSeq, Amt
      	from bPRTH h
      	left outer join bJCJM j on h.JCCo = j.JCCo and h.Job = j.Job
      	join bPREC e on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
      	where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
      		and h.Employee = @employee and h.PaySeq = @payseq
      		and h.Craft = @craft and h.Class = @class
      		and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
      		or (j.CraftTemplate is null and @template is null))
      		and e.SubjToAddOns = 'Y'
      		and h.Amt <> 0 --#130067
      	order by PostSeq
      
          	/* open  cursor */
      	open bcDistAddon
      	select @openDistAddon = 1
      
      	-- loop through Timecard cursor to distribute Addon amount
      	next_Seq1:
      		fetch next from bcDistAddon into @postseq, @amt
      		if @@fetch_status = -1 goto end_Seq1
      		if @@fetch_status <> 0 goto next_Seq1
      
      		/* distibute based on proportion of earnings to total earnings */
      		select @distamt = 0.00
      		if @totalearns <> 0.00 select @distamt = (@amt/@totalearns) * @addonamt
      		insert bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
      		values (@prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @addon, 0, @distamt)
      
      		/* accumulate amount distributed and save last posting seq# */
      		select @amtdist = @amtdist + @distamt, @lastpostseq = @postseq --issue 29488
      		goto next_Seq1
      
      	end_Seq1:
      		/* update difference to last entry */
      		update bPRTA set Amt = Amt + @addonamt - @amtdist
      			where  PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
      			and Employee = @employee and PaySeq = @payseq and PostSeq = @lastpostseq
      			and EarnCode = @addon
      
      		/* finished with addon */
      		close bcDistAddon
      
      		deallocate bcDistAddon
      		select @openDistAddon = 0
      		goto next_Addon
      
      bspexit:
      	if @openTemplate = 1
      		begin
      		close bcTemplate
      		deallocate bcTemplate
      		end
      	if @openAddon = 1
      		begin
      		close bcAddon
      		deallocate bcAddon
     
      		end
      	if @openTimecard = 1
      		begin
      		close bcTimecard
      		deallocate bcTimecard
      		end
      	if @openDay = 1
      		begin
      		close bcDay
      		deallocate bcDay
      		end
      	if @openDistDay = 1
      		begin
      		close bcDistDay
      		deallocate bcDistDay
      		end
      	if @openDistAddon = 1
      		begin
      		close bcDistAddon
      		deallocate bcDistAddon
      		end
      	if @openBasis = 1
      		begin
      		close bcBasis
      		deallocate bcBasis
      		end
      	if @openCapSeq = 1
      		begin
      		close bcCapSeq
      		deallocate bcCapSeq
      		end
      
          return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessAddons] TO [public]
GO
