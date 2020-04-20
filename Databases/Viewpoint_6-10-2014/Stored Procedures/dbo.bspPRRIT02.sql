SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRRIT02    Script Date: 8/28/99 9:33:34 AM ******/
   CREATE    proc [dbo].[bspPRRIT02]
   /********************************************************
   * CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
   * MODIFIED BY:	EN 12/18/01 - update effective 1/1/2002
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
   
   
   select @rcode = 0, @allowance = 3000, @procname = 'bspPRRIT02'
   
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
   	if @annualized_wage > 2650 select @tax_addition = 0, @wage_bracket = 2650, @rate = .0375
   	if @annualized_wage > 29650 select @tax_addition = 1012.5, @wage_bracket = 29650, @rate = .07
   	if @annualized_wage > 64820 select @tax_addition = 3474.4, @wage_bracket = 64820, @rate = .0775
   	if @annualized_wage > 142950 select @tax_addition = 9529.48, @wage_bracket = 142950, @rate = .09
   	if @annualized_wage > 308750 select @tax_addition = 24451.48, @wage_bracket = 308750, @rate = .099
   end
   
   if @status = 'M'
   begin
   	if @annualized_wage <= 6450 select @tax_addition = 0, @wage_bracket = 0, @rate = 0
   	if @annualized_wage > 6450 select @tax_addition = 0, @wage_bracket = 6450, @rate = .0375
   	if @annualized_wage > 51550 select @tax_addition = 1691.25, @wage_bracket = 51550, @rate = .07
   	if @annualized_wage > 109700 select @tax_addition = 5761.75, @wage_bracket = 109700, @rate = .0775
   	if @annualized_wage > 176800 select @tax_addition = 10962, @wage_bracket = 176800, @rate = .09
   	if @annualized_wage > 311900 select @tax_addition = 23121, @wage_bracket = 311900, @rate = .099
   end
   
   bspcalc: /* calculate Rhode Island Tax */
   
   
   select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRIT02] TO [public]
GO
