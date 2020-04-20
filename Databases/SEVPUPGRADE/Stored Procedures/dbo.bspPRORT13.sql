SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRORT11]    Script Date: 01/16/2008 09:51:48 ******/
CREATE  PROC [dbo].[bspPRORT13]
/********************************************************
* MODIFIED BY:	GG 1/6/98
*               EN 11/01/99 - personal exemption updated - effective 1/1/2000
*               GG 03/28/00 - set tax amount to 0.00 if calculated as negative
*				EN 11/26/01 - issue 15185 - update effective 1/1/2002
*				EN 10/8/02 - issue 18877 change double quotes to single
*				EN 2/3/03 - issue 20263  updated effective 3/1/2003
*				EN 1/11/05 - issue 26244  default status and exemptions
*				EN 1/20/06 - issue 119958  update effective 1/1/2006
*				EN 12/05/06 - issue 123248  update effective 1/1/2007
*				EN 12/16/08 - issue 126760  update effective 1/1/2008
*				EN 12/28/2010 #142574  update effective 1/1/2011
*				MV 12/07/11 - TK-10756 - 2012 tax updates
*				MV 01/03/12 - TK-11391 - 2012 tax update correction
*				MV 12/19/12 - TK-20314 2013 tax updates
*
* USAGE:
* 	Calculates Oregon Income Tax
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
(@subjamt bDollar = 0, 
@ppds tinyint = 0, 
@status char(1) = 'S', 
@exempts tinyint = 0,
@fedtax bDollar = 0, 
@amt bDollar = 0 output, 
@msg varchar(255) = null output)

AS
SET NOCOUNT ON

DECLARE 
	@ReturnCode int, 
	@AnnualWages bDollar,
	@AnnualWageBreak bDollar,
	@AnnualTaxable bDollar, 
	@BaseTaxAmt bDollar, 
	@BracketBaseAmt bDollar, 
	@Rate bRate,
	@FedMax bDollar, 
	@StandardDeduction bDollar,
	@PhaseOut bDollar,
	@StandardAllowance bDollar, 
	@ProcName varchar(30)

SELECT 
	@ReturnCode = 0, 
	@BaseTaxAmt = 0, 
	@BracketBaseAmt = 0, 
	@Rate = 0, 
	@ProcName = 'bspPRORT13'

-- #26244 set default status and/or exemptions if passed in values are invalid
IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('S','M')) SELECT @status = 'S'
IF @exempts IS NULL SELECT @exempts = 0

IF @ppds = 0
BEGIN
	SELECT @msg = @ProcName + ':  Missing # of Pay Periods per year!', @ReturnCode = 1
	RETURN @ReturnCode
END

/* annualize earnings and deduct allowance for exemptions and Fed tax */
SELECT @AnnualWages = (@subjamt * @ppds)

--define the Annual Wage Break
SELECT @AnnualWageBreak = 50000

--tax is computed differently when annual wages are on or above the Annual Wage Break
IF @AnnualWages <= @AnnualWageBreak
BEGIN --compute for wages below the Wage Break
	--define the maximum federal tax adjustment allowed
	SELECT @FedMax = 6250 
	SELECT @FedMax =
		(CASE 
			WHEN @fedtax * @ppds > @FedMax 
			THEN @FedMax 
			ELSE @fedtax * @ppds 
		END)

	--single with less than 3 allowances
	IF @status = 'S' AND @exempts < 3
	BEGIN
		SELECT @StandardDeduction = 2080

		SELECT @AnnualTaxable = @AnnualWages - @FedMax - @StandardDeduction

		IF @AnnualTaxable BETWEEN 0 AND 3250.00
		BEGIN
			SELECT @BaseTaxAmt = 188, @BracketBaseAmt = 0, @Rate = .05
		END
		ELSE IF @AnnualTaxable BETWEEN 3250.01 AND 8150.00
		BEGIN
			SELECT @BaseTaxAmt = 351, @BracketBaseAmt = 3250, @Rate = .07
		END
		ELSE If @AnnualTaxable BETWEEN 8150.01 AND 50000.00   
		BEGIN
			SELECT @BaseTaxAmt = 694, @BracketBaseAmt = 8150, @Rate = .09
		END
	END
	--all others (includes married and single with 3 or more allowances)
	ELSE
	BEGIN
		SELECT @StandardDeduction = 4160

		SELECT @AnnualTaxable = @AnnualWages - @FedMax - @StandardDeduction

		IF @AnnualTaxable BETWEEN 0 AND 6500.00
		BEGIN
			SELECT @BaseTaxAmt = 188, @BracketBaseAmt = 0, @Rate = .05
		END
		ELSE IF @AnnualTaxable BETWEEN 6500.01 AND 16300.00
		BEGIN
			SELECT @BaseTaxAmt = 513, @BracketBaseAmt = 6500, @Rate = .07
		END
		ELSE If @AnnualTaxable BETWEEN 16300.01 AND 50000.00
		BEGIN
			SELECT @BaseTaxAmt = 1199, @BracketBaseAmt = 16300, @Rate = .09
		END
	END
