SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRNYY13]    Script Date: 12/04/2007 09:01:03 ******/
CREATE  proc [dbo].[bspPRNYY13]
/********************************************************
* CREATED BY: 	bc	06/12/1998
* MODIFIED BY:	EN	01/27/1999
*				EN	01/17/2000 - tax addition amount wasn't being initialized for the lowest resident tax bracket which would have causeed no tax to be calculated
*				EN	01/27/2000 - nonresident tax rate changed from 50% to 25%
*               EN	02/02/2000 - fixed nonresident tax rates which were coded as .025 and should have been .0025
*               EN	02/09/2000 - fixed nonresident part of routine to correctly calc highest tax bracket ... replaced else with if
*				EN	10/08/2002 - issue 18877 change double quotes to single
*				EN	07/07/2003 - issue 21772 update effective 7/1/03
*				EN	12/01/2003 issue 22943  update effective 7/1/04
*				EN	11/11/2004 issue 25796  update effective 1/1/05
*				EN	01/10/2005 - issue 26244  default status and exemptions
*				EN	12/09/2005 - issue 119623  update effective 1/1/2006
*				EN	04/15/2009 #133290  update effective 5/1/2009
*				EN	12/09/2009 #136992  update effective 1/1/2010
*				CHS 04/28/2011 #143737   update effective 05/01/2011
*				CHS	12/26/2011	- B-08244 update effective 1/1/2012
*				EN 12/10/2012  B-11868/TK-20121/#147588 update effective 1/1/2013
*
* USAGE:
* 	Calculates Yonkers City Tax
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status
*	@exempts	# of exemptions
*	@resident	Yes or No whether they're lost in Yonkers or not
*
* OUTPUT PARAMETERS:
*	@amt		calculated Yonkers tax amount
*	@msg		error message if failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
**********************************************************/
(@subjamt bDollar = 0, 
 @ppds tinyint = 0, 
 @status char(1) = 'S', 
 @exempts tinyint = 0, 
 @resident bYN = null,
 @amt bDollar = 0 OUTPUT, 
 @msg varchar(255) = null OUTPUT)
 
AS
SET NOCOUNT ON
  
DECLARE @annualized_wage bDollar, 
		@deduction bDollar, 
		@rate bRate,
		@procname varchar(30), 
		@tax_addition bDollar, 
		@allowance bDollar,
		@SingleDeduction bDollar, 
		@MarriedDeduction bDollar, 
		@wage_bracket int

SELECT	@allowance = 1000, -- Exemption allowance (Table C)
		@SingleDeduction = 7150, -- Deduction Allowance for Single employee (Table B)
		@MarriedDeduction = 7650, -- Deduction Allowance for Married employee (Table B)
		@procname = 'bspPRNYY13'
  
-- #26244 set default status and/or exemptions if passed in values are invalid
IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('S','M')) SELECT @status = 'S'
IF @exempts IS NULL SELECT @exempts = 0

IF @ppds = 0
BEGIN
	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!'
	RETURN 1
END
  
-- determine Deduction Allowance based on marital status
IF @status = 'S' 
BEGIN
	SELECT @deduction = @SingleDeduction
END
ELSE
BEGIN
	SELECT @deduction = @MarriedDeduction
END
  
