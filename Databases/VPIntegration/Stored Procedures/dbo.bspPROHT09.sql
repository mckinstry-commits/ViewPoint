SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPROHT09]    Script Date: 10/26/2007 07:56:02 ******/
 CREATE  proc [dbo].[bspPROHT09]
 /********************************************************
 * CREATED BY: 	bc 6/4/98
 * MODIFIED BY:	GG 11/13/98
 * MODIFIED BY:  EN 11/07/99 - wasn't calculating tax for annual wages under $5000
 *				EN 10/8/02 - issue 18877 change double quotes to single
 *				EN 1/10/05 - issue 26244  default exemptions
 *				EN 11/29/05 - issue 30686  tax update effective 1/1/2006
 *				EN 9/5/06 - issue 122150 tax update effective 10/1/2006
 *				EN 10/26/07 - issue 125975 tax update effective 1/1/2008
 *				EN 12/11/08 - #131419  tax update effective 1/1/2009
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
 
 
 select @rcode = 0, @allowance = 650, @procname = 'bspPROHT09'
 
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
 
 	if @annualized_wage <= 5000 select @tax_addition = 0, @wage_bracket = 0, @rate = .00638
 	if @annualized_wage > 5000 select @tax_addition = 31.9, @wage_bracket = 5000, @rate = .01276
 	if @annualized_wage > 10000 select @tax_addition = 95.7, @wage_bracket = 10000, @rate = .02552
 	if @annualized_wage > 15000 select @tax_addition = 223.30, @wage_bracket = 15000, @rate = .0319
 	if @annualized_wage > 20000 select @tax_addition = 382.80, @wage_bracket = 20000, @rate = .03828
 	if @annualized_wage > 40000 select @tax_addition = 1148.40, @wage_bracket = 40000, @rate = .04466
 	if @annualized_wage > 80000 select @tax_addition = 2934.80, @wage_bracket = 80000, @rate = .05103
 	if @annualized_wage > 100000 select @tax_addition = 3955.40, @wage_bracket = 100000, @rate = .06379
 
 
 bspcalc: /* calculate Ohio Tax */
 
 
 select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
 
 
 bspexit:
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPROHT09] TO [public]
GO