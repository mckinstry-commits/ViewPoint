SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  CREATE proc [dbo].[bspPRCAT12]
/********************************************************
* CREATED BY: 	EN 11/29/00 - this revision effective 1/1/2001
* MODIFIED BY:  EN 12/11/01 - change effective 1/1/2002
*				EN 10/7/02 - issue 18877 change double quotes to single
*				EN 10/19/02 - issue 19393  change effective 1/1/2003
*				EN 11/19/03 - issue 23040  change effective 1/1/2004
*				EN 12/31/04 - issue 26244  default status and exemptions
*				EN 11/28/05 - issue 30680  change effective 1/1/2006
*				EN 11/13/06 - issue 123075  update effective 1/1/2007
*				EN 11/14/07 - issue 125988  update effective 1/1/2008
*				EN 12/03/08 - #131308  update effective 1/1/2009
*				EN 4/20/2009 #133341  update effective ASAP
*				EN 10/5/2009 #135373  update effective 11/1/2009
*				EN 11/30/2009 #136817  update effective 1/1/2010
*				CHS 11/11/2010 #142042  update effective 1/1/2011
*				KK 10/28/2011- TK-09330 #144891 update effective 1/1/2012 (refactored code)
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
 @regexempts tinyint = 0,
 @addexempts tinyint = 0, 
 @amt bDollar = 0 output, 
 @msg varchar(255) = NULL output)

AS
SET NOCOUNT ON

DECLARE @rcode int, 
	    @lowexempt bDollar, 
	    @stddedn bDollar, 
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
		@exempamt bDollar

SELECT @rcode = 0, 
	   @lowexempt = 0, 
	   @stddedn = 0, 
	   @taxable = 0, 
	   @estdedn = 1000, -- estdedn is from Table 2
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
	   @exempamt = 112.20 --exemption allowance from Table 4

-- #26244 set default status and/or exemptions if passed in values are invalid
IF (@status IS NULL) OR 
   (@status IS NOT NULL AND @status NOT IN ('S','M','H')) 
BEGIN
	SELECT @status = 'S'
END

IF @regexempts IS NULL 
BEGIN
	SELECT @regexempts = 0
END

IF @addexempts IS NULL
BEGIN
	SELECT @addexempts = 0
END

IF @ppds <> 0
BEGIN
	/* determine low income exemption and standard deduction */
	IF (@status = 'M' AND @regexempts >= 2) OR @status = 'H'
	BEGIN
		SELECT @lowexempt = 25054, @stddedn = 7538 -- lowexempt is from Table 1 and stddedn is from Table 3
	END
	ELSE
	BEGIN
		SELECT @lowexempt = 12527, @stddedn = 3769 -- lowexempt is from Table 1 and stddedn is from Table 3
	END

	/* determine taxable amount */
	IF @subjamt * @ppds >= @lowexempt 
	BEGIN
		SELECT @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)

		/* determine base tax amounts and rates */
		/* married */
		IF @status = 'M' -- from Table 5 Married
		BEGIN
			IF @taxable <= 14632						  BEGIN SELECT @basetax = 0, @limit = 0, @rate = @rate1 END
			ELSE IF @taxable BETWEEN 14632.01 AND 34692   BEGIN SELECT @basetax = 160.95, @limit = 14632, @rate = @rate2 END
			ELSE IF @taxable BETWEEN 34692.01 AND 54754   BEGIN SELECT @basetax = 602.27, @limit = 34692, @rate = @rate3 END
			ELSE IF @taxable BETWEEN 54754.01 AND 76008   BEGIN SELECT @basetax = 1485.00, @limit = 54754, @rate = @rate4 END
			ELSE IF @taxable BETWEEN 76008.01 AND 96058   BEGIN SELECT @basetax = 2887.76, @limit = 76008, @rate = @rate5 END
			ELSE IF @taxable BETWEEN 96058.01 AND 1000000 BEGIN SELECT @basetax = 4652.16, @limit = 96058, @rate = @rate6 END
			ELSE										  BEGIN SELECT @basetax = 97125.43, @limit = 1000000, @rate = @rate7 END
		END

		/* head of household */
		ELSE IF @status = 'H' -- from Table 5 Head of household
		BEGIN
			IF @taxable <= 14642						  BEGIN SELECT @basetax = 0, @limit = 0, @rate = @rate1 END
			ELSE IF @taxable BETWEEN 14642.01 AND 34692   BEGIN SELECT @basetax = 161.06, @limit = 14642, @rate = @rate2 END
			ELSE IF @taxable BETWEEN 34692.01 AND 44721   BEGIN SELECT @basetax = 602.16, @limit = 34692, @rate = @rate3 END
			ELSE IF @taxable BETWEEN 44721.01 AND 55348   BEGIN SELECT @basetax = 1043.44, @limit = 44721, @rate = @rate4 END
			ELSE IF @taxable BETWEEN 55348.01 AND 65376   BEGIN SELECT @basetax = 1744.82, @limit = 55348, @rate = @rate5 END
			ELSE IF @taxable BETWEEN 65376.01 AND 1000000 BEGIN SELECT @basetax = 2627.28, @limit = 65376, @rate = @rate6 END
			ELSE										  BEGIN SELECT @basetax = 98239.32, @limit = 1000000, @rate = @rate7 END
		END

		/* single */
		ELSE IF @status <> 'M' AND @status <> 'H' -- from Table 5 single
		BEGIN
			IF @taxable <= 7316							  BEGIN SELECT @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1 END
			ELSE IF @taxable BETWEEN 7316.01 AND 17346    BEGIN SELECT @basetax = 80.48, @limit = 7316, @rate = @rate2 END
			ELSE IF @taxable BETWEEN 17346.01 AND 27377   BEGIN SELECT @basetax = 301.14, @limit = 17346, @rate = @rate3 END
			ELSE IF @taxable BETWEEN 27377.01 AND 38004   BEGIN SELECT @basetax = 742.50, @limit = 27377, @rate = @rate4 END
			ELSE IF @taxable BETWEEN 38004.01 AND 48029   BEGIN SELECT @basetax = 1443.88, @limit = 38004, @rate = @rate5 END
			ELSE IF @taxable BETWEEN 48029.01 AND 1000000 BEGIN SELECT @basetax = 2326.08, @limit = 48029, @rate = @rate6 END
			ELSE										  BEGIN SELECT @basetax = 99712.71, @limit = 1000000, @rate = @rate7 END
		END

		/* calculate tax */
		SELECT @amt = (@basetax + (@taxable - @limit) * @rate)

		/* adjust for personal exemption */
		SELECT @amt = @amt - (@regexempts * @exempamt) -- multiply regexempts by exemption allowance from Table 4

		/* finish calculation */
		IF @amt < 0 
		BEGIN
			SELECT @amt = 0
		END

		SELECT @amt = @amt / @ppds
	END
END
ELSE
BEGIN
	SELECT @msg = 'bspPRCAT12:  Missing # of Pay Periods per year!', 
		   @rcode = 1
END

RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRCAT12] TO [public]
GO
