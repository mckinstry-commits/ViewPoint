SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPRNDT12]
 /********************************************************
  * CREATED BY: 	bc 6/15/98
  * MODIFIED BY:	GG 8/11/98
  *				EN 11/13/01 - issue 15016 - effective 1/1/2002
  *				EN 10/8/02 - issue 18877 change double quotes to single
  *				EN 11/11/02 issue 24562  update effective 1/1/2003
  *			 	EN 12/17/02 issue 24562  allowance changed back to 2002 value ($3,050.00)
  *				EN 12/01/03 issue 23129  update effective 1/1/2004
  *				EN 11/24/04 issue 26310  update effective 1/1/2005
  *				EN 1/10/05 - issue 26244  default status and exemptions
  *				EN 11/28/05 issue 30674  update effective 1/1/2006
  *				EN 11/06/06 issue 123018  update effective 1/1/2007
  *				EN 11/19/07 issue 126270  update effective 1/1/2008
  *				EN 12/18/08 #131519  update effective 1/1/2009
  *				EN 7/21/2009 #134844  update effective 1/1/2009 (ASAP)
  *				EN 12/2/2009 #136872  update effective 1/1/2010
  *				MV 12/23/10 #142570 updates effective 1/1/2011
  *				KK 06/14/2011 TK-05853 #144006 updates effective 1/1/2011 (Base tax amt and Excess Tax Rates)
  *				MV 12/14/11 TK-10758 - 2012 tax updates
  *
  * USAGE:
  * 	Calculates North Dakota Income Tax
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
  * 	0 	    success
  *		1 		failure
  **********************************************************/
(@subjamt bDollar = 0, 
 @ppds tinyint = 0, 
 @status char(1) = 'S', 
 @exempts tinyint = 0,
 @amt bDollar = 0 OUTPUT, 
 @msg varchar(255) = NULL OUTPUT)

AS
SET NOCOUNT ON
  
DECLARE @taxincome bDollar, 
		@allowance bDollar, 
		@basetax bDollar,
		@limit bDollar, 
		@rate bRate, 
		@rate1 bRate, 
		@rate2 bRate, 
		@rate3 bRate,
		@rate4 bRate, 
		@rate5 bRate
  
SELECT @allowance = 3800
--TK-05853 Updated rates as of 1/1/2011
SELECT @rate1 = .0151, 
	   @rate2 = .0282, 
	   @rate3 = .0313, 
	   @rate4 = .0363, 
	   @rate5 = .0399
  
-- #26244 set default status and/or exemptions if passed in values are invalid
IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('S','M')) 
BEGIN
	SELECT @status = 'S'
END

IF @exempts IS NULL SELECT @exempts = 0
 
IF @ppds = 0
BEGIN
  	SELECT @msg = 'Missing # of Pay Periods per year!'
	RETURN 1
END
  
/* determine taxable income */
SELECT @taxincome = (@subjamt * @ppds) - (@exempts * @allowance)
IF @taxincome < 1 SELECT @taxincome = 0
  
/* determine base tax and rate */
SELECT @basetax = 0, @limit = 0, @rate = 0

--TK-05853 Updated both filing status base taxes as of 1/1/2011  
IF @status = 'S' --Single
BEGIN
	IF @taxincome > 4000 AND @taxincome <= 38000 SELECT @basetax = 0, @limit = 4000, @rate = @rate1
  	IF @taxincome > 38000 AND @taxincome <= 79000 SELECT @basetax = 513.40, @limit = 38000, @rate = @rate2
  	IF @taxincome > 79000 AND @taxincome <= 180000 SELECT @basetax = 1669.60, @limit = 79000, @rate = @rate3
  	IF @taxincome > 180000 AND @taxincome <= 390000 SELECT @basetax = 4830.90, @limit = 180000, @rate = @rate4
  	IF @taxincome > 390000 SELECT @basetax = 12453.90, @limit = 390000, @rate = @rate5
END
IF @status = 'M' --Married
BEGIN
	IF @taxincome > 9600 AND @taxincome <= 67000 SELECT @basetax = 0, @limit = 9600, @rate = @rate1
  	IF @taxincome > 67000 AND @taxincome <= 127000 SELECT @basetax = 866.74, @limit = 67000, @rate = @rate2
  	IF @taxincome > 127000 AND @taxincome <= 225000 SELECT @basetax = 2558.74, @limit = 127000, @rate = @rate3
  	IF @taxincome > 225000 AND @taxincome <= 395000 SELECT @basetax = 5626.14, @limit = 225000, @rate = @rate4
  	IF @taxincome > 395000 SELECT @basetax = 11797.14, @limit = 395000, @rate = @rate5
END
  
  /* calculate tax */
  SELECT @amt = ROUND((@basetax + ((@taxincome - @limit) * @rate)) / @ppds, 0)
  
  IF @amt < 0 SELECT @amt = 0
  
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[bspPRNDT12] TO [public]
GO
