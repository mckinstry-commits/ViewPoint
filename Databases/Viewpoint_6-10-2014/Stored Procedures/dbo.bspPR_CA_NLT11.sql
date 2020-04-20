SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_NLT11]    Script Date: 02/27/2008 13:19:16 ******/
CREATE  proc [dbo].[bspPR_CA_NLT11]
/********************************************************
* CREATED BY: 	EN 5/15/08
* MODIFIED BY:	EN 5/15/09 #133697 tax update effective 1/1/09 and set a default for total claim (@TCP)
*				EN 6/22/2009 #134466 tax update effective 7/1/09
*				EN 12/18/2010 #137138 tax update effective 1/1/2010
*				EN 6/07/2010 #140051 tax update effective 7/1/2010
*				EN 08/23/2010 #140613  due to adjustment made in bspPRProcessFedCA to correct CPP/EI credits, @PP and @EI
*					are now passed in as annualized and no longer need to by multipled by number of pay periods
*				CHS	12/20/2010 #142328 tax update effective 1/1/2011
*
* USAGE:
* 	Calculates Newfoundland and Labrador Provincial Income Tax
*
* INPUT PARAMETERS:
*	@ppds	# of pay pds per year
*	@A		annualized taxable wages
*	@TCP	provincial total claim amount reported on Form TD1NL
*	@PP		Canada Pension Plan
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
*GRANT EXECUTE ON bspPR_CA_NLT11 TO public;
**********************************************************/
(@ppds tinyint = 0, @A bDollar = 0, @TCP bDollar = 0, 
	@PP bDollar = 0, @maxCPP bDollar = 0, @EI bDollar = 0, 
	@maxEI bDollar = 0, @K3P bDollar = 0, 
	@capstock bDollar = 0, @calcamt bDollar = 0 output,
	@msg varchar(255) = null output)
	
   AS
   SET NOCOUNT ON
  
   DECLARE @rcode int, @procname varchar(30)
   
   SELECT @rcode = 0, @procname = 'bspPR_CA_NLT11'

   -- validate pay periods
	IF @ppds = 0
		BEGIN
		SELECT @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
		RETURN @rcode
		END

   DECLARE @Rate bRate, --tax rate
			@KP bDollar, --provincial tax constant 
			@K1P bDollar, --provincial non-refundable personal tax credit
			@K2P bDollar, --provincial pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
			@TCrate bRate, --tax credit rate (used to compute K2)
			@T4 bDollar, --basic annual provincial tax
			@LCP bDollar, --labor sponsored funds tax credit
			@T2 bDollar --annual provincial tax payable
   
   SELECT @KP = 0, @K1P = 0, @K2P = 0, @T4 = 0, @LCP = 0, @T2 = 0, @calcamt = 0, @TCrate = .077

   -- IF form TD1NL was not filed (ie. no filing status entered) use default total claim
   IF ISNULL(@TCP,0) = 0 SELECT @TCP = 7989

   -- establish tax rate and constant
   IF      @A BETWEEN     0 AND 31904	SELECT @Rate = .077, @KP = 0
   ELSE IF @A BETWEEN 31904 AND 63807	SELECT @Rate = .125, @KP = 1531
   ELSE IF @A > 63807					SELECT @Rate = .133, @KP = 2042

   -- compute provincial non-refundable personal tax credit
   SELECT @K1P = ROUND(@TCrate * @TCP,2)

   -- compute pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
	SELECT @K2P = ROUND(@TCrate * (CASE WHEN @PP < @maxCPP THEN @PP ELSE @maxCPP END),2) --CPP portion
	SELECT @K2P = @K2P + ROUND(@TCrate * (CASE WHEN @EI < @maxEI THEN @EI ELSE @maxEI END),2) -- EI portion

   -- compute basic Annual Federal Tax
   SELECT @T4 = (@Rate * @A) - @KP - @K1P - @K2P - @K3P 

   -- compute labour-sponsored funds federal tax credit for the year
   SELECT @LCP = CASE WHEN .2 * @capstock < 2000 THEN .2 * @capstock ELSE 2000 END
 
   -- compute annual provincial tax payable
   SELECT @T2 = @T4 - @LCP
   IF @T2 < 0 SELECT @T2 = 0

   -- prorate tax amount for the pay period
   SELECT @calcamt = ROUND(@T2 / @ppds,2)


   bspexit:
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_NLT11] TO [public]
GO
