SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRVTT99    Script Date: 8/28/99 9:33:36 AM ******/
   CREATE   proc [dbo].[bspPRVTT99]
   /********************************************************
   * CREATED BY: 	bc 6/8/98
   * MODIFIED BY:	EN 12/31/98
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Vermont Income Tax
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
   
   
   select @rcode = 0, @procname = 'bspPRVTT99'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize taxable income  */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * 2750)
   
   
   /* select calculation elements for single folk */
   if @status = 'S'
   begin
   	if @annualized_wage <= 2650 goto bspexit
   	if @annualized_wage > 2650 select @tax_addition = 0, @rate = .0375, @wage_bracket = 2650
   	if @annualized_wage > 27300 select @tax_addition = 924.38, @rate = .07, @wage_bracket = 27300
   	if @annualized_wage > 58500 select @tax_addition = 3108.38,  @rate = .0775, @wage_bracket = 58500
   	if @annualized_wage > 131800 select @tax_addition = 8789.13, @rate = .09, @wage_bracket = 131800
   	if @annualized_wage > 284700 select @tax_addition = 22550.13, @rate = .099, @wage_bracket = 284700
   end
   
   /* select calculation elements for married folk */
   if @status = 'M'
   begin
   	if @annualized_wage <= 6450 goto bspexit
   	if @annualized_wage > 6450 select @tax_addition = 0, @rate = .0375, @wage_bracket = 6450
   	if @annualized_wage > 47500 select @tax_addition = 1539.38, @rate = .07, @wage_bracket = 47500
   	if @annualized_wage > 98500 select @tax_addition = 5109.38,  @rate = .0775, @wage_bracket = 98500
   	if @annualized_wage > 163000 select @tax_addition = 10108.13, @rate = .09, @wage_bracket = 163000
   	if @annualized_wage > 287600 select @tax_addition = 21322.13, @rate = .099, @wage_bracket = 287600
   end
   
   bspcalc: /* calculate Vermont Tax */
   
   select @amt = @tax_addition + (@annualized_wage - @wage_bracket) * @rate / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRVTT99] TO [public]
GO
