SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[bspPRNDT132]
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
  *				EN 12/27/2012 B-12061/#147738/TK-20387  update effective 1/1/2013
  *				EN 7/3/2013 User Story 54541/Task 54549  update effective 1/1/2013 (revision)
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
  
SELECT @allowance = 3900

SELECT @rate1 = .0122, 
	   @rate2 = .0227, 
	   @rate3 = .0252, 
	   @rate4 = .0293, 
	   @rate5 = .0322
  
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
	IF @taxincome BETWEEN   4100.01 AND  39000 SELECT @basetax =     0.00, @limit =   4100, @rate = @rate1
  	IF @taxincome BETWEEN  39000.01 AND  81000 SELECT @basetax =   425.78, @limit =  39000, @rate = @rate2
  	IF @taxincome BETWEEN  81000.01 AND 185000 SELECT @basetax =  1379.18, @limit =  81000, @rate = @rate3
  	IF @taxincome BETWEEN 185000.01 AND 400000 SELECT @basetax =  3999.98, @limit = 185000, @rate = @rate4
  	IF @taxincome >						400000 SELECT @basetax = 10299.48, @limit = 400000, @rate = @rate5
END
IF @status = 'M' --Married
BEGIN
	IF @taxincome BETWEEN  10000.01 AND  69000 SELECT @basetax =     0.00, @limit =  10000, @rate = @rate1
  	IF @taxincome BETWEEN  69000.01 AND 130000 SELECT @basetax =   719.80, @limit =  69000, @rate = @rate2
  	IF @taxincome BETWEEN 130000.01 AND 231000 SELECT @basetax =  2104.50, @limit = 130000, @rate = @rate3
  	IF @taxincome BETWEEN 231000.01 AND 405000 SELECT @basetax =  4649.70, @limit = 231000, @rate = @rate4
  	IF @taxincome >						405000 SELECT @basetax =  9747.90, @limit = 405000, @rate = @rate5
END
  
  /* calculate tax */
  SELECT @amt = ROUND((@basetax + ((@taxincome - @limit) * @rate)) / @ppds, 0)
  
  IF @amt < 0 SELECT @amt = 0
  
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspPRNDT132] TO [public]
GO
