SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPROHT062    Script Date: 8/28/99 9:33:31 AM ******/
 CREATE  proc [dbo].[bspPROHT062]
 /********************************************************
 * CREATED BY: 	bc 6/4/98
 * MODIFIED BY:	GG 11/13/98
 * MODIFIED BY:  EN 11/07/99 - wasn't calculating tax for annual wages under $5000
 *				EN 10/8/02 - issue 18877 change double quotes to single
 *				EN 1/10/05 - issue 26244  default exemptions
 *				EN 11/29/05 - issue 30686  tax update effective 1/1/2006
 *				EN 9/5/06 - issue 122150 tax update effective 10/1/2006
 *
 * USAGE:
 * 	Calculates Ohio Income Tax
 *
 * INPUT PARAMETERS:
 *	@subjamt 	subject earnings
 *	@ppds		# of pay pds per year
 *	@status		filing status - not used
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
 
 declare @rcode int, @annualized_wage bDollar, @rate bRate,
 @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
 
 
 select @rcode = 0, @allowance = 650, @procname = 'bspPROHT062'
 
 -- #26244 set default exemptions if passed in values are invalid
 if @exempts is null select @exempts = 0
 
 if @ppds = 0
 	begin
 	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
 
 	goto bspexit
 	end
 
 
 /* annualize taxable income */
 select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
 if @annualized_wage <= 0 select @annualized_wage = 0
 
 
 /* select calculation elements */
 
 	if @annualized_wage <= 5000 select @tax_addition = 0, @wage_bracket = 0, @rate = .00706
 	if @annualized_wage > 5000 select @tax_addition = 35.30, @wage_bracket = 5000, @rate = .01412
 	if @annualized_wage > 10000 select @tax_addition = 105.9, @wage_bracket = 10000, @rate = .02823
 	if @annualized_wage > 15000 select @tax_addition = 247.05, @wage_bracket = 15000, @rate = .03529
 	if @annualized_wage > 20000 select @tax_addition = 423.5, @wage_bracket = 20000, @rate = .04235
 	if @annualized_wage > 40000 select @tax_addition = 1270.5, @wage_bracket = 40000, @rate = .04941
 	if @annualized_wage > 80000 select @tax_addition = 3246.9, @wage_bracket = 80000, @rate = .05646
 	if @annualized_wage > 100000 select @tax_addition = 4376.1, @wage_bracket = 100000, @rate = .07058
 
 
 bspcalc: /* calculate Ohio Tax */
 
 
 select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
 
 
 bspexit:
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPROHT062] TO [public]
GO
