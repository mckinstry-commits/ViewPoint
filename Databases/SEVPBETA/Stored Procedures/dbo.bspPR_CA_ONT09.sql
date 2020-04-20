SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_ONT09]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_CA_ONT09]
   /********************************************************
   * CREATED BY: 	EN 3/26/08
   * MODIFIED BY:	EN 10/16/08  Update for changes effective 7/1/08
   *				EN 5/18/09 #133697 tax update effective 1/1/09 and set a default for total claim (@TCP)
   *
   * USAGE:
   * 	Calculates Ontario Provincial Income Tax
   *
   * INPUT PARAMETERS:
   *	@ppds	# of pay pds per year
   *	@A		annualized taxable wages
   *	@TCP	provincial total claim amount reported on Form TD1ON
   *	@addexempts	# of dependants under age 18 for which employee has made a written request + dependants who are disabled as indicated on Form TD1ON
   *	@PP		Canada Pension Plan contribution for the pay period
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
   **********************************************************/
	(@ppds tinyint = 0, @A bDollar = 0, @TCP bDollar = 0, @addexempts tinyint = 0, 
	@PP bDollar = 0, @maxCPP bDollar = 0, @EI bDollar = 0, @maxEI bDollar = 0, @K3P bDollar = 0, 
	@capstock bDollar = 0, @calcamt bDollar = 0 output,
	@msg varchar(255) = null output)
   as
   set nocount on
  
   declare @rcode int, @procname varchar(30)
   
   select @rcode = 0, @procname = 'bspPR_CA_ONT09'

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
			@V1 bDollar, --provincial surtax
			@V2 bDollar, --additional provincial tax (applies to Ontario Health Premium only)
			@S bDollar, --provincial tax reduction
			@Y bDollar, --additional reduction for certain dependents
			@LCP bDollar, --labor sponsored funds tax credit
			@T2 bDollar --annual provincial tax payable
   
   select @KP = 0, @K1P = 0, @K2P = 0, @T4 = 0, @V1 = 0, @S = 0, @Y = 0, @LCP = 0, @T2 = 0, @calcamt = 0, @TCrate = .0605

   -- if form TD1ON was not filed (ie. no filing status entered) use default total claim
   if @TCP is null select @TCP = 8881

   -- establish tax rate and constant
   select @rate = .1116, @KP = 2624
   if @A <= 73698 select @rate = .0915, @KP = 1142
   if @A <= 36848 select @rate = .0605, @KP = 0

   -- compute provincial non-refundable personal tax credit
   select @K1P = round(@TCrate * @TCP,2)

   -- compute pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
	select @K2P = round(@TCrate * (case when @ppds*@PP < @maxCPP then @ppds*@PP else @maxCPP end),2) --CPP portion
	select @K2P = @K2P + round(@TCrate * (case when @ppds*@EI < @maxEI then @ppds*@EI else @maxEI end),2) -- EI portion

   -- compute basic Annual Federal Tax
   select @T4 = (@rate * @A) - @KP - @K1P - @K2P - @K3P 

   -- compute provincial surtax
   select @V1 = 0
   if @T4 > 4257 select @V1 = .2 * (@T4 - 4257)
   if @T4 > 5370 select @V1 = @V1 + .36 * (@T4 - 5370)

   -- compute additional tax (applies to Ontario Health Premium)
   select @V2 = 0
   if @A > 20000 and @A <= 36000 select @V2 = case when .02*(@A-20000)<300 then .02*(@A-20000) else 300 end
   if @A > 36000 and @A <= 48000 select @V2 = case when 300+(.06*(@A-36000))<450 then 300+(.06*(@A-36000)) else 450 end
   if @A > 48000 and @A <= 72000 select @V2 = case when 450+(.25*(@A-48000))<600 then 450+(.25*(@A-48000)) else 600 end
   if @A > 72000 and @A <= 200000 select @V2 = case when 600+(.25*(@A-72000))<750 then 600+(.25*(@A-72000)) else 750 end
   if @A > 200000 select @V2 = case when 750+(.25*(@A-200000))<900 then 750+(.25*(@A-200000)) else 900 end

   -- compute provincial tax reduction
   select @Y = (379 * @addexempts)
   select @S = case when @T4+@V1 < (2*(205+@Y))-(@T4+@V1) then @T4+@V1 else (2*(205+@Y))-(@T4+@V1) end
   if @S < 0 select @S = 0

   -- compute labour-sponsored funds federal tax credit for the year
   select @LCP = case when .15 * @capstock < 1125 then .15 * @capstock else 1125 end
 
   -- compute annual provincial tax payable
   select @T2 = @T4 + @V1 + @V2 - @S - @LCP
   if @T2 < 0 select @T2 = 0

   -- prorate tax amount for the pay period
   select @calcamt = round(@T2 / @ppds,2)


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_ONT09] TO [public]
GO
