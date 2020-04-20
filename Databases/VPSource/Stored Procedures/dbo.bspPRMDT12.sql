SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[bspPRMDT12]
/********************************************************
* CREATED BY: 	EN	11/01/2001	- this revision effective 1/1/2002
* MODIFIED BY:	EN	10/08/2002	- issue 18877 change double quotes to single
*				EN	12/02/2003	- issue 23145  update effective 1/1/2004
*				EN	01/14/2004	- issue 23500  Maryland state tax calculating negative amount in certain CASEs
*				EN	11/16/2004	- issue 26219  update effective 1/1/2005 ... non-resident rate changed to 6% but resident rate base (4.75%) remains the same
*											passing in @res (Y/N) flag which specifies whether or not employee is a resident
*				EN	01/04/2005	- issue 26244  default exemptions and miscfactor
*				EN	12/13/2007	- issue 126491 update effective 1/1/2008 - exemption changed and added tax brackets rather than just using a flat tax rate
*				EN	07/24/2008	- #129150  update effective 7/1/2008 - added tax bracket and modIFied base tax computation
*				LS	12/27/2010	- #142598 update effective 1/1/2011 - removed 7.50% tax bracket (5th bracket)
*				CHS	06/07/2012	- 146588 D-05267 update effective 1/1/2012
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
			@BaseTax bDollar, 
			@ExcessWage bDollar

	SELECT @Rate = 0, @ProcName = 'bspPRMDT12'

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
	
	IF @AnnualizedWage < 0 
		BEGIN
			SELECT @amt = 0
			RETURN 0 /* Successfully Exit */
		END	

	/* SELECT calculation elements for Married Filing Joint or Head of Household */
	IF @status = 'M' OR @status = 'H'
		BEGIN
		IF		@AnnualizedWage BETWEEN      0.00 AND 150000 SELECT @BaseTax =     0.00, @Rate = .0600, @ExcessWage = 0 
		ELSE IF @AnnualizedWage BETWEEN 150000.01 AND 175000 SELECT @BaseTax =  9000.00, @Rate = .0625, @ExcessWage = 150000
		ELSE IF @AnnualizedWage BETWEEN 175000.01 AND 225000 SELECT @BaseTax = 10562.50, @Rate = .0650, @ExcessWage = 175000
		ELSE IF @AnnualizedWage BETWEEN 225000.01 AND 300000 SELECT @BaseTax = 13812.50, @Rate = .0675, @ExcessWage = 225000
		ELSE SELECT													@BaseTax = 18875.00, @Rate = .0700, @ExcessWage = 300000
		END
	
	ELSE /* SELECT calculation elements for Single, Married Filing Separately, or Dependent */
		BEGIN	
		IF		@AnnualizedWage BETWEEN      0.00 AND 100000 SELECT @BaseTax =     0.00, @Rate = .0600, @ExcessWage = 0 
		ELSE IF @AnnualizedWage BETWEEN 100000.01 AND 125000 SELECT @BaseTax =  6000.00, @Rate = .0625, @ExcessWage = 100000
		ELSE IF @AnnualizedWage BETWEEN 125000.01 AND 150000 SELECT @BaseTax =  7562.50, @Rate = .0650, @ExcessWage = 125000
		ELSE IF @AnnualizedWage BETWEEN 150000.01 AND 250000 SELECT @BaseTax =  9187.50, @Rate = .0675, @ExcessWage = 150000
		ELSE SELECT													@BaseTax = 15937.50, @Rate = .0700, @ExcessWage = 250000
		END

	Select @ExcessWage = @AnnualizedWage - @ExcessWage	
	Select @Rate = @Rate + @miscfactor		
	
	/* calculate Maryland Tax */
	SELECT @amt = (@BaseTax + (@ExcessWage * @Rate)) / @ppds

	RETURN 0
			
END


GO
GRANT EXECUTE ON  [dbo].[bspPRMDT12] TO [public]
GO
