SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_FWT11]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE PROC [dbo].[bspPR_CA_FWT11]
   /********************************************************
   * CREATED BY: 	EN 2/27/08
   * MODIFIED BY:	EN 3/7/08 - #127081 in declare statements change bState to varchar(4)
   *				EN 5/18/09 #133697 tax update effective 1/1/09
   *				EN 5/19/09 #133697 tax update effective 4/1/09
   *				EN 12/17/2010 #137138 tax update effective 1/1/2010
   *				EN 08/23/2010 #140613  due to adjustment made in bspPRProcessFedCA to correct CPP/EI credits, @PP and @EI
   *					are now passed in as annualized and no longer need to by multipled by number of pay periods
   *				EN 12/20/2010 #142337 tax update effective 1/1/2011 ... also moved code from bspPRProcessFedCA to determine default total claim (@TC) amount
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
   *	@nonresalienyn	YN flag to indicate whether or not employee is a resident of Canada
   *
   * OUTPUT PARAMETERS:
   *	@A			annualized taxable wages
   *	@calcamt	tax amount for the pay period
   *	@msg		error message IF failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   	(@ppds tinyint = 0, 
	@calcbasis bDollar = 0, 
	@HD bDollar = 0, 
	@F1 bDollar = 0, 
	@TC bDollar = 0, 
	@province varchar(4) = null, 
	@PP bDollar = 0, 
	@maxCPP bDollar, 
	@EI bDollar = 0, 
	@maxEI bDollar,
	@IE bDollar = 0, 
	@K3 bDollar = 0, 
	@capstock bDollar = 0, 
	@nonresalienyn bYN = 'N',
	@A bDollar = 0 output, 
	@calcamt bDollar = 0 output, 
	@msg varchar(255) = null output)

	AS
	SET NOCOUNT ON

	DECLARE @rcode int, @procname varchar(30)

	SELECT @rcode = 0, @procname = 'bspPR_CA_FWT11'

	-- validate pay periods
	IF @ppds = 0
   	BEGIN
   		SELECT @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   		RETURN @rcode
   	END
   
	DECLARE @Rate bRate, --tax rate
			@K bDollar, --tax constant 
			@K1 bDollar, --federal non-refundable personal tax credit
			@K2 bDollar, --pension plan (CPP/QPP) and Employment Insurance (EI) premium tax credits for the year
			@K4 bDollar, --Canada Employment Credit
			@maxwages bDollar, --maximum annualized taxable wages for computing K4
			@TCrate bRate, --tax credit rate (used to compute K2)
			--@maxQPP bDollar, --maximum pension contribution for Quebec
			--@maxQCEI bDollar, --maximum EI contribution for Quebec
			--@maxIE bDollar, --maximum insurable earnings for Quebec premium tax credits computation
			--@IErate bDollar, --insurable earnings rate for Quebec premium tax credits computation
			@T3 bDollar, --basic annual federal tax
			@LCF bDollar, --labor sponsored funds tax credit
			@T1 bDollar --annual federal tax payable
			--@QErate bDollar, --rate of basic annual federal tax to exclude from federal tax payable amount for Quebec employees

	SELECT @K = 0, @K1 = 0, @K2 = 0, @K4 = 0, @T3 = 0, @LCF = 0, @T1 = 0, @A = 0, @calcamt = 0

	-- constants
	SELECT @TCrate = .15 -- used to compute K1, K2, K4, and LCF
	--SELECT @maxQPP = 2163.15, @maxQCEI = 587.52 -- used to compute K2 for Quebec
	--SELECT @IErate = .00506
	--SELECT @QErate = .15

	-- compute annualized taxable wages
	SELECT @A = (@ppds * @calcbasis) - @HD - @F1

	-- establish tax rate and constant
	IF @A BETWEEN 0 AND 41544
	BEGIN
		SELECT @Rate = .15, @K = 0
	END
	ELSE IF @A BETWEEN 41545 AND 83088
	BEGIN
		SELECT @Rate = .22, @K = 2908
	END
	ELSE IF @A BETWEEN 83089 AND 128800
	BEGIN
		SELECT @Rate = .26, @K = 6232
	END
	ELSE IF @A >= 128801
	BEGIN
		SELECT @Rate = .29, @K = 10096
	END

	-- #142337 if form TD1 was not filed (ie. no filing status entered) use default total claim
	IF @TC IS NULL SELECT @TC = 10527
	IF @nonresalienyn = 'Y' SELECT @TC = 0

	-- compute federal non-refundable personal tax credit
	SELECT @K1 = @TCrate * @TC

	-- compute pension plan (CPP/QPP) and Employment Insurance (EI) premium tax credits for the year
	IF @province <> 'QC'
	BEGIN
		SELECT @K2 = ((@TCrate * (CASE WHEN @PP < @maxCPP THEN @PP ELSE @maxCPP END))) --CPP portion
		SELECT @K2 = @K2 + ((@TCrate * (CASE WHEN @EI < @maxEI THEN @EI ELSE @maxEI END))) -- EI portion
	END
--   IF @province = 'QC'
--	BEGIN
--	SELECT @K2 = ((@TCrate * (CASE WHEN @ppds*@PP < @maxQPP THEN @ppds*@PP ELSE @maxQPP END))) --CPP portion
--	SELECT @K2 = @K2 + ((@TCrate * (CASE WHEN @ppds*@EI < @maxQCEI THEN @ppds*@EI ELSE @maxQCEI END))) -- EI portion
--	SELECT @K2 = @K2 + ((@TCrate * (CASE WHEN @ppds*@IE*@IErate < @maxIE THEN @ppds*@IE*@IErate ELSE @maxIE END))) -- EI portion
--	END

	-- compute Canada Employment Credit
	SELECT @maxwages = 1065.00 -- used to compute K4 amount
	SELECT @K4 = (CASE WHEN @TCrate*@A<@TCrate*@maxwages THEN @TCrate*@A ELSE @TCrate*@maxwages END)

	-- compute basic Annual Federal Tax
	SELECT @T3 = (@Rate * @A) - @K - @K1 - @K2 - @K3 - @K4

	-- compute labour-sponsored funds federal tax credit for the year
	SELECT @LCF = CASE WHEN @TCrate * @capstock < 750 THEN @TCrate * @capstock ELSE 750 END

	-- compute annual federal tax payable
	IF @province <> 'QC' SELECT @T1 = @T3 - @LCF
	--IF @province = 'QC' SELECT @T1 = ((@T3 - @LCF) - (@QErate * @T3))
	IF @T1 < 0 SELECT @T1 = 0

	-- prorate tax amount for the pay period
	SELECT @calcamt = @T1 / @ppds


	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_FWT11] TO [public]
GO
