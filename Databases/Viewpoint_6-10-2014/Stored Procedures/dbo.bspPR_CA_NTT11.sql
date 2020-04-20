SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].[bspPR_CA_NTT11]    Script Date: 02/27/2008 13:19:16 ******/
CREATE  PROC [dbo].[bspPR_CA_NTT11]
/********************************************************
* CREATED BY: 	EN 5/15/08
* MODIFIED BY:	EN 5/18/09 #133697 tax update effective 1/1/09 and set a default for total claim (@TCP)
*				EN 12/18/2010 #137138 tax update effective 1/1/2010 ... also added code for LCP credit
*				EN 08/23/2010 #140613  due to adjustment made in bspPRProcessFedCA to correct CPP/EI credits, @PP and @EI
*					are now passed in as annualized and no longer need to by multipled by number of pay periods
*				LS 12/28/2010 #142329 tax update effective 1/1/2011
*
* USAGE:
* 	Calculates Northwest Territories Territorial Income Tax
*
* INPUT PARAMETERS:
*	@ppds	# of pay pds per year
*	@A		annualized taxable wages
*	@TCP	territorial total claim amount reported on Form TD1NT
*	@PP		Canada Pension Plan contribution for the pay period
*	@maxCPP	maximum pension contribution
*	@EI		Employment Insurance premium for the pay period
*	@maxEI	maximum EI contribution
*	@K3P	other territorial tax credits such as medical expenses and charitable donations
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
   set nocount on
  
   DECLARE @ProcName varchar(30)

   SELECT @ProcName = 'bspPR_CA_NTT11'

	-- validate pay periods
	IF @ppds = 0
	BEGIN
		SELECT @msg = @ProcName + ': Missing # of Pay Periods per year!'
		RETURN 1
	END

	DECLARE @Rate bRate, --tax rate
			@KP bDollar, --territorial tax constant 
			@K1P bDollar, --territorial non-refundable personal tax credit
			@K2P bDollar, --territorial pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
			@TaxCreditRate bRate, --tax credit rate (used to compute K2)
			@T4 bDollar, --basic annual territorial tax
			@LCP bDollar, --labor sponsored funds tax credit
			@T2 bDollar --annual territorial tax payable
   
	SELECT @KP = 0, 
		   @K1P = 0, 
		   @K2P = 0, 
		   @T4 = 0, 
		   @LCP = 0, 
		   @T2 = 0, 
		   @calcamt = 0, 
		   @TaxCreditRate = .059

	-- IF form TD1NT was not filed (ie. no filing status entered) use default total claim
	IF @TCP IS NULL SELECT @TCP = 12919

	-- Establish tax rate and constant [Rate, KP] used in T4 Calculation
	IF @A BETWEEN 0 AND 37626
	BEGIN
		SELECT @Rate = .0590, @KP = 0
	END
	ELSE IF @A BETWEEN 37626.01 AND 75253
	BEGIN
		SELECT @Rate = .0860, @KP = 1016
	END
	ELSE IF @A BETWEEN 75253.01 AND 122345
	BEGIN
		SELECT @Rate = .1220, @KP = 3725
	END
	ELSE IF @A > 122345
	BEGIN
		SELECT @Rate = .1405, @KP = 5988
	END

	-- compute territorial non-refundable personal tax credit [K1P]
	SELECT @K1P = ROUND(@TaxCreditRate * @TCP,2)

	-- compute pension plan (CPP/QPP) and Employment Insurance (EI) premium tax credits for the year
	SELECT @K2P = ROUND(@TaxCreditRate * (CASE WHEN @PP < @maxCPP THEN @PP ELSE @maxCPP END),2) --CPP portion
	SELECT @K2P = @K2P + ROUND(@TaxCreditRate * (CASE WHEN @EI < @maxEI THEN @EI ELSE @maxEI END),2) -- EI portion

	-- compute basic Annual Federal Tax [T4]
	SELECT @T4 = (@Rate * @A) - @KP - @K1P - @K2P - @K3P 

	-- compute labour-sponsored funds federal tax credit for the year [LCP]
	IF @capstock <= 5000 SELECT @LCP = .15 * @capstock
	IF @capstock > 5000
	BEGIN
		SELECT @LCP = .15 * 5000 --15% of the first 5000
		SELECT @LCP = @LCP + (.3 * (@capstock - 5000)) --30% after that
	END
	IF @LCP > 29250 SELECT @LCP = 29250 --cap LCP IF over the limit

	-- compute annual territorial tax payable [T2]
	-- T2 = T4 + V1 - S - LCP  (V1 and S = 0)
	SELECT @T2 = @T4 - @LCP
	IF @T2 < 0 SELECT @T2 = 0

	-- prorate tax amount for the pay period
	SELECT @calcamt = ROUND(@T2 / @ppds,2)

   	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_NTT11] TO [public]
GO
