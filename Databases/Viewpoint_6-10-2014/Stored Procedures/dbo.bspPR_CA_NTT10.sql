SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_NTT10]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_CA_NTT10]
   /********************************************************
   * CREATED BY: 	EN 5/15/08
   * MODIFIED BY:	EN 5/18/09 #133697 tax update effective 1/1/09 and set a default for total claim (@TCP)
   *				EN 12/18/2010 #137138 tax update effective 1/1/2010 ... also added code for LCP credit
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
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
	(@ppds tinyint = 0, @A bDollar = 0, @TCP bDollar = 0, 
	@PP bDollar = 0, @maxCPP bDollar = 0, @EI bDollar = 0, @maxEI bDollar = 0, @K3P bDollar = 0, 
	@capstock bDollar = 0, @calcamt bDollar = 0 output,
	@msg varchar(255) = null output)
   as
   set nocount on
  
   declare @rcode int, @procname varchar(30)

   select @rcode = 0, @procname = 'bspPR_CA_NTT10'

   -- validate pay periods
   if @ppds = 0
   	begin
   	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end

   declare @rate bRate, --tax rate
			@KP bDollar, --territorial tax constant 
			@K1P bDollar, --territorial non-refundable personal tax credit
			@K2P bDollar, --territorial pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
			@TCrate bRate, --tax credit rate (used to compute K2)
			@T4 bDollar, --basic annual territorial tax
			@LCP bDollar, --labor sponsored funds tax credit
			@T2 bDollar --annual territorial tax payable
   
   select @KP = 0, @K1P = 0, @K2P = 0, @T4 = 0, @LCP = 0, @T2 = 0, @calcamt = 0, @TCrate = .059

   -- if form TD1NT was not filed (ie. no filing status entered) use default total claim
   if @TCP is null select @TCP = 12740

   -- establish tax rate and constant
   select @rate = .1405, @KP = 5906
   if @A <= 120656 select @rate = .1220, @KP = 3674
   if @A <= 74214 select @rate = .0860, @KP = 1002
   if @A <= 37106 select @rate = .0590, @KP = 0

   -- compute territorial non-refundable personal tax credit
   select @K1P = round(@TCrate * @TCP,2)

   -- compute pension plan (CPP/QPP) and Employment Insurance (EI) premium tax credits for the year
	select @K2P = round(@TCrate * (case when @ppds*@PP < @maxCPP then @ppds*@PP else @maxCPP end),2) --CPP portion
	select @K2P = @K2P + round(@TCrate * (case when @ppds*@EI < @maxEI then @ppds*@EI else @maxEI end),2) -- EI portion

   -- compute basic Annual Federal Tax
   select @T4 = (@rate * @A) - @KP - @K1P - @K2P - @K3P 

   -- compute labour-sponsored funds federal tax credit for the year
   if @capstock < 5000 select @LCP = .15 * @capstock
   if @capstock >= 5000
	begin
	select @LCP = .15 * 5000 --15% of the first 5000
	select @LCP = @LCP + (.3 * (@capstock - 5000)) --30% after that
	end
   if @LCP > 29250 select @LCP = 29250 --cap LCP if over the limit
 
   -- compute annual territorial tax payable
   select @T2 = @T4 - @LCP
   if @T2 < 0 select @T2 = 0


   -- prorate tax amount for the pay period
   select @calcamt = round(@T2 / @ppds,2)


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_NTT10] TO [public]
GO
