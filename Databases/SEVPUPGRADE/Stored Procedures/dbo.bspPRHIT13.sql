SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRHIT13    Script Date: 8/28/99 9:33:22 AM ******/
CREATE proc [dbo].[bspPRHIT13]
/********************************************************
* CREATED BY: 	EN 10/26/00 - this revision effective 1/1/2001
* MODIFIED BY:  EN 10/30/00 - not using correct rates for the 2 highest Married AND Single brackets
*				EN 12/18/01 - update effective 1/1/2002
*				EN 10/8/02 - issue 18877 change double quotes to single
*				EN 1/4/05 - issue 26244  default status AND exemptions
*				EN 11/06/06 - issue 123014  update effective 1/1/2007
*				EN 6/12/2009 #133757 updated effective 1/1/2009 (retroactive)
*				CHS	12/22/2010	- #142591 tax update effective 1/1/2011
*				KK 12/27/2011 - TK-11092 #145266 tax update effective 1/1/2012
*				MV 12/07/2012 - TK20106 tax updates effective 1/1/2013.
*
* USAGE:
* 	Calculates Hawaii Income Tax
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
*GRANT EXECUTE ON bspPRHIT11 TO public;
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
		@taxincome bDollar, 
		@allowance bDollar, 
		@basetax bDollar,
		@limit bDollar, 
		@rate bRate, 
		@rate1 bRate, 
		@rate2 bRate, 
		@rate3 bRate,
		@rate4 bRate, 
		@rate5 bRate, 
		@rate6 bRate, 
		@rate7 bRate, 
		@rate8 bRate, 
		@procname varchar(30)
 
SELECT @rcode = 0, 
	   @allowance = 1144,
	   @rate1 = .014, 
	   @rate2 = .032, 
	   @rate3 = .055, 
	   @rate4 = .064, 
	   @rate5 = .068, 
	   @rate6 = .072, 
	   @rate7 = .076, 
	   @rate8 = .079,
	   @procname = 'bspPRHIT13'
 
-- #26244 set default status and/or exemptions IF passed in values are invalid
IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('S','M')) SELECT @status = 'S'
IF @exempts IS NULL SELECT @exempts = 0
 
IF @ppds = 0
BEGIN
	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
	RETURN @rcode
END
 
/* determine taxable income */
SELECT @taxincome = (@subjamt * @ppds) - (@allowance * @exempts)
IF @taxincome < 0 SELECT @taxincome = 0
 
/* determine base tax AND rate */
SELECT @basetax = 0, 
	   @limit = 0, 
	   @rate = 0
 
IF @status = 'S'
BEGIN
	IF		@taxincome BETWEEN     0 AND  2400 SELECT @basetax =    0, @limit =     0, @rate = @rate1
	ELSE IF @taxincome BETWEEN  2400.01 AND  4800 SELECT @basetax =   34, @limit =  2400, @rate = @rate2
	ELSE IF @taxincome BETWEEN  4800.01 AND  9600 SELECT @basetax =  110, @limit =  4800, @rate = @rate3
	ELSE IF @taxincome BETWEEN  9600.01 AND 14400 SELECT @basetax =  374, @limit =  9600, @rate = @rate4
	ELSE IF @taxincome BETWEEN 14400.01 AND 19200 SELECT @basetax =  682, @limit = 14400, @rate = @rate5
	ELSE IF @taxincome BETWEEN 19200.01 AND 24000 SELECT @basetax = 1008, @limit = 19200, @rate = @rate6
	ELSE IF @taxincome BETWEEN 24000.01 AND 36000 SELECT @basetax = 1354, @limit = 24000, @rate = @rate7
	ELSE									   SELECT @basetax = 2266, @limit = 36000, @rate = @rate8
END
 
 IF @status = 'M'
BEGIN
	IF		@taxincome BETWEEN     0 AND  4800 SELECT @basetax =    0, @limit =     0, @rate = @rate1
	ELSE IF @taxincome BETWEEN  4800.01 AND  9600 SELECT @basetax =   67, @limit =  4800, @rate = @rate2
	ELSE IF @taxincome BETWEEN  9600.01 AND 19200 SELECT @basetax =  221, @limit =  9600, @rate = @rate3
	ELSE IF @taxincome BETWEEN 19200.01 AND 28800 SELECT @basetax =  749, @limit = 19200, @rate = @rate4
	ELSE IF @taxincome BETWEEN 28800.01 AND 38400 SELECT @basetax = 1363, @limit = 28800, @rate = @rate5
	ELSE IF @taxincome BETWEEN 38400.01 AND 48000 SELECT @basetax = 2016, @limit = 38400, @rate = @rate6
	ELSE IF @taxincome BETWEEN 48000.01 AND 72000 SELECT @basetax = 2707, @limit = 48000, @rate = @rate7
	ELSE					                   SELECT @basetax = 4531, @limit = 72000, @rate = @rate8
END
 
/* calculate tax */
SELECT @amt = (@basetax + ((@taxincome - @limit) * @rate)) / @ppds
IF @amt < 0 SELECT @amt = 0
 
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRHIT13] TO [public]
GO
