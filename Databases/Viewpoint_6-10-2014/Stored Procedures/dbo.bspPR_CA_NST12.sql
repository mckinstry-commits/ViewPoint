SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].[bspPR_CA_NST12]    Script Date: 02/27/2008 13:19:16 ******/
CREATE  PROC [dbo].[bspPR_CA_NST12]
/********************************************************
* CREATED BY: 	EN 5/13/08
* MODIFIED BY:	EN 5/18/09 #133697 tax update effective 1/1/09 and set a default for total claim (@TCP)
*				EN 12/18/2010 #137138 tax update effective 1/1/2010
*				EN 6/07/2010 #140071 tax update effective 7/1/2010
*				EN 08/23/2010 #140613  due to adjustment made in bspPRProcessFedCA to correct CPP/EI credits, @PP and @EI
*					are now passed in as annualized and no longer need to by multipled by number of pay periods
*				LS 12/30/2010 #142330 - tax update effective 1/1/2011
*				CHS	11/29/2011	- #145165 tax update effective 1/1/2012
*
* USAGE:
* 	Calculates Nova Scotia Provincial Income Tax
*
* INPUT PARAMETERS:
*	@ppds	# of pay pds per year
*	@A		annualized taxable wages
*	@TCP	provincial total claim amount reported on Form TD1NS
*	@PP		Canada Pension Plan contribution for the pay period
*	@maxCPP	maximum pension contribution
*	@EI		Employment Insurance premium for the pay period
*	@maxEI	maximum EI contribution
*	@K3P	other provincial tax credits such as medical expenses and charitable donations
*	@capstock	YTD deduction for acquisition of approved shares of the capital stock of a prescribed labour-sponsored venture capital corporation
*
* OUTPUT PARAMETERS:
*	@calcamt	tax amount for the pay period
*	@msg		error message IF failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
**********************************************************/
	(@ppds tinyint = 0, 
	 @A bDollar = 0, 
	 @TCP bDollar, 
	 @PP bDollar = 0, 
	 @maxCPP bDollar = 0, 
	 @EI bDollar = 0, 
	 @maxEI bDollar = 0, 
	 @K3P bDollar = 0, 
	 @capstock bDollar = 0, 
	 @calcamt bDollar = 0 output,
	 @msg varchar(255) = null output)
AS
BEGIN
	SET NOCOUNT ON
  
	DECLARE @ProcName varchar(30)

	SELECT @ProcName = 'bspPR_CA_NST12'

	-- validate pay periods
	IF @ppds = 0
	BEGIN
	SELECT @msg = @ProcName + ': Missing # of Pay Periods per year!'
		RETURN 1
	END

	DECLARE @Rate bRate, --tax rate
			@KP bDollar, --provincial tax constant 
			@K1P bDollar, --provincial non-refundable personal tax credit
			@K2P bDollar, --provincial pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
			@TaxCreditRate bRate, --tax credit rate (used to compute K2)
			@T4 bDollar, --basic annual provincial tax
			@V1 bDollar, --provincial surtax
			@LCP bDollar, --labor sponsored funds tax credit
			@T2 bDollar --annual provincial tax payable

	SELECT @KP = 0, 
		   @K1P = 0, 
		   @K2P = 0, 
		   @T4 = 0, 
		   @V1 = 0, 
		   @LCP = 0, 
		   @T2 = 0, 
		   @calcamt = 0, 
		   @TaxCreditRate = .0879

	-- IF form TD1NT was not filed (ie. no filing status entered) use default total claim
	IF @TCP IS NULL SELECT @TCP = 8481

	-- establish tax rate and constant
	IF @A BETWEEN 0 AND 29590 
	BEGIN
		SELECT @Rate = .0879, @KP = 0
	END
	ELSE IF @A BETWEEN 29590.01 AND 59180
	BEGIN 
		SELECT @Rate = .1495, @KP = 1823
	END
	ELSE IF @A BETWEEN 59180.01 AND 93000 
	BEGIN
		SELECT @Rate = .1667, @KP = 2841
	END
	ELSE IF @A BETWEEN 93000.01 AND 150000 
	BEGIN
		SELECT @Rate = .1750, @KP = 3613
	END
	ELSE IF @A > 150000 
	BEGIN
		SELECT @Rate = .2100, @KP = 8863
	END

	-- compute provincial non-refundable personal tax credit
	SELECT @K1P = round(@TaxCreditRate * @TCP,2)

	-- compute pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
	SELECT @K2P = round(@TaxCreditRate * (case when @PP < @maxCPP then @PP else @maxCPP END),2) --CPP portion
	SELECT @K2P = @K2P + round(@TaxCreditRate * (case when @EI < @maxEI then @EI else @maxEI END),2) -- EI portion

	-- compute basic Annual Federal Tax
	SELECT @T4 = (@Rate * @A) - @KP - @K1P - @K2P - @K3P 

	-- compute provincial surtax [V1]
	SELECT @V1 = 0
	--IF @T4 > 10000 SELECT @V1 = .1 * (@T4 - 10000) <-- #140071  V1 not computed as of 7/1/2010

	-- compute labour-sponsored funds federal tax credit for the year [LCP]
	SELECT @LCP = case when .2 * @capstock < 2000 then .2 * @capstock else 2000 END

	-- compute annual provincial tax payable [T2]
	SELECT @T2 = @T4 + @V1 - @LCP
	IF @T2 < 0 SELECT @T2 = 0

	-- prorate tax amount for the pay period
	SELECT @calcamt = round(@T2 / @ppds,2)

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_NST12] TO [public]
GO
