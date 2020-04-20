SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRVAT98    Script Date: 8/28/99 9:33:36 AM ******/
   CREATE  proc [dbo].[bspPRVAT98]
   /********************************************************
   * CREATED BY: 	bc 6/8/98
   * MODIFIED BY:	bc 6/8/98
   * MODIFIED BY:  EN 1/17/00 - missing some crucial brackets in the tax calculation formula
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 Virginia Income Tax
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
   @procname varchar(30), @tax_addition bDollar, @deduction int, @allowance int
   
   
   select @rcode = 0, @deduction = 2500, @allowance = 800, @procname = 'bspPRVAT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize taxable income  */
   select @annualized_wage = (@subjamt * @ppds) - @deduction - (@exempts * @allowance)
   if @annualized_wage < 0 select @annualized_wage = 0
   
   
   /* select calculation elements */
   
   
   	if @annualized_wage <= 3000 select @tax_addition = 0, @rate = .02, @wage_bracket = 0
   	if @annualized_wage > 3000 select @tax_addition = 60, @rate = .03, @wage_bracket = 3000
   	if @annualized_wage > 5000 select @tax_addition = 120,  @rate = .05, @wage_bracket = 5000
   	if @annualized_wage > 17000 select @tax_addition = 720, @rate = .0575, @wage_bracket = 17000
   
   
   bspcalc: /* calculate Virginia Tax */
   
   
   select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRVAT98] TO [public]
GO
