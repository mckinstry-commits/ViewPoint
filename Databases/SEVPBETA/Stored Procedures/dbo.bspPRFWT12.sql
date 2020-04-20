SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRFWT12]    Script Date: 12/13/2007 15:22:31 ******/
   CREATE PROC [dbo].[bspPRFWT12]
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
   *				EN 12/8/2011 TK-10785/#145215 update effective 1/1/2012
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
		@ProcName = 'bspPRFWT12'

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
		SELECT @NonResWageAdjustment = 2150.00 --amount to add to nonresident alien employee's wages prior to calculating income tax withholding
		IF @exempts > 1 SELECT @exempts = 1 --allowances for nonresident alien tax computation are limited to 1
	END

	/* annualize earnings and deduct allowance for exemptions */
	SELECT @AnnualizedTaxableAmt = 0, 
		@WithholdingAllowance = 3800
	SELECT @AnnualizedTaxableAmt = (@subjamt * @ppds) + @NonResWageAdjustment - (@exempts * @WithholdingAllowance)

	SELECT @BaseTaxAmt = 0, 
		@BracketBaseAmt = 0, 
		@Rate = 0 --default rate

	/* married */
	IF @status = 'M'
	BEGIN
		IF @AnnualizedTaxableAmt BETWEEN 8100.01 AND 25500
		BEGIN
			SELECT @BaseTaxAmt = 0, @BracketBaseAmt = 8100, @Rate = .1
		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 25500.01 AND 78800
		BEGIN
			SELECT @BaseTaxAmt = 1740.00, @BracketBaseAmt = 25500, @Rate = .15
		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 78800.01 AND 150800
		BEGIN
			SELECT @BaseTaxAmt = 9735.00, @BracketBaseAmt = 78800, @Rate = .25
		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 150800.01 AND 225550
		BEGIN
			SELECT @BaseTaxAmt = 27735.00, @BracketBaseAmt = 150800, @Rate = .28
		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 225550.01 AND 396450
		BEGIN
			SELECT @BaseTaxAmt = 48665.00, @BracketBaseAmt = 225550, @Rate = .33
		END
		ELSE IF @AnnualizedTaxableAmt >= 396450.01
		BEGIN
			SELECT @BaseTaxAmt = 105062.00, @BracketBaseAmt = 396450, @Rate = .35
		END
	END --@status = 'M'

	/* single */
	IF @status = 'S'
   	BEGIN
		IF @AnnualizedTaxableAmt BETWEEN 2150.01 AND 10850
		BEGIN
			SELECT @BaseTaxAmt = 0, @BracketBaseAmt = 2150, @Rate = .1
   		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 10850.01 AND 37500
		BEGIN
			SELECT @BaseTaxAmt = 870.00, @BracketBaseAmt = 10850, @Rate = .15
   		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 37500.01 AND 87800
		BEGIN
			SELECT @BaseTaxAmt = 4867.50, @BracketBaseAmt = 37500, @Rate = .25
   		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 87800.01 AND 180800
		BEGIN
			SELECT @BaseTaxAmt = 17442.50, @BracketBaseAmt = 87800, @Rate = .28
   		END
		ELSE IF @AnnualizedTaxableAmt BETWEEN 180800.01 AND 390500
		BEGIN
			SELECT @BaseTaxAmt = 43482.50, @BracketBaseAmt = 180800, @Rate = .33
   		END
		ELSE IF @AnnualizedTaxableAmt >= 381250.01
		BEGIN
			SELECT @BaseTaxAmt = 112683.50, @BracketBaseAmt = 390500, @Rate = .35
   		END
   	END --@status = 'S'

	-- perform Fed Tax calculation (or step 2 of non-resident alien tax computation) only if employee fits a tax bracket
	IF @Rate <> 0
	BEGIN
   		SELECT @amt = (@BaseTaxAmt + (@AnnualizedTaxableAmt - @BracketBaseAmt) * @Rate) / @ppds
   		IF @amt IS NULL OR @amt < 0 SELECT @amt = 0
	END

	----steps 3 and 4 of non-resident alien tax computation
	--IF @nonresalienyn = 'Y'
	--BEGIN
	--	SELECT @NonResTaxAmt = 0 --default

	--	IF @AnnualizedTaxableAmt BETWEEN 2050 AND 6049.99
	--	BEGIN
	--		SELECT @NonResTaxAmt = (@AnnualizedTaxableAmt - 2050) * .1
	--	END
	--	ELSE IF @AnnualizedTaxableAmt BETWEEN 6050 AND 67699.99
	--	BEGIN
	--		SELECT @NonResTaxAmt = 400.00
	--	END
	--	ELSE IF @AnnualizedTaxableAmt BETWEEN 67700 AND 87699.99
	--	BEGIN
	--		SELECT @NonResTaxAmt = 400 - ((@AnnualizedTaxableAmt - 67700) * .02)
	--	END

 --  		SELECT @amt = @amt + (@NonResTaxAmt / @ppds)
	--END


   	RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRFWT12] TO [public]
GO
