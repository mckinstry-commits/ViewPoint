SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

  CREATE  PROC [dbo].[bspPRNYC11]
  /********************************************************
  * CREATED BY: 	EN 12/06/00 - effective 1/1/2001
  * MODIFIED BY:  EN 9/25/01 - effective 10/1/2001
  *				EN 5/17/02 - effective 6/1/2002
  *				EN 10/8/02 - issue 18877 change double quotes to single
  *				EN 7/7/03 - issue 21771  update effective 7/1/03
  *				EN 12/01/03 issue 22943  update effective 7/1/04
  *				EN 11/11/04 issue 25796  update effective 1/1/05
  *				EN 1/10/05 - issue 26244  default status and exemptions
  *				EN 12/9/05 - issue 119623  update effective 1/1/2006
  *				MV 11/3/10 - #141156 update effective 9/1/2010 - $500,000+ wage bracket
  *				EN 3/17/11 #142765 update effective 1/1/2011 (mod to highest wage bracket)
  *
  * USAGE:
  * 	Calculates New York City Tax
  *
  * INPUT PARAMETERS:
  *	@subjamt 	subject earnings
  *	@ppds		# of pay pds per year
  *	@status		filing status
  *	@exempts	# of exemptions
  *	@resident	Y or N whether they live in the Big Apple or not
  *
  * OUTPUT PARAMETERS:
  *	@amt		calculated NYC tax amount
  *	@msg		error message if failure
  *
  * RETURN VALUE:
  * 	0 	    	success
  *	1 		failure
  **********************************************************/
  	(@subjamt bDollar = 0, @ppds TINYINT = 0, @status CHAR(1) = 'S', @exempts TINYINT = 0,
  	 @resident bYN = NULL, @amt bDollar = 0 OUTPUT, @msg VARCHAR(255) = NULL OUTPUT)
  	 
  AS
  SET NOCOUNT ON
  
  DECLARE @rcode INT, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
  @procname VARCHAR(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket INT
  
  SELECT @rcode = 0, @allowance = 1000, @procname = 'bspPRNYC11'
  
  -- #26244 set default status and/or exemptions if passed in values are invalid
  IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('S','M')) SELECT @status = 'S'
  IF @exempts IS NULL SELECT @exempts = 0
 
  IF @ppds = 0
  BEGIN
  	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  	GOTO bspexit
  END
  
  
  IF @status = 'S' SELECT @deduction = 5000
  IF @status = 'M' SELECT @deduction = 5500
  
  
  /* single and married code for residents of NYC */
  
  /* annualize taxable income */
  SELECT @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance) - @deduction
  IF @annualized_wage <= 0 GOTO bspexit
  
  /* initialize calculation elements */
  
  IF @status = 'S'
  BEGIN
  	IF @annualized_wage <= 8000 SELECT @tax_addition = 0, @wage_bracket = 0, @rate = .019
  	IF @annualized_wage > 8000 SELECT @tax_addition = 152, @wage_bracket = 8000, @rate = .0265
  	IF @annualized_wage > 8700 SELECT @tax_addition = 171, @wage_bracket = 8700, @rate = .031
  	IF @annualized_wage > 15000 SELECT @tax_addition = 366, @wage_bracket = 15000, @rate = .037
  	IF @annualized_wage > 25000 SELECT @tax_addition = 736, @wage_bracket = 25000, @rate = .039
  	IF @annualized_wage > 60000 SELECT @tax_addition = 2101, @wage_bracket = 60000, @rate = .04
   	IF @annualized_wage > 500000 SELECT @tax_addition = 19701, @wage_bracket = 500000, @rate = .0425
  END
  IF @status = 'M'
  BEGIN
  	IF @annualized_wage <= 8000 SELECT @tax_addition = 0, @wage_bracket = 0, @rate = .019
  	IF @annualized_wage > 8000 SELECT @tax_addition = 152, @wage_bracket = 8000, @rate = .0265
  	IF @annualized_wage > 8700 SELECT @tax_addition = 171, @wage_bracket = 8700, @rate = .031
  	IF @annualized_wage > 15000 SELECT @tax_addition = 366, @wage_bracket = 15000, @rate = .037
  	IF @annualized_wage > 25000 SELECT @tax_addition = 736, @wage_bracket = 25000, @rate = .039
  	IF @annualized_wage > 60000 SELECT @tax_addition = 2101, @wage_bracket = 60000, @rate = .04
  	IF @annualized_wage > 500000 SELECT @tax_addition = 19701, @wage_bracket = 500000, @rate = .0425
  END
  
  /* calculate New York City Tax for residents */
  SELECT @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate)  / @ppds
 
  
  bspexit:
  	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNYC11] TO [public]
GO
