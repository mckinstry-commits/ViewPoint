SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPROHT13]
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
 *				EN 08/20/2013  Story 59174 / Task 59706 tax update effective 09/01/2013
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
 (@subjamt bDollar	= 0, 
  @ppds tinyint		= 0, 
  @status char(1)	= 'S', 
  @exempts tinyint	= 0,
  @amt bDollar		= 0		OUTPUT, 
  @msg varchar(255) = NULL	OUTPUT)

 AS
 SET NOCOUNT ON
 
 DECLARE @rcode int, 
		 @annualized_wage bDollar, 
		 @rate bRate,
		 @procname varchar(30), 
		 @tax_addition bDollar, 
		 @allowance bDollar, 
		 @wage_bracket int
 
 
 SELECT @rcode		= 0, 
		@allowance	= 650, 
		@procname	= 'bspPROHT13'
 
 -- #26244 set default exemptions if passed in values are invalid
 IF @exempts IS NULL SELECT @exempts = 0
 
 IF @ppds = 0
 BEGIN
 	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
 	GOTO bspexit
 END
 
 /* annualize taxable income */
 SELECT @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
 IF @annualized_wage <= 0 SELECT @annualized_wage = 0
 
 /* select calculation elements */
 IF		 @annualized_wage					  <= 5000 SELECT @tax_addition =       0, @wage_bracket =      0, @rate = .00581
 ELSE IF @annualized_wage BETWEEN  5000.01 AND  10000 SELECT @tax_addition =   29.05, @wage_bracket =   5000, @rate = .01161
 ELSE IF @annualized_wage BETWEEN 10000.01 AND  15000 SELECT @tax_addition =   87.10, @wage_bracket =  10000, @rate = .02322
 ELSE IF @annualized_wage BETWEEN 15000.01 AND  20000 SELECT @tax_addition =  203.20, @wage_bracket =  15000, @rate = .02903
 ELSE IF @annualized_wage BETWEEN 20000.01 AND  40000 SELECT @tax_addition =  348.35, @wage_bracket =  20000, @rate = .03483
 ELSE IF @annualized_wage BETWEEN 40000.01 AND  80000 SELECT @tax_addition = 1044.95, @wage_bracket =  40000, @rate = .04064
 ELSE IF @annualized_wage BETWEEN 80000.01 AND 100000 SELECT @tax_addition = 2670.55, @wage_bracket =  80000, @rate = .04644
 ELSE												  SELECT @tax_addition = 3599.35, @wage_bracket = 100000, @rate = .05805
 
 /* calculate Ohio Tax */
 SELECT @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
 
 bspexit:
 	RETURN @rcode
   
GO
GRANT EXECUTE ON  [dbo].[bspPROHT13] TO [public]
GO
