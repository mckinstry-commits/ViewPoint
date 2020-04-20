SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

    CREATE PROC [dbo].[bspPRALT13]
    /********************************************************
    * CREATED BY: 	EN 6/1/98
    * MODIFIED BY:	EN 6/1/98
    * MODIFIED BY:       EN 11/29/99 - neg tax calced if subj amt input is 0 (ie. non-taxable amount)
    *			GH 07/16/01 - prevent negative amount to calculate
    *			EN 10/7/02 - issue 18877 change double quotes to single
    *			EN 12/03/03 - issue 23061  added isnull check
    *			EN 12/31/04 - issue 26244  default status and exemptions
	*			EN 11/03/06 - issue 123000 tax update effective 1/1/2007
	*			EN 12/8/10 #142431  tax update effective 1/1/2011
	*			CHS	03/28/2013	- 45015 tax update effective 2/19/2013 - no tax changes - however 
	*				I corrected some errors in the coding - there was a .99 cent gap in the brackets.
    *
    * USAGE:
    * 	Calculates Alabama Income Tax
    *
    * INPUT PARAMETERS:
    
    *	@subjamt 	subject earnings
    *	@ppds		# of pay pds per year
    *	@status		filing status
    *	@exempts	# of exemptions
    *	@fedtax		Federal Income tax
    *
    * OUTPUT PARAMETERS:
    *	@amt		calculated tax amount
    *	@msg		error message if failure
    *
    * RETURN VALUE:
    * 	0 	    	success
    *	1 		failure
    **********************************************************/
    (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'O', @exempts tinyint = 0,
    @fedtax bDollar = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
    AS
    SET NOCOUNT ON
    
    DECLARE @rcode int, @AnnualAmt bDollar, @StdDedn bDollar, @PersExempt bDollar, @DependentExempt bDollar,
		@BaseTax1 bDollar, @BaseTax2 bDollar,
		@Rate1 bDollar, @Rate2 bDollar, @Rate3 bDollar, @MaxDedn bDollar, @Decrement bDollar, @ProcName varchar(30)
    
    SELECT @rcode = 0
    SELECT @Rate1 = .02, @Rate2 = .04, @Rate3 = .05
    SELECT @ProcName = 'bspPRALT13'
 
    -- #26244 set default status and/or exemptions if passed in values are invalid
    IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('O','S','H','M','B')) SELECT @status = 'O'
    IF @exempts IS NULL SELECT @exempts = 0
 
    IF @ppds = 0
    	BEGIN
    	SELECT @msg = isnull(@ProcName,'') + ':  Missing # of Pay Periods per year!', @rcode = 1
    	RETURN @rcode
    	END
    
    IF @subjamt < .01
        BEGIN
        SELECT @amt = 0
    	RETURN @rcode
        END
    
    /* annualize earnings */
    SELECT @AnnualAmt = @subjamt * @ppds

    /* deduct standard dedn from earnings */

	--establish std deduction, personal exemption, and tax bracket parameters
	-- for married filing joint (B), head of family (H), single (S), and no exemptions (O)
	IF @status = 'B' OR @status = 'H' OR @status = 'O' OR @status = 'S'
	BEGIN
		--@MaxDedn and @Decrement are the parameters to compute standard deduction
		IF @status = 'B' --married filing joint
		BEGIN
			SELECT @PersExempt = 3000
			SELECT @BaseTax1 = 1000, @BaseTax2 = 5000
			SELECT @MaxDedn = 7500, @Decrement = 175
		END

		IF @status = 'H' --head of family
		BEGIN
			SELECT @PersExempt = 3000
			SELECT @BaseTax1 = 500, @BaseTax2 = 2500
			SELECT @MaxDedn = 4700, @Decrement = 135
		END

		IF @status = 'S' --single
		BEGIN
			SELECT @PersExempt = 1500
			SELECT @BaseTax1 = 500, @BaseTax2 = 2500
			SELECT @MaxDedn = 2500, @Decrement = 25
		END

		IF @status = 'O' --no exemptions
		BEGIN
			SELECT @PersExempt = 0
			SELECT @BaseTax1 = 500, @BaseTax2 = 2500
			SELECT @MaxDedn = 2500, @Decrement = 25
		END

		--compute standard deduction based $500 wage increments
		IF      @AnnualAmt BETWEEN     0 AND 20499.99 SELECT @StdDedn = @MaxDedn
		ELSE IF @AnnualAmt BETWEEN 20500 AND 20999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 1)
		ELSE IF @AnnualAmt BETWEEN 21000 AND 21499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 2)
		ELSE IF @AnnualAmt BETWEEN 21500 AND 21999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 3)
		ELSE IF @AnnualAmt BETWEEN 22000 AND 22499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 4)
		ELSE IF @AnnualAmt BETWEEN 22500 AND 22999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 5)
		ELSE IF @AnnualAmt BETWEEN 23000 AND 23499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 6)
		ELSE IF @AnnualAmt BETWEEN 23500 AND 23999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 7)
		ELSE IF @AnnualAmt BETWEEN 24000 AND 24499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 8)
		ELSE IF @AnnualAmt BETWEEN 24500 AND 24999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 9)
		ELSE IF @AnnualAmt BETWEEN 25000 AND 25499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 10)
		ELSE IF @AnnualAmt BETWEEN 25500 AND 25999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 11)
		ELSE IF @AnnualAmt BETWEEN 26000 AND 26499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 12)
		ELSE IF @AnnualAmt BETWEEN 26500 AND 26999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 13)
		ELSE IF @AnnualAmt BETWEEN 27000 AND 27499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 14)
		ELSE IF @AnnualAmt BETWEEN 27500 AND 27999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 15)
		ELSE IF @AnnualAmt BETWEEN 28000 AND 28499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 16)
		ELSE IF @AnnualAmt BETWEEN 28500 AND 28999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 17)
		ELSE IF @AnnualAmt BETWEEN 29000 AND 29499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 18)
		ELSE IF @AnnualAmt BETWEEN 29500 AND 29999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 19)
		ELSE IF @AnnualAmt >= 30000                   SELECT @StdDedn = @MaxDedn - (@Decrement * 20)
	END

	--establish std deduction, personal exemption, and tax bracket parameters for married filing separate
	IF @status='M'
	BEGIN
		--@MaxDedn and @Decrement are the parameters to compute standard deduction
		SELECT @PersExempt = 1500
		SELECT @BaseTax1 = 500, @BaseTax2 = 2500
		SELECT @MaxDedn = 3750, @Decrement = 88

		--compute standard deduction based $250 wage increments
		IF      @AnnualAmt BETWEEN     0 AND 10249.99 SELECT @StdDedn = @MaxDedn
		ELSE IF @AnnualAmt BETWEEN 10250 AND 10499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 1)
		ELSE IF @AnnualAmt BETWEEN 10500 AND 10749.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 2)
		ELSE IF @AnnualAmt BETWEEN 10750 AND 10999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 3)
		ELSE IF @AnnualAmt BETWEEN 11000 AND 11249.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 4)
		ELSE IF @AnnualAmt BETWEEN 11250 AND 11499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 5)
		ELSE IF @AnnualAmt BETWEEN 11500 AND 11749.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 6)
		ELSE IF @AnnualAmt BETWEEN 11750 AND 11999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 7)
		ELSE IF @AnnualAmt BETWEEN 12000 AND 12249.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 8)
		ELSE IF @AnnualAmt BETWEEN 12250 AND 12499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 9)
		ELSE IF @AnnualAmt BETWEEN 12500 AND 12749.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 10)
		ELSE IF @AnnualAmt BETWEEN 12750 AND 12999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 11)
		ELSE IF @AnnualAmt BETWEEN 13000 AND 13249.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 12)
		ELSE IF @AnnualAmt BETWEEN 13250 AND 13499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 13)
		ELSE IF @AnnualAmt BETWEEN 13500 AND 13749.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 14)
		ELSE IF @AnnualAmt BETWEEN 13750 AND 13999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 15)
		ELSE IF @AnnualAmt BETWEEN 14000 AND 14249.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 16)
		ELSE IF @AnnualAmt BETWEEN 14250 AND 14499.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 17)
		ELSE IF @AnnualAmt BETWEEN 14500 AND 14749.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 18)
		ELSE IF @AnnualAmt BETWEEN 14750 AND 14999.99 SELECT @StdDedn = @MaxDedn - (@Decrement * 19)
		ELSE IF @AnnualAmt >= 15000                   SELECT @StdDedn = @MaxDedn - 1750 --(@Decrement * 20)

		-- the value 1750 was hard coded above as the AL spec deviated from the @Decrement value on the last line
	END

	-- establish Dependent Exemption
	IF @AnnualAmt BETWEEN 0 AND 20000
	BEGIN
		SELECT @DependentExempt = 1000 * @exempts
	END
	ELSE IF @AnnualAmt BETWEEN 20000.01 AND 100000
	BEGIN
		SELECT @DependentExempt = 500 * @exempts
	END
	ELSE IF @AnnualAmt >= 100000.01
	BEGIN
		SELECT @DependentExempt = 300 * @exempts
	END

	-- subtract std dedn, ,personal exemption, dependent exemption, and annual fed tax from annual earnings
	SELECT @AnnualAmt = @AnnualAmt - (@StdDedn + @PersExempt + @DependentExempt + (@fedtax*@ppds) )

    IF @AnnualAmt < .01
    BEGIN
        SELECT @amt = 0
    	RETURN @rcode
    END

    /* calculate tax */
    IF @AnnualAmt < @BaseTax1
	BEGIN
		SELECT @amt = @Rate1 * @AnnualAmt
	END
	ELSE
	BEGIN
		SELECT @amt = (@Rate1 * @BaseTax1)
		SELECT @AnnualAmt = @AnnualAmt - @BaseTax1

		IF @AnnualAmt < @BaseTax2
		BEGIN
 			SELECT @amt = @amt + (@Rate2 * @AnnualAmt)
		END
		ELSE
		BEGIN
			SELECT @amt = @amt + (@Rate2 * @BaseTax2)
			SELECT @AnnualAmt = @AnnualAmt - @BaseTax2
			SELECT @amt = @amt + (@Rate3 * @AnnualAmt)
		END
	END

    SELECT @amt = @amt / @ppds
    IF @amt < 0 SELECT @amt = 0
    
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRALT13] TO [public]
GO
