SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRRIT00    Script Date: 8/28/99 9:33:34 AM ******/
   CREATE  proc [dbo].[bspPRRIT00]
   /********************************************************
   * CREATED BY: 	bc 6/4/98
   * MODIFIED BY:	EN 1/6/99
   * MODIFIED BY:  EN 1/6/00 - tax table update effective 1/1/2000
   * MODIFIED BY:  EN 1/17/00 - @tax_addition variable dimensioned as int - should have been bDollar - was throwing off tax calculation
   * MODIFIED BY:  EN 1/17/00 - tax calculation formula was missing some crucial brackets
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Rhode Island Income Tax
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
   
   declare @rcode int, @annualized_wage bDollar, @rate bRate,
   @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
   
   
   select @rcode = 0, @allowance = 2800, @procname = 'bspPRRIT00'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize taxable income less standard deductions */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
   
   
   /* select calculation elements for singles and heads of households */
   if @status = 'S' or @status = 'H'
   begin
   	if @annualized_wage <= 2650 select @tax_addition = 0, @wage_bracket = 0, @rate = 0
   	if @annualized_wage > 2650 select @tax_addition = 0, @wage_bracket = 2650, @rate = .039
   	if @annualized_wage > 27850 select @tax_addition = 982.80, @wage_bracket = 27850, @rate = .073
   	if @annualized_wage > 59900 select @tax_addition = 3316.04, @wage_bracket = 59900, @rate = .081
   	if @annualized_wage > 134200 select @tax_addition = 9304.62, @wage_bracket = 134200, @rate = .094
   	if @annualized_wage > 289950 select @tax_addition = 23882.82, @wage_bracket = 289950, @rate = .103
   end
   
   if @status = 'M'
   begin
   	if @annualized_wage <= 6450 select @tax_addition = 0, @wage_bracket = 0, @rate = 0
   	if @annualized_wage > 6450 select @tax_addition = 0, @wage_bracket = 6450, @rate = .039
   	if @annualized_wage > 48400 select @tax_addition = 1636.05, @wage_bracket = 48400, @rate = .073
   	if @annualized_wage > 101000 select @tax_addition = 5465.33, @wage_bracket = 101000, @rate = .081
   	if @annualized_wage > 166000 select @tax_addition = 10704.33, @wage_bracket = 166000, @rate = .094
   	if @annualized_wage > 292900 select @tax_addition = 22582.17, @wage_bracket = 292900, @rate = .103
   end
   
   bspcalc: /* calculate Rhode Island Tax */
   
   
   select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRIT00] TO [public]
GO
