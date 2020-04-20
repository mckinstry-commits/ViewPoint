SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRVTT98    Script Date: 8/28/99 9:33:36 AM ******/
   CREATE   proc [dbo].[bspPRVTT98]
   /********************************************************
   * CREATED BY: 	bc 6/8/98
   * MODIFIED BY:	bc 6/8/98
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 Vermont Income Tax
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
   
   declare @rcode int, @annualized_wage bDollar, @rate bRate, @wage_bracket int,
   @procname varchar(30), @tax_addition int
   
   
   select @rcode = 0, @procname = 'bspPRVTT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize taxable income  */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * 2700)
   
   
   /* select calculation elements for single folk */
   if @status = 'S'
   begin
   	if @annualized_wage <= 2650 goto bspexit
   	if @annualized_wage > 2650 select @tax_addition = 0, @rate = .0375, @wage_bracket = 2650
   	if @annualized_wage > 26900 select @tax_addition = 909.38, @rate = .07, @wage_bracket = 26900
   	if @annualized_wage > 57450 select @tax_addition = 3047.88,  @rate = .0775, @wage_bracket = 57450
   	if @annualized_wage > 129650 select @tax_addition = 8643.38, @rate = .09, @wage_bracket = 129650
   	if @annualized_wage > 280000 select @tax_addition = 22174.88, @rate = .099, @wage_bracket = 280000
   end
   
   /* select calculation elements for married folk */
   if @status = 'M'
   begin
   	if @annualized_wage <= 6450 goto bspexit
   	if @annualized_wage > 6450 select @tax_addition = 0, @rate = .0375, @wage_bracket = 6450
   	if @annualized_wage > 46750 select @tax_addition = 1511.25, @rate = .07, @wage_bracket = 46750
   	if @annualized_wage > 96450 select @tax_addition = 4990.25,  @rate = .0775, @wage_bracket = 96450
   	if @annualized_wage > 160350 select @tax_addition = 9942.50, @rate = .09, @wage_bracket = 160350
   	if @annualized_wage > 282850 select @tax_addition = 20967.5, @rate = .099, @wage_bracket = 282850
   end
   
   bspcalc: /* calculate Vermont Tax */
   
   
   select @amt = @tax_addition + (@annualized_wage - @wage_bracket) * @rate / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRVTT98] TO [public]
GO
