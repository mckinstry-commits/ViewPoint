SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNYC01    Script Date: 8/28/99 9:33:30 AM ******/
   CREATE   proc [dbo].[bspPRNYC01]
   /********************************************************
   * CREATED BY: 	EN 12/06/00 - effective 1/1/2001
   * MODIFIED BY:	EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates New York City Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status
   *	@exempts	# of exemptions
   *	@resident	Y or N whether they live in the Big Apple or not
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated NYC tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   	(@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
   	 @resident bYN = null, @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
   @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
   
   select @rcode = 0, @allowance = 1000, @procname = 'bspPRNYC01'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   
   if @status = 'S' select @deduction = 5000
   if @status = 'M' select @deduction = 5500
   
   
   /* single and married code for residents of NYC */
   if @resident ='Y'
   begin
   
   /* annualize taxable income */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance) - @deduction
   if @annualized_wage <= 0 goto bspexit
   
   /* initialize calculation elements */
   
   
   	if @annualized_wage <= 8000 select @tax_addition = 0, @wage_bracket = 0, @rate = .0175
   	if @annualized_wage > 8000 select @tax_addition = 140, @wage_bracket = 8000, @rate = .025
   	if @annualized_wage > 8700 select @tax_addition = 158, @wage_bracket = 8700, @rate = .029
   	if @annualized_wage > 15000 select @tax_addition = 341, @wage_bracket = 15000, @rate = .0345
   	if @annualized_wage > 25000 select @tax_addition = 686, @wage_bracket = 25000, @rate = .037
   	if @annualized_wage > 60000 select @tax_addition = 1980, @wage_bracket = 60000, @rate = .04
   
   res_calc: /* calculate New York City Tax for residents */
   
   
   select @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate)  / @ppds
   goto bspexit
   
   end
   
   
   /* code for anyone who works in NYC but doesn't live there */
   if @resident = 'N'
   begin
   
   /* annualize taxable income */
   select @annualized_wage = (@subjamt * @ppds)
   
   /* initialize calculation elements */
   
   	if @annualized_wage <= 4000 goto bspexit
   
   	if @annualized_wage > 4000 select @wage_bracket = 3000, @rate = .0025
   	if @annualized_wage > 10000 select @wage_bracket = 2000, @rate = .0025
   	if @annualized_wage > 20000 select @wage_bracket = 1000, @rate = .0025
   	if @annualized_wage > 30000 select @wage_bracket = 0, @rate = .0025
   
   
   nonres_calc: /* calculate New York City Tax for nonresidents */
   
   select @amt = (@annualized_wage - @wage_bracket) * @rate  / @ppds
   goto bspexit
   
   end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNYC01] TO [public]
GO
