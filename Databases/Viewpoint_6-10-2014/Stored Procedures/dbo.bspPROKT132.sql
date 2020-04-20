SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[bspPROKT132]
/********************************************************
* CREATED BY: 	bc	06/04/98
* MODIFIED BY:	EN	12/17/98
* MODIFIED BY:  EN	12/22/99 - fixed to round tax to nearest dollar
*				EN	12/18/01 - update effective 1/1/2002 - Fixed
*				EN	01/18/02 - issue 15955 - changed tax rate on wages over $22,560 from .0665 to .07
*				EN	10/08/02 - issue 18877 change double quotes to single
*				EN	12/30/02 - issue 19786  update effective 1/1/2003
*				EN	12/30/03 - issue 23419  update effective 1/1/2004
*				EN	12/23/04 - issue 26631  update effective 1/1/2005
*				EN	01/10/05 - issue 26244  default status and exemptions
*				EN	12/22/05 - issue 119715  update effective 1/1/2006
*				EN	12/11/06 - issue 123295  update effective 1/1/2007
*				EN	12/18/07 - issue 126532  update effective 1/1/2008
*				EN	12/11/08 - #131413  update effective 1/1/2009
*				EN	12/18/09 #137167  updated effective 1/1/2010
*				MV	12/21/10 - #142572 updated effective 1/1/2011
*				MV	12/27/11 - #B-08263 tax updates for 2012
*				CHS 12/28/2012	- B-12067 Tax update effective 1/1/2013
*				CHS 12/28/2012	- B-12067 Tax update effective 1/1/2013 Some the marrried brackets got missed in the first go round.
*
* USAGE:
* 	Calculates Oklahoma Income Tax
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
GRANT EXECUTE ON bspPROKT11 TO public;
GO
**********************************************************/
(@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
  @amt bDollar = 0 output, @msg varchar(255) = null output)
  as
  set nocount on
 
  declare @rcode int, @annualized_wage bDollar, @rate bRate,
  @procname varchar(30), @tax_addition bDollar, @wage_bracket int,
  @deduction_1 int, @deduction_2 int
 
 
  select @rcode = 0, @procname = 'bspPROKT132'
 
  -- #26244 set default status and/or exemptions if passed in values are invalid
  if (@status is null) or (@status is not null and @status not in ('S','M','H')) select @status = 'S'
  if @exempts is null select @exempts = 0
 
  if @ppds = 0
  	begin
  	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  	goto bspexit
  	end
 
 
  /* annualize taxable income and subtract per exemption allowance */
  select @annualized_wage = (@subjamt * @ppds) - (@exempts * 1000)
 
  if @annualized_wage < 0 goto bspexit
  
  /* select calculation elements for married people */
  if @status = 'M'
		BEGIN
		IF      @annualized_wage                 < 12200.00 SELECT @tax_addition =   0, @wage_bracket =     0, @rate = .0000
		ELSE IF @annualized_wage BETWEEN 12200 AND 14199.99 SELECT @tax_addition =   0, @wage_bracket = 12200, @rate = .0050
		ELSE IF @annualized_wage BETWEEN 14200 AND 17199.99 SELECT @tax_addition =  10, @wage_bracket = 14200, @rate = .0100
		ELSE IF @annualized_wage BETWEEN 17200 AND 19699.99 SELECT @tax_addition =  40, @wage_bracket = 17200, @rate = .0200
		ELSE IF @annualized_wage BETWEEN 19700 AND 21999.99 SELECT @tax_addition =  90, @wage_bracket = 19700, @rate = .0300
		ELSE IF @annualized_wage BETWEEN 22000 AND 24399.99 SELECT @tax_addition = 159, @wage_bracket = 22000, @rate = .0400
		ELSE IF @annualized_wage BETWEEN 24400 AND 27199.99 SELECT @tax_addition = 255, @wage_bracket = 24400, @rate = .0500
		ELSE                                                SELECT @tax_addition = 395, @wage_bracket = 27200, @rate = .0525
		END
 
  /* select calculation elements for everybody else */
  IF @status = 'S' or @status = 'H'
		BEGIN
		IF      @annualized_wage                 <  6100.00 SELECT @tax_addition =   0.00, @wage_bracket =     0, @rate = .0000
		ELSE IF @annualized_wage BETWEEN  6100 AND  7099.99 SELECT @tax_addition =   0.00, @wage_bracket =  6100, @rate = .0050
		ELSE IF @annualized_wage BETWEEN  7100 AND  8599.99 SELECT @tax_addition =   5.00, @wage_bracket =  7100, @rate = .0100
		ELSE IF @annualized_wage BETWEEN  8600 AND  9849.99 SELECT @tax_addition =  20.00, @wage_bracket =  8600, @rate = .0200
		ELSE IF @annualized_wage BETWEEN  9850 AND 10999.99 SELECT @tax_addition =  45.00, @wage_bracket =  9850, @rate = .0300
		ELSE IF @annualized_wage BETWEEN 11000 AND 13299.99 SELECT @tax_addition =  79.50, @wage_bracket = 11000, @rate = .0400
		ELSE IF @annualized_wage BETWEEN 13300 AND 14799.99 SELECT @tax_addition = 171.50, @wage_bracket = 13300, @rate = .0500
		ELSE                                                SELECT @tax_addition = 246.50, @wage_bracket = 14800, @rate = .0525
		END
 
  /* calculate Oklahoma Tax */
  select @amt = @tax_addition + (@annualized_wage - @wage_bracket) * @rate
  select @amt = ROUND((@amt/ @ppds),0)
 
 if @amt < 0
	BEGIN
	SELECT @amt = 0
	END
 
  bspexit:
  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPROKT132] TO [public]
GO
