SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRFWT11]    Script Date: 12/13/2007 15:22:31 ******/
   CREATE PROC [dbo].[bspPRFWT11]
   /********************************************************
   * CREATED BY: 	EN 12/12/00 - update effective 1/1/2001
   * MODIFIED BY:  EN 6/18/01 - update effective 7/1/2001
   *				EN 12/18/01 - update effective 1/1/2002
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 11/22/02 - issue 19461  update effective 1/1/2003
   *				EN 5/29/03 - issue 21381  update effective retroactive to 1/1/2003
   *				EN 1/26/04 - issue 23516  default exempts to 0 IF passed in as null
   *				EN 2/11/04 - issue 23668  remove automatic rounding in favor of using the 
   *											"Round result to nearest whole dollar" checkbox in PR Dedn/Liabs
   *				EN 12/2/04 - issue 26375  update effective 1/1/2005
   *				EN 12/8/05 - issue 119608  update effective 1/1/2006
   *				EN 12/14/06 - issue 123318  update effective 1/1/2007
   *				EN 8/21/07 - issue 120519  added non-resident alien tax addon computation
   *				EN 12/13/07 - issue 126498  update effective 1/1/2008
   *				EN 12/12/08 - #131432  update effective 1/1/2009
   *				EN 2/23/09 - #132384  update effective immediately as part of federal stimulus plan
   *				EN 11/30/2009 #136828  update effective 1/1/2010 (modIFied both fed tax and non-res alien computations)
   *				EN 12/28/2010 #142569 update effective 1/1/2011
   *
   * USAGE:
   * 	Calculates Federal Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status (S or M)
   *	@exempts	# of exemptions
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated Fed tax amount
   *	@msg		error message IF failure
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
	@msg varchar(255) = null output)

	AS
	SET NOCOUNT ON

	DECLARE @rcode int, 
		@WithholdingAllowance bDollar,
		@AnnualizedTaxableAmt bDollar, 
		@BaseTaxAmt bDollar, 
		@BracketBaseAmt bDollar, 
		@Rate bRate, 
		@NonResTaxAmt bDollar, 
		@NonResWageAdjustment bDollar,
		@ProcName varchar(30)
  
	SELECT @rcode = 0, 
		@amt = 0,
		@ProcName = 'bspPRFWT11'

	--validate # of pay periods
	IF @ppds = 0
	BEGIN
		SELECT @msg = @ProcName + ': Missing # of Pay Periods per year!', @rcode = 1
		RETURN @rcode
	END
   
	--default @status to 'S' if not defined in filing status
	IF (@status IS NOT NULL AND @status <> 'M') OR (@status IS NULL) 
	BEGIN
		SELECT @status = 'S'    -- use single status IF not valid
	END

	--default exemptions to 0 if not defined in filing status
	IF @exempts IS NULL SELECT @exempts = 0

	SELECT @NonResWageAdjustment = 0 --default to 0 for U.S. citizens

	--step 1 of non-resident alien tax computation
	IF @nonresalienyn = 'Y' 
	BEGIN
		SELECT @NonResWageAdjustment = 2100.00 --amount to add to nonresident alien employee's wages prior to calculating income tax withholding
		IF @exempts > 1 SELECT @exempts = 1 --allowances for nonresident alien tax computation are limited to 1
	END

	/* annualize earnings and deduct allowance for exemptions */
	SELECT @AnnualizedTaxableAmt = 0, 
		@WithholdingAllowance = 3700
	SELECT @AnnualizedTaxableAmt = (@subjamt * @ppds) + @NonResWageAdjustment - (@exempts * @WithholdingAllowance)

	SELECT @BaseTaxAmt = 0, 
		@BracketBaseAmt = 0, 
		@Rate = 0 --default rate

	/* married */
	IF @status = 'M'
	BEGIN
		IF @AnnualizedTaxableAmt BETWEEN 7900.01 AND 24900
		BEGIN
			SELECT @BaseTaxAmt = 0, @BracketBaseAmt = 7900, @Rate = .1
		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 24900.01 AND 76900
		BEGIN
			SELECT @BaseTaxAmt = 1700.00, @BracketBaseAmt = 24900, @Rate = .15
		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 76900.01 AND 147250
		BEGIN
			SELECT @BaseTaxAmt = 9500.00, @BracketBaseAmt = 76900, @Rate = .25
		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 147250.01 AND 220200
		BEGIN
			SELECT @BaseTaxAmt = 27087.50, @BracketBaseAmt = 147250, @Rate = .28
		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 220200.01 AND 387050
		BEGIN
			SELECT @BaseTaxAmt = 47513.50, @BracketBaseAmt = 220200, @Rate = .33
		END
		ELSE IF @AnnualizedTaxableAmt >= 387050.01
		BEGIN
			SELECT @BaseTaxAmt = 102574.00, @BracketBaseAmt = 387050, @Rate = .35
		END
	END --@status = 'M'

	/* single */
	IF @status = 'S'
   	BEGIN
		IF @AnnualizedTaxableAmt BETWEEN 2100.01 AND 10600
		BEGIN
			SELECT @BaseTaxAmt = 0, @BracketBaseAmt = 2100, @Rate = .1
   		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 10600.01 AND 36600
		BEGIN
			SELECT @BaseTaxAmt = 850.00, @BracketBaseAmt = 10600, @Rate = .15
   		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 36600.01 AND 85700
		BEGIN
			SELECT @BaseTaxAmt = 4750.00, @BracketBaseAmt = 36600, @Rate = .25
   		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 85700.01 AND 176500
		BEGIN
			SELECT @BaseTaxAmt = 17025.00, @BracketBaseAmt = 85700, @Rate = .28
   		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 176500.01 AND 381250
		BEGIN
			SELECT @BaseTaxAmt = 42449.00, @BracketBaseAmt = 176500, @Rate = .33
   		END
		ELSE IF @AnnualizedTaxableAmt >= 381250.01
		BEGIN
			SELECT @BaseTaxAmt = 110016.50, @BracketBaseAmt = 381250, @Rate = .35
   		END
   	END --@status = 'S'

	-- perform Fed Tax calculation (or step 2 of non-resident alien tax computation) only if employee fits a tax bracket
	IF @Rate <> 0
	BEGIN
   		SELECT @amt = (@BaseTaxAmt + (@AnnualizedTaxableAmt - @BracketBaseAmt) * @Rate) / @ppds
   		IF @amt IS NULL OR @amt < 0 SELECT @amt = 0
	END

	--steps 3 and 4 of non-resident alien tax computation
	IF @nonresalienyn = 'Y'
	BEGIN
		SELECT @NonResTaxAmt = 0 --default

		IF @AnnualizedTaxableAmt BETWEEN 2050 AND 6049.99
		BEGIN
			SELECT @NonResTaxAmt = (@AnnualizedTaxableAmt - 2050) * .1
		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 6050 AND 67699.99
		BEGIN
			SELECT @NonResTaxAmt = 400.00
		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 67700 AND 87699.99
		BEGIN
			SELECT @NonResTaxAmt = 400 - ((@AnnualizedTaxableAmt - 67700) * .02)
		END

   		SELECT @amt = @amt + (@NonResTaxAmt / @ppds)
	END


   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRFWT11] TO [public]
GO
