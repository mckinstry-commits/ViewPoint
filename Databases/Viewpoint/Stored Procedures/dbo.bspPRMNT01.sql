SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMNT01    Script Date: 8/28/99 9:33:28 AM ******/
   CREATE   proc [dbo].[bspPRMNT01]
   /********************************************************
   * CREATED BY: 	EN 11/29/00 - this revision effective 1/1/2001
   * MODIFIED BY:	EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Minnesota Income Tax
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
   
   declare @rcode int, @annualized_wage bDollar, @dedn bDollar, @rate bRate,
   @procname varchar(30), @tax_addition bDollar, @wage_bracket int
   
   select @rcode = 0, @dedn = 2900, @procname = 'bspPRMNT01'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   
   /* annualize earnings then subtract standard deductions */
   select @annualized_wage = (@subjamt * @ppds) - (@dedn * @exempts)
   
   /* calculation defaults */
   select @tax_addition = 0, @wage_bracket = 0, @rate = 0
   
   
   /* single wage table and tax */
   if @status = 'S'
   	begin
   		if @annualized_wage <= 1650 goto bspexit
   		if @annualized_wage > 1650 select @wage_bracket = 1650, @rate = .0535
   		if @annualized_wage > 19770 select @tax_addition = 969, @wage_bracket = 19770, @rate = .0705
   		if @annualized_wage > 61150 select @tax_addition = 3887, @wage_bracket = 61150, @rate = .0785
   end
   
   /* married wage table and tax */
   if @status = 'M'
   	begin
   		if @annualized_wage <= 4700 goto bspexit
   		if @annualized_wage > 4700 select @wage_bracket = 4700, @rate = .0535
   		if @annualized_wage > 31180 select @tax_addition = 1417, @wage_bracket = 31180, @rate = .0705
   		if @annualized_wage > 109900 select @tax_addition = 6966, @wage_bracket = 109900, @rate = .0785
   end
   
   
   bspcalc: /* calculate Minnesota Tax rounded to the nearest dollar */
   	select @amt = ROUND(((@tax_addition + (@annualized_wage - @wage_bracket) * @rate) / @ppds),0)
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMNT01] TO [public]
GO
