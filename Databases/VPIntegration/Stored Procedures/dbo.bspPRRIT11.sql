SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRRIT11]    Script Date: 12/18/2007 08:04:43 ******/
CREATE Proc [dbo].[bspPRRIT11]
/********************************************************
* CREATED BY: 	EN	12/19/2000	- update effective 1/1/2001
* MODIFIED BY:	EN	12/18/2001	- update effective 1/1/2002
*				EN	10/09/2002	- issue 18877 change double quotes to single
*				EN	12/02/2002	- issue 19517  update effective 1/1/2003
*				EN	12/09/2003	- issue 23230  update effective 1/1/2004
*				EN	12/15/2005	- issue 26538  update effective 1/1/2005
*				EN	01/11/2005	- issue 26244  default status and exemptions
*				EN	12/27/2005	- issue 119724  update effective 1/1/2006
*				EN	12/22/2006	- issue 123385  update effective 1/1/2007
*				EN	12/18/2007	- issue 126525  update effective 1/1/2008
*				EN	12/12/2008	- #131446 update effective 1/1/2009
*				EN	12/04/2009	- #136918 update effective 1/1/2010
*				CHS	12/10/2010	- #142441 update effective 1/1/2011
*
* USAGE:
* 	Calculates Rhode Island Income Tax
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status
*	@exempts	# of exemptions
*
* OUTPUT PARAMETERS:
*	@amt		calculated tax amount
*	@msg		error message IF failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
**********************************************************/
(@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
  @amt bDollar = 0 output, @msg varchar(255) = null output)
  
  AS
  SET NOCOUNT ON
  
  DECLARE @rcode int, @annualized_wage bDollar, @rate bRate,
  @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
  
  
  SELECT @rcode = 0, @allowance = 1000, @procname = 'bspPRRIT11'
  
  -- #26244 set default status and/or exemptions IF passed in values are invalid
  IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('S','M','H')) SELECT @status = 'S'
  IF @exempts IS NULL SELECT @exempts = 0
 
  IF @ppds = 0
  	BEGIN
  	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  
  	RETURN @rcode
  	END
  	
  -- check wage limit for exemption amounts
  IF (@subjamt * @ppds) > 195000 SELECT @allowance = 0
  
  /* annualize taxable income less standard deductions */
  SELECT @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
  
  
  /* SELECT calculation elements for singles and heads of households and married*/
  IF @status = 'S' OR @status = 'H' OR @status = 'M'
	BEGIN
	IF @annualized_wage <= 55000 SELECT @tax_addition =       0, @wage_bracket =      0, @rate = .0375
	IF @annualized_wage >  55000 SELECT @tax_addition = 2063.00, @wage_bracket =  55000, @rate = .0475
	IF @annualized_wage > 125000 SELECT @tax_addition = 5388.00, @wage_bracket = 125000, @rate = .0599
	END
   
  bspcalc: /* calculate Rhode Island Tax */
  
  
  SELECT @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRIT11] TO [public]
GO
