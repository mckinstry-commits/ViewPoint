SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_NBT11]    Script Date: 02/27/2008 13:19:16 ******/
CREATE  proc [dbo].[bspPR_CA_NBT12]
/********************************************************
* CREATED BY: 	EN 5/13/08
* MODIFIED BY:	EN 5/15/09 #133697 tax update effective 1/1/09 and set a default for total claim (@TCP)
*				EN 6/22/2009 #134466 tax update effective 7/1/09
*				EN 12/18/2010 #137138 tax update effective 1/1/2010
*				EN 08/23/2010 #140613  due to adjustment made in bspPRProcessFedCA to correct CPP/EI credits, @PP and @EI
*					are now passed in as annualized and no longer need to by multipled by number of pay periods
*				MV 12/21/2010 - #142327 tax update effective 1/1/2011
*				MV 11/29/11 - #TK-10421 tax update effective 1/1/2012
*
* USAGE:
* 	Calculates New Brunswick Provincial Income Tax
*
* INPUT PARAMETERS:
*	@ppds	# of pay pds per year
*	@A		annualized taxable wages
*	@TCP	provincial total claim amount reported on Form TD1NB
*	@PP		Canada Pension Plan
*	@maxCPP	maximum pension contribution
*	@EI		Employment Insurance premium for the pay period
*	@maxEI	maximum EI contribution
*	@K3P	other provincial tax credits such as medical expenses and charitable donations
*	@capstock	YTD deduction for acquisition of approved shares of the capital stock of a prescribed labour-sponsored venture capital corporation
*
* OUTPUT PARAMETERS:
*	@calcamt	tax amount for the pay period
*	@msg		error message if failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
*GRANT EXECUTE ON bspPR_CA_NBT11 TO public;
**********************************************************/
(@ppds tinyint = 0, @A bDollar = 0, @TCP bDollar = 0, 
	@PP bDollar = 0, @maxCPP bDollar = 0, @EI bDollar = 0, @maxEI bDollar = 0, @K3P bDollar = 0, 
	@capstock bDollar = 0, @calcamt bDollar = 0 output,
	@msg varchar(255) = null output)
   as
   set nocount on
  
   declare @rcode int, @procname varchar(30)
   
   select @rcode = 0, @procname = 'bspPR_CA_NBT12'
   
   -- validate pay periods
   if @ppds = 0
   	begin
   	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end

   declare @rate bRate, --tax rate
			@KP bDollar, --provincial tax constant 
			@K1P bDollar, --provincial non-refundable personal tax credit
			@K2P bDollar, --provincial pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
			@TCrate bRate, --tax credit rate (used to compute K2)
			@T4 bDollar, --basic annual provincial tax
			@LCP bDollar, --labor sponsored funds tax credit
			@T2 bDollar --annual provincial tax payable
   
   select @KP = 0, @K1P = 0, @K2P = 0, @T4 = 0, @LCP = 0, @T2 = 0, @calcamt = 0, @TCrate = .091

   -- if form TD1NB was not filed (ie. no filing status entered) use default total claim
   if @TCP is null select @TCP = 9203

   -- establish tax rate and constant
   select @rate = .143, @KP = 3734
   if @A <= 124178 select @rate = .124, @KP = 1375
   if @A <= 76380 select @rate = .121, @KP = 1146
   if @A <= 38190 select @rate = .091, @KP = 0

   -- compute provincial non-refundable personal tax credit
   select @K1P = round(@TCrate * @TCP,2)

   -- compute pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
	select @K2P = round(@TCrate * (case when @PP < @maxCPP then @PP else @maxCPP end),2) --CPP portion
	select @K2P = @K2P + round(@TCrate * (case when @EI < @maxEI then @EI else @maxEI end),2) -- EI portion

   -- compute basic Annual Federal Tax
   select @T4 = (@rate * @A) - @KP - @K1P - @K2P - @K3P 

   -- compute labour-sponsored funds federal tax credit for the year
   select @LCP = case when .2 * @capstock < 2000 then .2 * @capstock else 2000 end
 
   -- compute annual provincial tax payable
   select @T2 = @T4 - @LCP
   if @T2 < 0 select @T2 = 0

   -- prorate tax amount for the pay period
   select @calcamt = round(@T2 / @ppds,2)


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_NBT12] TO [public]
GO
