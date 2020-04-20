SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_FWT08]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_CA_FWT08]
   /********************************************************
   * CREATED BY: 	EN 2/27/08
   * MODIFIED BY:  EN 3/7/08 - #127081 in declare statements change bState to varchar(4)
   *
   * USAGE:
   * 	Calculates Canada Federal Income Tax
   *
   * INPUT PARAMETERS:
   *	@ppds	# of pay pds per year
   *	@calcbasis	Income for the pay period
   *	@HD		annual deduction for living in a prescribed zone
   *	@F1		annual deductions such as child care expenses and support
   *	@TC		total claim amount reported on Form TD1
   *	@province	resident province
   *	@PP		Canada Pension Plan or Quebec Pension Plan contribution for the pay period
   *	@maxCPP	maximum pension contribution
   *	@EI		Employment Insurance premium for the pay period
   *	@maxEI	maximum EI contribution
   *	@IE		insurable earnings for the pay period (used for computing Quebec QPP and EI fed tax credits)
   *	@K3		other federal tax credits such as medical expenses and charitable donations
   *	@capstock	YTD deduction for acquisition of approved shares of the capital stock of a prescribed labour-sponsored venture capital corporation
   *
   * OUTPUT PARAMETERS:
   *	@A			annualized taxable wages
   *	@calcamt	tax amount for the pay period
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   	(@ppds tinyint = 0, @calcbasis bDollar = 0, @HD bDollar = 0, @F1 bDollar = 0, 
	@TC bDollar = 0, @province varchar(4) = null, @PP bDollar = 0, @maxCPP bDollar, @EI bDollar = 0, @maxEI bDollar,
	@IE bDollar = 0, @K3 bDollar = 0, @capstock bDollar = 0, @A bDollar = 0 output, 
	@calcamt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on

   declare @rcode int, 
			@rate bRate, --tax rate
			@K bDollar, --tax constant 
			@K1 bDollar, --federal non-refundable personal tax credit
			@K2 bDollar, --pension plan (CPP/QPP) and Employment Insurance (EI) premium tax credits for the year
			@K4 bDollar, --Canada Employment Credit
			@maxwages bDollar, --maximum annualized taxable wages for computing K4
			@TCrate bRate, --tax credit rate (used to compute K2)
			--@maxQPP bDollar, --maximum pension contribution for Quebec
			--@maxQCEI bDollar, --maximum EI contribution for Quebec
			@maxIE bDollar, --maximum insurable earnings for Quebec premium tax credits computation
			@IErate bDollar, --insurable earnings rate for Quebec premium tax credits computation
			@T3 bDollar, --basic annual federal tax
			@LCF bDollar, --labor sponsored funds tax credit
			@T1 bDollar, --annual federal tax payable
			--@QErate bDollar, --rate of basic annual federal tax to exclude from federal tax payable amount for Quebec employees
			@procname varchar(30)
   
   select @rcode = 0, @rate = 0, @K = 0, @K1 = 0, @K2 = 0, @K4 = 0, @T3 = 0, @LCF = 0, @T1 = 0
   select @A = 0, @calcamt = 0, @procname = 'bspPR_CA_FWT08'
   
   -- constants
   select @maxwages = 1019.00, @TCrate = .15, --@maxQPP = 2049.30, @maxQCEI = 571.29, 
		@IErate = .0045 --, @QErate = .165

   -- validate pay periods
   if @ppds = 0
   	begin
   	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   -- compute annualized taxable wages
   select @A = (@ppds * @calcbasis) - @HD - @F1

   -- establish tax rate and constant
   select @rate = .29, @K = 9378
   if @A <= 123184 select @rate = .26, @K = 5683
   if @A <= 75769 select @rate = .22, @K = 2652
   if @A <= 37885 select @rate = .15, @K = 0

   -- compute federal non-refundable personal tax credit
   select @K1 = @TCrate * @TC

   -- determine federal non-refundable personal tax credit based on claim code
   --select @K1 = 0
   --if @regexempts = 1 select @K1 = 1440.00
   --if @regexempts = 2 select @K1 = 1584.30
   --if @regexempts = 3 select @K1 = 1872.90
   --if @regexempts = 4 select @K1 = 2161.50
   --if @regexempts = 5 select @K1 = 2450.10
   --if @regexempts = 6 select @K1 = 2738.70
   --if @regexempts = 7 select @K1 = 3027.30
   --if @regexempts = 8 select @K1 = 3315.90
   --if @regexempts = 9 select @K1 = 3604.50
   --if @regexempts = 10 select @K1 = 3893.10

   -- compute pension plan (CPP/QPP) and Employment Insurance (EI) premium tax credits for the year
   if @province <> 'QC'
	begin
	select @K2 = ((@TCrate * (case when @ppds*@PP < @maxCPP then @ppds*@PP else @maxCPP end))) --CPP portion
	select @K2 = @K2 + ((@TCrate * (case when @ppds*@EI < @maxEI then @ppds*@EI else @maxEI end))) -- EI portion
	end
--   if @province = 'QC'
--	begin
--	select @K2 = ((@TCrate * (case when @ppds*@PP < @maxQPP then @ppds*@PP else @maxQPP end))) --CPP portion
--	select @K2 = @K2 + ((@TCrate * (case when @ppds*@EI < @maxQCEI then @ppds*@EI else @maxQCEI end))) -- EI portion
--	select @K2 = @K2 + ((@TCrate * (case when @ppds*@IE*@IErate < @maxIE then @ppds*@IE*@IErate else @maxIE end))) -- EI portion
--	end

   -- compute Canada Employment Credit
   select @K4 = (case when @TCrate*@A<@TCrate*@maxwages then @TCrate*@A else @TCrate*@maxwages end)

   -- compute basic Annual Federal Tax
   select @T3 = (@rate * @A) - @K - @K1 - @K2 - @K3 - @K4

   -- compute labour-sponsored funds federal tax credit for the year
   select @LCF = case when @TCrate * @capstock < 750 then @TCrate * @capstock else 750 end
 
   -- compute annual federal tax payable
   if @province <> 'QC' select @T1 = @T3 - @LCF
   --if @province = 'QC' select @T1 = ((@T3 - @LCF) - (@QErate * @T3))
   if @T1 < 0 select @T1 = 0

   -- prorate tax amount for the pay period
   select @calcamt = @T1 / @ppds


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_FWT08] TO [public]
GO
