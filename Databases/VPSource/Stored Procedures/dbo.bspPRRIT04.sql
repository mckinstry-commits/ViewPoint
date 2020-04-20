SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRRIT04    Script Date: 8/28/99 9:33:34 AM ******/
   CREATE      proc [dbo].[bspPRRIT04]
   /********************************************************
   * CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
   * MODIFIED BY:	EN 12/18/01 - update effective 1/1/2002
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *				EN 12/2/02 - issue 19517  update effective 1/1/2003
   *				EN 12/09/03 - issue 23230  update effective 1/1/2004
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
   
   
   select @rcode = 0, @allowance = 3100, @procname = 'bspPRRIT04'
   
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
   	if @annualized_wage > 30800 select @tax_addition = 1055.63, @wage_bracket = 30800, @rate = .07
   	if @annualized_wage > 68500 select @tax_addition = 3694.63, @wage_bracket = 68500, @rate = .0775
   	if @annualized_wage > 148700 select @tax_addition = 9910.13, @wage_bracket = 148700, @rate = .09
   	if @annualized_wage > 321200 select @tax_addition = 25435.13, @wage_bracket = 321200, @rate = .099
   end
   
   if @status = 'M'
   begin
   	if @annualized_wage <= 6450 select @tax_addition = 0, @wage_bracket = 0, @rate = 0
   	if @annualized_wage > 6450 select @tax_addition = 0, @wage_bracket = 6450, @rate = .0375
   	if @annualized_wage > 53550 select @tax_addition = 1766.25, @wage_bracket = 53550, @rate = .07
   	if @annualized_wage > 113950 select @tax_addition = 5994.25, @wage_bracket = 113950, @rate = .0775
   	if @annualized_wage > 183700 select @tax_addition = 11399.88, @wage_bracket = 183700, @rate = .09
   	if @annualized_wage > 324050 select @tax_addition = 24031.38, @wage_bracket = 324050, @rate = .099
   end
   
   bspcalc: /* calculate Rhode Island Tax */
   
   
   select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRIT04] TO [public]
GO
