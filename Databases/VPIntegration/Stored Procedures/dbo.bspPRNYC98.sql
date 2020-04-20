SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNYC98    Script Date: 8/28/99 9:33:30 AM ******/
   CREATE   proc [dbo].[bspPRNYC98]
   /********************************************************
   * CREATED BY: 	bc 6/12/98
   * MODIFIED BY:	bc 6/12/98
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 New York City Tax
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
   @procname varchar(30), @tax_addition int, @allowance bDollar, @wage_bracket int
   
   select @rcode = 0, @allowance = 1000, @procname = 'bspPRNYC98'
   
   
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
   
   
   	if @annualized_wage <= 8000 select @wage_bracket = 0, @rate = .022
   	if @annualized_wage > 8000 select @tax_addition = 176, @wage_bracket = 8000, @rate = .0308
   	if @annualized_wage > 8700 select @tax_addition = 198, @wage_bracket = 8700, @rate = .0363
   	if @annualized_wage > 15000 select @tax_addition = 426, @wage_bracket = 15000, @rate = .0435
   	if @annualized_wage > 25000 select @tax_addition = 861, @wage_bracket = 25000, @rate = .0457
   	if @annualized_wage > 60000 select @tax_addition = 2461, @wage_bracket = 60000, @rate = .0468
   
   res_calc: /* calculate New York City Tax for residents */
   
   
   select @amt = @tax_addition + (@annualized_wage - @wage_bracket) * @rate  / @ppds
   goto bspexit
   
   end
   
   
   /* code for anyone who works in NYC but doesn't live there */
   if @resident = 'N'
   begin
   
   /* annualize taxable income */
   select @annualized_wage = (@subjamt * @ppds)
   
   /* initialize calculation elements */
   
   	if @annualized_wage <= 4000 goto bspexit
   
   	if @annualized_wage > 4000 select @wage_bracket = 3000, @rate = .045
   	if @annualized_wage > 10000 select @wage_bracket = 2000, @rate = .045
   	if @annualized_wage > 20000 select @wage_bracket = 1000, @rate = .045
   	if @annualized_wage > 30000 select @wage_bracket = 0, @rate = .045
   
   
   nonres_calc: /* calculate New York City Tax for nonresidents */
   
   
   select @amt = (@annualized_wage - @wage_bracket) * @rate  / @ppds
   goto bspexit
   
   end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNYC98] TO [public]
GO
