SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNMT02    Script Date: 8/28/99 9:33:30 AM ******/
   CREATE    proc [dbo].[bspPRNMT02]
   /********************************************************
   * CREATED BY: 	EN 10/26/00 - this revision effective 1/1/2001
   * MODIFIED BY:  EN 11/29/00 - lowest tax bracket not being calculated correctly
   * 				EN 11/26/01 - issue 15183 - revision effective 1/1/2002
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
   
   select @rcode = 0, @allowance = 2900, @procname = 'bspPRNMT02'
   
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
   
   	if @annualized_wage <= 1650 goto bspexit
   
   
   	if @annualized_wage <= 7150 select @tax_addition = 0, @wage_bracket = 1650, @rate = .017
   	if @annualized_wage > 7150 select @tax_addition = 93.50, @wage_bracket = 7150, @rate = .032
   	if @annualized_wage > 12650 select @tax_addition = 269.50, @wage_bracket = 12650, @rate = .047
   	if @annualized_wage > 17650 select @tax_addition = 504.5, @wage_bracket = 17650, @rate = .06
   	if @annualized_wage > 27650 select @tax_addition = 1104.50, @wage_bracket = 27650, @rate = .071
   	if @annualized_wage > 43650 select @tax_addition = 2240.50, @wage_bracket = 43650, @rate = .079
   	if @annualized_wage > 66650 select @tax_addition = 4057.50, @wage_bracket = 66650, @rate = .085
   end
   
   if @status = 'M'
   	begin
   
   	if @annualized_wage <= 4700 goto bspexit
   
   
   	if @annualized_wage <= 12700 select @tax_addition = 0, @wage_bracket = 4700, @rate = .017
   	if @annualized_wage > 12700 select @tax_addition = 136, @wage_bracket = 12700, @rate = .032
   	if @annualized_wage > 20700 select @tax_addition = 392, @wage_bracket = 20700, @rate = .047
   	if @annualized_wage > 28700 select @tax_addition = 768, @wage_bracket = 28700, @rate = .06
   	if @annualized_wage > 44700 select @tax_addition = 1728, @wage_bracket = 44700, @rate = .071
   	if @annualized_wage > 68700 select @tax_addition = 3432, @wage_bracket = 68700, @rate = .079
   	if @annualized_wage > 104700 select @tax_addition = 6276, @wage_bracket = 104700, @rate = .085
   end
   
   bspcalc: /* calculate New Mexico Tax */
   
   select @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate)
   if @amt < 12 select @amt = 0 /*annual withholding amounts under $12.00 need not be deducted or withheld */
   select @amt = @amt / @ppds
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNMT02] TO [public]
GO
