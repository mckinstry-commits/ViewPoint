
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_ONT13]    Script Date: 02/27/2008 13:19:16 ******/
CREATE  proc [dbo].[bspPR_CA_ONT132]
/********************************************************
* CREATED BY: 	EN  3/26/08
* MODIFIED BY:	EN  10/16/08  Update for changes effective 7/1/08
*				EN  05/18/09 #133697 tax update effective 1/1/09 and set a default for total claim (@TCP)
*				EN  12/18/10 #137138 tax update effective 1/1/2010
*				EN  08/23/10 #140613  due to adjustment made in bspPRProcessFedCA to correct CPP/EI credits, @PP and @EI
*						are now passed in as annualized and no longer need to by multipled by number of pay periods
*				CHS	12/16/10 tax update effective 01/01/11
*				CHS	11/30/11 tax update effective 01/01/12
*				KK	05/25/12 tax update effective 01/01/13 (Refactored code as per best practice)
*				CHS	12/11/12 TK-20145 B-11807 #147555 tax update effective 01/01/13
*					NOTE: the previous file bspPR_CA_ONT13 was a mid-year tax update and should have been named 
*					bspPR_CA_ONT122. Because bspPR_CA_ONT13 has already been released to the wild, this update will be named
*					bspPR_CA_ONT132
*
* USAGE:
* 	Calculates Ontario Provincial Income Tax
*
* INPUT PARAMETERS:
*	@ppds		# of pay pds per year
*	@A			annualized taxable wages
*	@TCP		provincial total claim amount reported on Form TD1ON
*	@addexempts	# of dependants under age 18 for which employee has made a written request + dependants who are disabled as indicated on Form TD1ON
*	@PP			Canada Pension Plan contribution for the pay period
*	@maxCPP		maximum pension contribution
*	@EI			Employment Insurance premium for the pay period
*	@maxEI		maximum EI contribution
*	@K3P		other provincial tax credits such as medical expenses and charitable donations
*	@capstock	YTD deduction for acquisition of approved shares of the capital stock of a prescribed labour-sponsored venture capital corporation
*
* OUTPUT PARAMETERS:
*	@calcamt	tax amount for the pay period
*	@msg		error message if failure
*
* RETURN VALUE:
* 	0 	    success
*	1 		failure
**********************************************************/
(@ppds tinyint = 0, 
 @A bDollar = 0, 
 @TCP bDollar = 0, 
 @addexempts tinyint = 0,
 @PP bDollar = 0, 
 @maxCPP bDollar = 0, 
 @EI bDollar = 0, 
 @maxEI bDollar = 0,
 @K3P bDollar = 0, 
 @capstock bDollar = 0, 
 @calcamt bDollar = 0 OUTPUT,
 @msg varchar(255) = NULL OUTPUT)

AS
SET NOCOUNT ON
  
DECLARE @procname varchar(30)
   
SELECT	@procname = 'bspPR_CA_ONT132'
   
-- validate pay periods
IF @ppds = 0
BEGIN
	SELECT @msg = @procname + ': Missing # of Pay Periods per year!'
   	RETURN 1
END

DECLARE @rate bRate, --tax rate
		@KP bDollar, --provincial tax constant 
		@K1P bDollar, --provincial non-refundable personal tax credit
		@K2P bDollar, --provincial pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
		@TCrate bRate, --tax credit rate (used to compute K2)
		@T4 bDollar, --basic annual provincial tax
		@V1 bDollar, --provincial surtax
		@V2 bDollar, --additional provincial tax (applies to Ontario Health Premium only)
		@S bDollar, --provincial tax reduction
		@Y bDollar, --additional reduction for certain dependents
		@LCP bDollar, --labor sponsored funds tax credit
		@T2 bDollar, --annual provincial tax payable
		@BPA bDollar -- Basic Personal Ammount
   
SELECT	@KP = 0, 
		@K1P = 0, 
		@K2P = 0, 
		@T4 = 0, 
		@V1 = 0, 
		@S = 0, 
		@Y = 0, 
		@LCP = 0, 
		@T2 = 0, 
		@calcamt = 0, 
		@TCrate = .0505, 
		@BPA = 221

-- if form TD1ON was not filed (ie. no filing status entered) use default total claim
IF @TCP IS NULL SELECT @TCP = 9574

-- establish tax rate and constant
IF		@A <= 39723					   SELECT @rate = .0505, @KP = 0
ELSE IF @A BETWEEN 39723.01 AND  79448 SELECT @rate = .0915, @KP = 1629
ELSE IF @A BETWEEN 79448.01 AND 509000 SELECT @rate = .1116, @KP = 3226
ELSE IF @A > 509000.01				   SELECT @rate = .1316, @KP = 13406

-- compute provincial non-refundable personal tax credit
SELECT @K1P = round(@TCrate * @TCP,2)

-- compute pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
SELECT @K2P = round(@TCrate * (CASE WHEN @PP < @maxCPP THEN @PP ELSE @maxCPP END),2) --CPP portion
SELECT @K2P = @K2P + round(@TCrate * (CASE WHEN @EI < @maxEI THEN @EI ELSE @maxEI END),2) -- EI portion

-- compute basic Annual Federal Tax
SELECT @T4 = (@rate * @A) - @KP - @K1P - @K2P - @K3P 

-- compute provincial surtax
SELECT @V1 = 0
IF @T4 > 4289 SELECT @V1 = .2 * (@T4 - 4289)
IF @T4 > 5489 SELECT @V1 = @V1 + .36 * (@T4 - 5489)

-- compute additional tax (applies to Ontario Health Premium)
SELECT @V2 = 0
	 IF @A > 20000 and @A <= 36000	SELECT @V2 = CASE WHEN		.06*(@A-20000)<300   THEN	   .06*(@A-20000)   ELSE 300 END
ELSE IF @A > 36000 and @A <= 48000	SELECT @V2 = CASE WHEN 300+(.06*(@A-36000))<450  THEN 300+(.06*(@A-36000))  ELSE 450 END
ELSE IF @A > 48000 and @A <= 72000	SELECT @V2 = CASE WHEN 450+(.25*(@A-48000))<600  THEN 450+(.25*(@A-48000))  ELSE 600 END
ELSE IF @A > 72000 and @A <= 200000 SELECT @V2 = CASE WHEN 600+(.25*(@A-72000))<750  THEN 600+(.25*(@A-72000))  ELSE 750 END
ELSE IF @A > 200000					SELECT @V2 = CASE WHEN 750+(.25*(@A-200000))<900 THEN 750+(.25*(@A-200000)) ELSE 900 END

   -- compute provincial tax reduction
SELECT @Y = (409 * @addexempts)
SELECT @S = CASE WHEN @T4+@V1 < (2*(@BPA+@Y))-(@T4+@V1) THEN @T4+@V1 ELSE (2*(@BPA+@Y))-(@T4+@V1) END
IF @S < 0 SELECT @S = 0

   -- compute labour-sponsored funds federal tax credit for the year
SELECT @LCP = CASE WHEN .15 * @capstock < 750 THEN .15 * @capstock ELSE 750 END
 
   -- compute annual provincial tax payable
SELECT @T2 = @T4 + @V1 + @V2 - @S - @LCP
IF @T2 < 0 SELECT @T2 = 0

   -- prorate tax amount for the pay period
SELECT @calcamt = round(@T2 / @ppds,2)

RETURN 0
GO


GRANT EXECUTE ON  [dbo].[bspPR_CA_ONT132] TO [public]
GO
