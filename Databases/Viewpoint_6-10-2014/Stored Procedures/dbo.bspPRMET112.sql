SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRMET112]    Script Date: 10/26/2007 10:20:46 ******/
   CREATE PROC [dbo].[bspPRMET112]
   /********************************************************
   * CREATED BY: 	EN 12/13/00 - tax update effective 1/1/2001
   * MODIFIED BY:  EN 11/13/01 - issue 15015
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 12/09/02 - issue 19593  tax update effective 1/1/2003
   *				EN 10/29/03 - issue 22881 tax update effective 1/1/2004
   *				EN 11/16/04 - issue 26218 tax update effective 1/1/2005
   *				EN 1/4/05 - issue 26244  default status and exemptions
   *				EN 11/02/05 - issue 30243  tax update effective 1/1/2006
   *				EN 11/27/06 - issue 123198  tax update effective 1/1/2007
   *				EN 10/26/07 - issue 125983  tax update effective 1/1/2008
   *				EN 11/25/08 - #131231  bracket range and base tax update effective 1/1/2009
   *				EN 11/13/2009 #136568  bracket range and base tax update effective 1/1/2010
   *				EN 12/29/2010 #142397  tax update effective 1/1/2011
   *
   * USAGE:
   * 	Calculates Maine Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status
   *	@exempts	# of exemptions
   *	@nonresalienyn	= Y if employee is a Nonresident Alien, else = N
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
	@status char(1) = 'S', 
	@exempts tinyint = 0,
	@nonresalienyn bYN = 'N',
	@amt bDollar = 0 output, 
	@msg varchar(255) = NULL output)

	AS
	SET NOCOUNT ON

	DECLARE @ReturnCode int, 
		@AnnualizedWage bDollar, 
		@WithholdingAllowance bDollar, 
		@Rate bRate,
		@Procname varchar(30), 
		@BaseTaxAmt bDollar, 
		@BracketBaseAmt int

	SELECT @ReturnCode = 0, 
		@WithholdingAllowance = 2850, 
		@Procname = 'bspPRMET112'

	-- #26244 set default status and/or exemptions if passed in values are invalid
	-- #123198  As of 1/1/2007 Maine stopped including a table for 'B' ... if employee is married filing separately
	--   with the intent of withholding at the single rate, filing status 'S' should be used.
	IF (@status IS NULL) OR (@status IS NOT NULL and @status NOT IN ('S','M','B')) SELECT @status = 'S'
	IF @exempts IS NULL SELECT @exempts = 0

	IF @ppds = 0
	BEGIN
		SELECT @msg = @Procname + ':  Missing # of Pay Periods per year!', @ReturnCode = 1
		RETURN @ReturnCode
	END
   
   
	-- annualize earnings then subtract standard deductions
	SELECT @AnnualizedWage = (@subjamt * @ppds) - (@WithholdingAllowance * @exempts)

	-- adjust AnnualWage for Nonresident Aliens (New feature as of 1/1/2011!)
	IF @nonresalienyn = 'Y'
	BEGIN
		SELECT @AnnualizedWage = @AnnualizedWage + 5800
	END

	-- determine calculation values based on bracket
	IF @status = 'S' --single wage table and tax
	BEGIN
		IF @AnnualizedWage < 2950
		BEGIN
			SELECT @amt = 0
			RETURN @ReturnCode
		END 
		ELSE IF @AnnualizedWage BETWEEN 2950 AND 7950 - .01
		BEGIN
			SELECT @BaseTaxAmt = 0, @BracketBaseAmt = 2950, @Rate = .02
		END
		ELSE IF @AnnualizedWage BETWEEN 7950 AND 12900 - .01
		BEGIN
			SELECT @BaseTaxAmt = 100, @BracketBaseAmt = 7950, @Rate = .045
		END
		ELSE IF @AnnualizedWage BETWEEN 12900 AND 22900 - .01
		BEGIN
			SELECT @BaseTaxAmt = 323, @BracketBaseAmt = 12900, @Rate = .07
		END
		ELSE
		BEGIN
			SELECT @BaseTaxAmt = 1023, @BracketBaseAmt = 22900, @Rate = .085
		END
	END
	ELSE --married wage table and tax
	BEGIN
		IF @AnnualizedWage < 6800
		BEGIN
			SELECT @amt = 0
			RETURN @ReturnCode
		END 
		ELSE IF @AnnualizedWage BETWEEN 6800 AND 16800 - .01
		BEGIN
			SELECT @BaseTaxAmt = 0, @BracketBaseAmt = 6800, @Rate = .02
		END
		ELSE IF @AnnualizedWage BETWEEN 16800 AND 26750 - .01
		BEGIN
			SELECT @BaseTaxAmt = 200, @BracketBaseAmt = 16800, @Rate = .045
		END
		ELSE IF @AnnualizedWage BETWEEN 26750 AND 46700 - .01
		BEGIN
			SELECT @BaseTaxAmt = 648, @BracketBaseAmt = 26750, @Rate = .07
		END
		ELSE
		BEGIN
			SELECT @BaseTaxAmt = 2045, @BracketBaseAmt = 46700, @Rate = .085
		END
	END
   
	-- calculate Maine Tax
	SELECT @amt = @BaseTaxAmt + ((@AnnualizedWage - @BracketBaseAmt) * @Rate)

	IF @amt<=40 SELECT @amt=0 --#30243 apply low income tax credit

	SELECT @amt = ROUND((@amt / @ppds),0) --Maine specifies that tax is to be rounded to the nearest dollar


	RETURN @ReturnCode

GO
GRANT EXECUTE ON  [dbo].[bspPRMET112] TO [public]
GO
