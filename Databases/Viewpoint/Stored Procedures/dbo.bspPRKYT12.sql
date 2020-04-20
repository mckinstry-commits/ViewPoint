SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRKYT12]    Script Date: 12/20/2007 07:54:34 ******/
CREATE PROC [dbo].[bspPRKYT12]
/********************************************************
* CREATED BY: EN 10/26/00 - this revision effective 1/1/2001
* MODIFIED BY: EN 4/11/02 - issue 16966  Std dedn changed from $1750 (year 2001) to $1800
*				EN 10/8/02 - issue 18877 change double quotes to single
*				EN 11/11/03 - issue 22982  Std dedn changed from $1800 to $1870 (note that it should have been $1830 in 2003 but we did not have that info)
*				EN 11/08/04 - issue 26052  Std dedn changed from $1870 to $1910
*				EN 1/4/05 - issue 26244  default exemptions
*				EN 7/5/5 - issue 29119  update effective 1/1/05 - added 5.8% tax bracket
*				EN 12/13/05 - issue 30336  update effective 12/13/05 - changed std dedn from $1910 to $1970
*				EN 12/11/06 - issue 123293  update effective 1/1/07 - changed std dedn from $1970 to $2050
*				EN 12/20/07 - issue 126565  update effective 1/1/08 - changed std dedn from $2050 to $2100
*				EN 12/17/08 - #131505  update effective 1/1/2009 - changed std dedn from $2100 to $2190
*				EN 12/17/09 #137123  updated effective 1/1/2010 - changed std dedn from $2190 to $2210
*				EN 11/16/10 #141634  update effective 1/1/2011 - changed std dedn from $2210 to $2240
*				KK 11/08/12 #144966 Update effective 1/1/2012 - changed std dedn from $2240 to $2290 and refactored
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
*	@amt		calculated tax amount
*	@msg		error message if failure
*
* RETURN VALUE:
* 0 	    	success
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
		@procname varchar(30)

SELECT  @rcode = 0, 
	    @stddedn = 2290, 
	    @creditamt = 20,
	    @procname = 'bspPRKYT12'

-- #26244 set default exemptions if passed in values are invalid
IF @exempts IS NULL 
BEGIN
	SELECT @exempts = 0
END

IF @ppds <> 0
BEGIN
	/* determine taxable income */
	SELECT @taxincome = (@subjamt * @ppds) - @stddedn
	IF @taxincome < 0 
	BEGIN
		SELECT @taxincome = 0
	END

	/* calculate tax */
	IF @taxincome < 3000
	BEGIN
		SELECT @amt = .02 * @taxincome
		GOTO end_loop
	END

	SELECT @amt = (.02 * 3000)
	SELECT @taxincome = @taxincome - 3000

	IF @taxincome < 1000
	BEGIN
		SELECT @amt = @amt + (.03 * @taxincome)
		GOTO end_loop
	END

	SELECT @amt = @amt + (.03 * 1000)
	SELECT @taxincome = @taxincome - 1000

	IF @taxincome < 1000
	BEGIN
		SELECT @amt = @amt + (.04 * @taxincome)
		GOTO end_loop
	END

	SELECT @amt = @amt + (.04 * 1000)
	SELECT @taxincome = @taxincome - 1000

	IF @taxincome < 3000
	BEGIN
		SELECT @amt = @amt + (.05 * @taxincome)
		GOTO end_loop
	END

	SELECT @amt = @amt + (.05 * 3000)
	SELECT @taxincome = @taxincome - 3000

	--issue 29119 added 5.8% tax bracket
	IF @taxincome < 67000
	BEGIN
		SELECT @amt = @amt + (.058 * @taxincome)
		GOTO end_loop
	END

	SELECT @amt = @amt + (.058 * 67000)
	SELECT @taxincome = @taxincome - 67000

	SELECT @amt = @amt + (.06 * @taxincome)

	end_loop:

	/* subtract credits */
	SELECT @amt = @amt - (@exempts * @creditamt)

	/* de-annualize */
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
GRANT EXECUTE ON  [dbo].[bspPRKYT12] TO [public]
GO
