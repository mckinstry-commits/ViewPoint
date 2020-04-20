SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREIC04    Script Date: 8/28/99 9:33:34 AM ******/
   CREATE       proc [dbo].[bspPREIC04]
   /********************************************************
   * CREATED BY: 	EN 9/13/00
   * MODIFIED BY:  EN 12/18/01 - effective 1/1/2002
   *				EN 1/8/02 - issue 15822 - more changes effective 1/1/2002
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 11/22/02 - issue 19462  update effective 1/1/2003
   *				EN 12/02/03 - issue 23142  update effective 1/1/2004
   *
   * USAGE:
   * 	Calculates Earned Income Credit
   *
   * INPUT PARAMETERS:
   *   @prco       PR Company
   *   @employee   Employee
   *   @dlcode     dedn code
   *	@calcbasis 	subject earnings
   *	@ppds		# of pay pds per year
   *	@accumamt	YTD EIC accumulation
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated EIC amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    success
   *	1 		failure
   **********************************************************/
   (@prco bCompany, @employee bEmployee, @dlcode bEDLCode, @calcbasis bDollar = 0, @ppds tinyint = 0, @accumamt bDollar = 0,
    @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @annualized_wage bDollar, @rate1 bRate, @rate2 bRate,
   @procname varchar(30), @tax_addition bDollar, @bracket1 bDollar, @bracket2 bDollar,
   @maxpayamt bDollar, @EICStatus char(1)
   
   select @rcode = 0, @rate1 = .204, @rate2 = .09588, @procname = 'bspPREIC04'
   
   -- validate pay periods
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   -- get EICStatus
   select @EICStatus = EICStatus from PRED where PRCo = @prco and Employee = @employee and DLCode = @dlcode
   if @@rowcount = 0 or (@@rowcount = 1 and @EICStatus <> 'S' and @EICStatus <> 'M' and @EICStatus <> 'B')
       begin
       select @msg = @procname + ':  Employee ' + convert(varchar(6),@employee) + 'missing valid EIC Status!', @rcode = 1
       goto bspexit
       end
   
   -- set constants depending on EIC Status
   if @EICStatus = 'S'
       select @bracket1 = 7660, @bracket2 = 14040, @maxpayamt = 1563
   if @EICStatus = 'M'
       select @bracket1 = 7660, @bracket2 = 15040, @maxpayamt = 1563
   if @EICStatus = 'B'
       select @bracket1 = 3830, @bracket2 = 7520, @maxpayamt = 781
   
   -- annualize taxable income less standard deductions
   select @annualized_wage = (@calcbasis * @ppds)
   
   bspcalc: -- calculate EIC
   
   if abs(@accumamt) <= @maxpayamt
       begin
       if @annualized_wage < @bracket1 select @amt = (@annualized_wage * @rate1) / @ppds
       if @annualized_wage >= @bracket1 and @annualized_wage < @bracket2 select @amt = @maxpayamt / @ppds
       if @annualized_wage >= @bracket2 select @amt = (@maxpayamt - (@rate2 * (@annualized_wage - @bracket2))) / @ppds
       if @amt < 0 select @amt = 0
       end
   
   -- limit by max pay amount
   if @maxpayamt < abs(@accumamt) + @amt select @amt = @maxpayamt - abs(@accumamt)
   
   -- round to 0 decimal places and reverse sign for negative deduction
   select @amt = ROUND(@amt,0) * -1
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREIC04] TO [public]
GO
