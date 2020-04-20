SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_NUT102]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_CA_NUT102]
   /********************************************************
   * CREATED BY: 	EN 5/15/08
   * MODIFIED BY:	EN 5/18/09 #133697 tax update effective 1/1/09 and set a default for total claim (@TCP)
   *				EN 12/18/2010 #137138 tax update effective 1/1/2010
   *				EN 08/23/2010 #140613  due to adjustment made in bspPRProcessFedCA to correct CPP/EI credits, @PP and @EI
   *					are now passed in as annualized and no longer need to by multipled by number of pay periods
   *
   * USAGE:
   * 	Calculates Nunavut Territorial Income Tax
   *
   * INPUT PARAMETERS:
   *	@ppds	# of pay pds per year
   *	@A		annualized taxable wages
   *	@TCP	territorial total claim amount reported on Form TD1NU
   *	@PP		Canada Pension Plan contribution for the pay period
   *	@maxCPP	maximum pension contribution
   *	@EI		Employment Insurance premium for the pay period
   *	@maxEI	maximum EI contribution
   *	@K3P	other territorial tax credits such as medical expenses and charitable donations
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
	@PP bDollar = 0, @maxCPP bDollar = 0, @EI bDollar = 0, @maxEI bDollar = 0, @K3P bDollar = 0, @calcamt bDollar = 0 output,
	@msg varchar(255) = null output)
   as
   set nocount on
  
   declare @rcode int, @procname varchar(30)
   
   select @rcode = 0, @procname = 'bspPR_CA_NUT102'
   
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
			@T2 bDollar --annual territorial tax payable
   
   select @KP = 0, @K1P = 0, @K2P = 0, @T4 = 0, @T2 = 0, @calcamt = 0, @TCrate = .040

   -- if form TD1NU was not filed (ie. no filing status entered) use default total claim
   if @TCP is null select @TCP = 11714

   -- establish tax rate and constant
   select @rate = .115, @KP = 5910
   if @A <= 127021 select @rate = .090, @KP = 2735
   if @A <= 78130 select @rate = .070, @KP = 1172
   if @A <= 39065 select @rate = .040, @KP = 0

   -- compute territorial non-refundable personal tax credit
   select @K1P = round(@TCrate * @TCP,2)

   -- compute pension plan (CPP/QPP) and Employment Insurance (EI) premium tax credits for the year
	select @K2P = round(@TCrate * (case when @PP < @maxCPP then @PP else @maxCPP end),2) --CPP portion
	select @K2P = @K2P + round(@TCrate * (case when @EI < @maxEI then @EI else @maxEI end),2) -- EI portion

   -- compute basic Annual Federal Tax
   select @T4 = (@rate * @A) - @KP - @K1P - @K2P - @K3P 

   -- compute annual territorial tax payable
   select @T2 = @T4
   if @T2 < 0 select @T2 = 0

   -- prorate tax amount for the pay period
   select @calcamt = round(@T2 / @ppds,2)


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_NUT102] TO [public]
GO
