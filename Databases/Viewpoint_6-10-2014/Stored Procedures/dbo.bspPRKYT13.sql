SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPRKYT13]
/********************************************************
* CREATED BY:   EN 10/26/00 - this revision effective 1/1/2001
* MODIFIED BY:  EN 04/11/02 - #16966 Std dedn changed from $1750 (year 2001) to $1800
*				EN 10/08/02 - #18877 change double quotes to single
*				EN 11/11/03 - #22982 Std dedn changed from $1800 to $1870 (note that it should have been $1830 in 2003 but we did not have that info)
*				EN 11/08/04 - #26052 Std dedn changed from $1870 to $1910
*				EN 01/04/05 - #26244 default exemptions
*				EN 07/05/05 - #29119 update effective 1/1/05 - added 5.8% tax bracket
*				EN 12/13/05 - #30336 update effective 12/13/05 - changed std dedn from $1910 to $1970
*				EN 12/11/06 - #123293 update effective 1/1/07 - changed std dedn from $1970 to $2050
*				EN 12/20/07 - #126565 update effective 1/1/08 - changed std dedn from $2050 to $2100
*				EN 12/17/08 - #131505 update effective 1/1/2009 - changed std dedn from $2100 to $2190
*				EN 12/17/09 - #137123 update effective 1/1/2010 - changed std dedn from $2190 to $2210
*				EN 11/16/10 - #141634 update effective 1/1/2011 - changed std dedn from $2210 to $2240
*				KK 11/08/12 - #144966 Update effective 1/1/2012 - changed std dedn from $2240 to $2290 and refactored
*				KK 10/24/12 - B-11431/#147345 Update effective 1/1/2013 - changed std dedn from $2290 to $2360 and refactored with no GOTOs
*				KK 10/29/12 - B-11431/#147345 Revision for reusability
*
*
* USAGE:
* 	Calculates Kentucky Income Tax
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status
*	@exempts	# of exemptions
*
* OUTPUT PARAMETERS:
*	@amt	calculated tax amount
*	@msg	error message if failure
*
* RETURN VALUE:
*   0 	    success
*	1 		failure
**********************************************************/
(@subjamt bDollar = 0, 
 @ppds tinyint = 0, 
 @exempts tinyint = 0,
 @amt bDollar = 0 OUTPUT, 
 @msg varchar(255) = NULL OUTPUT)

AS
SET NOCOUNT ON

DECLARE @rcode int, 
		@taxincome bDollar, 
		@stddedn bDollar, 
		@creditamt bDollar,
		@procname varchar(30), 
		@rateA bRate,
		@rateB bRate,
		@rateC bRate,
		@rateD bRate,
		@rateE bRate,
		@rateF bRate,
		@calcamtA bDollar,
		@calcamtB bDollar,
		@calcamtC bDollar,
		@calcamtD bDollar,
		@calcamtE bDollar

SELECT  @rcode = 0, 
	    @stddedn = 2360, 
	    @creditamt = 20, -- credit per exemption
	    @procname = 'bspPRKYT13'

-- #26244 set default exemptions if passed in values are invalid
IF @exempts IS NULL SELECT @exempts = 0

IF @ppds = 0
BEGIN
	SELECT @msg = @procname + ': Missing # of Pay Periods per year!'
	RETURN 1
END

/* determine taxable income */
SELECT @taxincome = (@subjamt * @ppds) - @stddedn
IF @taxincome < 0 
BEGIN
	SELECT @taxincome = 0
END

SELECT  @rateA = .020,
		@rateB = .030,
		@rateC = .040,
		@rateD = .050,
		@rateE = .058,
		@rateF = .060
SELECT	@calcamtA = 3000 * @rateA,				 -- 2013: 60
		@calcamtB = (1000 * @rateB) + @calcamtA, -- 2013: 90 = 30 + 60
		@calcamtC = (1000 * @rateC) + @calcamtB, -- 2013: 130 = 40 + 90
		@calcamtD = (3000 * @rateD) + @calcamtC, -- 2013: 280 = 150 + 130 
		@calcamtE = (67000 * @rateE) + @calcamtD -- 2013: 4166 = 3886 + 280
		-- More than $67,000.00 will calculate at a rate of 6%
		
/* calculate tax */
IF		@taxincome BETWEEN    0.00 AND  3000 SELECT @amt = @taxincome * @rateA -- First 3000
ELSE IF	@taxincome BETWEEN 3000.01 AND  4000 SELECT @amt = @calcamtA + ((@taxincome - 3000) * @rateB) -- Next 1000
ELSE IF	@taxincome BETWEEN 4000.01 AND  5000 SELECT @amt = @calcamtB + ((@taxincome - 4000) * @rateC) -- Next 1000
ELSE IF	@taxincome BETWEEN 5000.01 AND  8000 SELECT @amt = @calcamtC + ((@taxincome - 5000) * @rateD) -- Next 3000
ELSE IF	@taxincome BETWEEN 8000.01 AND 75000 SELECT @amt = @calcamtD + ((@taxincome - 8000) * @rateE) -- Next 67000
ELSE										 SELECT @amt = @calcamtE + ((@taxincome - 75000) * @rateF) -- excess of 75000

/* subtract credits */
SELECT @amt = @amt - (@exempts * @creditamt)

/* de-annualize tax amount */
SELECT @amt = @amt/@ppds
IF @amt < 0 SELECT @amt = 0

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[bspPRKYT13] TO [public]
GO
