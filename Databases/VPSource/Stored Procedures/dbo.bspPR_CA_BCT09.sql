SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_BCT09]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_CA_BCT09]
   /********************************************************
   * CREATED BY: 	EN 5/15/08
   * MODIFIED BY:	EN 5/15/09 #133697 tax update effective 1/1/09 and set a default for total claim (@TCP)
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
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
	(@ppds tinyint = 0, @A bDollar = 0, @TCP bDollar = 0, @PP bDollar = 0, 
	@maxCPP bDollar = 0, @EI bDollar = 0, @maxEI bDollar = 0, @K3P bDollar = 0, @HD bDollar = 0, 
	@capstock bDollar = 0, @calcamt bDollar = 0 output,
	@msg varchar(255) = null output)
   as
   set nocount on
 
   declare @rcode int, @procname varchar(30)
   
   select @rcode = 0, @procname = 'bspPR_CA_BCT09'
   
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
			@S bDollar, --provincial tax reduction
			@A1 bDollar, --annual net income
			@LCP bDollar, --labor sponsored funds tax credit
			@T2 bDollar --annual provincial tax payable
   
   select @KP = 0, @K1P = 0, @K2P = 0, @T4 = 0, @S = 0, @A1 = 0, @LCP = 0, @T2 = 0, @calcamt = 0, @TCrate = .0506

   -- if form TD1BC was not filed (ie. no filing status entered) use default total claim
   if @TCP is null select @TCP = 9373

   -- establish tax rate and constant
   select @rate = .1470, @KP = 6810
   if @A <= 99588 select @rate = .1229, @KP = 4411
   if @A <= 82014 select @rate = .1050, @KP = 2943
   if @A <= 71433 select @rate = .0781, @KP = 943
   if @A <= 35716 select @rate = .0506, @KP = 0

   -- compute provincial non-refundable personal tax credit
   select @K1P = round(@TCrate * @TCP,2)

   -- compute pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
	select @K2P = round(@TCrate * (case when @ppds*@PP < @maxCPP then @ppds*@PP else @maxCPP end),2) --CPP portion
	select @K2P = @K2P + round(@TCrate * (case when @ppds*@EI < @maxEI then @ppds*@EI else @maxEI end),2) -- EI portion

   -- compute basic Annual Federal Tax
   select @T4 = (@rate * @A) - @KP - @K1P - @K2P - @K3P 

   -- compute provincial tax reduction
   select @A1 = @A + @HD
   if @A1 <= 17285 select @S = case when @T4 < 389 then @T4 else 389 end
   if @A1 > 17285 and @A1 <= 29441.25 select @S = case when @T4 < 389-((@A1-17285)*.032) then @T4 else 389-((@A1-17285)*.032) end
   if @A1 > 29441.25 select @S = 0

   -- compute labour-sponsored funds federal tax credit for the year
   select @LCP = case when .15 * @capstock < 2000 then .15 * @capstock else 2000 end
 
   -- compute annual provincial tax payable
   select @T2 = @T4 + @S - @LCP
   if @T2 < 0 select @T2 = 0

   -- prorate tax amount for the pay period
   select @calcamt = round(@T2 / @ppds,2)


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_BCT09] TO [public]
GO