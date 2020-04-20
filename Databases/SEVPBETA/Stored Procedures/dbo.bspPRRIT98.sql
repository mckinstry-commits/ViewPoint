SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRRIT98    Script Date: 8/28/99 9:33:34 AM ******/
   CREATE   proc [dbo].[bspPRRIT98]
   /********************************************************
   * CREATED BY: 	bc 6/4/98
   * MODIFIED BY:	bc 6/4/98
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 Rhode Island Income Tax
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
   @procname varchar(30), @tax_addition int, @allowance bDollar, @wage_bracket int
   
   
   select @rcode = 0, @allowance = 2700, @procname = 'bspPRRIT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize taxable income less standard deductions */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
   
   
   /* select calculation elements for singles and heads o' households */
   if @status = 'S' or @status = 'H'
   begin
   	if @annualized_wage <= 2650 select @wage_bracket = 0, @rate = 0
   	if @annualized_wage > 2650 select @wage_bracket = 2650, @rate = .041
   	if @annualized_wage > 26900 select @tax_addition = 982.13, @wage_bracket = 26900, @rate = .076
   	if @annualized_wage > 57450 select @tax_addition = 3291.71, @wage_bracket = 57450, @rate = .084
   	if @annualized_wage > 129650 select @tax_addition = 9334.85, @wage_bracket = 129650, @rate = .097
   	if @annualized_wage > 280000 select @tax_addition = 23948.87, @wage_bracket = 280000, @rate = .107
   end
   
   if @status = 'M'
   begin
   	if @annualized_wage <= 6450 select @wage_bracket = 0, @rate = 0
   	if @annualized_wage > 6450 select @wage_bracket = 6450, @rate = .041
   	if @annualized_wage > 46750 select @tax_addition = 1632.15, @wage_bracket = 46750, @rate = .076
   	if @annualized_wage > 96450 select @tax_addition = 5389.47, @wage_bracket = 96450, @rate = .084
   	if @annualized_wage > 160350 select @tax_addition = 10737.90, @wage_bracket = 160350, @rate = .097
   	if @annualized_wage > 282850 select @tax_addition = 22644.90, @wage_bracket = 282850, @rate = .107
   end
   
   bspcalc: /* calculate Rhode Island Tax */
   
   
   select @amt = @tax_addition + (@annualized_wage - @wage_bracket) * @rate  / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRIT98] TO [public]
GO
