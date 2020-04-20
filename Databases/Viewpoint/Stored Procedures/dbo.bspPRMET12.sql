SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRMET12]    Script Date: 10/26/2007 10:20:46 ******/
   CREATE PROC [dbo].[bspPRMET12]
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
   *				EN 11/28/2011 TK-10385/#145057 tax update effective 1/1/2012
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
		@Procname = 'bspPRMET12'

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
		SELECT @AnnualizedWage = @AnnualizedWage + 5950
	END

	-- determine calculation values based on bracket
	IF @status = 'S' --single wage table and tax
	BEGIN
		IF @AnnualizedWage < 3100
		BEGIN
			SELECT @amt = 0
			RETURN @ReturnCode
		END 
		ELSE IF @AnnualizedWage BETWEEN 3100 AND 8200 - .01
		BEGIN
			SELECT @BaseTaxAmt = 0, @BracketBaseAmt = 3100, @Rate = .02
		END
		ELSE IF @AnnualizedWage BETWEEN 8200 AND 13250 - .01
		BEGIN
			SELECT @BaseTaxAmt = 102, @BracketBaseAmt = 8200, @Rate = .045
		END
		ELSE IF @AnnualizedWage BETWEEN 13250 AND 23450 - .01
		BEGIN
			SELECT @BaseTaxAmt = 329, @BracketBaseAmt = 13250, @Rate = .07
		END
		ELSE
		BEGIN
			SELECT @BaseTaxAmt = 1043, @BracketBaseAmt = 23450, @Rate = .085
		END
	END
	ELSE --married wage table and tax
	BEGIN
		IF @AnnualizedWage < 9050
		BEGIN
			SELECT @amt = 0
			RETURN @ReturnCode
		END 
		ELSE IF @AnnualizedWage BETWEEN 9050 AND 19250 - .01
		BEGIN
			SELECT @BaseTaxAmt = 0, @BracketBaseAmt = 9050, @Rate = .02
		END
		ELSE IF @AnnualizedWage BETWEEN 19250 AND 29400 - .01
		BEGIN
			SELECT @BaseTaxAmt = 204, @BracketBaseAmt = 19250, @Rate = .045
		END
		ELSE IF @AnnualizedWage BETWEEN 29400 AND 49750 - .01
		BEGIN
			SELECT @BaseTaxAmt = 661, @BracketBaseAmt = 29400, @Rate = .07
		END
		ELSE
		BEGIN
			SELECT @BaseTaxAmt = 2085, @BracketBaseAmt = 49750, @Rate = .085
		END
	END
   
	-- calculate Maine Tax
	SELECT @amt = @BaseTaxAmt + ((@AnnualizedWage - @BracketBaseAmt) * @Rate)

	IF @amt<=40 SELECT @amt=0 --#30243 apply low income tax credit

	SELECT @amt = ROUND((@amt / @ppds),0) --Maine specifies that tax is to be rounded to the nearest dollar


	RETURN @ReturnCode
GO
GRANT EXECUTE ON  [dbo].[bspPRMET12] TO [public]
GO
