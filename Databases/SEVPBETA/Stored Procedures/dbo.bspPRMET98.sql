SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMET98    Script Date: 8/28/99 9:33:27 AM ******/
   CREATE   proc [dbo].[bspPRMET98]
   /********************************************************
   * CREATED BY: 	bc 6/2/98
   * MODIFIED BY:	bc 6/2/98
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 Maine Income Tax
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
   
   select @rcode = 0, @dedn = 2150, @procname = 'bspPRMET98'
   
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
   		if @annualized_wage <= 2000 goto bspcalc
   		if @annualized_wage > 2000 select @wage_bracket = 2000, @rate = .02
   		if @annualized_wage > 6150 select @tax_addition = 83, @wage_bracket = 6150, @rate = .045
   		if @annualized_wage > 10250 select @tax_addition = 268, @wage_bracket = 10250, @rate = .07
   		if @annualized_wage > 18500 select @tax_addition = 846, @wage_bracket = 18500, @rate = .085
   end
   
   /* married wage table and tax */
   if @status = 'M' 
   	begin
   		if @annualized_wage <= 4750 goto bspcalc
   		if @annualized_wage > 4750 select @wage_bracket = 4750, @rate = .02
   		if @annualized_wage > 13000 select @tax_addition = 165, @wage_bracket = 13000, @rate = .045
   		if @annualized_wage > 21250 select @tax_addition = 536, @wage_bracket = 21250, @rate = .07
   		if @annualized_wage > 37750 select @tax_addition = 1691, @wage_bracket = 37750, @rate = .085
   end
   
   
   /* married with two incomes, wage table and tax */
   if @status = 'B' 
   	begin
   		if @annualized_wage <= 2375 goto bspcalc
   		if @annualized_wage > 2375 select @wage_bracket = 2375, @rate = .02
   		if @annualized_wage > 6500 select @tax_addition = 83, @wage_bracket = 6500, @rate = .045
   		if @annualized_wage > 10625 select @tax_addition = 268, @wage_bracket = 10625, @rate = .07
   		if @annualized_wage > 18875 select @tax_addition = 846, @wage_bracket = 18875, @rate = .085
   end
   
   
   bspcalc: /* calculate Maine Tax */
   	select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMET98] TO [public]
GO
