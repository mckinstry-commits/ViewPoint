SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspPRPensionDeduct04]
   /********************************************************
   * CREATED BY:   GG 10/13/04
   * MODIFIED BY:	
   *
   * USAGE:
   * 	Custom routine to calculate Pension deduction (#25661 - Meadow Valley).
   *
   *	Called from bspPRProcessEmpl, must be processed after employee based
   *	Medical deduction.
   *
   *	Reads earnings codes for add-on earnings and auto earnings for medical 'salary reduction'
   *	and Medical deduction from from MiscAmt1,2,3 in bPRRM.
   
   *	Pension deduction = Add-on earnings + medical 'salary reduction' - medical deduction
   	If result is < 0 then use 0.00
   *
   * INPUT PARAMETERS:
   *	@prco	 	  	PR Company
   *	@prgroup		PR Group
   *	@prenddate		PR Ending Date
   *	@employee		Employee
   *	@payseq			Pay sequence
   *	@routine		PR routine linked to this deduction
   *
   * OUTPUT PARAMETERS:
   *	@calcamt	  calculated deduction amount
   *	@errmsg		  error message if failure
   *
   * RETURN VALUE:
   * 	0 	    success
   *	1 		failure
   **********************************************************/
   (@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
    @routine varchar(10), @calcamt bDollar = 0 output, @errmsg varchar(255) = null output)
     
   as
   set nocount on
     
   declare @rcode int, @procname varchar(30), @addon bEDLCode, @autoearn bEDLCode, @meddedn bEDLCode,
   	@amt1 bDollar, @amt2 bDollar, @amt3 bDollar
     
   select @rcode = 0, @addon = 0, @autoearn = 0, @meddedn = 0,
   	@amt1 = 0, @amt2 = 0, @amt3 = 0, @procname = 'bspPRPensionDeduct04'
   
   -- get addon earnings code, auto earnings code, and medical deduction code from Routine master MiscAmt1, 2, 3
   select @addon = MiscAmt1, @autoearn = MiscAmt2, @meddedn = MiscAmt3
   from dbo.bPRRM (nolock)
   where PRCo = @prco and Routine = @routine
   
   
   -- get craft add-on earnings - posted with prevailing wage jobs
   if @addon <> 0
   	begin
   	select @amt1 = Amount
   	from dbo.bPRDT (nolock)
   	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
   		and PaySeq = @payseq and EDLType = 'E' and EDLCode = @addon	-- MiscAmt1 (add-on earnings code)
   	end
   
   -- get negative earnings for pre-tax medical deduction
   if @autoearn <> 0
   	begin
   	select @amt2 = Amount
   	from dbo.bPRDT (nolock)
   	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
   		and PaySeq = @payseq and EDLType = 'E' and EDLCode = @autoearn	-- MiscAmt2  (negative earnings for pre-tax medical deduction)
   	end
   
   -- get medical deduction amount
   if @meddedn <> 0
   	begin
   	select @amt3 = case UseOver when 'Y' then OverAmt else Amount end
   	from dbo.bPRDT (nolock)
   	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
   		and PaySeq = @payseq and EDLType = 'D' and EDLCode = @meddedn	-- MiscAmt3 (medical deduction)
   	end
   
   -- calculate amount
   select @calcamt = @amt1 + @amt2 - @amt3	-- @amt2 should be negative
   if @calcamt < 0 select @calcamt = 0	-- if result is less than zero, return 0
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPensionDeduct04] TO [public]
GO
