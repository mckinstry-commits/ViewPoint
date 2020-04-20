SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMNT98    Script Date: 8/28/99 9:33:27 AM ******/
   CREATE   proc [dbo].[bspPRMNT98]
   /********************************************************
   * CREATED BY: 	bc 6/2/98
   * MODIFIED BY:	bc 6/2/98
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 Minnesota Income Tax
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
   
   select @rcode = 0, @dedn = 2700, @procname = 'bspPRMNT98'
   
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
   		if @annualized_wage > 1550 select @wage_bracket = 1550, @rate = .06
   		if @annualized_wage > 18510 select @tax_addition = 1018, @wage_bracket = 18510, @rate = .08
   		if @annualized_wage > 57280 select @tax_addition = 4119, @wage_bracket = 57280, @rate = .085
   end
   
   /* married wage table and tax */
   if @status = 'M' 
   	begin
   		if @annualized_wage <= 4400 goto bspexit
   		if @annualized_wage > 4400 select @wage_bracket = 4400, @rate = .06
   		if @annualized_wage > 29200 select @tax_addition = 1448, @wage_bracket = 29200, @rate = .08
   		if @annualized_wage > 102940 select @tax_addition = 7387, @wage_bracket = 102940, @rate = .085
   end
   
   
   bspcalc: /* calculate Minnesota Tax rounded to the nearest dollar */
   	select @amt = ROUND(((@tax_addition + (@annualized_wage - @wage_bracket) * @rate) / @ppds),0) 
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMNT98] TO [public]
GO
