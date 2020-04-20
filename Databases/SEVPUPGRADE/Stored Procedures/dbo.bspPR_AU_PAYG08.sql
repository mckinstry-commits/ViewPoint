SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_AU_PAYG08]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_AU_PAYG08]
   /********************************************************
   * CREATED BY: 	EN 6/04/08
   * MODIFIED BY:
   *
   * USAGE:
   * 	Calculates Australia PAYG (Pay As You Go) national income tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@scale		used to determine coefficients and tax computation methods
   *	@status		"M" if employee submitted a Medicare levy variation declaration and claimed a spouse, otherwise "S"
   *	@addlexempts	# of children if employee submitted a Medicare levy variation and claimed dependent children
   *	@nonresalienyn	"Y" if employee is a nonresident alien, otherwise "N"
   *	@ftb_offset	total FTB amount and tax offset claimed by employee on the Withholding declaration
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   	(@subjamt bDollar = 0, @ppds tinyint = 0, @scale tinyint = 0, @status char(1) = 'S', @addlexempts tinyint = 0, 
	@nonresalienyn bYN = 'N', @ftb_offset bDollar = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
  
   declare @rcode int, 
			@x bDollar, --adjusted earnings 
			@a bUnitCost, --rate coefficient for computing weekly withholding amount
			@b bUnitCost, --deduction coefficient for computing weekly withholding amount
			@y bDollar, --weekly withholding amount
			@whamt bDollar, --withholding amount for the pay period
			@FTB bDollar, --Family Tax Benefit
			@wet bDollar, --weekly earnings threshold for medicare levy
			@west bDollar, --weekly earnings shade-in threshold for medicare levy
			@mlft bDollar, --medicare levy family threshold
			@ac bDollar, --additional child allowance for medicare levy
			@sopm bUnitCost, --shading out point multiplier for medicare levy
			@sopd bUnitCost, --shading out point divisor for medicare levy
			@wlaf bUnitCost, --weekly levy adjustment factor
			@ml bUnitCost, --medicare levy
			@WFT bDollar, --Weekly Family Threshold
			@SOP bDollar, --Shading Out Point
			@WLA bDollar, --Weekly Levy Adjustment
			@procname varchar(30)
   
	select @rcode = 0, @x = 0, @a = 0, @b = 0, @y = 0, @whamt = 0, @FTB = 0, @wet = 0, @west = 0,
			@mlft = 0, @ac = 0, @sopm = 0, @sopd = 0, @wlaf = 0, @procname = 'bspPR_AU_PAYG08'

	-- validate pay periods
	if @ppds = 0
		begin
		select @msg = 'Missing # of Pay Periods per year!', @rcode = 1
		goto bspexit
		end
	if @ppds not in (52,26,12)
		begin
		select @msg = 'Pay Frequency must be Weekly, Biweekly (Fortnightly), or Monthly.', @rcode = 1
		goto bspexit
		end

	-- compute x
	if @ppds = 52 select @x = floor(@subjamt) + .99 --weekly
	if @ppds = 26 select @x = floor(@subjamt/2) + .99 --fortnightly
	if @ppds = 12 --monthly
		begin
		if @subjamt - floor(@subjamt) = .33 select @x = @subjamt + .01
		select @x = floor((@x * 3) / 13) + .99
		end

	-- determine a & b coefficients and medicare levy parameters based on scale (@addlexempts)
	if @scale = 1
		begin
		select @a = .1650, @b = .1650
		if @x >= 259 select @a = .3150, @b = 39.1765
		if @x >= 1125 select @a = .4150, @b = 151.6765
		if @x >= 2567 select @a = .4650, @b = 280.0419
		end
	if @scale = 2
		begin
		select @a = 0, @b = 0
		if @x >= 110 select @a = .1516, @b = 16.7314
		if @x >= 318 select @a = .2526, @b = 48.9018
		if @x >= 374 select @a = .1667, @b = 16.7125
		if @x >= 570 select @a = .3150, @b = 101.3575
		if @x >= 1436 select @a = .4150, @b = 244.9729
		if @x >= 2878 select @a = .4650, @b = 388.8960
		--set medicare levy parameters
		select @wet = 318, @west = 374, @mlft = 27927, @ac = 2594, @sopm = .1000, @sopd = .0850, @wlaf = 318.5200, @ml = .0150
		end
	if @scale = 3
		begin
		select @a = .2900, @b = .2900
		if @x >= 576 select @a = .3000, @b = 6.0592
		if @x >= 1442 select @a = .4000, @b = 150.2900
		if @x >= 2884 select @a = .4500, @b = 294.5208
		end
	if @scale = 4
		begin
		if @nonresalienyn = 'N' select @a = .4650
		if @nonresalienyn = 'Y' select @a = .4500
		end
	if @scale = 5
		begin
		select @a = 0, @b = 0
		if @x >= 110 select @a = .1516, @b = 16.7314
		if @x >= 570 select @a = .3000, @b = 101.4335
		if @x >= 1436 select @a = .4000, @b = 245.0489
		if @x >= 2878 select @a = .4500, @b = 388.9720
		end
	if @scale = 6
		begin
		select @a = 0, @b = 0
		if @x >= 110 select @a = .1516, @b = 16.7314
		if @x >= 537 select @a = .2021, @b = 43.8742
		if @x >= 570 select @a = .3500, @b = 128.2909
		if @x >= 631 select @a = .3075, @b = 101.4383
		if @x >= 1436 select @a = .4075, @b = 245.0537
		if @x >= 2878 select @a = .4575, @b = 388.9768
		--set medicare levy parameters
		select @wet = 537, @west = 631, @mlft = 27927, @ac = 2594, @sopm = .0500, @sopd = .0425, @wlaf = 537.0600, @ml = .0075
		end
	if @scale = 7
		begin
		select @a = 0, @b = 0
		if @x >= 111 select @a = .1500, @b = 16.7308
		if @x >= 321 select @a = .2500, @b = 48.9231
		if @x >= 378 select @a = .1650, @b = 16.7310
		if @x >= 576 select @a = .3150, @b = 103.2694
		if @x >= 1442 select @a = .4150, @b = 247.5002
		if @x >= 2884 select @a = .4650, @b = 391.7310
		--set medicare levy parameters
		select @wet = 321, @west = 378, @mlft = 28247, @ac = 2594, @sopm = .1000, @sopd = .0850, @wlaf = 321.9200, @ml = .0150
		end

	-- compute y (weekly withholding amount)
	select @y = round((@a * @x) - @b, 0)

	-- to get withholding amount, convert y to the pay frequency equivalent if pay freq is not weekly
	if @ppds = 52 select @whamt = @y
	if @ppds = 26 select @whamt = @y * 2
	if @ppds = 12 select @whamt = round((@y * 13) / 3,0)

	-- if scale 4 is used (no tax file number provided) aplly straight tax rate to earnings
	if @scale = 4 select @whamt = round(@subjamt * @a, 0)

	select @amt = @whamt

	-- compute Medicare Levy Adjustment if applicable (ie. employee has applied via Medicare levy variation declaration form (NAT 0929))
	--  @status = "M" if employee answered 'Yes' to question 9 on the NAT 0929
	--  @addlexempts > 0 (# of children) if employee answered 'Yes' to question 12 on NAT 0929
	--  where scale is 4 (no tax file number provided), Medicare levy is applicable for residents only
	if @scale in (2,6,7) and (@status = 'M' or @addlexempts > 0) and not (@scale = 4 and @nonresalienyn = 'Y')
		begin
		select @WFT = 0, @SOP = 0, @WLA = 0
		-- include Weekly Family Threshold (WFT) and Shading Out Point (SOP) in WLA computation if earnings exceed the shade-in threshold
		if @x >= @west
			begin
			if @status = 'M' and @addlexempts = 0 select @WFT = round(@mlft / 52, 2) --'Yes' to question 9, 'No' to question 12
			if @addlexempts > 0 select @WFT = round(((@addlexempts * @ac) + @mlft) / 52, 2) --'Yes' to question 12

			select @SOP = floor((@WFT * @sopm) / @sopd)

			if @x < @WFT select @WLA = @x * @ml
			if @x >= @WFT and @x < @SOP select @WLA = (@WFT * @ml) - ((@x - @WFT) * @sopd)
			end
		-- otherwise just compute WLA
		if @x < @west select @WLA = (@x - @wlaf) * @sopm

		select @WLA = round(@WLA, 0) --round to the nearest dollar

		-- adjust WLA for pay frequency if not weekly
		if @ppds = 26 select @WLA = @WLA * 2
		if @ppds = 12 select @WLA = round((@WLA * 13) / 3, 0)

		-- if weekly levy amount was computed, use it ... otherwise continue and attempt to apply FTB
		if @WLA <> 0
			begin
			-- reduce withholding amount by WLA to get net withholding amount
			select @amt = @amt - @WLA
			--select @amt = @whamt - @WLA
			--goto bspexit
			end
		end
			
	-- compute Family Tax Benefit (FTB) if employee has elected on Withholding declaration
	--  to use FTB or special tax offset to reduce the witholding amount
	if @ftb_offset > 0 and @scale in (2,5,6,7)
		begin
		if @ppds = 52 select @FTB = .019 * @ftb_offset
		if @ppds = 26 select @FTB = .038 * @ftb_offset
		if @ppds = 12 select @FTB = .083 * @ftb_offset
		select @FTB = round(@FTB, 0) --round to nearest dollar

		-- reduce withholding amount by FTB to get net withholding amount
		select @amt = @amt - @FTB
		--select @amt = @whamt - @FTB
		--goto bspexit
		end

	-- if neither WLA or FTB was applicable, use straight withholding amount
	--select @amt = @whamt
	--goto bspexit


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_PAYG08] TO [public]
GO
