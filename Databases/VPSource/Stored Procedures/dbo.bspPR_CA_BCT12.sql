SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].[bspPR_CA_BCT12]    Script Date: 02/27/2008 13:19:16 ******/
CREATE  proc [dbo].[bspPR_CA_BCT12]
/********************************************************
* CREATED BY: 	EN 05/15/2008
* MODIFIED BY:	EN 05/15/2009	- #133697 tax update effective 1/1/09 and set a default for total claim (@TCP)
*				EN 12/17/2009	- #137138 tax update effective 1/1/2010
*				MV 08/23/2010	- #140617 - corrected tax rate from .0781 to .0770 for 2010 
*				EN 08/23/2010	- #140613  due to adjustment made in bspPRProcessFedCA to correct CPP/EI credits, @PP and @EI
*									are now passed in as annualized and no longer need to by multipled by number of pay periods
*				LS 12/22/2010	- #142325 tax update effective 1/1/2011
*				CHS	11/29/2011	- #145159 tax update effective 1/1/2012
*
* USAGE:
* 	Calculates British Columbia Provincial Income Tax
*
* INPUT PARAMETERS:
*	@ppds	# of pay pds per year
*	@A		annualized taxable wages
*	@TCP	provincial total claim amount reported on Form TD1BC
*	@PP		Canada Pension Plan contribution for the pay period
*	@maxCPP	maximum pension contribution
*	@EI		Employment Insurance premium for the pay period
*	@maxEI	maximum EI contribution
*	@K3P	other provincial tax credits such as medical expenses and charitable donations
*	@HD		annual deduction for living in a prescribed zone
*	@capstock	YTD deduction for acquisition of approved shares of the capital stock of a prescribed labour-sponsored venture capital corporation
*
* OUTPUT PARAMETERS:
*	@calcamt	tax amount for the pay period
*	@msg		error message IF failure
*
* RETURN VALUE:
* 	0 	    success
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
	 @HD bDollar = 0, 
	 @capstock bDollar = 0, 
	 @calcamt bDollar = 0 output,
	 @msg varchar(255) = null output)
AS
BEGIN
	SET NOCOUNT ON
 
	DECLARE @ProcName varchar(30)

	SELECT @ProcName = 'bspPR_CA_BCT12'

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
			@S bDollar, --provincial tax reduction
			@SBracket1 bDollar, -- prov. tax reduction Bracket 1
			@SBracket2 bDollar, -- prov. tax reduction Bracket 2
			@Sii bDollar, -- provincial tax cap
			@Sii2 bDollar, -- 2nd provincial tax cap
			@A1 bDollar, --annual net income
			@LCP bDollar, --labor sponsored funds tax credit
			@T2 bDollar --annual provincial tax payable
   
	SELECT @KP = 0, 
		   @K1P = 0, 
		   @K2P = 0, 
		   @T4 = 0, 
		   @S = 0, 
		   @A1 = 0, 
		   @LCP = 0, 
		   @T2 = 0, 
		   @calcamt = 0, 
		   @TaxCreditRate = .0506

	-- IF form TD1BC was not filed (ie. no filing status entered) use default total claim
	IF @TCP IS NULL SELECT @TCP = 11354


	-- establish tax rate and constant
	SELECT @Rate = .1470, @KP = 7059
	IF @A <= 103205 SELECT @Rate = .1229, @KP = 4571
	IF @A <= 84993 SELECT @Rate = .1050, @KP = 3050
	IF @A <= 74028 SELECT @Rate = .0770, @KP = 977
	IF @A <= 37013 SELECT @Rate = .0506, @KP = 0


	-- compute provincial non-refundable personal tax credit (K1P)
	SELECT @K1P = ROUND(@TaxCreditRate * @TCP,2)

   -- compute pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year (K2P)
	SELECT @K2P = ROUND(@TaxCreditRate * (CASE WHEN @PP < @maxCPP THEN @PP ELSE @maxCPP END),2) --CPP portion
	SELECT @K2P = @K2P + ROUND(@TaxCreditRate * (CASE WHEN @EI < @maxEI THEN @EI ELSE @maxEI END),2) -- EI portion

   -- compute basic Annual Federal Tax (T4)
   SELECT @T4 = (@Rate * @A) - @KP - @K1P - @K2P - @K3P 

   -- compute provincial tax reduction (S)
	SELECT @A1 = @A + @HD
	SELECT @Sii = 403,
		   @SBracket1 = 17913,
		   @SBracket2 = 30506.75,
		   @Sii2 = @Sii - ((@A1 - @SBracket1)*.032)
		   
		-- If A <= 1st Bracket, Then S is the lessor of T4 or @Sii
	IF @A1 <= @SBracket1 SELECT @S = CASE WHEN @T4 < @Sii THEN @T4 ELSE @Sii END
	
		-- If A > 1st Bracket <= 2nd Bracket, Then S = The lessor of T4 and @Sii2
	IF @A1 > @SBracket1 AND @A1 <= @SBracket2 
	BEGIN
		SELECT @S = CASE WHEN @T4 < @Sii2 THEN @T4 ELSE @Sii2 END
	END
	IF @A1 > @SBracket2 SELECT @S = 0

   -- compute labour-sponsored funds federal tax credit for the year (LCP)
	SELECT @LCP = CASE WHEN .15 * @capstock < 2000 THEN .15 * @capstock ELSE 2000 END

	-- compute annual provincial tax payable (T2) T2 = T4 + V1 - S - LCP
	SELECT @T2 = @T4 + @S - @LCP   -- V1 = 0
	IF @T2 < 0 SELECT @T2 = 0

	-- prorate tax amount for the pay period 
	SELECT @calcamt = ROUND(@T2 / @ppds,2)

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_BCT12] TO [public]
GO
