SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[bspPRPRT11]
/********************************************************
* CREATED BY: 	EN 12/20/00 - update effective 1/1/2001
* MODIFIED BY:	EN 12/27/00 - init @tax_subtraction amount in lowest bracket else 0 tax is calculated
*				EN 1/15/02 - update effective 1/1/2002
*				EN 10/8/02 - issue 18877 change double quotes to single
*				EN 12/01/03 issue 23133  update effective 1/1/2004
*				EN 1/11/05 - issue 26244  default status and exemptions
*				EN 11/17/06 - issue 123152  update effective 1/1/2007
*				EN 1/17/08 - issue 126788  update effective 1/1/2008
*				EN 10/28/11 TK-09327  update effective 1/1/2011
*
* USAGE:
* 	Calculates Puerto Rico Income Tax
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status 
*				- 'S' for individual to claim complete personal exemption
*				- 'M' for married filing jointly to claim complete personal exemption
*				- 'B' for married filing jointly to claim half the personal exemption
*				- 'H' or any other status not specified above to claim no personal exemption
*	@exempts	# of dependents to compute exemption for dependents
*	@addtl_exempts	# of allowances for deductions
*	@misc_factor	1 to apply joint custody exemption (half of regular) for dependents, otherwise 0
*	@misc_amt	additional annual veteran's personal exemption amount if any 
*				-plus- annual special deduction amount if any
*
* OUTPUT PARAMETERS:
*	@amt		calculated tax amount
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
 @addtl_exempts tinyint = 0, 
 @misc_factor tinyint = 0,
 @misc_amt bDollar = 0, 
 @amt bDollar = 0 OUTPUT, 
 @msg varchar(255) = null OUTPUT)
 
AS
SET NOCOUNT ON

DECLARE	@annualized_wage bDollar, 
		@rate bRate,
		@tax_subtraction bDollar, 
		@personalexempt int,
		@dependentexempt bDollar,
		@allowfordedns bDollar
   
-- validate @ppds
IF @ppds = 0
BEGIN
	SELECT @msg = 'Missing # of Pay Periods per year!'
	RETURN 1
END
   
-- #26244 set default status and/or exemptions if passed in values are invalid
IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('S','M','B','H'))
BEGIN
	SELECT @status = 'S'
END

IF @exempts IS NULL SELECT @exempts = 0

IF @addtl_exempts IS NULL SELECT @addtl_exempts = 0

IF @misc_factor IS NULL SELECT @misc_factor = 0

-- Determine annual personal exemption based on filing status
IF @status = 'S'		SELECT @personalexempt = 3500
ELSE IF @status = 'M'	SELECT @personalexempt = 7000
ELSE IF @status = 'B'	SELECT @personalexempt = 3500
ELSE IF @status = 'H'	SELECT @personalexempt = 0
ELSE					SELECT @personalexempt = 0

-- Determine annual exemption for dependents
IF @misc_factor = 1
BEGIN
	SELECT @dependentexempt = @exempts * 1250
END
ELSE
BEGIN
	SELECT @dependentexempt = @exempts * 2500
END

-- Determine annual allowance for deductions
SELECT @allowfordedns = @addtl_exempts * 500

-- Annualize wages ... if < $20,000 tax is $0.00
SELECT @annualized_wage = @subjamt * @ppds

IF @annualized_wage < 20000
BEGIN
	SELECT @amt = 0
END
ELSE
BEGIN
	-- From annual taxable income subtract personal exemption, exemption for dependents, 
	-- allowance for deductions, and additional personal exemption for veterans/special deduction amount (@misc_amt)
	SELECT @annualized_wage =	@annualized_wage 
								- @personalexempt 
								- @dependentexempt 
								- @allowfordedns
								- @misc_amt

	-- If taxable income < $0.00 tax is $0.00
	IF @annualized_wage < 0 
	BEGIN
		SELECT @amt = 0
	END
	ELSE
	BEGIN   
		-- Determine base tax amounts and rates
		IF @annualized_wage BETWEEN 0.00 AND 5000.00
		BEGIN
			SELECT @tax_subtraction = 0, @rate = .0
		END
		ELSE IF @annualized_wage BETWEEN 5000.01 AND 22000.00
		BEGIN
			SELECT @tax_subtraction = 350, @rate = .07
		END
		ELSE IF @annualized_wage BETWEEN 22000.01 AND 40000.00
		BEGIN
			SELECT @tax_subtraction = 1890, @rate = .14
		END
		ELSE IF @annualized_wage BETWEEN 40000.01 AND 60000.00
		BEGIN
			SELECT @tax_subtraction = 6290, @rate = .25
		END
		ELSE IF @annualized_wage >= 60000.01
		BEGIN
			SELECT @tax_subtraction = 11090, @rate = .33
		END
		   
		-- Calculate tax
		SELECT @amt = ((@annualized_wage * @rate) - @tax_subtraction) / @ppds
	END
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[bspPRPRT11] TO [public]
GO
