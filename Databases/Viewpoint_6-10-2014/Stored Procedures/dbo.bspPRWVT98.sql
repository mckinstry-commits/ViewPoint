SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRWVT98    Script Date: 8/28/99 9:33:37 AM ******/
   CREATE   proc [dbo].[bspPRWVT98]
   /********************************************************
   * CREATED BY: 	bc 6/8/98
   * MODIFIED BY:	bc 6/8/98
   * MODIFIED BY:  EN 1/17/00 - missing some crucial brackets in the tax calculation formula
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 West Virginia Income Tax
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
   
   
   select @rcode = 0, @allowance = 2000, @procname = 'bspPRWVT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize taxable income  */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
   if @annualized_wage < 0 select @annualized_wage = 0
   
   
   /* select calculation elements */
   
   
   	if @annualized_wage <= 10000 select @tax_addition = 0, @rate = .03, @wage_bracket = 0
   	if @annualized_wage > 10000 select @tax_addition = 300, @rate = .04, @wage_bracket = 10000
   	if @annualized_wage > 25000 select @tax_addition = 900,  @rate = .045, @wage_bracket = 25000
   	if @annualized_wage > 40000 select @tax_addition = 1575,  @rate = .06, @wage_bracket = 40000
   	if @annualized_wage > 60000 select @tax_addition = 2775, @rate = .065, @wage_bracket = 60000
   
   
   bspcalc: /* calculate West Virginia Tax */
   
   
   select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRWVT98] TO [public]
GO
