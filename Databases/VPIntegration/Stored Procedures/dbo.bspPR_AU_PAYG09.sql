SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_AU_PAYG09]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_AU_PAYG09]
   /********************************************************
   * CREATED BY: 	EN 6/04/08
   * MODIFIED BY:	EN 9/17/08  for payments made on or after 1 July 2008
   *				EN 9/8/09  #134853  update effective as of 1 July 2009
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
			@mlft = 0, @ac = 0, @sopm = 0, @sopd = 0, @wlaf = 0, @procname = 'bspPR_AU_PAYG09'

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
		select @x = floor((@subjamt * 3) / 13) + .99
		end

	-- determine a & b coefficients and medicare levy parameters based on scale (@addlexempts)
	if @scale = 1
		begin
		select @a = .1650, @b = .1650
		if @x >= 259 select @a = .2346, @b = 18.0692
		if @x >= 355 select @a = .3350, @b = 53.7885
		if @x >= 908 select @a = .3150, @b = 35.6154
		if @x >= 1221 select @a = .3950, @b = 133.3077
		if @x >= 3144 select @a = .4650, @b = 353.4038
		end
	if @scale = 2
		begin
		select @a = 0, @b = 0
		if @x >= 196 select @a = .1514, @b = 29.7115
		if @x >= 339 select @a = .2523, @b = 63.9308
		if @x >= 398 select @a = .1665, @b = 29.7117
		if @x >= 571 select @a = .1867, @b = 41.2502
		if @x >= 666 select @a = .3350, @b = 140.1502
		if @x >= 1219 select @a = .3150, @b = 115.7540
		if @x >= 1532 select @a = .3950, @b = 238.3387
		if @x >= 3455 select @a = .4650, @b = 480.2156
		--set medicare levy parameters
		select @wet = 339, @west = 398, @mlft = 29750, @ac = 2757, @sopm = .1000, @sopd = .0850, @wlaf = 339.0300, @ml = .0150
		end
	if @scale = 3
		begin
		select @a = .2900, @b = .2900
		if @x >= 673 select @a = .3000, @b = 6.7308
		if @x >= 1538 select @a = .3800, @b = 129.8077
		if @x >= 3461 select @a = .4500, @b = 372.1154
		end
	if @scale = 4
		begin
		if @nonresalienyn = 'N' select @a = .4650
		if @nonresalienyn = 'Y' select @a = .4500
		end
	if @scale = 5
		begin
		select @a = 0, @b = 0
		if @x >= 196 select @a = .1514, @b = 29.7115
		if @x >= 571 select @a = .1716, @b = 41.2500
		if @x >= 666 select @a = .3200, @b = 140.2423
		if @x >= 1219 select @a = .3000, @b = 115.8462
		if @x >= 1532 select @a = .3800, @b = 238.4308
		if @x >= 3455 select @a = .4500, @b = 480.3077
		end
	if @scale = 6
		begin
		select @a = 0, @b = 0
		if @x >= 196 select @a = .1514, @b = 29.7115
		if @x >= 572 select @a = .2220, @b = 70.1202
		if @x >= 666 select @a = .3700, @b = 168.8048
		if @x >= 673 select @a = .3275, @b = 140.1966
		if @x >= 1219 select @a = .3075, @b = 115.8004
		if @x >= 1532 select @a = .3875, @b = 238.3850
		if @x >= 3455 select @a = .4575, @b = 480.2620
		--set medicare levy parameters
		select @wet = 572, @west = 673, @mlft = 29750, @ac = 2757, @sopm = .0500, @sopd = .0425, @wlaf = 572.1200, @ml = .0075
		end
	if @scale = 7
		begin
		select @a = 0, @b = 0
		if @x >= 198 select @a = .1500, @b = 29.7115
		if @x >= 342 select @a = .2500, @b = 63.9308
		if @x >= 402 select @a = .1650, @b = 29.7117
		if @x >= 576 select @a = .1850, @b = 41.2502
		if @x >= 673 select @a = .3350, @b = 142.2117
		if @x >= 1225 select @a = .3150, @b = 117.6925
		if @x >= 1538 select @a = .3950, @b = 240.7694
		if @x >= 3461 select @a = .4650, @b = 483.0771
		--set medicare levy parameters
		select @wet = 342, @west = 402, @mlft = 30025, @ac = 2757, @sopm = .1000, @sopd = .0850, @wlaf = 342.1900, @ml = .0150
		end

	-- compute y (weekly withholding amount)
	select @y = round((@a * @x) - @b, 0)

	-- to get withholding amount, convert y to the pay frequency equivalent if pay freq is not weekly
	if @ppds = 52 select @whamt = @y
	if @ppds = 26 select @whamt = @y * 2
	if @ppds = 12 select @whamt = round((@y * 13) / 3, 0)

	-- if scale 4 is used (no tax file number provided) aplly straight tax rate to earnings
	if @scale = 4 select @whamt = round(@subjamt * @a, 0)

	select @amt = @whamt

	-- compute Medicare Levy Adjustment if applicable (ie. employee has applied via Medicare levy variation declaration form (NAT 0929))
	--  @status = "M" if employee answered 'Yes' to question 9 on the NAT 0929
	--  @addlexempts > 0 (# of children) if employee answered 'Yes' to question 12 on NAT 0929
	--  where scale is 4 (no tax file number provided), Medicare levy is applicable for residents only
	if @scale in (2,6,7) and (@status = 'M' or @addlexempts > 0) and not (@scale = 4 and @nonresalienyn = 'Y')
	 and not (@status <> 'M' and @addlexempts > 0)
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
			
	-- compute Tax Offset (FTB) if employee has elected on Withholding declaration
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
GRANT EXECUTE ON  [dbo].[bspPR_AU_PAYG09] TO [public]
GO
