SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRProcessCraftBasis    Script Date: 8/28/99 9:35:36 AM ******/
CREATE     procedure [dbo].[bspPRProcessCraftBasis]
/***********************************************************
* CREATED BY: 	 GG  04/10/98
* MODIFIED BY:    GG  04/15/98
*				EN 10/9/02 - issue 18877 change double quotes to single
*				EN 9/24/04 - issue 20562  change from using bPRCO_LiabDist to bPREC_IncldLiabDist to determine whether an earnings code is included in liab distribs
*				CHS 10/15/2010 - #140541 - change bPRDB.EarnCode to EDLCode   
*				CHS 02/17/2010 - #142620 Prevent divide by zero
*
* USAGE:
* Calculates basis amounts for Craft deductions and liabilities
* Called from bspPRProcessCraft procedure for each dedn/liab code.
*
* INPUT PARAMETERS
*   @prco          PR Company
*   @prgroup       PR Group
*   @prenddate     Pay Period ending date
*   @employee      Employee
*   @payseq        Payment Sequence
*   @method        DL calculation method
*   @posttoall     earnings posted to all days (Y,N)
*   @dlcode        DL code
*   @dltype        DL code type (D,L)
*   @effectdate    effective date for rates
*   @stddays       standard # of days in Pay Period
*
* OUTPUT PARAMETERS
*   @oldcalcbasis  basis amount subject to old rate
*   @newcalcbasis  basis amount subject to new rate
*   @accumbasis    basis amount used to update accumulaltions
*   @oldliabbasis  basis subject to old rate used for liab dist
*   @newliabbasis  basis subject to new rate used for liab dist
*   @errmsg  	    error message if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
       @prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq  tinyint,
       @method varchar(10), @posttoall bYN, @dlcode bEDLCode, @dltype char(1), 
       @effectdate bDate, @stddays tinyint, @oldcalcbasis bDollar output, @newcalcbasis bDollar output,
       @accumbasis bDollar output, @oldliabbasis bDollar output, @newliabbasis bDollar output,
       @errmsg varchar(255) output
   
   as
   set nocount on
   
   declare @rcode int, @basis bDollar
   
   select @rcode = 0
   
   -- reset calculation, accumulation, and liability distribution basis amounts
   select @oldcalcbasis = 0.00, @newcalcbasis = 0.00, @accumbasis = 0.00
   select  @oldliabbasis = 0.00, @newliabbasis = 0.00
   
   -- Flat Amount or Routine
   if @method in ('A', 'R')
       begin
       -- accumulate calculation basis - exclude 'Subject Only' earnings
       select @basis = isnull(sum(e.Amt),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
   
       -- old or new based on PR End Date and Craft Effective Date
       if @prenddate < @effectdate select @oldcalcbasis = @basis
       if @prenddate >= @effectdate select @newcalcbasis = @basis
   
       -- accumulation basis - include all subject earnings
       select @accumbasis = isnull(sum(e.Amt),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode
   
       -- liability distribution basis
       if @dltype = 'L'
           begin
           select @oldliabbasis = @oldcalcbasis, @newliabbasis = @newcalcbasis -- default to calculation basis
           -- basis excludes earnings where IncldLiabDist<>'Y'
           select @basis = isnull(sum(e.Amt),0.00)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
               and e.IncldLiabDist='Y' --issue 20562
   
           -- old or new based on PR End Date and Craft Effective Date
           if @prenddate < @effectdate select @oldliabbasis = @basis
           if @prenddate >= @effectdate select @newliabbasis = @basis
           end
       end
   -- Rate of Gross
   if @method = 'G'
       begin
       -- old rate calculation basis - excludes 'Subject Only' earnings
       select @oldcalcbasis = isnull(sum(e.Amt),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
           and e.PostDate < @effectdate
   
       -- new rate calculation basis - excludes 'Subject Only' earnings
       select @newcalcbasis = isnull(sum(e.Amt),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
           and e.PostDate >= @effectdate
   
       -- accumulation basis - includes all subject earnings
       select @accumbasis = isnull(sum(e.Amt),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode
   
       -- liability distribution basis
       if @dltype = 'L'
           begin
           select @oldliabbasis = @oldcalcbasis, @newliabbasis = @newcalcbasis  -- default to calculation basis
           -- old basis excludes earnings where IncldLiabDist<>'Y'
           select @oldliabbasis = isnull(sum(e.Amt),0.00)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
               and e.IncldLiabDist='Y' and e.PostDate < @effectdate --issue 20562
           -- new basis excludes earnings where IncldLiabDist<>'Y'
           select @newliabbasis = isnull(sum(e.Amt),0.00)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
               and e.IncldLiabDist='Y' and e.PostDate >= @effectdate --issue 20562
           end
       end
   -- Rate per Hour, Variable Rate per Hour
   -- Even though variable rate codes will reaccumulate their calculation and liability basis,
   -- we need a non zero value to pass back to bspPRProcessCraft.
   if @method in ('H', 'V')
       begin
        -- old rate calculation basis - excludes 'Subject Only' earnings
       select @oldcalcbasis = isnull(sum(e.Hours),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
           and e.PostDate < @effectdate
   
       -- new rate calculation basis - excludes 'Subject Only' earnings
       select @newcalcbasis = isnull(sum(e.Hours),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
           and e.PostDate >= @effectdate
   
       -- accumulation basis - includes all subject earnings
       select @accumbasis = isnull(sum(e.Hours),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode
   
       -- liability distribution basis
       if @dltype = 'L'
           begin
           select @oldliabbasis = @oldcalcbasis, @newliabbasis = @newcalcbasis  -- default to calculation basis
           -- old basis excludes earnings where IncldLiabDist<>'Y'
           select @oldliabbasis = isnull(sum(e.Hours),0.00)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
               and e.IncldLiabDist='Y' and e.PostDate < @effectdate --issue 20562
           -- new basis excludes earnings where IncldLiabDist<>'Y'
           select @newliabbasis = isnull(sum(e.Hours),0.00)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
   
               and e.IncldLiabDist='Y' and e.PostDate >= @effectdate --issue 20562
           end
       end
   -- Factored Rate per Hour
   if @method = 'F'
       begin
        -- old rate calculation basis - excludes 'Subject Only' earnings
       select @oldcalcbasis = isnull(sum(e.Hours * e.Factor),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
           and e.PostDate < @effectdate
   
       -- new rate calculation basis - excludes 'Subject Only' earnings
       select @newcalcbasis = isnull(sum(e.Hours * e.Factor),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
           and e.PostDate >= @effectdate
   
       -- accumulation basis - includes all subject earnings
       select @accumbasis = isnull(sum(e.Hours),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode
   
       -- liability distribution basis
       if @dltype = 'L'
           begin
           select @oldliabbasis = @oldcalcbasis, @newliabbasis = @newcalcbasis  -- default to calculation basis
           -- old basis excludes earnings where IncldLiabDist<>'Y'
           select @oldliabbasis = isnull(sum(e.Hours * e.Factor),0.00)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
               and e.IncldLiabDist='Y' and e.PostDate < @effectdate --issue 20562
           -- new basis excludes earnings where IncldLiabDist<>'Y'
           select @newliabbasis = isnull(sum(e.Hours * e.Factor),0.00)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
               and e.IncldLiabDist='Y' and e.PostDate >= @effectdate --issue 20562
           end
       end
   -- Rate of Deduction
   if @method = 'DN'
       begin
       -- use calculated or override amount of basis deduction
       select @basis = 0.00
       select @basis = case t.UseOver
                           when 'Y' then t.OverAmt
                           else t.Amount
                       end
       from bPRDT t
       join bPRDL d on d.PRCo = t.PRCo and d.DednCode = t.EDLCode
       where t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
           and t.PaySeq = @payseq and t.EDLType = 'D' and d.DLCode = @dlcode
   
       -- old and new basis based on PR End Date and Crfat Effective Date
       if @prenddate < @effectdate select @oldcalcbasis = @basis
       if @prenddate >= @effectdate select @newcalcbasis = @basis
   
       -- accumulation basis is amount of deduction
       select @accumbasis = @basis
   
       -- liability distribution basis
       if @dltype = 'L'
           begin
           select @oldliabbasis = 0.00, @newliabbasis = 0.00
           -- basis excludes 'Subject Only' earnings
           select @basis = isnull(sum(e.Amt),0.00)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
           -- old and new basis based on PR End Date and Craft Effective Date
           if @prenddate < @effectdate select @oldliabbasis = @basis
           if @prenddate >= @effectdate select @newliabbasis = @basis
   
           -- basis excludes earnings where IncldLiabDist<>'Y'
           select @basis = isnull(sum(e.Amt),0.00)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
               and e.IncldLiabDist='Y' --issue 20562
           -- old and new basis based on PR End Date and Craft Effective Date
   	  if @prenddate < @effectdate select @oldliabbasis = @basis
           if @prenddate >= @effectdate select @newliabbasis = @basis
           end
       end
       
   -- Straight Time Equivalent
   if @method = 'S'
       begin
       -- old calculation basis is STE = earnings/factor
       select @oldcalcbasis = isnull(sum(e.Amt / e.Factor),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() 
			and b.PRCo = @prco 
			and b.DLCode = @dlcode 
			and b.SubjectOnly = 'N'
			and e.PostDate < @effectdate
			and isnull(e.Factor, 0.00) <> 0.00 --#142620 Prevent divide by zero
   
       -- new calculation basis is STE = earnings/factor
       select @newcalcbasis = isnull(sum(e.Amt / e.Factor),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() 
			and b.PRCo = @prco
			and b.DLCode = @dlcode 
			and b.SubjectOnly = 'N'
			and e.PostDate >= @effectdate
			and isnull(e.Factor, 0.00) <> 0.00 --#142620 Prevent divide by zero
   
       -- accumulation basis is STE
       select @accumbasis = isnull(sum(e.Amt / e.Factor),0.00)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() 
			and b.PRCo = @prco 
			and b.DLCode = @dlcode
			and isnull(e.Factor, 0.00) <> 0.00 --#142620 Prevent divide by zero
   
       -- liability distribution basis is also STE
       if @dltype = 'L'
           begin
           select @oldliabbasis = @oldcalcbasis, @newliabbasis = @newcalcbasis  -- default to calculation basis
           -- old basis excluding earnings where IncldLiabDist<>'Y'
           select @oldliabbasis = isnull(sum(e.Amt / e.Factor),0.00)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
               and e.IncldLiabDist='Y' 
               and e.PostDate < @effectdate --issue 20562
               and isnull(e.Factor, 0.00) <> 0.00 --#142620 Prevent divide by zero
               
           -- new basis excluding earnings where IncldLiabDist<>'Y'
           select @newliabbasis = isnull(sum(e.Amt / e.Factor),0.00)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() 
				and b.PRCo = @prco 
				and b.DLCode = @dlcode 
				and b.SubjectOnly = 'N'
				and e.IncldLiabDist='Y' 
				and e.PostDate >= @effectdate --issue 20562
				and isnull(e.Factor, 0.00) <> 0.00 --#142620 Prevent divide by zero
           end
       end
       
   -- Rate per Day
   if @method = 'D'
       begin
       -- old calculation basis is number of days worked prior to effective date - exclude 'Subject Only' earnings
       select @oldcalcbasis = count(distinct e.PostDate)
       from bPRPE e
   
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
           and e.PostDate < @effectdate
       -- new calculation basis is number of days worked equal or later than effective date - exclude 'Subject Only' earnings
       select @newcalcbasis = count(distinct e.PostDate)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
           and e.PostDate >= @effectdate
   
       -- accumulation basis is # of days worked - all subject earnings
       select @accumbasis = count(distinct e.PostDate)
       from bPRPE e
       join bPRDB b on b.EDLCode = e.EarnCode
       where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode
   
       -- accumulate liability dist basis - actual days worked used even if posted to all
       if @dltype = 'L'
           begin
           select @oldliabbasis = @oldcalcbasis, @newliabbasis = @newcalcbasis  -- default to calculation basis
           -- old basis excluding earnings where IncldLiabDist<>'Y'
           select @oldliabbasis = count(distinct e.PostDate)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
               and e.IncldLiabDist='Y' and e.PostDate < @effectdate --issue 20562
           -- new basis excluding earnings where IncldLiabDist<>'Y'
           select @newliabbasis = count(distinct e.PostDate)
           from bPRPE e
           join bPRDB b on b.EDLCode = e.EarnCode
           where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
               and e.IncldLiabDist='Y' and e.PostDate >= @effectdate --issue 20562
           end
   
       if @posttoall = 'Y' -- posted to all days - calculation and accums based on std # of days in Pay Period
           begin
           select @oldcalcbasis = 0.00, @newcalcbasis = 0.00
           if @prenddate < @effectdate
               select @oldcalcbasis = @stddays
           else
               select @newcalcbasis = @stddays
           -- accumulation basis is std # of days for Pay Period
           select @accumbasis = @stddays
           end
       end
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessCraftBasis] TO [public]
GO
