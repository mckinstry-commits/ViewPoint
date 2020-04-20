SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNYT03    Script Date: 8/28/99 9:33:30 AM ******/
   CREATE proc [dbo].[bspPRNYT03]
   /********************************************************
   * CREATED BY: 	bc 6/4/98
   * MODIFIED BY:	bc 6/4/98
   * MODIFIED BY:  EN 1/17/00 - tax addition variable was not being initialized for the lowest bracket which would have caused no tax to calculate
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 7/7/03 - issue 21770  update effective 7/1/03
   *
   * USAGE:
   * 	Calculates New York Income Tax
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
   
   select @rcode = 0, @allowance = 1000, @procname = 'bspPRNYT03'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   if @status = 'S' select @deduction = 6975
   if @status = 'M' select @deduction = 7475
   
   /* annualize taxable income */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance) - @deduction
   if @annualized_wage <= 0 goto bspexit
   
   
   /* initialize calculation elements */
   
   if @status = 'S'
   	begin
   	if @annualized_wage <= 8000 select @tax_addition = 0, @wage_bracket = 0, @rate = .04
   	if @annualized_wage > 8000 select @tax_addition = 320, @wage_bracket = 8000, @rate = .045
   	if @annualized_wage > 11000 select @tax_addition = 455, @wage_bracket = 11000, @rate = .0525
   	if @annualized_wage > 13000 select @tax_addition = 560, @wage_bracket = 13000, @rate = .059
   	if @annualized_wage > 20000 select @tax_addition = 973, @wage_bracket = 20000, @rate = .0685
   	if @annualized_wage > 90000 select @tax_addition = 5768, @wage_bracket = 90000, @rate = .0764
   	if @annualized_wage > 100000 select @tax_addition = 6532, @wage_bracket = 100000, @rate = .0944
   	if @annualized_wage > 150000 select @tax_addition = 11252, @wage_bracket = 150000, @rate = .1125
   	if @annualized_wage > 200000 select @tax_addition = 16877, @wage_bracket = 200000, @rate = .0865
   	if @annualized_wage > 500000 select @tax_addition = 42827, @wage_bracket = 500000, @rate = .0905
   	end
   if @status = 'M'
   	begin
   	if @annualized_wage <= 8000 select @tax_addition = 0, @wage_bracket = 0, @rate = .04
   	if @annualized_wage > 8000 select @tax_addition = 320, @wage_bracket = 8000, @rate = .045
   	if @annualized_wage > 11000 select @tax_addition = 455, @wage_bracket = 11000, @rate = .0525
   	if @annualized_wage > 13000 select @tax_addition = 560, @wage_bracket = 13000, @rate = .059
   	if @annualized_wage > 20000 select @tax_addition = 973, @wage_bracket = 20000, @rate = .0685
   	if @annualized_wage > 90000 select @tax_addition = 5768, @wage_bracket = 90000, @rate = .0764
   	if @annualized_wage > 100000 select @tax_addition = 6532, @wage_bracket = 100000, @rate = .0814
   	if @annualized_wage > 150000 select @tax_addition = 10604, @wage_bracket = 150000, @rate = .1255
   	if @annualized_wage > 200000 select @tax_addition = 16877, @wage_bracket = 200000, @rate = .0865
   	if @annualized_wage > 500000 select @tax_addition = 42827, @wage_bracket = 500000, @rate = .0905
   	end
   bspcalc: /* calculate New York Tax */
   
   
   select @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate)  / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNYT03] TO [public]
GO
