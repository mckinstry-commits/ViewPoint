SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNMT032    Script Date: 8/28/99 9:33:30 AM ******/
   CREATE      proc [dbo].[bspPRNMT032]
   /********************************************************
   * CREATED BY: 	EN 10/26/00 - this revision effective 1/1/2001
   * MODIFIED BY:  EN 11/29/00 - lowest tax bracket not being calculated correctly
   * 				EN 11/26/01 - issue 15183 - revision effective 1/1/2002
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 10/28/02 issue 19131  tax update effective 1/1/2003
   *				EN 5/13/03 - issue 21259  tax update effective retroactive 1/1/2003
   *
   * USAGE:
   * 	Calculates New Mexico Income Tax
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
   @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
   
   select @rcode = 0, @allowance = 3050, @procname = 'bspPRNMT032'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   /* annualize taxable income */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
   
   
   /* initialize calculation elements */
   
   if @status = 'S'
   	begin
   
   	if @annualized_wage <= 1700 goto bspexit
   
   
   	if @annualized_wage <= 7200 select @tax_addition = 0, @wage_bracket = 1700, @rate = .017
   	if @annualized_wage > 7200 select @tax_addition = 93.50, @wage_bracket = 7200, @rate = .032
   	if @annualized_wage > 12700 select @tax_addition = 269.50, @wage_bracket = 12700, @rate = .047
   	if @annualized_wage > 17700 select @tax_addition = 504.5, @wage_bracket = 17700, @rate = .06
   	if @annualized_wage > 27700 select @tax_addition = 1104.50, @wage_bracket = 27700, @rate = .071
   	if @annualized_wage > 43700 select @tax_addition = 2240.50, @wage_bracket = 43700, @rate = .077
   end
   
   if @status = 'M'
   	begin
   
   	if @annualized_wage <= 4850 goto bspexit
   
   
   	if @annualized_wage <= 12900 select @tax_addition = 0, @wage_bracket = 4900, @rate = .017
   	if @annualized_wage > 12900 select @tax_addition = 136, @wage_bracket = 12900, @rate = .032
   	if @annualized_wage > 20900 select @tax_addition = 392, @wage_bracket = 20900, @rate = .047
   	if @annualized_wage > 28900 select @tax_addition = 768, @wage_bracket = 28900, @rate = .06
   	if @annualized_wage > 44900 select @tax_addition = 1728, @wage_bracket = 44900, @rate = .071
   	if @annualized_wage > 68900 select @tax_addition = 3432, @wage_bracket = 68900, @rate = .077
   end
   
   bspcalc: /* calculate New Mexico Tax */
   
   select @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate)
   if @amt < 12 select @amt = 0 /*annual withholding amounts under $12.00 need not be deducted or withheld */
   select @amt = @amt / @ppds
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNMT032] TO [public]
GO
