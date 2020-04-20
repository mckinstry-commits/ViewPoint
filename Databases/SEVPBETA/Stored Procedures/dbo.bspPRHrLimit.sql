SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPRHrLimit]
/********************************************************
* CREATED BY:   GG 08/18/00
* MODIFIED BY:	EN 10/8/02 - issue 18877 change double quotes to single
*				CHS 10/15/2010 - #140541 - change bPRDB.EarnCode to EDLCode
*
* USAGE:
* 	Calculates deduction amount as a rate of earnings
*   but limited by hours.  Rate should be setup with Craft
*   but can be overridden by Class, Template, or Employee.
*   Hourly limit setup with dedn, with override allowed by Employee.
*
*   Developed for use with Iron Workers Union dues calculation.
*
*	Called from bspPRProcessCraft
*
* INPUT PARAMETERS:
*	@prco	 	  PR Company
*	@dlcode	      Deduction code
*	@rate         Deduction rate
*	@limitamt     Limit amount, hours per Pay Period
*
* OUTPUT PARAMETERS:
*	@calcamt	  calculated deduction amount
*   @eligamt      eligible earnings
*	@errmsg		  error message if failure
*
* RETURN VALUE:
* 	0 	    success
*	1 		failure
**********************************************************/
   (@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
    @dltype char(1), @dlcode bEDLCode, @rate bRate, @limitamt bDollar = 0, @calcamt bDollar = 0 output,
   @eligamt bDollar = 0 output, @totalhrs bHrs output, @errmsg varchar(255) = null output)
   
   as
   set nocount on
   
   declare @rcode int, @procname varchar(30), @openEarnings tinyint, @hrs bHrs, @earnrate bRate,
   @amt bDollar, @remainhrs bHrs
   
   select @rcode = 0, @totalhrs = 0, @procname = 'bspPRHrLimit'
   
   -- create a cursor to process earnings subject to this deduction, includes addons
   declare bcEarnings cursor for
   select  Hours, Rate, Amt
   from bPRPE e
   join bPRDB b on b.EDLCode = e.EarnCode
   where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
   order by PostDate, PostSeq, Rate     -- process in posting data order
   
   open bcEarnings
   select @openEarnings = 1
   
   -- first get hours for any pay seq's <= the one being processed
   select @totalhrs = isnull(sum(Hours),0)
   from bPRDT
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   	and Employee = @employee and PaySeq <= @payseq
        and EDLType = @dltype and EDLCode = @dlcode
   
   -- loop through Earnings
   next_Earnings:
       fetch next from bcEarnings into @hrs, @earnrate, @amt
       if @@fetch_status = -1 goto end_Earnings
       if @@fetch_status <> 0 goto next_Earnings
   
       if @totalhrs >= @limitamt goto end_Earnings    -- limit exceeded
   
       -- all earnings are eligible
       if @totalhrs + @hrs <= @limitamt
           begin
           select @eligamt = @eligamt + @amt   -- accum earnings basis
           select @totalhrs = @totalhrs + @hrs -- accum hours
           goto next_Earnings
           end
   
       -- portion of earnings are eligible
       select @remainhrs = @limitamt - @totalhrs
       select @eligamt = @eligamt + ((@remainhrs / @hrs) * @amt)
       select @totalhrs = @totalhrs + @remainhrs
   
       end_Earnings:   -- limit reached or all earnings processed
           close bcEarnings
           deallocate bcEarnings
           select @openEarnings = 0
   
           -- calculate deduction amount
           select @calcamt = @rate * @eligamt
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRHrLimit] TO [public]
GO
