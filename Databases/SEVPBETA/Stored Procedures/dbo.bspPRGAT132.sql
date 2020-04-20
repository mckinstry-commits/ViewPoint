SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StORed Procedure dbo.bspPRGAT132    Script Date: 8/28/99 9:33:20 AM ******/
   CREATE proc [dbo].[bspPRGAT132]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY:	EN 6/5/98
   *               GH 9/8/99 CORrected unmarried head of household OR married filing jointly AND one
   *                         spouse wORking rates, AND way exemptions are hANDled.
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 1/19/04 - issue 23529  update effective 1/1/2004
   *				EN 1/4/05 - issue 26244  default status AND exemptions
   *				MV 12/12/12 - TK-20169 2013 tax updates
   *				MV 01/28/13 - TFS_ID/147858 if no allowances are claimed then personal allowance(@adultexempt) is 0. 
   *
   * USAGE:
   * 	Calculates GeORgia Income Tax
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
   *	@msg		errOR message IF failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   
   *	1 		failure
   **********************************************************/
   (@subjamt bDollar = 0,
    @ppds tinyint = 0,
    @status char(1) = 'S',
    @regexempts tinyint = 0,
    @addexempts tinyint = 0,
    @amt bDollar = 0 output,
    @msg varchar(255) = null output)
    
	AS
	SET NOCOUNT ON
   
   DECLARE @rcode int, @adultexempt bDollar, @stddedn bDollar, @taxincome bDollar,
   @basetax bDollar, @limit bDollar, @rate bRate, @rate1 bRate, @rate2 bRate, @rate3 bRate,
   @rate4 bRate, @rate5 bRate, @rate6 bRate, @procname varchar(30)
   
   
   SELECT @rcode = 0
   SELECT @rate1 = .01, @rate2 = .02, @rate3 = .03, @rate4 = .04, @rate5 = .05, @rate6 = .06
   SELECT @procname = 'bspPRGAT132'
   
   -- #26244 set default status AND/OR exemptions IF passed in values are invalid
   IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('S','H','M','F','B')) SELECT @status = 'S'
   IF @regexempts IS NULL SELECT @regexempts = 0
   IF @addexempts IS NULL SELECT @addexempts = 0
   
   IF @ppds = 0
   BEGIN
   	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	RETURN @rcode
   END
   
   /* determine stANDard deduction AND adult exemption */
   SELECT @stddedn = 3000, @adultexempt = CASE @addexempts WHEN 0 THEN 0 ELSE 7400 END-- M - Married filing jointly
   IF @status = 'S' OR @status = 'H' SELECT @stddedn = 2300, @adultexempt = CASE @addexempts WHEN 0 THEN 0 ELSE 2700 END
   IF @status = 'F' OR @status = 'B' SELECT @stddedn = 1500, @adultexempt = CASE @addexempts WHEN 0 THEN 0 ELSE 3700 END
   
   /* determine taxable income */
   SELECT @taxincome = (@subjamt * @ppds) - @stddedn - @adultexempt - (@regexempts * 3000)
   IF @taxincome < 0 SELECT @taxincome = 0
   
   /* determine base tax and rate */
   /* single */
	IF @status = 'S'
   	BEGIN
   	 IF @taxincome <= 750						SELECT @basetax = 0,		@limit = 0,		@rate = @rate1
   	 IF @taxincome BETWEEN 750.01	AND 2250	SELECT @basetax = 7.5,		@limit = 750,	@rate = @rate2
   	 IF @taxincome BETWEEN 2250.01	AND 3750	SELECT @basetax = 37.5,		@limit = 2250,	@rate = @rate3
   	 IF @taxincome BETWEEN 3750.01	AND 5250	SELECT @basetax = 82.5,		@limit = 3750,	@rate = @rate4
   	 IF @taxincome BETWEEN 5250.01	AND	7000	SELECT @basetax = 142.5,	@limit = 5250,	@rate = @rate5
   	 IF @taxincome >=      7000.01				SELECT @basetax = 230,		@limit = 7000,	@rate = @rate6
   	END
   
   /* unmarried head of household OR married filing jointly AND one spouse wORking */
	IF @status = 'H' OR @status = 'M'
   	BEGIN
   	 IF @taxincome <= 1000							SELECT @basetax = 0,	@limit = 0,		@rate = @rate1
   	 IF @taxincome BETWEEN 1000.01	AND 3000		SELECT @basetax = 10,	@limit = 1000,	@rate = @rate2
   	 IF @taxincome BETWEEN 3000.01	AND 5000		SELECT @basetax = 50,	@limit = 3000,	@rate = @rate3
   	 IF @taxincome BETWEEN 5000.01	AND 7000		SELECT @basetax = 110,	@limit = 5000,	@rate = @rate4
   	 IF @taxincome BETWEEN 7000.01	AND 10000	SELECT @basetax = 190,	@limit = 7000,	@rate = @rate5
   	 IF @taxincome >=	   10000.01				SELECT @basetax = 340,	@limit = 10000,	@rate = @rate6
   	END
   
   /* married filing separately OR married both wORking */
   IF @status = 'F' OR @status = 'B'
   	BEGIN
   	 IF @taxincome <= 500						SELECT @basetax = 0,	@limit = 0,		@rate = @rate1
   	 IF @taxincome BETWEEN  500.01	AND	1500	SELECT @basetax = 5,	@limit = 500,	@rate = @rate2
   	 IF @taxincome BETWEEN 1500.01	AND 2500	SELECT @basetax = 25,	@limit = 1500,	@rate = @rate3
   	 IF @taxincome BETWEEN 2500.01	AND	3500	SELECT @basetax = 55,	@limit = 2500,	@rate = @rate4
   	 IF @taxincome BETWEEN 3500.01	AND	5000	SELECT @basetax = 95,	@limit = 3500,	@rate = @rate5
   	 IF @taxincome >=	   5000.01				SELECT @basetax = 170,	@limit = 5000,	@rate = @rate6
   	END
   
   /* calculate tax */
   SELECT @amt = (@basetax + ((@taxincome - @limit) * @rate)) / @ppds
   IF @amt < 0 SELECT @amt = 0
   
   
   bspexit:
   	return @rcode
   
GO
GRANT EXECUTE ON  [dbo].[bspPRGAT132] TO [public]
GO
