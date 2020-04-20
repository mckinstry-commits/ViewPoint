SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRART994    Script Date: 8/28/99 9:33:12 AM ******/
CREATE PROC [dbo].[bspPRART994]
/********************************************************
* CREATED BY: 	EN 6/1/98
* MODIFIED BY:	EN 1/12/99
*				EN 10/7/02 - issue 18877 change double quotes to single
*				EN 12/03/03 - issue 23061  added isnull check
*				EN 12/31/04 - issue 26244  default exemptions
*				EN 2/07/05 - issue 26943  added low income tax rate computation
*				EN 12/16/2011 TK-10782/#145193 fixed bracket 1 ... excess over should be set to @a2, not 3000
*
* USAGE:
* 	Calculates Arkansas Income Tax
*
* INPUT PARAMETERS:

*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status
*	@exempts	# of exemptions
*	@miscfactor 1 if using low income tax rates, else 0
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
 @status char(1) = '', 
 @exempts tinyint = 0,
 @miscfactor bRate, 
 @amt bDollar = 0 output, 
 @msg varchar(255) = null output)
 
AS
SET NOCOUNT ON

DECLARE @a1 bDollar, 
		@baseamt bDollar, 
		@rate bUnitCost, 
		@excessover bDollar, 
		@procname varchar(30)

/* validate pay periods */
IF @ppds = 0
BEGIN
	SELECT @msg = isnull(@procname,'') + ':  Missing # of Pay Periods per year!'
	RETURN 1
END

--#26943 declarations
DECLARE @a2 bDollar

SELECT @a1 = 0, 
	   @amt = 0,
	   @procname = 'bspPRART994'

-- #26244 set default exemptions if passed in value is invalid
IF ISNULL(@status, 'X') NOT IN ('','S','M','H')
BEGIN
	SELECT @status = ''
END

-- status of S, M, or H only applies for low income tax rate computations (ie. when misc factor=1)
IF ISNULL(@miscfactor, 0) = 0 
BEGIN
	SELECT @status = '' 
END

-- exemption value is required even if it is 0
IF @exempts IS NULL 
BEGIN
	SELECT @exempts = 0
END

-- Step 1 - annualize earnings
SELECT @a1 = @subjamt * @ppds

-- Step 2 - subtract standard deduction from annualized earnings
SELECT @a2 = @a1 - 2000
IF @a2 > 0
BEGIN
	-- Step 3 - determine tax bracket
	IF @a2 BETWEEN 0.01 AND 3000
	BEGIN
		SELECT @baseamt = 0, @rate = .01, @excessover = @a2
	END
	ELSE IF @a2 BETWEEN 3000.01 AND 6000
	BEGIN
		SELECT @baseamt = 30, @rate = .025, @excessover = @a2 - 3000
	END
	ELSE IF @a2 BETWEEN 6000.01 AND 9000
	BEGIN
		SELECT @baseamt = 105, @rate = .035, @excessover = @a2 - 6000
	END
	ELSE IF @a2 BETWEEN 9000.01 AND 15000
	BEGIN
		SELECT @baseamt = 210, @rate = .045, @excessover = @a2 - 9000
	END
	ELSE IF @a2 BETWEEN 15000.01 AND 25000
	BEGIN
		SELECT @baseamt = 480, @rate = .06, @excessover = @a2 - 15000
	END
	ELSE IF @a2 > 25000.01
	BEGIN
		SELECT @baseamt = 1080, @rate = .07, @excessover = @a2 - 25000
	END

	-- calculate tax
	SELECT @amt = @baseamt + (@rate * @excessover)

	-- low income tax rate computations
	IF @status = 'S' --single
	BEGIN
		IF @a2 BETWEEN 7800 AND 9300 SELECT @amt = @amt / 3 --use 1/3 of normal tax rate
		IF @a2 BETWEEN 9300.01 AND 11400 SELECT @amt = (@amt / 3) * 2 --use 2/3 of normal tax rate
	END
	IF @status = 'M' --married filing joint
	BEGIN
		IF @a2 BETWEEN 15500 AND 16000 SELECT @amt = @amt / 3 --use 1/3 of normal tax rate
		IF @a2 BETWEEN 16000.01 AND 16200 SELECT @amt = (@amt / 3) * 2 --use 2/3 of normal tax rate
	END
	IF @status = 'H' --unmarried head of household
	BEGIN
		IF @a2 BETWEEN 12100 AND 15200 SELECT @amt = @amt / 3 --use 1/3 of normal tax rate
		IF @a2 BETWEEN 15200.01 AND 16200 SELECT @amt = (@amt / 3) * 2 --use 2/3 of normal tax rate
	END

	-- Steps 4 through 6 - subtract personal tax credits and de-annualize then round
	SELECT @amt = (@amt - (@exempts * 20)) / @ppds
	SELECT @amt = ROUND(@amt, 2)
	
	IF @amt < 0 SELECT @amt = 0
END
ELSE
BEGIN
	SELECT @amt = 0
END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[bspPRART994] TO [public]
GO
