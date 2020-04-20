SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_NST102]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_CA_NST102]
   /********************************************************
   * CREATED BY: 	EN 5/13/08
   * MODIFIED BY:	EN 5/18/09 #133697 tax update effective 1/1/09 and set a default for total claim (@TCP)
   *				EN 12/18/2010 #137138 tax update effective 1/1/2010
   *				EN 6/07/2010 #140071 tax update effective 7/1/2010
   *
   * USAGE:
   * 	Calculates Nova Scotia Provincial Income Tax
   *
   * INPUT PARAMETERS:
   *	@ppds	# of pay pds per year
   *	@A		annualized taxable wages
   *	@TCP	provincial total claim amount reported on Form TD1NS
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
	(@ppds tinyint = 0, @A bDollar = 0, @TCP bDollar = 0, 
	@PP bDollar = 0, @maxCPP bDollar = 0, @EI bDollar = 0, @maxEI bDollar = 0, @K3P bDollar = 0, 
	@capstock bDollar = 0, @calcamt bDollar = 0 output,
	@msg varchar(255) = null output)
   as
   set nocount on
  
   declare @rcode int, @procname varchar(30)
   
   select @rcode = 0, @procname = 'bspPR_CA_NST102'
   
   -- validate pay periods
   if @ppds = 0
   	begin
   	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end

   declare @Rate bRate, --tax rate
			@KP bDollar, --provincial tax constant 
			@K1P bDollar, --provincial non-refundable personal tax credit
			@K2P bDollar, --provincial pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
			@TCrate bRate, --tax credit rate (used to compute K2)
			@T4 bDollar, --basic annual provincial tax
			@V1 bDollar, --provincial surtax
			@LCP bDollar, --labor sponsored funds tax credit
			@T2 bDollar --annual provincial tax payable
   
   select @KP = 0, @K1P = 0, @K2P = 0, @T4 = 0, @V1 = 0, @LCP = 0, @T2 = 0, @calcamt = 0, @TCrate = .0879

   -- if form TD1NT was not filed (ie. no filing status entered) use default total claim
   if @TCP is null select @TCP = 8231

   -- establish tax rate and constant
   IF @A BETWEEN 0 AND 29590 
		SELECT @Rate = .0879, @KP = 0
   ELSE IF @A BETWEEN 29591 AND 59180 
		SELECT @Rate = .1495, @KP = 1823
   ELSE IF @A BETWEEN 59181 AND 93000 
		SELECT @Rate = .1667, @KP = 2841
   ELSE IF @A BETWEEN 93001 AND 150000 
		SELECT @Rate = .1750, @KP = 3613
   ELSE IF @A > 150000 
		SELECT @Rate = .2450, @KP = 14113

   -- compute provincial non-refundable personal tax credit
   select @K1P = round(@TCrate * @TCP,2)

   -- compute pension plan (CPP) and Employment Insurance (EI) premium tax credits for the year
	select @K2P = round(@TCrate * (case when @ppds*@PP < @maxCPP then @ppds*@PP else @maxCPP end),2) --CPP portion
	select @K2P = @K2P + round(@TCrate * (case when @ppds*@EI < @maxEI then @ppds*@EI else @maxEI end),2) -- EI portion

   -- compute basic Annual Federal Tax
   select @T4 = (@Rate * @A) - @KP - @K1P - @K2P - @K3P 

   -- compute provincial surtax
   select @V1 = 0
   --if @T4 > 10000 select @V1 = .1 * (@T4 - 10000) <-- #140071  V1 not computed as of 7/1/2010

   -- compute labour-sponsored funds federal tax credit for the year
   select @LCP = case when .2 * @capstock < 2000 then .2 * @capstock else 2000 end
 
   -- compute annual provincial tax payable
   select @T2 = @T4 + @V1 - @LCP
   if @T2 < 0 select @T2 = 0

   -- prorate tax amount for the pay period
   select @calcamt = round(@T2 / @ppds,2)


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_NST102] TO [public]
GO
