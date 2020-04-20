SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNMT98    Script Date: 8/28/99 9:33:30 AM ******/
   CREATE   proc [dbo].[bspPRNMT98]
   /********************************************************
   * CREATED BY: 	bc 6/4/98
   * MODIFIED BY:	bc 6/4/98
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 New Mexico Income Tax
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
   
   select @rcode = 0, @allowance = 2650, @procname = 'bspPRNMT98'
   
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
   
   	if @annualized_wage <= 1500 goto bspexit
   
   
   	if @annualized_wage <= 7000 select @wage_bracket = 0, @rate = .017
   	if @annualized_wage > 7000 select @tax_addition = 93.50, @wage_bracket = 7000, @rate = .032
   	if @annualized_wage > 12500 select @tax_addition = 269.50, @wage_bracket = 12500, @rate = .047
   	if @annualized_wage > 17500 select @tax_addition = 504.5, @wage_bracket = 17500, @rate = .06
   	if @annualized_wage > 27500 select @tax_addition = 1104.50, @wage_bracket = 27500, @rate = .071
   	if @annualized_wage > 35000 select @tax_addition = 2240.50, @wage_bracket = 43500, @rate = .079
   	if @annualized_wage > 66500 select @tax_addition = 4057.50, @wage_bracket = 66500, @rate = .085
   end
   
   if @status = 'M'
   	begin
   
   	if @annualized_wage <= 4250 goto bspexit
   
   
   	if @annualized_wage <= 12250 select @wage_bracket = 0, @rate = .017
   	if @annualized_wage > 12250 select @tax_addition = 136, @wage_bracket = 12250, @rate = .032
   	if @annualized_wage > 20250 select @tax_addition = 392, @wage_bracket = 20250, @rate = .047
   	if @annualized_wage > 28250 select @tax_addition = 768, @wage_bracket = 28250, @rate = .06
   	if @annualized_wage > 44250 select @tax_addition = 1728, @wage_bracket = 44250, @rate = .071
   	if @annualized_wage > 68250 select @tax_addition = 3432, @wage_bracket = 68250, @rate = .079
   	if @annualized_wage > 104250 select @tax_addition = 6276, @wage_bracket = 104250, @rate = .085
   end
   
   bspcalc: /* calculate New Mexico Tax */
   
   
   select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
   if @amt < 12 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNMT98] TO [public]
GO
