SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMET04   Script Date: 8/28/99 9:33:27 AM ******/
   CREATE      proc [dbo].[bspPRMET04]
   /********************************************************
   * CREATED BY: 	EN 12/13/00 - tax update effective 1/1/2001
   * MODIFIED BY:  EN 11/13/01 - issue 15015
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 12/09/02 - issue 19593  tax update effective 1/1/2003
   *				EN 10/29/03 - issue 22881 tax update effective 1/1/2004
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
   
   select @rcode = 0, @dedn = 2850, @procname = 'bspPRMET04'
   
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
   		if @annualized_wage <= 2000 goto bspcalc
   		if @annualized_wage > 2000 select @wage_bracket = 2000, @rate = .02
   		if @annualized_wage > 6350 select @tax_addition = 87, @wage_bracket = 6350, @rate = .045
   		if @annualized_wage > 10650 select @tax_addition = 281, @wage_bracket = 10650, @rate = .07
   		if @annualized_wage > 19350 select @tax_addition = 890, @wage_bracket = 19350, @rate = .085
   end
   
   /* married wage table and tax */
   if @status = 'M'
   	begin
   		if @annualized_wage <= 5300 goto bspcalc
   		if @annualized_wage > 5300 select @wage_bracket = 5300, @rate = .02
   		if @annualized_wage > 14000 select @tax_addition = 174, @wage_bracket = 14000, @rate = .045
   		if @annualized_wage > 22650 select @tax_addition = 563, @wage_bracket = 22650, @rate = .07
   		if @annualized_wage > 40000 select @tax_addition = 1778, @wage_bracket = 40000, @rate = .085
   end
   
   
   /* married with two incomes, wage table and tax */
   if @status = 'B'
   	begin
   		if @annualized_wage <= 2650 goto bspcalc
   		if @annualized_wage > 2650 select @wage_bracket = 2650, @rate = .02
   		if @annualized_wage > 7000 select @tax_addition = 87, @wage_bracket = 7000, @rate = .045
   		if @annualized_wage > 11325 select @tax_addition = 282, @wage_bracket = 11325, @rate = .07
   		if @annualized_wage > 20000 select @tax_addition = 889, @wage_bracket = 20000, @rate = .085
   end
   
   
   bspcalc: /* calculate Maine Tax */
   	select @amt = round(((@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds),0)
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMET04] TO [public]
GO
