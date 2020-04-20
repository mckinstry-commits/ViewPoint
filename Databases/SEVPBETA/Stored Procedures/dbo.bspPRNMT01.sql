SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNMT01    Script Date: 8/28/99 9:33:30 AM ******/
   CREATE  proc [dbo].[bspPRNMT01]
   /********************************************************
   * CREATED BY: 	EN 10/26/00 - this revision effective 1/1/2001
   * MODIFIED BY:  EN 11/29/00 - lowest tax bracket not being calculated correctly
   *				EN 10/8/02 - issue 18877 change double quotes to single
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
   
   select @rcode = 0, @allowance = 2800, @procname = 'bspPRNMT01'
   
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
   
   	if @annualized_wage <= 1600 goto bspexit
   
   
   	if @annualized_wage <= 7100 select @tax_addition = 0, @wage_bracket = 1600, @rate = .017
   	if @annualized_wage > 7100 select @tax_addition = 93.50, @wage_bracket = 7100, @rate = .032
   	if @annualized_wage > 12600 select @tax_addition = 269.50, @wage_bracket = 12600, @rate = .047
   	if @annualized_wage > 17600 select @tax_addition = 504.5, @wage_bracket = 17600, @rate = .06
   	if @annualized_wage > 27600 select @tax_addition = 1104.50, @wage_bracket = 27600, @rate = .071
   	if @annualized_wage > 43600 select @tax_addition = 2240.50, @wage_bracket = 43600, @rate = .079
   	if @annualized_wage > 66600 select @tax_addition = 4057.50, @wage_bracket = 66600, @rate = .085
   end
   
   if @status = 'M'
   	begin
   
   	if @annualized_wage <= 4550 goto bspexit
   
   
   	if @annualized_wage <= 12550 select @tax_addition = 0, @wage_bracket = 4550, @rate = .017
   	if @annualized_wage > 12550 select @tax_addition = 136, @wage_bracket = 12550, @rate = .032
   	if @annualized_wage > 20550 select @tax_addition = 392, @wage_bracket = 20550, @rate = .047
   	if @annualized_wage > 28550 select @tax_addition = 768, @wage_bracket = 28550, @rate = .06
   	if @annualized_wage > 44550 select @tax_addition = 1728, @wage_bracket = 44550, @rate = .071
   	if @annualized_wage > 68550 select @tax_addition = 3432, @wage_bracket = 68550, @rate = .079
   	if @annualized_wage > 104550 select @tax_addition = 6276, @wage_bracket = 104550, @rate = .085
   end
   
   bspcalc: /* calculate New Mexico Tax */
   
   select @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate)
   if @amt < 12 select @amt = 0 /*annual withholding amounts under $12.00 need not be deducted or withheld */
   select @amt = @amt / @ppds
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNMT01] TO [public]
GO
