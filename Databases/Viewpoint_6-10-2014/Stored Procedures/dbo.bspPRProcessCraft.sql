SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          procedure [dbo].[bspPRProcessCraft]
/***********************************************************
* CREATED:  GG  04/17/98
* MODIFIED:	GG  04/09/99
*           LM  06/15/99 - modified PRPE table to have username
*           GG 07/05/99 - added procedure check
*           GG 01/06/00 - fix AP vendor info update to bPRDT
*           GG 01/12/00 - fix to reset LiabDistBasis for each DLCode
*	       	GG 03/07/00 - fix fo set LiabDistBasis to 0 for Liabs with 0 CalcBasis
*		 	GG 08/15/00 - fix to get override rates for both dedns and liabs
*           DANF 08/18/00 - remove reference of system user id
*           GG 08/18/00 - call special routine for Iron Workers deduction
*	        GH 11/06/00 -- added isnull to @hrs when updating to bPRDT
*           GG 01/30/01 - skip calculations for both dedns and liabs if calculation basis = 0 (#11690)
*           GG 03/30/01 - fix to update bPRCA.Amt with override amount one time only
*	        GG 11/06/01 - Issue #15186 - fix bPRCA update
*		 	GG 01/11/02 - Issue #15279 - update bPRCA.EligibleAmt
*		 	MV 1/28/02 - Issue #15711 - check for correct CalcCategory , #13977 - round @calcamt if RndToDollar flag is set.
*		 	GG 02/20/02 - Issue #16216 - use job craft vendor with partial reciprocal agreements
*           EN 2/22/02 - Issue #16377 - insert bPRCX stmts were all missing field list
*		 	GH 07/01/02 - Issue #17796 - Calculate difference if rate has changed
*			GG 07/09/02	- #10865 - Update AP info to bPRCA
*			EN 10/9/02 - issue 18877 change double quotes to single
*			GG 03/07/03 - #20340 - use Vendor setup with dedn/liab as fall back if no Vendor overrides by Craft
*			EN 3/24/03 - issue 11030 rate of earnings liability limit
*			EN 8/18/03 - issue 21186 call Benefit based on day of week routine (bspPRDailyBen)
*			EN 11/20/03 - 21846 pass PRGroup & PREndDate to bspPRProcessCraftCapRate
*			EN 5/7/04 - 24542 only apply empl override rate if cap limit was not reached ... use rate returned by bspPRProcessCraftCapRate instead
*			GG 07/07/04 - #25012 & #25015 fix to capped rates with employee overrides
*			EN 7/28/04 - issue 24545  call new routine bspPRExemptRateOfGross
*			EN 9/24/04 - issue 20562  change from using bPRCO_LiabDist to bPREC_IncldLiabDist to determine whether an earnings code is included in liab distribs
*			EN 4/8/05 - issue 28379  added @@error check to see if SQL error occured when routine was called
*           AW 9/26/07 - issue 125597 & 125598 specific routine added for calculating union dues
*			CHS 10/15/2010 - #140541 - change bPRDB.EarnCode to EDLCode
*			CHS 10/28/2010 - #140541 - refactor
*
* USAGE:
* Calculates Craft deductions and liabilities for a select Employee and Pay Seq.
* Called from main bspPRProcess procedure.
* Will calculate most dedn/liab methods.
*
* INPUT PARAMETERS
*   @prco	    PR Company
*   @prgroup	PR Group
*   @prenddate	PR Ending Date
*   @employee	Employee to process
*   @payseq	Payment Sequence #
*   @ppds      # of pay periods in a year
*   @limitmth  Pay Period limit month
*   @stddays   standard # of days in Pay Period
*   @bonus     indicates a Bonus Pay Sequence - Y or N
*   @posttoall earnings posted to all days in Pay Period - Y or N
*
* OUTPUT PARAMETERS
*   @errmsg  	Error message if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
    
	@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
	@ppds tinyint, @limitmth bMonth, @stddays tinyint, @bonus bYN,
	@posttoall bYN, @errmsg varchar(255) output
    
     as
     set nocount on
    
     declare @rcode int, 
     @craft bCraft,
     @effectdate bDate, @oldcaplimit bDollar, @recipopt char(1), @template smallint,
     @class bClass, @newcaplimit bDollar, @jobcraft bCraft,  
     @cmvendorgroup bGroup, @cmvendor bVendor           
    
     -- Standard deduction/liability variables
     declare @dlcode bEDLCode 
    
     -- cursor flags
     declare @openCraft tinyint, @openCraftDL tinyint, @openFactor tinyint
    
     select @rcode = 0
    
     -- create cursor for all posted Craft, Class, and Template combinations - includes row for null Template
     declare bcCraft cursor for select distinct h.Craft, h.Class, j.CraftTemplate
     from dbo.bPRTH h
     left outer join bJCJM j on h.JCCo = j.JCCo and h.Job = j.Job
     where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate and h.Employee = @employee
     	and h.PaySeq = @payseq and h.Craft is not null and h.Class is not null
    
     open bcCraft
     select @openCraft = 1
    
     -- loop through Craft/Class/Templates
     next_Craft:
         fetch next from bcCraft into @craft, @class, @template
         if @@fetch_status = -1 goto end_Craft
         if @@fetch_status <> 0 goto next_Craft
    
         -- clear Process Earnings
         delete dbo.bPRPE where VPUserName = SUSER_SNAME()
    
         -- load Process Earnings with all earnings posted to this Craft/Class/Template
         insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt)   	-- Timecards --issue 20562
         	select SUSER_SNAME(), h.PostSeq, h.PostDate, h.EarnCode, e.Factor, e.IncldLiabDist, h.Hours, h.Rate, h.Amt --issue 20562
             from dbo.bPRTH h
             left join dbo.bJCJM j with (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
             join dbo.bPREC e with (nolock) on e.PRCo = h.PRCo and e.EarnCode = h.EarnCode
             where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
                 and h.Employee = @employee and h.PaySeq = @payseq
                 and h.Craft = @craft and h.Class = @class
                 and ((j.CraftTemplate = @template) or (h.Job is null and @template is null)
                 or (j.CraftTemplate is null and @template is null))
    
         insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt) 	-- Addons --issue 20562
             select SUSER_SNAME(), a.PostSeq, t.PostDate, a.EarnCode, e.Factor, e.IncldLiabDist, 0, a.Rate, a.Amt --issue 20562
             from dbo.bPRTA a with (nolock)
             join dbo.bPRTH t on t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate
                 and t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
             left join dbo.bJCJM j with (nolock) on t.JCCo = j.JCCo and t.Job = j.Job
             join dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
             where a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate
                 and a.Employee = @employee and a.PaySeq = @payseq
                 and t.Craft = @craft and t.Class = @class
                 and ((j.CraftTemplate = @template) or (t.Job is null and @template is null)
                 or (j.CraftTemplate is null and @template is null))
    
         -- get Craft/Class/Template info
         select @effectdate = EffectiveDate, @cmvendorgroup = VendorGroup, @cmvendor = Vendor
         from dbo.bPRCM with (nolock)
         where PRCo = @prco and Craft = @craft
         if @@rowcount = 0
             begin
             select @errmsg = 'Missing Craft ' + @craft + '.  Cannot process!', @rcode = 1
             goto bspexit
             end
         -- check for Template override
         select @effectdate = EffectiveDate
         from dbo.bPRCT with (nolock)
         where PRCo = @prco and Craft = @craft and Template = @template and OverEffectDate = 'Y'
    
         -- get Craft/Class Capped Code limits
         select @oldcaplimit = OldCapLimit, @newcaplimit = NewCapLimit
         from dbo.bPRCC with (nolock)
         where PRCo = @prco and Craft = @craft and Class = @class
         if @@rowcount = 0
             begin
             select @errmsg = 'Missing Craft/Class ' + @craft + '/' + @class + '.  Cannot process!', @rcode = 1
             goto bspexit
             end
         -- check for Template override
         select @oldcaplimit = OldCapLimit, @newcaplimit = NewCapLimit
         from dbo.bPRTC with (nolock)
         where PRCo = @prco and Craft = @craft and Class = @class and Template = @template and OverCapLimit = 'Y'
    
         -- set Reciprocal Craft defaults
         select @recipopt = 'N', @jobcraft = null
         -- check for Template override
         select @recipopt = RecipOpt, @jobcraft = JobCraft
         from dbo.bPRCT with (nolock)
         where PRCo = @prco and Craft = @craft and Template = @template
    
       -- create cursor for Craft/Class/Template DLs
      declare bcCraftDL cursor for
		-- get all DLs from Craft Items that are not marked as Pre-Tax
		select distinct EDLCode 
		from dbo.bPRCI i with (nolock) 
			join dbo.bPRDL d on d.PRCo = i.PRCo and d.DLType = i.EDLType and d.DLCode = i.EDLCode
		where i.PRCo = @prco 
			and Craft = @craft
			and (EDLType = 'D' or EDLType = 'L')
			and d.PreTax = 'N' -- we only want non-PreTax Dls as the PreTax DLs have already been calculated at this point.
			
		union

		-- get all DLs from Craft Deductions/Liabilities that are not marked as Pre-Tax		
		select distinct c.DLCode 
		from dbo.bPRCD c with (nolock) 
			join dbo.bPRDL d on d.PRCo = c.PRCo and d.DLCode = c.DLCode
		where c.PRCo = @prco 
			and c.Craft = @craft 
			and c.Class = @class
			and d.PreTax = 'N' -- we only want non-PreTax Dls as the PreTax DLs have already been calculated at this point.
			
		union
	
		-- get all DLs from Template Items that are not marked as Pre-Tax	
		select distinct t.EDLCode 
		from dbo.bPRTI t with (nolock) 
			join dbo.bPRDL d on d.PRCo = t.PRCo and d.DLType = t.EDLType and d.DLCode = t.EDLCode
		where t.PRCo = @prco 
			and Craft = @craft
			and Template = @template 
			and (EDLType = 'D' or EDLType = 'L')
			and d.PreTax = 'N' -- we only want non-PreTax Dls as the PreTax DLs have already been calculated at this point.
						
		union
		
		-- get all DLs from Template Deductions/Liabilities that are not marked as Pre-Tax			
		select distinct td.DLCode 
		from dbo.bPRTD td with (nolock)
			join dbo.bPRDL d on d.PRCo = td.PRCo and d.DLCode = td.DLCode 
		where td.PRCo = @prco 
			and td.Craft = @craft 
			and td.Class = @class
			and td.Template = @template
			and d.PreTax = 'N' -- we only want non-PreTax Dls as the PreTax DLs have already been calculated at this point.			
    
     open bcCraftDL
         select @openCraftDL = 1
    
         -- loop through Craft/Class/Template DL cursor
         next_CraftDL:
             fetch next from bcCraftDL into @dlcode
             if @@fetch_status = -1 goto end_CraftDL
             if @@fetch_status <> 0 goto next_CraftDL
             
             
        -- get a specific Craft Deduction/Liability acummulations
		exec @rcode = bspPRProcessCraftDednLiabCalc @prco, @dlcode, @prgroup, @prenddate, 
			@employee, @payseq, @ppds, @limitmth, @stddays, @bonus, @posttoall, @craft, 
			@class, @template, @effectdate, @oldcaplimit, @newcaplimit, @jobcraft, @recipopt, @errmsg output
		if @rcode <> 0 goto bspexit             
             
             

         goto next_CraftDL
    
         end_CraftDL:
             close bcCraftDL
             deallocate bcCraftDL
             select @openCraftDL = 0
             goto next_Craft
    
     end_Craft:
         close bcCraft
         deallocate bcCraft
         select @openCraft = 0
    
     bspexit:
    
         -- clear Payroll Process entries
         delete dbo.bPRPE where VPUserName = SUSER_SNAME()
    
         if @openCraftDL = 1
             begin
        		close bcCraftDL
         	deallocate bcCraftDL
           	end
         if @openCraft = 1
             begin
        		close bcCraft
         	deallocate bcCraft
           	end
         if @openFactor = 1
             begin
        		close bcFactor
         	deallocate bcFactor
           	end
    
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessCraft] TO [public]
GO
