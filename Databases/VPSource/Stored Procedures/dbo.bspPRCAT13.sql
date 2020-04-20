
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPRCAT13]
/********************************************************
* CREATED BY: 	EN	11/29/2000	- this revision effective 1/1/2001
* MODIFIED BY:  EN	12/11/2001	- change effective 1/1/2002
*				EN	10/07/2002	- #18877 change double quotes to single
*				EN	10/19/2002	- #19393 change effective 1/1/2003
*				EN	11/19/2003	- #23040 change effective 1/1/2004
*				EN	12/31/2004	- #26244 default status and exemptions
*				EN	11/28/2005	- #30680 change effective 1/1/2006
*				EN	11/13/2006	- #123075 update effective 1/1/2007
*				EN	11/14/2007	- #125988 update effective 1/1/2008
*				EN	12/03/2008	- #131308 update effective 1/1/2009
*				EN	04/20/2009	- #133341 update effective ASAP
*				EN	10/05/2009	- #135373 update effective 11/1/2009
*				EN	11/30/2009	- #136817 update effective 1/1/2010
*			    CHS	11/11/2010	- #142042 update effective 1/1/2011
*				KK	10/28/2011	- TK-09330/#144891 update effective 1/1/2012 (refactored code)
*				KK	10/30/2012	- B-11485/#147373 update effective 1/1/2013
*				CHS 12/07/2012	- B-11769 /#147522 update effective 1/1/2013 (with changes from Proposition 30) 
*
* USAGE:
* 	Calculates California Income Tax
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status
*	@regexempts	# of regular exemptions
*	@addexempts	# of additional exemptions
*
* OUTPUT PARAMETERS:
*	@amt		calculated tax amount
*	@msg		error message if failure
*
* RETURN VALUE:
* 	0 	    success
*	1 		failure
**********************************************************/
(@subjamt bDollar = 0, 
 @ppds tinyint = 0, 
 @status char(1) = 'S', 
 @regexempts tinyint = 0, -- Regular exemptions (Table 4)
 @addexempts tinyint = 0, -- Additional exemptions (Table 2: estimated deductions)
 @amt bDollar = 0 OUTPUT, 
 @msg varchar(255) = NULL OUTPUT)

AS
SET NOCOUNT ON

DECLARE @lowexempt bDollar, 
	    @stddedn bDollar, 
	    @annualamt bDollar,
	    @taxable bDollar,
		@estdedn bDollar, 
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
		@rate9 bRate, 
		@rate10 bRate,		
		@exempamt bDollar

SELECT @lowexempt = 0, 
	   @stddedn = 0, 
	   @annualamt = 0,
	   @taxable = 0, 
	   @estdedn = 1000, -- estdedn (Table 2: estimated deduction for additional exemptions) 
	   @basetax = 0, 
	   @limit = 0, 
	   @rate = 0,
	   @rate1 = .0110, 
	   @rate2 = .0220, 
	   @rate3 = .0440, 
	   @rate4 = .0660, 
	   @rate5 = .0880, 
	   @rate6 = .1023, 
	   @rate7 = .1133,
	   @rate8 = .1243, 
	   @rate9 = .1353, 
	   @rate10 = .1463,	   
	   @exempamt = 114.40 -- Regular exemption allowance (Table 4)

-- #26244 set default status and/or exemptions if passed in values are invalid
IF (@status IS NULL) OR 
   (@status IS NOT NULL AND @status NOT IN ('S','M','H')) 
BEGIN
	SELECT @status = 'S'
END

IF @regexempts IS NULL SELECT @regexempts = 0
IF @addexempts IS NULL SELECT @addexempts = 0

IF @ppds = 0
BEGIN
	SELECT @msg = 'bspPRCAT13:  Missing # of Pay Periods per year!' 
	RETURN 1
END

/* determine low income exemption (Table 1) and standard deduction (Table 3) */
IF (@status = 'M' AND @regexempts >= 2) OR @status = 'H'
BEGIN
	SELECT @lowexempt = 25537, @stddedn = 7682
END
ELSE
BEGIN
	SELECT @lowexempt = 12769, @stddedn = 3841
END

/* annualize income */
SELECT @annualamt = @subjamt * @ppds

/* if gross annual earnings are below the low income exemption, the taxable amount is 0.00 */
IF @annualamt < @lowexempt
BEGIN
	SELECT @amt = 0.00
	RETURN 0
END

/* deterine taxable amount: annualized income, less std deduction and additional estimated deduction */
SELECT @taxable = @annualamt - @stddedn - (@addexempts * @estdedn)
 
