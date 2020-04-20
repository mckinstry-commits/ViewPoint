SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRRIT01    Script Date: 8/28/99 9:33:34 AM ******/
   CREATE  proc [dbo].[bspPRRIT01]
   /********************************************************
   * CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
   * MODIFIED BY:	EN 10/9/02 - issue 18877 change double quotes to single
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
   
   
   select @rcode = 0, @allowance = 2900, @procname = 'bspPRRIT01'
   
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
   	if @annualized_wage > 2650 select @tax_addition = 0, @wage_bracket = 2650, @rate = .038
   	if @annualized_wage > 28700 select @tax_addition = 996.41, @wage_bracket = 28700, @rate = .071
   	if @annualized_wage > 62200 select @tax_addition = 3388.31, @wage_bracket = 62200, @rate = .079
   	if @annualized_wage > 138400 select @tax_addition = 9411.92, @wage_bracket = 138400, @rate = .092
   	if @annualized_wage > 299000 select @tax_addition = 24155.00, @wage_bracket = 299000, @rate = .101
   end
   
   if @status = 'M'
   begin
   	if @annualized_wage <= 6450 select @tax_addition = 0, @wage_bracket = 0, @rate = 0
   	if @annualized_wage > 6450 select @tax_addition = 0, @wage_bracket = 6450, @rate = .038
   	if @annualized_wage > 49900 select @tax_addition = 1661.96, @wage_bracket = 49900, @rate = .071
   	if @annualized_wage > 105200 select @tax_addition = 5610.38, @wage_bracket = 105200, @rate = .079
   	if @annualized_wage > 171200 select @tax_addition = 10827.68, @wage_bracket = 171200, @rate = .092
   	if @annualized_wage > 302050 select @tax_addition = 22839.71, @wage_bracket = 302050, @rate = .101
   end
   
   bspcalc: /* calculate Rhode Island Tax */
   
   
   select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRIT01] TO [public]
GO
