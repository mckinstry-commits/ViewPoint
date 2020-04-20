SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMET03   Script Date: 8/28/99 9:33:27 AM ******/
   CREATE     proc [dbo].[bspPRMET03]
   /********************************************************
   * CREATED BY: 	EN 12/13/00 - tax update effective 1/1/2001
   * MODIFIED BY:  EN 11/13/01 - issue 15015
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 12/09/02 - issue 19593  tax update effective 1/1/2003
   *
   * USAGE:
   * 	Calculates Maine Income Tax
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
   
   select @rcode = 0, @dedn = 2850, @procname = 'bspPRMET03'
   
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
   		if @annualized_wage <= 1900 goto bspcalc
   		if @annualized_wage > 1900 select @wage_bracket = 1900, @rate = .02
   		if @annualized_wage > 6150 select @tax_addition = 85, @wage_bracket = 6150, @rate = .045
   		if @annualized_wage > 10350 select @tax_addition = 274, @wage_bracket = 10350, @rate = .07
   		if @annualized_wage > 18850 select @tax_addition = 869, @wage_bracket = 18850, @rate = .085
   end
   
   /* married wage table and tax */
   if @status = 'M'
   	begin
   		if @annualized_wage <= 5100 goto bspcalc
   		if @annualized_wage > 5100 select @wage_bracket = 5100, @rate = .02
   		if @annualized_wage > 13600 select @tax_addition = 170, @wage_bracket = 13600, @rate = .045
   		if @annualized_wage > 22050 select @tax_addition = 550, @wage_bracket = 22050, @rate = .07
   		if @annualized_wage > 39050 select @tax_addition = 1740, @wage_bracket = 39050, @rate = .085
   end
   
   
   /* married with two incomes, wage table and tax */
   if @status = 'B'
   	begin
   		if @annualized_wage <= 2550 goto bspcalc
   		if @annualized_wage > 2550 select @wage_bracket = 2550, @rate = .02
   		if @annualized_wage > 6800 select @tax_addition = 85, @wage_bracket = 6800, @rate = .045
   		if @annualized_wage > 11025 select @tax_addition = 275, @wage_bracket = 11025, @rate = .07
   		if @annualized_wage > 19525 select @tax_addition = 870, @wage_bracket = 19525, @rate = .085
   end
   
   
   bspcalc: /* calculate Maine Tax */
   	select @amt = round(((@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds),0)
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMET03] TO [public]
GO
