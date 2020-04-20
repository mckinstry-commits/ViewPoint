SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_ABT11]    Script Date: 02/27/2008 13:19:16 ******/
CREATE  proc [dbo].[bspPR_CA_ABT11]
/********************************************************
* CREATED BY: 	EN 5/15/08
* MODIFIED BY:	EN 5/15/09 #133697 set a default for total claim (@TCP)
*				EN 12/17/2010 #137138 tax update effective 1/1/2010
*				EN 08/18/2010 #140613  due to adjustment made in bspPRProcessFedCA to correct CPP/EI credits, @PP and @EI 
*					are now passed in as annualized and no longer need to by multipled by number of pay periods
*				LS 12/20/2010 #143324 tax update effective 1/1/2011
*
* USAGE:
* 	Calculates Alberta Provincial Income Tax
*
* INPUT PARAMETERS:
*	@ppds	# of pay pds per year
*	@A		annualized taxable wages
*	@TCP	provincial total claim amount reported on Form TD1AB
*	@PP		Canada Pension Plan contribution for the pay period
*	@maxCPP	maximum pension contribution
*	@EI		Employment Insurance premium for the pay period
*	@maxEI	maximum EI contribution
*	@K3P	other provincial tax credits such as medical expenses and charitable donations
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
	 @calcamt bDollar = 0 output,
	 @msg varchar(255) = null output)
as
BEGIN
	SET NOCOUNT ON

	DECLARE @ReturnCode int, 
			@ProcName varchar(30)

	SELECT @ReturnCode = 0, 
		   @ProcName = 'bspPR_CA_ABT11'

	-- validate pay periods
	IF @ppds = 0
	BEGIN
		SELECT @msg = @ProcName + ': Missing # of Pay Periods per year!', @ReturnCode = 1
		RETURN @ReturnCode
	END

	DECLARE @Rate bRate, --tax rate
			@K1P bDollar, --provincial non-refundable personal tax credit
			@K2P bDollar, --provincial pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
			@TaxCreditRate bRate, --tax credit rate (used to compute K2)
			@T4 bDollar, --basic annual provincial tax
			@T2 bDollar --annual provincial tax payable
   
	SELECT @Rate = 0.10, @K1P = 0, @K2P = 0, @T4 = 0, @T2 = 0, @calcamt = 0, @TaxCreditRate = .10

	-- IF form TD1AB was not filed (ie. no filing status entered) use default total claim
	IF @TCP IS NULL SELECT @TCP = 16977

	-- compute provincial non-refundable personal tax credit
	SELECT @K1P = ROUND(@TaxCreditRate * @TCP,2)

   -- compute pension plan (CPP/QPP) and Employment Insurance (EI) premium tax credits for the year
	SELECT @K2P = ROUND(@TaxCreditRate * (CASE WHEN @PP < @maxCPP THEN @PP ELSE @maxCPP END),2) --CPP portion
	SELECT @K2P = @K2P + ROUND(@TaxCreditRate * (CASE WHEN @EI < @maxEI THEN @EI ELSE @maxEI END),2) -- EI portion

   -- compute basic Annual Federal Tax
	SELECT @T4 = (@Rate * @A) - @K1P - @K2P - @K3P 

	-- compute annual provincial tax payable
	SELECT @T2 = @T4
	IF @T2 < 0 SELECT @T2 = 0

	-- prorate tax amount for the pay period
	SELECT @calcamt = ROUND(@T2 / @ppds,2)

	RETURN @ReturnCode
END

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_ABT11] TO [public]
GO
