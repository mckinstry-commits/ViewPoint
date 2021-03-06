SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNCT98    Script Date: 8/28/99 9:33:29 AM ******/
   CREATE    proc [dbo].[bspPRNCT98]
   /********************************************************
   * CREATED BY: 	bc 6/2/98
   * MODIFIED BY:	bc 6/2/98
   * MODIFIED BY:  EN 1/17/00 - @tax_subtraction was dimensioned to int which would throw off tax calculation slightly
   *               EN 9/18/00 - single calculation was not subtracting std dedn and withholding allowance
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 North Carolina Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status
   *	@exempts	# of exemptions
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
   @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
   @procname varchar(30), @tax_subtraction bDollar, @allowance bDollar
   
   select @rcode = 0, @procname = 'bspPRNCT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize earnings */
   select @annualized_wage = @subjamt * @ppds
   
   /* calculation defaults */
   select @tax_subtraction = 0, @rate = 0
   
   /* swingin' single */
   if @status = 'S'
   	begin
   	select @deduction = 3000
   
   	/* subtract deductions and allowances from taxable income */
   	if @annualized_wage < 60000 select @allowance = 2500
   		else select @allowance = 2000
   
      	select @annualized_wage = @annualized_wage - @deduction - (@exempts * @allowance)
   
   	if @annualized_wage <= 12750 select @rate = .06
   	if @annualized_wage > 12750 select @tax_subtraction = 127.5, @rate = .07
   	if @annualized_wage > 60000 select @tax_subtraction = 577.5, @rate = .0775
   end
   
   /* head of household */
   if @status = 'H'
   	begin
   	select @deduction = 4400
   
   	if @annualized_wage < 80000 select @allowance = 2500
   		else select @allowance = 2000
   
   
   	/* subtract deductions and allowances from taxable income */
   	select @annualized_wage = @annualized_wage - @deduction - (@exempts * @allowance)
   
   	if @annualized_wage <= 17000 select @rate = .06
   	if @annualized_wage > 17000 select @tax_subtraction = 170, @rate = .07
   	if @annualized_wage > 80000 select @tax_subtraction = 770, @rate = .0775
   end
   
   /* married or qualifying widow(er) */
   if @status = 'M' or @status = 'W'
   	begin
   	select @deduction = 2500
   
   	if @annualized_wage < 50000 select @allowance = 2500
   		else select @allowance = 2000
   
   
   	/* subtract deductions and allowances from taxable income */
   	select @annualized_wage = @annualized_wage - @deduction - (@exempts * @allowance)
   
   
   
   	if @annualized_wage <= 10625 select @rate = .06
   	if @annualized_wage > 10625 select @tax_subtraction = 106.25, @rate = .07
   	if @annualized_wage > 50000 select @tax_subtraction = 481.25, @rate = .0775
   end
   
   
   
   bspcalc: /* calculate North Carolina Tax */
   
   
   select @annualized_wage = @annualized_wage * @rate - @tax_subtraction
   if @annualized_wage <= 0 goto bspexit
   select @amt = ROUND(@annualized_wage / @ppds,0)
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNCT98] TO [public]
GO
