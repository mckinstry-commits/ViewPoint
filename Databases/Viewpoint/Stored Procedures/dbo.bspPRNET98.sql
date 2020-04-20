SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNET98    Script Date: 8/28/99 9:33:29 AM ******/
   CREATE   proc [dbo].[bspPRNET98]
   /********************************************************
   * CREATED BY: 	bc 6/2/98
   * MODIFIED BY:	bc 6/2/98
   * MODIFIED BY:  EN 1/17/00 - @tax_addition was dimensioned to int which would throw off tax calculation slightly
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 Nebraska Income Tax
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
   
   select @rcode = 0, @allowance = 1490, @procname = 'bspPRNET98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize earnings */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
   
   /* calculation defaults */
   select @tax_addition = 0, @rate = 0
   
   /* swingin' single */
   if @status = 'S'
   	begin
   
   	if @annualized_wage <= 2200 goto bspexit
   
   	if @annualized_wage > 2200 select @wage_bracket = 2200, @rate = .0249
   	if @annualized_wage > 4400 select @tax_addition = 54.78, @wage_bracket = 4400, @rate = .0347
   	if @annualized_wage > 15500 select @tax_addition = 439.95, @wage_bracket = 15500, @rate = .0532
   	if @annualized_wage > 22750 select @tax_addition = 825.65, @wage_bracket = 22750, @rate = .0657
   	if @annualized_wage > 28100 select @tax_addition = 1177.15, @wage_bracket = 28100, @rate = .0698
   	if @annualized_wage > 54100 select @tax_addition = 2991.95, @wage_bracket = 54100, @rate = .0722
   	if @annualized_wage > 75100 select @tax_addition = 4508.15, @wage_bracket = 75100, @rate = .0736
   end
   
   /* Married */
   if @status = 'M'
   	begin
   
   	if @annualized_wage <= 5250 goto bspexit
   
   	if @annualized_wage > 5250 select @wage_bracket = 5250, @rate = .0249
   	if @annualized_wage > 8250 select @tax_addition = 74.70, @wage_bracket = 8250, @rate = .0347
   	if @annualized_wage > 22400 select @tax_addition = 565.71, @wage_bracket = 22400, @rate = .0532
   	if @annualized_wage > 35400 select @tax_addition = 1257.31, @wage_bracket = 35400, @rate = .0657
   	if @annualized_wage > 42950 select @tax_addition = 1753.35, @wage_bracket = 42950, @rate = .0698
   	if @annualized_wage > 58250 select @tax_addition = 2821.29, @wage_bracket = 58250, @rate = .0722
   	if @annualized_wage > 75250 select @tax_addition = 4048.69, @wage_bracket = 75250, @rate = .0736
   end
   
   
   bspcalc: /* calculate Nebraska Tax */
   
   
   select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNET98] TO [public]
GO
