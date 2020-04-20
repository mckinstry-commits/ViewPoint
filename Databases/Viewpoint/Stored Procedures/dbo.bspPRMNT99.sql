SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMNT99    Script Date: 8/28/99 9:33:28 AM ******/
   CREATE   proc [dbo].[bspPRMNT99]
   /********************************************************
   * CREATED BY: 	bc 6/2/98
   * MODIFIED BY:	EN 12/17/98
   * MODIFIED BY:  EN 7/9/99  change effective 1/1/99
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
   @procname varchar(30), @tax_addition int, @wage_bracket int
   
   select @rcode = 0, @dedn = 2750, @procname = 'bspPRMNT99'
   
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
   		if @annualized_wage <= 1550 goto bspexit
   		if @annualized_wage > 1550 select @wage_bracket = 1550, @rate = .055
   		if @annualized_wage > 18800 select @tax_addition = 949, @wage_bracket = 18800, @rate = .0725
   		if @annualized_wage > 58220 select @tax_addition = 3807, @wage_bracket = 58220, @rate = .08
   end
   
   /* married wage table and tax */
   if @status = 'M' 
   	begin
   		if @annualized_wage <= 4450 goto bspexit
   		if @annualized_wage > 4450 select @wage_bracket = 4400, @rate = .055
   		if @annualized_wage > 29670 select @tax_addition = 1387, @wage_bracket = 29670, @rate = .0725
   		if @annualized_wage > 104650 select @tax_addition = 6823, @wage_bracket = 104650, @rate = .08
   end
   
   
   bspcalc: /* calculate Minnesota Tax rounded to the nearest dollar */
   	select @amt = ROUND(((@tax_addition + (@annualized_wage - @wage_bracket) * @rate) / @ppds),0) 
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMNT99] TO [public]
GO
