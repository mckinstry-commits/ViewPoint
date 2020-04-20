
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRFWT13]    Script Date: 12/13/2007 15:22:31 ******/
   CREATE PROC [dbo].[bspPRFWT13]
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
   *				EN 1/3/2013 D-06412/#147775/TK-20583 update effective 1/1/2013
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
		@ProcName = 'bspPRFWT13'

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
		SELECT @NonResWageAdjustment = 2200.00 --amount to add to nonresident alien employee's wages prior to calculating income tax withholding
		IF @exempts > 1 SELECT @exempts = 1 --allowances for nonresident alien tax computation are limited to 1
	END

	/* annualize earnings and deduct allowance for exemptions */
	SELECT @AnnualizedTaxableAmt = 0, 
		   @WithholdingAllowance = 3900
	SELECT @AnnualizedTaxableAmt = (@subjamt * @ppds) + @NonResWageAdjustment - (@exempts * @WithholdingAllowance)

	SELECT @BaseTaxAmt = 0, 
		   @BracketBaseAmt = 0, 
		   @Rate = 0 --default rate

	/* married */
	IF @status = 'M'
	BEGIN
		IF @AnnualizedTaxableAmt      BETWEEN   8300.01 AND  26150 SELECT @BaseTaxAmt =         0, @BracketBaseAmt =   8300, @Rate = .10
		ELSE IF @AnnualizedTaxableAmt BETWEEN  26150.01 AND  80800 SELECT @BaseTaxAmt =   1785.00, @BracketBaseAmt =  26150, @Rate = .15
		ELSE IF @AnnualizedTaxableAmt BETWEEN  80800.01 AND 154700 SELECT @BaseTaxAmt =   9982.50, @BracketBaseAmt =  80800, @Rate = .25
		ELSE IF @AnnualizedTaxableAmt BETWEEN 154700.01 AND 231350 SELECT @BaseTaxAmt =  28457.50, @BracketBaseAmt = 154700, @Rate = .28
		ELSE IF @AnnualizedTaxableAmt BETWEEN 231350.01 AND 406650 SELECT @BaseTaxAmt =  49919.50, @BracketBaseAmt = 231350, @Rate = .33
		ELSE IF @AnnualizedTaxableAmt BETWEEN 406650.01 AND 458300 SELECT @BaseTaxAmt = 107768.50, @BracketBaseAmt = 406650, @Rate = .35
		ELSE IF @AnnualizedTaxableAmt >=      458300.01            SELECT @BaseTaxAmt = 125846.00, @BracketBaseAmt = 458300, @Rate = .396
	END

	/* single */
	IF @status = 'S'
   	BEGIN
		IF @AnnualizedTaxableAmt      BETWEEN  2200.01 AND   11125 SELECT @BaseTaxAmt =         0, @BracketBaseAmt =   2200, @Rate = .10
		ELSE IF @AnnualizedTaxableAmt BETWEEN 11125.01 AND   38450 SELECT @BaseTaxAmt =    892.50, @BracketBaseAmt =  11125, @Rate = .15
		ELSE IF @AnnualizedTaxableAmt BETWEEN 38450.01 AND   90050 SELECT @BaseTaxAmt =   4991.25, @BracketBaseAmt =  38450, @Rate = .25
		ELSE IF @AnnualizedTaxableAmt BETWEEN 90050.01 AND  185450 SELECT @BaseTaxAmt =  17891.25, @BracketBaseAmt =  90050, @Rate = .28
		ELSE IF @AnnualizedTaxableAmt BETWEEN 185450.01 AND 400550 SELECT @BaseTaxAmt =  44603.25, @BracketBaseAmt = 185450, @Rate = .33
		ELSE IF @AnnualizedTaxableAmt BETWEEN 400550.01 AND 402200 SELECT @BaseTaxAmt = 115586.25, @BracketBaseAmt = 400550, @Rate = .35
		ELSE IF @AnnualizedTaxableAmt >=      402200.01            SELECT @BaseTaxAmt = 116163.75, @BracketBaseAmt = 402200, @Rate = .396
   	END

	-- perform Fed Tax calculation (or step 2 of non-resident alien tax computation) only if employee fits a tax bracket
	IF @Rate <> 0
	BEGIN
   		SELECT @amt = (@BaseTaxAmt + (@AnnualizedTaxableAmt - @BracketBaseAmt) * @Rate) / @ppds
   		IF @amt IS NULL OR @amt < 0 SELECT @amt = 0
	END


   	RETURN @rcode
GO


GRANT EXECUTE ON  [dbo].[bspPRFWT13] TO [public]
GO