IF @resident = 'Y' -- compute tax for single and married residents of Yonkers
BEGIN
	/* annualize taxable income */
	SELECT @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance) - @deduction
	IF @annualized_wage <= 0 
	BEGIN
		RETURN 0
	END
	  
	/* initialize calculation elements */
	IF @status = 'S'
	BEGIN
		IF @annualized_wage <     8200 SELECT @tax_addition =      0, @wage_bracket =       0, @rate = .04
		IF @annualized_wage >=    8200 SELECT @tax_addition =    328, @wage_bracket =    8200, @rate = .045
		IF @annualized_wage >=   11300 SELECT @tax_addition =    468, @wage_bracket =   11300, @rate = .0525
		IF @annualized_wage >=   13350 SELECT @tax_addition =    575, @wage_bracket =   13350, @rate = .059
		IF @annualized_wage >=   20550 SELECT @tax_addition =   1000, @wage_bracket =   20550, @rate = .0645
		IF @annualized_wage >=   77150 SELECT @tax_addition =   4651, @wage_bracket =   77150, @rate = .0665
		IF @annualized_wage >=   92600 SELECT @tax_addition =   5678, @wage_bracket =   92600, @rate = .0758
		IF @annualized_wage >=  102900 SELECT @tax_addition =   6459, @wage_bracket =  102900, @rate = .0808
		IF @annualized_wage >=  154350 SELECT @tax_addition =  10616, @wage_bracket =  154350, @rate = .0715
		IF @annualized_wage >=  205850 SELECT @tax_addition =  14298, @wage_bracket =  205850, @rate = .0815
		IF @annualized_wage >=  257300 SELECT @tax_addition =  18491, @wage_bracket =  257300, @rate = .0735
		IF @annualized_wage >= 1029250 SELECT @tax_addition =  75230, @wage_bracket = 1029250, @rate = .4902
		IF @annualized_wage >= 1080750 SELECT @tax_addition = 100475, @wage_bracket = 1080750, @rate = .0962
	END
	ELSE IF @status = 'M'
	BEGIN
		IF @annualized_wage <     8200 SELECT @tax_addition =      0, @wage_bracket =       0, @rate = .04
		IF @annualized_wage >=    8200 SELECT @tax_addition =    328, @wage_bracket =    8200, @rate = .045
		IF @annualized_wage >=   11300 SELECT @tax_addition =    468, @wage_bracket =   11300, @rate = .0525
		IF @annualized_wage >=   13350 SELECT @tax_addition =    575, @wage_bracket =   13350, @rate = .059
		IF @annualized_wage >=   20550 SELECT @tax_addition =   1000, @wage_bracket =   20550, @rate = .0645
		IF @annualized_wage >=   77150 SELECT @tax_addition =   4651, @wage_bracket =   77150, @rate = .0665  	
		IF @annualized_wage >=   92600 SELECT @tax_addition =   5678, @wage_bracket =   92600, @rate = .0728
		IF @annualized_wage >=  102900 SELECT @tax_addition =   6428, @wage_bracket =  102900, @rate = .0778
		IF @annualized_wage >=  154350 SELECT @tax_addition =  10431, @wage_bracket =  154350, @rate = .0808
		IF @annualized_wage >=  205850 SELECT @tax_addition =  14592, @wage_bracket =  205850, @rate = .0715
		IF @annualized_wage >=  308750 SELECT @tax_addition =  21949, @wage_bracket =  308750, @rate = .0815
		IF @annualized_wage >=  360250 SELECT @tax_addition =  26147, @wage_bracket =  360250, @rate = .0735
		IF @annualized_wage >= 1029250 SELECT @tax_addition =  75318, @wage_bracket = 1029250, @rate = .0765
		IF @annualized_wage >= 2058550 SELECT @tax_addition = 154059, @wage_bracket = 2058550, @rate = .8842
		IF @annualized_wage >= 2110050 SELECT @tax_addition = 199596, @wage_bracket = 2110050, @rate = .0962
	END
	  
	/* calculate Yonkers City Tax for residents */
	SELECT @amt = ROUND(((@tax_addition + (@annualized_wage - @wage_bracket) * @rate) * .15 / @ppds), 2)
	RETURN 0
END
ELSE IF @resident = 'N' -- compute tax for anyone who works in NYC but doesn't live there
BEGIN
	/* annualize taxable income */ 
	SELECT @annualized_wage = (@subjamt * @ppds)

	/* initialize calculation elements */

	IF @annualized_wage <= 3999.99 RETURN 0
	IF @annualized_wage > 3999.99	SELECT @wage_bracket = 3000, @rate = .005
	IF @annualized_wage > 10000		SELECT @wage_bracket = 2000, @rate = .005
	IF @annualized_wage > 20000		SELECT @wage_bracket = 1000, @rate = .005
	IF @annualized_wage > 30000		SELECT @wage_bracket =    0, @rate = .005

	/* calculate Yonkers Tax for nonresidents */
	SELECT @amt = ROUND((@annualized_wage - @wage_bracket) * @rate  / @ppds, 2)
	RETURN 0
END
  
  
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[bspPRNYY13] TO [public]
GO