/* determine base tax amounts and rates */
/* single */
IF @status <> 'M' AND @status <> 'H' -- from Table 5 single
BEGIN
	IF		@taxable BETWEEN	  0.00 AND    7455 BEGIN SELECT @basetax =      0.00, @limit =       0, @rate = @rate1  END
	ELSE IF @taxable BETWEEN   7455.01 AND   17676 BEGIN SELECT @basetax =     82.01, @limit =    7455, @rate = @rate2  END
	ELSE IF @taxable BETWEEN  17676.01 AND   27897 BEGIN SELECT @basetax =    306.87, @limit =   17676, @rate = @rate3  END
	ELSE IF @taxable BETWEEN  27897.01 AND   38726 BEGIN SELECT @basetax =    756.59, @limit =   27897, @rate = @rate4  END
	ELSE IF @taxable BETWEEN  38726.01 AND   48942 BEGIN SELECT @basetax =   1471.30, @limit =   38726, @rate = @rate5  END
	ELSE IF @taxable BETWEEN  48942.01 AND  250000 BEGIN SELECT @basetax =   2370.31, @limit =   48942, @rate = @rate6  END
	ELSE IF @taxable BETWEEN 250000.01 AND  300000 BEGIN SELECT @basetax =  22938.54, @limit =  250000, @rate = @rate7  END	
	ELSE IF @taxable BETWEEN 300000.01 AND  500000 BEGIN SELECT @basetax =  28603.54, @limit =  300000, @rate = @rate8  END	
	ELSE IF @taxable BETWEEN 500000.01 AND 1000000 BEGIN SELECT @basetax =  53463.54, @limit =  500000, @rate = @rate9  END	
	ELSE										   BEGIN SELECT @basetax = 121113.54, @limit = 1000000, @rate = @rate10 END
END

/* married */
ELSE IF @status = 'M' -- from Table 5 Married
BEGIN
	IF		@taxable BETWEEN      0.00 AND	 14910 BEGIN SELECT @basetax =      0.00, @limit =       0, @rate = @rate1  END
	ELSE IF @taxable BETWEEN  14910.01 AND   35352 BEGIN SELECT @basetax =    164.01, @limit =   14910, @rate = @rate2  END
	ELSE IF @taxable BETWEEN  35352.01 AND   55794 BEGIN SELECT @basetax =    613.73, @limit =   35352, @rate = @rate3  END
	ELSE IF @taxable BETWEEN  55794.01 AND   77452 BEGIN SELECT @basetax =   1513.18, @limit =   55794, @rate = @rate4  END
	ELSE IF @taxable BETWEEN  77452.01 AND   97884 BEGIN SELECT @basetax =   2942.61, @limit =   77452, @rate = @rate5  END
	ELSE IF @taxable BETWEEN  97884.01 AND  500000 BEGIN SELECT @basetax =   4740.63, @limit =   97884, @rate = @rate6  END
	ELSE IF @taxable BETWEEN 500000.01 AND  600000 BEGIN SELECT @basetax =  45877.10, @limit =  500000, @rate = @rate7  END
	ELSE IF @taxable BETWEEN 600000.01 AND 1000000 BEGIN SELECT @basetax =  57207.10, @limit =  600000, @rate = @rate8  END
	ELSE										   BEGIN SELECT @basetax = 106927.10, @limit = 1000000, @rate = @rate10 END
END

/* head of household */
ELSE IF @status = 'H' -- from Table 5 Head of household
BEGIN
	IF		@taxable BETWEEN      0.00 AND	 14920 BEGIN SELECT @basetax =      0.00, @limit =       0, @rate = @rate1  END
	ELSE IF @taxable BETWEEN  14920.01 AND   35351 BEGIN SELECT @basetax =    164.12, @limit =   14920, @rate = @rate2  END
	ELSE IF @taxable BETWEEN  35351.01 AND   45571 BEGIN SELECT @basetax =    613.60, @limit =   35351, @rate = @rate3  END
	ELSE IF @taxable BETWEEN  45571.01 AND   56400 BEGIN SELECT @basetax =   1063.28, @limit =   45571, @rate = @rate4  END
	ELSE IF @taxable BETWEEN  56400.01 AND   66618 BEGIN SELECT @basetax =   1777.99, @limit =   56400, @rate = @rate5  END
	ELSE IF @taxable BETWEEN  66618.01 AND  340000 BEGIN SELECT @basetax =   2677.17, @limit =   66618, @rate = @rate6  END
	ELSE IF @taxable BETWEEN 340000.01 AND  408000 BEGIN SELECT @basetax =  30644.15, @limit =  340000, @rate = @rate7  END
	ELSE IF @taxable BETWEEN 408000.01 AND  680000 BEGIN SELECT @basetax =  38348.55, @limit =  408000, @rate = @rate8  END
	ELSE IF @taxable BETWEEN 680000.01 AND 1000000 BEGIN SELECT @basetax =  72158.15, @limit =  680000, @rate = @rate9  END	
	ELSE										   BEGIN SELECT @basetax = 115454.15, @limit = 1000000, @rate = @rate10 END
END

/* calculate tax */
SELECT @amt = (@basetax + (@taxable - @limit) * @rate)

/* adjust for personal exemption */
SELECT @amt = @amt - (@regexempts * @exempamt) -- multiply regexempts by exemption allowance from Table 4

/* finish calculation */
IF @amt < 0 SELECT @amt = 0.00
SELECT @amt = @amt / @ppds

RETURN 0
GO


GRANT EXECUTE ON  [dbo].[bspPRCAT13] TO [public]
GO
