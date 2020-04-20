SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRWIT98    Script Date: 8/28/99 9:33:37 AM ******/
   CREATE   proc [dbo].[bspPRWIT98]
   /********************************************************
   * CREATED BY: 	bc 6/8/98
   * MODIFIED BY:	bc 6/8/98
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 Wisconsin Income Tax
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
   @procname varchar(30), @tax_addition bDollar, @deduction int, @dedn  int
   
   
   select @rcode = 0, @procname = 'bspPRWIT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   /* method 'A' */
   /* annualize taxable income  */
   select @annualized_wage = (@subjamt * @ppds)
   
   /* determine the deduction based on status and annualized wages */
   if @status = 'S'
   begin
   	if @annualized_wage < 7500 select @deduction = 3900
   	if @annualized_wage >= 40000 select @deduction = 0
   	if @annualized_wage >= 7500 and @annualized_wage < 40000
   		select @deduction = 3900 - (.12 * (@annualized_wage - 7500))
   end
   
   if @status = 'M'
   begin
   	if @annualized_wage < 10000 select @deduction = 5100
   	if @annualized_wage >= 35500 select @deduction = 0
   	if @annualized_wage >= 10000 and @annualized_wage < 35500
   		select @deduction = 5100 - (.20 * (@annualized_wage - 10000))
   end
   
   select @annualized_wage = @annualized_wage - @deduction
   
   /* annualzied_wage is less than zero and has 0 exemptions */
   if @annualized_wage <=0 and @exempts = 0
   begin
   	select @annualized_wage = @subjamt * @ppds * .0255
   	goto bspcalc
   end
   
   /* select calculation elements */
   
   	if @annualized_wage <= 7500 select @tax_addition = 0, @rate = .049, @wage_bracket = 0
   	if @annualized_wage > 7500 select @tax_addition = 367.5, @rate = .0655, @wage_bracket = 7500
   	if @annualized_wage > 15000 select @tax_addition = 858.75, @rate = .0693, @wage_bracket = 15000
   
   
   
   bspcalc: /* calculate Wisconsin Tax */
   
   
   select @amt = @tax_addition + (@annualized_wage - @wage_bracket) * @rate
   select @amt = (@amt - 20 * @exempts) / @ppds
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRWIT98] TO [public]
GO
