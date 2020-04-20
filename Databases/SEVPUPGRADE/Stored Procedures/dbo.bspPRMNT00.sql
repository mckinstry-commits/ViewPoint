SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMNT00    Script Date: 8/28/99 9:33:28 AM ******/
   CREATE  proc [dbo].[bspPRMNT00]
   /********************************************************
   * CREATED BY: 	bc 6/2/98
   * MODIFIED BY:	EN 12/17/98
   * MODIFIED BY:  EN 7/9/99  change effective 1/1/99
   * MODIFIED BY:  EN 11/29/99 - update effective 1/1/2000
   *               EN 7/6/00 - this update effective 1/1/2000 supercedes formula released before 7/1/2000
   *				EN 10/8/02 - issue 18877 change double quotes to single
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
   
   select @rcode = 0, @dedn = 2800, @procname = 'bspPRMNT00'
   
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
   		if @annualized_wage <= 1600 goto bspexit
   		if @annualized_wage > 1600 select @wage_bracket = 1600, @rate = .0535
   		if @annualized_wage > 19170 select @tax_addition = 940, @wage_bracket = 19170, @rate = .0705
   		if @annualized_wage > 59310 select @tax_addition = 3770, @wage_bracket = 59310, @rate = .0785
   end
   
   /* married wage table and tax */
   if @status = 'M'
   	begin
   		if @annualized_wage <= 4550 goto bspexit
   		if @annualized_wage > 4550 select @wage_bracket = 4550, @rate = .0535
   		if @annualized_wage > 30230 select @tax_addition = 1374, @wage_bracket = 30230, @rate = .0705
   		if @annualized_wage > 106580 select @tax_addition = 6757, @wage_bracket = 106580, @rate = .0785
   end
   
   
   bspcalc: /* calculate Minnesota Tax rounded to the nearest dollar */
   	select @amt = ROUND(((@tax_addition + (@annualized_wage - @wage_bracket) * @rate) / @ppds),0)
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMNT00] TO [public]
GO
