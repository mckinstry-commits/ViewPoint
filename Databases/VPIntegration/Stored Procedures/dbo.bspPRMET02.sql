SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMET02   Script Date: 8/28/99 9:33:27 AM ******/
   CREATE    proc [dbo].[bspPRMET02]
   /********************************************************
   * CREATED BY: 	EN 12/13/00 - tax update effective 1/1/2001
   * MODIFIED BY:  EN 11/13/01 - issue 15015
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Maine Income Tax
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
   
   declare @rcode int, @annualized_wage bDollar, @dedn bDollar, @rate bRate,
   @procname varchar(30), @tax_addition bDollar, @wage_bracket int
   
   select @rcode = 0, @dedn = 2850, @procname = 'bspPRMET02'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   
   /* annualize earnings then subtract standard deductions */
   select @annualized_wage = (@subjamt * @ppds) - (@dedn * @exempts)
   
   /* calculation defaults */
   select @tax_addition = 0, @wage_bracket = 0, @rate = 0
   
   
   /* single wage table and tax */
   if @status = 'S'
   	begin
   		if @annualized_wage <= 1850 goto bspcalc
   		if @annualized_wage > 1850 select @wage_bracket = 1850, @rate = .02
   		if @annualized_wage > 6050 select @tax_addition = 84, @wage_bracket = 6050, @rate = .045
   		if @annualized_wage > 10200 select @tax_addition = 271, @wage_bracket = 10200, @rate = .07
   		if @annualized_wage > 18550 select @tax_addition = 856, @wage_bracket = 18550, @rate = .085
   end
   
   /* married wage table and tax */
   if @status = 'M'
   	begin
   		if @annualized_wage <= 5000 goto bspcalc
   		if @annualized_wage > 5000 select @wage_bracket = 5000, @rate = .02
   		if @annualized_wage > 13400 select @tax_addition = 168, @wage_bracket = 13400, @rate = .045
   		if @annualized_wage > 21700 select @tax_addition = 542, @wage_bracket = 21700, @rate = .07
   		if @annualized_wage > 38400 select @tax_addition = 1711, @wage_bracket = 38400, @rate = .085
   end
   
   
   /* married with two incomes, wage table and tax */
   if @status = 'B'
   	begin
   		if @annualized_wage <= 2500 goto bspcalc
   		if @annualized_wage > 2500 select @wage_bracket = 2500, @rate = .02
   		if @annualized_wage > 6700 select @tax_addition = 84, @wage_bracket = 6700, @rate = .045
   		if @annualized_wage > 10850 select @tax_addition = 271, @wage_bracket = 10850, @rate = .07
   		if @annualized_wage > 19200 select @tax_addition = 856, @wage_bracket = 19200, @rate = .085
   end
   
   
   bspcalc: /* calculate Maine Tax */
   	select @amt = round(((@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds),0)
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMET02] TO [public]
GO