END
ELSE -- annual wages >= $50,000
BEGIN --compute tax for wages on or above the wage break
	--determine Phase Out (Fed Max) amount
	IF @status = 'S' 
	BEGIN
		IF @AnnualWages BETWEEN 50000 AND 124999.99	SELECT @PhaseOut = 6250
		ELSE IF @AnnualWages BETWEEN 125000.00 AND 129999.99 SELECT @PhaseOut = 5000
		ELSE IF @AnnualWages BETWEEN 130000.00 AND 134999.99 SELECT @PhaseOut = 3750
		ELSE IF @AnnualWages BETWEEN 135000.00 AND 139999.99 SELECT @PhaseOut = 2500
		ELSE IF @AnnualWages BETWEEN 140000.00 AND 144999.99 SELECT @PhaseOut = 1250
		ELSE IF @AnnualWages >= 145000.00 SELECT @PhaseOut = 0
	END
	ELSE
	BEGIN
		IF @AnnualWages BETWEEN 50000 AND 249999.99 SELECT @PhaseOut = 6250
		ELSE IF @AnnualWages BETWEEN 250000 AND 259999.99 SELECT @PhaseOut = 5000
		ELSE IF @AnnualWages BETWEEN 260000 AND 269999.99 SELECT @PhaseOut = 3750
		ELSE IF @AnnualWages BETWEEN 270000 AND 279999.99 SELECT @PhaseOut = 2500
		ELSE IF @AnnualWages BETWEEN 280000 AND 289999.99 SELECT @PhaseOut = 1250
		ELSE IF @AnnualWages >= 290000 SELECT @PhaseOut = 0
	END
	--define the maximum federal tax adjustment allowed
	SELECT @FedMax =
		(CASE 
			WHEN @fedtax * @ppds > @PhaseOut 
			THEN @PhaseOut 
			ELSE @fedtax * @ppds 
		END)

	--single with less than 3 allowances
	IF @status = 'S' AND @exempts < 3
	BEGIN
		SELECT @StandardDeduction = 2080

		SELECT @AnnualTaxable = @AnnualWages - @FedMax - @StandardDeduction

		IF @AnnualTaxable BETWEEN 41670 AND 124999.99
		BEGIN
			SELECT @BaseTaxAmt = 506, @BracketBaseAmt = 8150, @Rate = .09
		END
		ELSE If @AnnualTaxable >= 125000
		BEGIN
			SELECT @BaseTaxAmt = 11022, @BracketBaseAmt = 125000, @Rate = .099
		END
	END
	--all others (includes married and single with 3 or more allowances)
	ELSE
	BEGIN
		SELECT @StandardDeduction = 4160

		SELECT @AnnualTaxable = @AnnualWages - @FedMax - @StandardDeduction

		IF @AnnualTaxable BETWEEN 39590.00 AND 249999.99
		BEGIN
			SELECT @BaseTaxAmt = 1011, @BracketBaseAmt = 16300, @Rate = .09
		END
		ELSE If @AnnualTaxable >= 250000
		BEGIN
			SELECT @BaseTaxAmt = 22044, @BracketBaseAmt = 250000, @Rate = .099
		END
	END
END


--calculate Oregon Tax
SELECT @StandardAllowance = 188
SELECT @amt = (	@BaseTaxAmt 
				+ ((@AnnualTaxable - @BracketBaseAmt) * @Rate) 
				- (@StandardAllowance * @exempts)
			  ) / @ppds 

IF @amt IS NULL OR @amt < 0 
BEGIN
	SELECT @amt = 0.00
END

RETURN @ReturnCode

GO
GRANT EXECUTE ON  [dbo].[bspPRORT13] TO [public]
GO
