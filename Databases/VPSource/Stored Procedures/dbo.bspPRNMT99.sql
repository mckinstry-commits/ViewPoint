SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNMT99    Script Date: 8/28/99 9:33:30 AM ******/
   CREATE   proc [dbo].[bspPRNMT99]
   /********************************************************
   * CREATED BY: 	bc 6/4/98
   * MODIFIED BY:	EN 12/17/98
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
   @procname varchar(30), @tax_addition int, @allowance bDollar, @wage_bracket int
   
   select @rcode = 0, @allowance = 2700, @procname = 'bspPRNMT99'
   
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
   
   	if @annualized_wage <= 1550 goto bspexit
   
   
   	if @annualized_wage <= 7050 select @wage_bracket = 0, @rate = .017
   	if @annualized_wage > 7050 select @tax_addition = 93.50, @wage_bracket = 7050, @rate = .032
   	if @annualized_wage > 12550 select @tax_addition = 269.50, @wage_bracket = 12550, @rate = .047
   	if @annualized_wage > 17550 select @tax_addition = 504.5, @wage_bracket = 17550, @rate = .06
   	if @annualized_wage > 27550 select @tax_addition = 1104.50, @wage_bracket = 27550, @rate = .071
   	if @annualized_wage > 43550 select @tax_addition = 2240.50, @wage_bracket = 43550, @rate = .079
   	if @annualized_wage > 66550 select @tax_addition = 4057.50, @wage_bracket = 66550, @rate = .085
   end
   
   if @status = 'M'
   	begin
   
   	if @annualized_wage <= 4400 goto bspexit
   
   
   	if @annualized_wage <= 12400 select @wage_bracket = 0, @rate = .017
   	if @annualized_wage > 12400 select @tax_addition = 136, @wage_bracket = 12400, @rate = .032
   	if @annualized_wage > 20400 select @tax_addition = 392, @wage_bracket = 20400, @rate = .047
   	if @annualized_wage > 28400 select @tax_addition = 768, @wage_bracket = 28400, @rate = .06
   	if @annualized_wage > 44400 select @tax_addition = 1728, @wage_bracket = 44400, @rate = .071
   	if @annualized_wage > 68400 select @tax_addition = 3432, @wage_bracket = 68400, @rate = .079
   	if @annualized_wage > 104400 select @tax_addition = 6276, @wage_bracket = 104400, @rate = .085
   end
   
   bspcalc: /* calculate New Mexico Tax */
   
   select @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate)  / @ppds
   if @amt < 12 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNMT99] TO [public]
GO
