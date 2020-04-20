SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRMOT112]    Script Date: 01/03/2008 10:56:16 ******/
CREATE PROC [dbo].[bspPRMOT12]
/********************************************************
* CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
* MODIFIED BY:  EN 12/26/00 - change maximum federal deduction for head of household from 10000 to 5000
*               EN 3/9/01 - correct 2001 std dedn amounts from what was originally reported by CCH
*				EN 12/26/01 - update effective 1/1/2002
*				EN 1/8/02 - issue 15808 / negative tax calced if exemptions exceed wages
*				EN 10/8/02 - issue 18877 change double quotes to single
*				EN 12/2/02 - issue 19505  update effective 1/1/2003
*				EN 12/16/03 - issue 23353  update effective 1/1/2004
*				EN 12/17/04 - issue 26563  upate effective 1/1/2005
*				EN 1/4/05 - issue 26244  default status and exemptions
*				EN 12/12/05 - issue 119631  update effective 1/1/2006
*				EN 12/14/06 - issue 123315  update effective 1/1/2007
*				EN 1/03/08 - issue 126634  update effective 1/1/2008
*				EN 12/31/09 - #131597  update effective 1/1/2009
*				EN 10/16/2009 #135829  resolve divide-by-zero error when computing fed withheld amount
*				EN 12/29/2009 #137250  update effective 1/1/2010
*				EN 12/31/2010 #142688  update effective 1/1/2011
*				CHS 03/24/2011 
*				MV 12/29/2011 - TK-11299 2012 tax updates
*
* USAGE:
* 	Calculates Missouri Income Tax
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status
*	@exempts	# of exemptions
*	@fedtax		federal tax withholdings amount
*	@fed_subjamt	federal income tax subject amount (taxable income)
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
 @fedtax bDollar = 0, 
 @fed_subjamt bDollar = 0, 
 @amt bDollar = 0 output, 
 @msg varchar(255) = null output)

AS
SET NOCOUNT ON
 
DECLARE @AnnualizedWage bDollar, 
		@StdDedn bDollar, 
		@Rate bRate,
		@Procname varchar(30), 
		@MaxFedTaxDedn bDollar,
		@Allowance bDollar,
		@EmployeeAllowance bDollar,
		@NonWorkingSpouseAllow bDollar,
		@DependentAllow bDollar,
		@HeadHouseAllow bDollar, 
		@TaxableIncome bDollar,
		@TaxAccumulated bDollar,
		@FedTaxDedn bDollar

DECLARE @TaxBracket int,
		@BracketWageIncrement bDollar,
		@TaxRateMultiplier bDollar,
	    @AnnualTax bDollar,
		@BaseTax bDollar,
		@Rate1 bRate,
		@Rate2 bRate,
		@Rate3 bRate,
		@Rate4 bRate,
		@Rate5 bRate,
		@Rate6 bRate,
		@Rate7 bRate,
		@Rate8 bRate,
		@Rate9 bRate,
		@Rate10 bRate
 
SELECT @Procname = 'bspPRMOT12', 
	   @EmployeeAllowance = 2100,
	   @NonWorkingSpouseAllow = 2100,
	   @DependentAllow = 1200, 
	   @HeadHouseAllow = 3500,
	   @Rate = 0, 
	   @Rate1 = .015,
	   @Rate2 = .02,
	   @Rate3 = .025,
	   @Rate4 = .03,
	   @Rate5 = .035,
	   @Rate6 = .04,
	   @Rate7 = .045,
	   @Rate8 = .05,
	   @Rate9 = .055,
	   @Rate10 = .06,
	   @BracketWageIncrement = 1000

-- #26244 set default status and/or exemptions if passed in values are invalid
IF (@status IS NULL) or (@status IS NOT NULL AND @status NOT IN ('S','M','B','H')) SELECT @status = 'S'
IF @exempts IS NULL SELECT @exempts = 0

IF @ppds = 0
BEGIN
	SELECT @msg = @Procname + ':  Missing # of Pay Periods per year!'
	RETURN 1
END

-- annualize earnings
SELECT @AnnualizedWage = (@subjamt * @ppds)

-- specify deduction parameters and allowance(s) if employee is single or married/both working
IF @status = 'S' OR @status = 'B'
BEGIN
	SELECT @StdDedn = 5950, 
		   @MaxFedTaxDedn = 5000

	SELECT @Allowance = 0

	IF @exempts > 0 --1st exemption represents employee
	BEGIN
		SELECT @Allowance = @Allowance + @EmployeeAllowance
	END

	IF @exempts > 1 --remaining allowances represent dependents
	BEGIN
		SELECT @Allowance = @Allowance + (@DependentAllow * (@exempts - 1))
	END
END 

-- specify deduction parameters and allowance(s) if employee is married with non-working spouse
IF @status = 'M'
BEGIN
	SELECT @StdDedn = 11900, 
		   @MaxFedTaxDedn = 10000

	SELECT @Allowance = 0

	IF @exempts > 0 --1st exemption represents employee
	BEGIN
		SELECT @Allowance = @Allowance + @EmployeeAllowance
	END

	IF @exempts > 1 --2nd allowances represent non-working spouse
	BEGIN
		SELECT @Allowance = @Allowance + @NonWorkingSpouseAllow
	END

	IF @exempts > 2 --remaining allowances represent dependents
	BEGIN
		SELECT @Allowance = @Allowance + (@DependentAllow * (@exempts - 2))
	END
END

-- specify deduction parameters and allowance(s) if employee is head of household
IF @status = 'H'
BEGIN
	SELECT @StdDedn = 8700, 
		   @MaxFedTaxDedn = 5000

	SELECT @Allowance = 0

	IF @exempts > 0 --1st exemption represents employee
	BEGIN
		SELECT @Allowance = @Allowance + @HeadHouseAllow
	END

	IF @exempts > 1 --remaining allowances represent dependents
	BEGIN
		SELECT @Allowance = @Allowance + (@DependentAllow * (@exempts - 1))
	END
END

-- calculate employee's federal income tax deduction factored to the state subject amount
--#135829 modified to resolve divide-by-zero error when @fed_subjamt=0
SELECT @FedTaxDedn = 
	CASE WHEN ISNULL(@fed_subjamt,0) = 0 
		THEN 0.00
		ELSE ((@fedtax * @ppds) * @subjamt) / @fed_subjamt 
		END

-- impose limit on federal tax deduction
IF @FedTaxDedn > @MaxFedTaxDedn 
SELECT @FedTaxDedn = @MaxFedTaxDedn

-- calculate the Missouri taxable income
SELECT @TaxableIncome = @AnnualizedWage - @StdDedn - @Allowance - @FedTaxDedn
IF @TaxableIncome < 0.00 
BEGIN
	SELECT @amt = 0
	RETURN 0
END

--determine tax bracket ... no higher than 10
SELECT @TaxBracket = FLOOR(@TaxableIncome / @BracketWageIncrement) + 1
IF @TaxBracket > 10 SELECT @TaxBracket = 10

--accumulate base tax amount
SELECT @BaseTax = 0.00
IF @TaxBracket > 1 SELECT @BaseTax = @BracketWageIncrement * @Rate1
IF @TaxBracket > 2 SELECT @BaseTax = @BaseTax + (@BracketWageIncrement * @Rate2) 
IF @TaxBracket > 3 SELECT @BaseTax = @BaseTax + (@BracketWageIncrement * @Rate3)
IF @TaxBracket > 4 SELECT @BaseTax = @BaseTax + (@BracketWageIncrement * @Rate4)
IF @TaxBracket > 5 SELECT @BaseTax = @BaseTax + (@BracketWageIncrement * @Rate5)
IF @TaxBracket > 6 SELECT @BaseTax = @BaseTax + (@BracketWageIncrement * @Rate6)
IF @TaxBracket > 7 SELECT @BaseTax = @BaseTax + (@BracketWageIncrement * @Rate7)
IF @TaxBracket > 8 SELECT @BaseTax = @BaseTax + (@BracketWageIncrement * @Rate8)
IF @TaxBracket > 9 SELECT @BaseTax = @BaseTax + (@BracketWageIncrement * @Rate9)

--compute multiplier to use with tax rate
SELECT @TaxRateMultiplier = @TaxableIncome - (@BracketWageIncrement * (@TaxBracket - 1))

--determine tax rate
IF @TaxBracket = 1 SELECT @Rate = @Rate1
ELSE IF @TaxBracket = 2 SELECT @Rate = @Rate2
ELSE IF @TaxBracket = 3 SELECT @Rate = @Rate3
ELSE IF @TaxBracket = 4 SELECT @Rate = @Rate4
ELSE IF @TaxBracket = 5 SELECT @Rate = @Rate5
ELSE IF @TaxBracket = 6 SELECT @Rate = @Rate6
ELSE IF @TaxBracket = 7 SELECT @Rate = @Rate7
ELSE IF @TaxBracket = 8 SELECT @Rate = @Rate8
ELSE IF @TaxBracket = 9 SELECT @Rate = @Rate9
ELSE SELECT @Rate = @Rate10

--compute Missouri Tax rounded to the nearest dollar
SELECT @amt = ROUND((@BaseTax + (@TaxRateMultiplier * @Rate)) / @ppds, 0)

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspPRMOT12] TO [public]
GO
