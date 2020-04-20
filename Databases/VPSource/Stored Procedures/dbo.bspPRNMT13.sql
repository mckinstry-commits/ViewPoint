
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPRNMT13]
/********************************************************
* CREATED BY: 	EN 10/26/00 - this revision effective 1/1/2001
* MODIFIED BY:  EN 11/29/00 - lowest tax bracket not being calculated correctly
* 				EN 11/26/01 - issue 15183 - revision effective 1/1/2002
*				EN 10/8/02 - issue 18877 change double quotes to single
*				EN 10/28/02 issue 19131  tax update effective 1/1/2003
*				EN 5/13/03 - issue 21259  tax update effective retroactive 1/1/2003
*				EN 10/13/03 - issue 22712  update effective retroactive to 7/1/03
*				EN 11/21/03 - issue 23079  update effective 1/1/2004
*				EN 12/17/04 - issue 26566  update effective 1/1/2005
*				EN 1/10/05 - issue 26244  default status and exemptions
*				EN 11/18/05 - issue 30404  update effective 1/1/2006
*				EN 11/27/06 - issue 123200  update effective 1/1/2007
*				EN 12/13/07 - issue 126489  update effecitve 1/1/2008
*				EN 12/12/08 - issue 131077 update effective 1/1/2009 - removed restriction that annual tax amts under $29 need not be considered
*				MV 12/23/10 - #142595  updates effective 1/1/11
*				KK 11/29/10 - TK-10383 #145138 updates effective 1/1/12, and refactored code
*				MV 01/15/13 - TK-20811 2013 tax updates effective 1/1/13
*
* USAGE:
* 	Calculates New Mexico Income Tax
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
*	1 			failure
**********************************************************/
(@subjamt bDollar = 0, 
 @ppds tinyint = 0, 
 @status char(1) = 'S', 
 @exempts tinyint = 0,
 @amt bDollar = 0 OUTPUT, 
 @msg varchar(255) = NULL OUTPUT)

AS
SET NOCOUNT ON

DECLARE @rcode int, 
		@annualized_wage bDollar, 
		@deduction bDollar, 
		@rate bRate,
		@procname varchar(30), 
		@tax_addition bDollar, 
		@allowance bDollar, 
		@wage_bracket int

SELECT  @rcode = 0, 
		@allowance = 3900,
		@procname = 'bspPRNMT13'
		
-- #26244 set default status and/or exemptions if passed in values are invalid
IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('S','M')) 
BEGIN
	SELECT @status = 'S'
END

IF @exempts IS NULL 
BEGIN
	SELECT @exempts = 0
END

IF @ppds <> 0
BEGIN
	/* annualize taxable income */
	SELECT @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
	
	/* initialize calculation elements */
	IF @status = 'S'
	BEGIN
	
		IF @annualized_wage <= 2200
		BEGIN
			SELECT @amt = 0
			RETURN 0
		END
		ELSE IF @annualized_wage BETWEEN 2200.01  AND 7700 
			BEGIN SELECT @tax_addition = 0.00,    @wage_bracket = 2200, @rate = .017 END
		ELSE IF @annualized_wage BETWEEN 7700.01  AND 13200
			BEGIN SELECT @tax_addition = 93.50,   @wage_bracket = 7700, @rate = .032 END
		ELSE IF @annualized_wage BETWEEN 13200.01 AND 18200
			BEGIN SELECT @tax_addition = 269.50,  @wage_bracket = 13200, @rate = .047 END
		ELSE IF @annualized_wage BETWEEN 18200.01 AND 28200
			BEGIN SELECT @tax_addition = 504.50,  @wage_bracket = 18200, @rate = .049 END
		ELSE IF @annualized_wage BETWEEN 28200.01 AND 44200
			BEGIN SELECT @tax_addition = 994.50,  @wage_bracket = 28200, @rate = .049 END
		ELSE IF @annualized_wage BETWEEN 44200.01 AND 67200
			BEGIN SELECT @tax_addition = 1778.50, @wage_bracket = 44200, @rate = .049 END
		ELSE 
			BEGIN SELECT @tax_addition = 2905.50, @wage_bracket = 67200, @rate = .049 END
	END

	IF @status = 'M'
	BEGIN
		IF @annualized_wage <= 8300
		BEGIN
			SELECT @amt = 0
			RETURN 0
		END
		ELSE IF @annualized_wage BETWEEN 8300.01  AND 16300 
			BEGIN SELECT @tax_addition = 0.00,    @wage_bracket = 8300, @rate = .017 END
		ELSE IF @annualized_wage BETWEEN 16300.01 AND 24300
			BEGIN SELECT @tax_addition = 136.00,  @wage_bracket = 16300, @rate = .032 END
		ELSE IF @annualized_wage BETWEEN 24300.01 AND 32300
			BEGIN SELECT @tax_addition = 392.00,  @wage_bracket = 24300, @rate = .047 END
		ELSE IF @annualized_wage BETWEEN 32300.01 AND 48300
			BEGIN SELECT @tax_addition = 768.00,  @wage_bracket = 32300, @rate = .049 END
		ELSE IF @annualized_wage BETWEEN 48300.01 AND 72300
			BEGIN SELECT @tax_addition = 1552.00, @wage_bracket = 48300, @rate = .049 END
		ELSE IF @annualized_wage BETWEEN 72300.01 AND 108300
			BEGIN SELECT @tax_addition = 2728.00, @wage_bracket = 72300, @rate = .049 END
		ELSE 
			BEGIN SELECT @tax_addition = 4492, @wage_bracket = 108300, @rate = .049 END
	END
	/* calculate New Mexico Tax */
	SELECT @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate)
	SELECT @amt = @amt / @ppds
	IF @amt < 0
	BEGIN
		SELECT @amt = 0
	END
END

ELSE
BEGIN
	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
END

RETURN @rcode
GO


GRANT EXECUTE ON  [dbo].[bspPRNMT13] TO [public]
GO
