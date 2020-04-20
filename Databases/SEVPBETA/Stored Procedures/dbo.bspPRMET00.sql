SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMET00    Script Date: 8/28/99 9:33:27 AM ******/
   CREATE  proc [dbo].[bspPRMET00]
   /********************************************************
   * CREATED BY: 	bc 6/2/98
   * MODIFIED BY:	EN 12/16/98
   * MODIFIED BY:  EN 10/19/99 - update effective 1/1/2000
   * MODIFIED BY:  EN 11/02/99 - round off resulting tax amount to the nearest dollar
   *				EN 10/8/02 - issue 18877 change double quotes to single
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
   
   select @rcode = 0, @dedn = 2850, @procname = 'bspPRMET00'
   
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
   		if @annualized_wage <= 1450 goto bspcalc
   		if @annualized_wage > 1450 select @wage_bracket = 1450, @rate = .02
   		if @annualized_wage > 5600 select @tax_addition = 83, @wage_bracket = 5600, @rate = .045
   		if @annualized_wage > 9700 select @tax_addition = 268, @wage_bracket = 9700, @rate = .07
   		if @annualized_wage > 17950 select @tax_addition = 846, @wage_bracket = 17950, @rate = .085
   end
   
   /* married wage table and tax */
   if @status = 'M'
   	begin
   		if @annualized_wage <= 4350 goto bspcalc
   		if @annualized_wage > 4350 select @wage_bracket = 4350, @rate = .02
   		if @annualized_wage > 12600 select @tax_addition = 165, @wage_bracket = 12600, @rate = .045
   		if @annualized_wage > 20850 select @tax_addition = 536, @wage_bracket = 20850, @rate = .07
   		if @annualized_wage > 37350 select @tax_addition = 1691, @wage_bracket = 37350, @rate = .085
   end
   
   
   /* married with two incomes, wage table and tax */
   if @status = 'B'
   	begin
   		if @annualized_wage <= 2175 goto bspcalc
   		if @annualized_wage > 2175 select @wage_bracket = 2175, @rate = .02
   		if @annualized_wage > 6300 select @tax_addition = 83, @wage_bracket = 6300, @rate = .045
   		if @annualized_wage > 10425 select @tax_addition = 268, @wage_bracket = 10425, @rate = .07
   		if @annualized_wage > 18675 select @tax_addition = 846, @wage_bracket = 18675, @rate = .085
   end
   
   
   bspcalc: /* calculate Maine Tax */
   	select @amt = round(((@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds),0)
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMET00] TO [public]
GO
