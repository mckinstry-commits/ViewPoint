SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].[bspPRMDT11]    Script Date: 12/13/2007 10:19:49 ******/
CREATE proc [dbo].[bspPRMDT11]
/********************************************************
* CREATED BY: 	EN 11/01/01 - this revision effective 1/1/2002
* MODIFIED BY:	EN 10/8/02 - issue 18877 change double quotes to single
*				EN 12/02/03 - issue 23145  update effective 1/1/2004
*				EN 1/14/04 - issue 23500  Maryland state tax calculating negative amount in certain CASEs
*				EN 11/16/04 - issue 26219  update effective 1/1/2005 ... non-resident rate changed to 6% but resident rate base (4.75%) remains the same
*											passing in @res (Y/N) flag which specifies whether or not employee is a resident
*				EN 1/4/05 - issue 26244  default exemptions and miscfactor
*				EN 12/13/07 - issue 126491 update effective 1/1/2008 - exemption changed and added tax brackets rather than just using a flat tax rate
*				EN 7/24/08 - #129150  update effective 7/1/2008 - added tax bracket and modIFied base tax computation
*				LS 12/27/10	- #142598 update effective 1/1/2011 - removed 7.50% tax bracket (5th bracket)
*
* USAGE:
* 	Calculates Maryland Income Tax
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@exempts	# of exemptions
*	@miscfactor	factor used for speacial tax routines
*
* OUTPUT PARAMETERS:
*	@amt		calculated tax amount
*	@msg		error message IF failure
*
* RETURN VALUE:
* 	0 			success
*	1 			failure
**********************************************************/
	(@subjamt bDollar = 0, 
	 @ppds tinyint = 0, 
	 @status char(1) = null, 
	 @exempts tinyint = 0,
	 @miscfactor bRate = 0, 
	 @res char(1) = 'Y', 
	 @amt bDollar = 0 output, 
	 @msg varchar(255) = null output)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @AnnualizedWage bDollar, 
			@Rate bRate,
			@ProcName varchar(30), 
			@Deductions bDollar,
			@Bracket1 int, 
			@Bracket2 int, 
			@Bracket3 int, 
			@Bracket4 int,
			@BaseTax bDollar, 
			@ExcessWage bDollar

	SELECT @Rate = 0, @ProcName = 'bspPRMDT11'

	-- #26244 set default exemptions and/or misc factor IF passed in values are invalid
	IF @exempts IS NULL SELECT @exempts = 0
	IF @miscfactor IS NULL SELECT @miscfactor = 0

	IF @ppds = 0
	BEGIN
		SELECT @msg = @ProcName + ':  Missing # of Pay Periods per year!'
		RETURN 1
	END


	/* annualize earnings */
	SELECT @AnnualizedWage = (@subjamt * @ppds)

	/* no tax on annual income below 5000 */
	IF @AnnualizedWage < 5000
	BEGIN
		SELECT @amt = 0
		RETURN 0 /* Successfully Exit */
	END

	SELECT @Deductions = @AnnualizedWage * .15

	IF @Deductions < 1500 SELECT @Deductions = 1500
	IF @Deductions > 2000 SELECT @Deductions = 2000


	SELECT @AnnualizedWage = @AnnualizedWage - @Deductions - (3200 * @exempts)

	IF @AnnualizedWage < 0 SELECT @AnnualizedWage = 0

	--#126491 add brackets
	/* SELECT calculation elements for Married Filing Joint or Head of Household */
	IF @status = 'M' OR @status = 'H'
	BEGIN
		SELECT @Bracket1 = 200000, 
			   @Bracket2 = 350000, 
			   @Bracket3 = 500000
		--1st bracket
		IF @AnnualizedWage BETWEEN 0 AND @Bracket1
		BEGIN
			SELECT @BaseTax = 0, 
				   @Rate = .0475 + @miscfactor
			SELECT @ExcessWage = @AnnualizedWage
		END
		--2nd bracket
		ELSE IF @AnnualizedWage BETWEEN (@Bracket1 + .01) AND @Bracket2
		BEGIN
			SELECT @BaseTax = 12000,
				   @Rate = .05 + @miscfactor
			SELECT @ExcessWage = @AnnualizedWage - @Bracket1
		END
		--3rd bracket
		ELSE IF @AnnualizedWage BETWEEN (@Bracket2 + .01) AND @Bracket3
		BEGIN
			SELECT @BaseTax = 21375, 
				   @Rate = .0525 + @miscfactor
			SELECT @ExcessWage = @AnnualizedWage - @Bracket2
		END
		--4th bracket (highest)
		ELSE IF @AnnualizedWage > @Bracket3
		BEGIN
		SELECT @BaseTax = 31125,
			   @Rate = .055 + @miscfactor
			SELECT @ExcessWage = @AnnualizedWage - @Bracket3
		END
	END
	ELSE /* SELECT calculation elements for Single, Married Filing Separately, or Dependent */
	BEGIN
		SELECT @Bracket1 = 150000, 
			   @Bracket2 = 300000, 
			   @Bracket3 = 500000
		--1st bracket
		IF @AnnualizedWage BETWEEN 0 AND @Bracket1   
		BEGIN
			SELECT @BaseTax = 0, 
				   @Rate = .0475 + @miscfactor
			SELECT @ExcessWage = @AnnualizedWage
		END
		--2nd bracket
		ELSE IF @AnnualizedWage BETWEEN (@Bracket1 + .01) AND @Bracket2
		BEGIN
			SELECT @BaseTax = 9000,
				   @Rate = .05 + @miscfactor
			SELECT @ExcessWage = @AnnualizedWage - @Bracket1
		END
		--3rd bracket
		ELSE IF @AnnualizedWage BETWEEN (@Bracket2 + .01) AND @Bracket3
		BEGIN
			SELECT @BaseTax = 18375,
				   @Rate = .0525 + @miscfactor
			SELECT @ExcessWage = @AnnualizedWage - @Bracket2
		END
		--4th bracket (highest)
		ELSE IF @AnnualizedWage > @Bracket3
		BEGIN
			SELECT @BaseTax = 31375,
				   @Rate = .055 + @miscfactor
			SELECT @ExcessWage = @AnnualizedWage - @Bracket3
		END
	END

	/* calculate Maryland Tax */
	SELECT @amt = (@BaseTax + (@ExcessWage * @Rate)) / @ppds

	RETURN 0
			
END


GO
GRANT EXECUTE ON  [dbo].[bspPRMDT11] TO [public]
GO
