SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_AU_PAYG10]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  PROC [dbo].[bspPR_AU_PAYG10]
   /********************************************************
   * CREATED BY: 	EN 6/04/08
   * MODIFIED BY:	EN 9/17/08  for payments made on or after 1 July 2008
   *				EN 9/8/09  #134853  update effective as of 1 July 2009
   *				EN 2/2/2010 #137909 (version 092) add ability to compute HELP component
   *				EN 9/8/09  #134853  update effective as of 1 July 2009
   *
   * USAGE:
   * 	Calculates Australia PAYG (Pay As You Go) national income tax
   *
   *	In general, the tax computation is based on a formula (y = ax – b) laid out in the NAT 1004 document found
   *	on the ATO (Australian federal government) website.
   *	From this value the Medicare Levy Adjustment is subtracted if applicable (Scales 2, 21, 6, 61, 7 and 71 only).  
   *	Also the Tax Offset will be subtracted if applicable (Scales 2, 21, 5, 51, 6, 61, 7 and 71 only).
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@Scale		used to determine coefficients and tax computation methods
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
   	(@subjamt bDollar = 0, @ppds TINYINT = 0, @Scale TINYINT = 0, @status CHAR(1) = 'S', @addlexempts TINYINT = 0, 
	@nonresalienyn bYN = 'N', @ftb_offset bDollar = 0, @amt bDollar = 0 OUTPUT, @msg VARCHAR(255) = null OUTPUT)
   AS
   SET NOCOUNT ON
  
   DECLARE @rcode INT, 
			@x bDollar, --adjusted earnings 
			@a bUnitCost, --rate coefficient for computing weekly withholding amount
			@b bUnitCost, --deduction coefficient for computing weekly withholding amount
			@y bDollar, --weekly withholding amount
			@FTB bDollar, --Family Tax Benefit
			@WeekEarnThresh bDollar, --weekly earnings threshold for medicare levy
			@WeekEarnShadeIn bDollar, --weekly earnings shade-in threshold for medicare levy
			@MedLevyFamThresh bDollar, --medicare levy family threshold
			@AddlChild bDollar, --additional child allowance for medicare levy
			@ShadeOutMultiplier bUnitCost, --shading out point multiplier for medicare levy
			@ShadeOutDivisor bUnitCost, --shading out point divisor for medicare levy
			@WeekLevyAdjust bUnitCost, --weekly levy adjustment factor
			@MedicareLevy bUnitCost, --medicare levy
			@WFT bDollar, --Weekly Family Threshold
			@SOP bDollar, --Shading Out Point
			@WLA bDollar, --Weekly Levy Adjustment
			@procname VARCHAR(30)
   
	SELECT @rcode = 0, @x = 0, @a = 0, @b = 0, @y = 0, @FTB = 0, @WeekEarnThresh = 0, @WeekEarnShadeIn = 0,
			@MedLevyFamThresh = 0, @AddlChild = 0, @ShadeOutMultiplier = 0, @ShadeOutDivisor = 0, @WeekLevyAdjust = 0, @procname = 'bspPR_AU_PAYG10'

	-- validate pay periods
	IF @ppds = 0
	BEGIN
		SELECT @msg = 'Missing # of Pay Periods per year!', @rcode = 1
		GOTO bspexit
	END
	IF @ppds NOT IN (52,26,12)
	BEGIN
		SELECT @msg = 'Pay Frequency must be Weekly, Biweekly (Fortnightly), or Monthly.', @rcode = 1
		GOTO bspexit
	END

	-- validate scale
	IF @Scale NOT IN (1,2,3,4,5,6,7,11,21,31,51,61,71)
	BEGIN
		SELECT @msg = 'Valid scales are 1-7, 11, 21, 31, 51, 61, 71.', @rcode = 1
		GOTO bspexit
	END

	-- compute x
	IF @ppds = 52 SELECT @x = FLOOR(@subjamt) + .99 --weekly
	IF @ppds = 26 SELECT @x = FLOOR(@subjamt/2) + .99 --fortnightly
	IF @ppds = 12 
	BEGIN
		IF @subjamt - FLOOR(@subjamt) = .33 SELECT @x = @subjamt + .01 --monthly
		SELECT @x = FLOOR((@subjamt * 3) / 13) + .99
	END

	-- determine a & b coefficients based on scale (@addlexempts)
	IF @Scale = 1
	BEGIN
		IF @x BETWEEN 0 AND 258.99 SELECT @a = .1650, @b = .1650
		ELSE IF @x BETWEEN 259 AND 393.99 SELECT @a = .2204, @b = 14.3827
		ELSE IF @x BETWEEN 394 AND 979.99 SELECT @a = .3350, @b = 59.5615
		ELSE IF @x BETWEEN 980 AND 1220.99 SELECT @a = .3150, @b = 39.9462
		ELSE IF @x BETWEEN 1221 AND 3143.99 SELECT @a = .3850, @b = 125.4269
		ELSE SELECT @a = .4650, @b = 376.9654
	END
	ELSE IF @Scale = 11
	BEGIN
		IF @x BETWEEN 0 AND 258.99 SELECT @a = .1650, @b = .1650
		ELSE IF @x BETWEEN 259 AND 393.99 SELECT @a = .2204, @b = 14.3827
		ELSE IF @x BETWEEN 394 AND 545.99 SELECT @a = .3350, @b = 59.5615
		ELSE IF @x BETWEEN 546 AND 643.99 SELECT @a = .3750, @b = 59.5615
		ELSE IF @x BETWEEN 644 AND 742.99 SELECT @a = .3800, @b = 59.5615
		ELSE IF @x BETWEEN 743 AND 797.99 SELECT @a = .3850, @b = 59.5615
		ELSE IF @x BETWEEN 798 AND 881.99 SELECT @a = .3900, @b = 59.5615
		ELSE IF @x BETWEEN 882 AND 979.99 SELECT @a = .3950, @b = 59.5615
		ELSE IF @x BETWEEN 980 AND 981.99 SELECT @a = .3750, @b = 39.9462
		ELSE IF @x BETWEEN 982 AND 1049.99 SELECT @a = .3800, @b = 39.9462
		ELSE IF @x BETWEEN 1050 AND 1186.99 SELECT @a = .3850, @b = 39.9462
		ELSE IF @x BETWEEN 1187 AND 1220.99 SELECT @a = .3900, @b = 39.9462
		ELSE IF @x BETWEEN 1221 AND 1285.99 SELECT @a = .4600, @b = 125.4269
		ELSE IF @x BETWEEN 1286 AND 3143.99 SELECT @a = .4650, @b = 125.4269
		ELSE SELECT @a = .5450, @b = 376.9654
	END
	ELSE IF @Scale = 2
	BEGIN
		IF @x BETWEEN 0 AND 204.99 SELECT @a = 0, @b = 0
		ELSE IF @x BETWEEN 205 AND 351.99 SELECT @a = .1513, @b = 31.1538
		ELSE IF @x BETWEEN 352 AND 413.99 SELECT @a = .2522, @b = 66.7077
		ELSE IF @x BETWEEN 414 AND 570.99 SELECT @a = .1664, @b = 31.1548
		ELSE IF @x BETWEEN 571 AND 704.99 SELECT @a = .1866, @b = 42.6933
		ELSE IF @x BETWEEN 705 AND 1290.99 SELECT @a = .3350, @b = 147.3625
		ELSE IF @x BETWEEN 1291 AND 1531.99 SELECT @a = .3150, @b = 121.5240
		ELSE IF @x BETWEEN 1532 AND 3454.99 SELECT @a = .3850, @b = 228.7856
		ELSE SELECT @a = .4650, @b = 505.2163
	END
	ELSE IF @Scale = 21
	BEGIN
		IF @x BETWEEN 0 AND 204.99 SELECT @a = 0, @b = 0
		ELSE IF @x BETWEEN 205 AND 351.99 SELECT @a = .1513, @b = 31.1538
		ELSE IF @x BETWEEN 352 AND 413.99 SELECT @a = .2522, @b = 66.7077
		ELSE IF @x BETWEEN 414 AND 570.99 SELECT @a = .1664, @b = 31.1548
		ELSE IF @x BETWEEN 571 AND 704.99 SELECT @a = .1866, @b = 42.6933
		ELSE IF @x BETWEEN 705 AND 862.99 SELECT @a = .3350, @b = 147.3625
		ELSE IF @x BETWEEN 863 AND 961.99 SELECT @a = .3750, @b = 147.3625
		ELSE IF @x BETWEEN 962 AND 1059.99 SELECT @a = .3800, @b = 147.3625
		ELSE IF @x BETWEEN 1060 AND 1115.99 SELECT @a = .3850, @b = 147.3625
		ELSE IF @x BETWEEN 1116 AND 1198.99 SELECT @a = .3900, @b = 147.3625
		ELSE IF @x BETWEEN 1199 AND 1290.99 SELECT @a = .3950, @b = 147.3625
		ELSE IF @x BETWEEN 1291 AND 1298.99 SELECT @a = .3750, @b = 121.5240
		ELSE IF @x BETWEEN 1299 AND 1366.99 SELECT @a = .3800, @b = 121.5240
		ELSE IF @x BETWEEN 1367 AND 1504.99 SELECT @a = .3850, @b = 121.5240
		ELSE IF @x BETWEEN 1505 AND 1531.99 SELECT @a = .3900, @b = 121.5240
		ELSE IF @x BETWEEN 1532 AND 3454.99 SELECT @a = .4600, @b = 228.7856
		ELSE IF @x BETWEEN 1604 AND 3454.99 SELECT @a = .4650, @b = 228.7856
		ELSE SELECT @a = .5450, @b = 505.2163
	END
	ELSE IF @Scale = 3
	BEGIN
		IF @x BETWEEN 0 AND 710.99 SELECT @a = .2900, @b = .2900
		ELSE IF @x BETWEEN 711 AND 1537.99 SELECT @a = .3000, @b = 7.1154
		ELSE IF @x BETWEEN 1538 AND 3460.99 SELECT @a = .3700, @b = 114.8077
		ELSE SELECT @a = .4500, @b = 391.7308
	END
	ELSE IF @Scale = 31
	BEGIN
		IF @x BETWEEN 0 AND 710.99 SELECT @a = .2900, @b = .2900
		ELSE IF @x BETWEEN 711 AND 862.99 SELECT @a = .3000, @b = 7.1154
		ELSE IF @x BETWEEN 863 AND 961.99 SELECT @a = .3400, @b = 7.1154
		ELSE IF @x BETWEEN 962 AND 1059.99 SELECT @a = .3450, @b = 7.1154
		ELSE IF @x BETWEEN 1060 AND 1115.99 SELECT @a = .3500, @b = 7.1154
		ELSE IF @x BETWEEN 1116 AND 1198.99 SELECT @a = .3550, @b = 7.1154
		ELSE IF @x BETWEEN 1199 AND 1298.99 SELECT @a = .3600, @b = 7.1154
		ELSE IF @x BETWEEN 1299 AND 1366.99 SELECT @a = .3650, @b = 7.1154
		ELSE IF @x BETWEEN 1367 AND 1504.99 SELECT @a = .3700, @b = 7.1154
		ELSE IF @x BETWEEN 1505 AND 1537.99 SELECT @a = .3750, @b = 7.1154
		ELSE IF @x BETWEEN 1538 AND 1603.99 SELECT @a = .4450, @b = 114.8077
		ELSE IF @x BETWEEN 1604 AND 3460.99 SELECT @a = .4500, @b = 114.8077
		ELSE SELECT @a = .5300, @b = 391.7308
	END
	ELSE IF @Scale = 4
	BEGIN
		IF @nonresalienyn = 'N' SELECT @a = .4650
		ELSE IF @nonresalienyn = 'Y' SELECT @a = .4500
	END
	ELSE IF @Scale = 5
	BEGIN
		IF @x BETWEEN 0 AND 204.99 SELECT @a = 0, @b = 0
		ELSE IF @x BETWEEN 205 AND 570.99 SELECT @a = .1513, @b = 31.1538
		ELSE IF @x BETWEEN 571 AND 704.99 SELECT @a = .1715, @b = 42.6923
		ELSE IF @x BETWEEN 705 AND 1291.99 SELECT @a = .3200, @b = 147.4538
		ELSE IF @x BETWEEN 1291 AND 1532.99 SELECT @a = .3000, @b = 121.6154
		ELSE IF @x BETWEEN 1532 AND 3454.99 SELECT @a = .3700, @b = 238.8769
		ELSE SELECT @a = .4500, @b = 505.3077
	END
	ELSE IF @Scale = 51
	BEGIN
		IF @x BETWEEN 0 AND 204.99 SELECT @a = 0, @b = 0
		ELSE IF @x BETWEEN 205 AND 570.99 SELECT @a = .1513, @b = 31.1538
		ELSE IF @x BETWEEN 571 AND 704.99 SELECT @a = .1715, @b = 42.6923
		ELSE IF @x BETWEEN 705 AND 862.99 SELECT @a = .3200, @b = 147.4538
		ELSE IF @x BETWEEN 863 AND 961.99 SELECT @a = .3600, @b = 147.4538
		ELSE IF @x BETWEEN 962 AND 1059.99 SELECT @a = .3650, @b = 147.4538
		ELSE IF @x BETWEEN 1060 AND 1115.99 SELECT @a = .3700, @b = 147.4538
		ELSE IF @x BETWEEN 1116 AND 1198.99 SELECT @a = .3750, @b = 147.4538
		ELSE IF @x BETWEEN 1199 AND 1290.99 SELECT @a = .3800, @b = 147.4538
		ELSE IF @x BETWEEN 1291 AND 1298.99 SELECT @a = .3600, @b = 121.6154
		ELSE IF @x BETWEEN 1299 AND 1366.99 SELECT @a = .3650, @b = 121.6154
		ELSE IF @x BETWEEN 1367 AND 1504.99 SELECT @a = .3700, @b = 121.6154
		ELSE IF @x BETWEEN 1505 AND 1531.99 SELECT @a = .3750, @b = 121.6154
		ELSE IF @x BETWEEN 1532 AND 1603.99 SELECT @a = .4450, @b = 228.8769
		ELSE IF @x BETWEEN 1604 AND 3454.99 SELECT @a = .4500, @b = 228.8769
		ELSE SELECT @a = .5300, @b = 505.3077
	END
	ELSE IF @Scale = 6
	BEGIN
		IF @x BETWEEN 0 AND 204.99 SELECT @a = 0, @b = 0
		ELSE IF @x BETWEEN 205 AND 570.99 SELECT @a = .1513, @b = 31.1538
		ELSE IF @x BETWEEN 571 AND 593.99 SELECT @a = .1715, @b = 42.6923
		ELSE IF @x BETWEEN 594 AND 698.99 SELECT @a = .2219, @b = 72.6885
		ELSE IF @x BETWEEN 699 AND 704.99 SELECT @a = .1790, @b = 42.6925
		ELSE IF @x BETWEEN 705 AND 1290.99 SELECT @a = .3275, @b = 147.4078
		ELSE IF @x BETWEEN 1291 AND 1531.99 SELECT @a = .3075, @b = 121.5694
		ELSE IF @x BETWEEN 1532 AND 3454.99 SELECT @a = .3775, @b = 228.8309
		ELSE SELECT @a = .4575, @b = 505.2617
	END
	ELSE IF @Scale = 61
	BEGIN
		IF @x BETWEEN 0 AND 204.99 SELECT @a = 0, @b = 0
		ELSE IF @x BETWEEN 205 AND 570.99 SELECT @a = .1513, @b = 31.1538
		ELSE IF @x BETWEEN 571 AND 593.99 SELECT @a = .1715, @b = 42.6923
		ELSE IF @x BETWEEN 594 AND 698.99 SELECT @a = .2219, @b = 72.6885
		ELSE IF @x BETWEEN 699 AND 704.99 SELECT @a = .1790, @b = 42.6925
		ELSE IF @x BETWEEN 705 AND 862.99 SELECT @a = .3275, @b = 147.4078
		ELSE IF @x BETWEEN 863 AND 961.99 SELECT @a = .3675, @b = 147.4078
		ELSE IF @x BETWEEN 962 AND 1059.99 SELECT @a = .3725, @b = 147.4078
		ELSE IF @x BETWEEN 1060 AND 1115.99 SELECT @a = .3775, @b = 147.4078
		ELSE IF @x BETWEEN 1116 AND 1198.99 SELECT @a = .3825, @b = 147.4078
		ELSE IF @x BETWEEN 1199 AND 1290.99 SELECT @a = .3875, @b = 147.4078
		ELSE IF @x BETWEEN 1291 AND 1298.99 SELECT @a = .3675, @b = 121.5694
		ELSE IF @x BETWEEN 1299 AND 1366.99 SELECT @a = .3725, @b = 121.5694
		ELSE IF @x BETWEEN 1367 AND 1504.99 SELECT @a = .3775, @b = 121.5694
		ELSE IF @x BETWEEN 1505 AND 1531.99 SELECT @a = .3825, @b = 121.5694
		ELSE IF @x BETWEEN 1532 AND 1603.99 SELECT @a = .4525, @b = 228.8309
		ELSE IF @x BETWEEN 1604 AND 3454.99 SELECT @a = .4575, @b = 228.8309
		ELSE SELECT @a = .5375, @b = 505.2617
	END
	ELSE IF @Scale = 7
	BEGIN
		IF @x BETWEEN 0 AND 206.99 SELECT @a = 0, @b = 0
		ELSE IF @x BETWEEN 207 AND 354.99 SELECT @a = .1500, @b = 31.1538
		ELSE IF @x BETWEEN 355 AND 417.99 SELECT @a = .2500, @b = 66.7077
		ELSE IF @x BETWEEN 418 AND 575.99 SELECT @a = .1650, @b = 31.1548
		ELSE IF @x BETWEEN 576 AND 710.99 SELECT @a = .1850, @b = 42.6933
		ELSE IF @x BETWEEN 711 AND 1297.99 SELECT @a = .3350, @b = 149.4240
		ELSE IF @x BETWEEN 1298 AND 1537.99 SELECT @a = .3150, @b = 123.4625
		ELSE IF @x BETWEEN 1538 AND 3460.99 SELECT @a = .3850, @b = 231.1548
		ELSE SELECT @a = .4650, @b = 508.0779
	END
	ELSE IF @Scale = 71
	BEGIN
		IF @x BETWEEN 0 AND 206.99 SELECT @a = 0, @b = 0
		ELSE IF @x BETWEEN 207 AND 354.99 SELECT @a = .1500, @b = 31.1538
		ELSE IF @x BETWEEN 355 AND 417.99 SELECT @a = .2500, @b = 66.7077
		ELSE IF @x BETWEEN 418 AND 575.99 SELECT @a = .1650, @b = 31.1548
		ELSE IF @x BETWEEN 576 AND 710.99 SELECT @a = .1850, @b = 42.6933
		ELSE IF @x BETWEEN 711 AND 862.99 SELECT @a = .3350, @b = 149.4240
		ELSE IF @x BETWEEN 863 AND 961.99 SELECT @a = .3750, @b = 149.4240
		ELSE IF @x BETWEEN 962 AND 1059.99 SELECT @a = .3800, @b = 149.4240
		ELSE IF @x BETWEEN 1060 AND 1115.99 SELECT @a = .3850, @b = 149.4240
		ELSE IF @x BETWEEN 1116 AND 1198.99 SELECT @a = .3900, @b = 149.4240
		ELSE IF @x BETWEEN 1199 AND 1297.99 SELECT @a = .3950, @b = 149.4240
		ELSE IF @x BETWEEN 1298 AND 1298.99 SELECT @a = .3750, @b = 123.4625
		ELSE IF @x BETWEEN 1299 AND 1366.99 SELECT @a = .3800, @b = 123.4625
		ELSE IF @x BETWEEN 1367 AND 1504.99 SELECT @a = .3850, @b = 123.4625
		ELSE IF @x BETWEEN 1505 AND 1537.99 SELECT @a = .3900, @b = 123.4625
		ELSE IF @x BETWEEN 1538 AND 1603.99 SELECT @a = .4600, @b = 231.1548
		ELSE IF @x BETWEEN 1604 AND 3460.99 SELECT @a = .4650, @b = 231.1548
		ELSE SELECT @a = .5450, @b = 508.0779
	END
	-- compute y (weekly withholding amount)
	SELECT @y = ROUND((@a * @x) - @b, 0)

	-- to get withholding amount, convert y to the pay frequency equivalent if pay freq is not weekly
	IF @ppds = 52 SELECT @amt = @y
	IF @ppds = 26 SELECT @amt = @y * 2
	IF @ppds = 12 SELECT @amt = ROUND((@y * 13) / 3, 0)

	-- if scale 4 is used (no tax file number provided) aplly straight tax rate to earnings
	IF @Scale = 4 SELECT @amt = ROUND(@subjamt * @a, 0)


	-- determine medicare levy parameters based on scale (@addlexempts)
	IF @Scale IN (2, 21)
	BEGIN
		SELECT @WeekEarnThresh = 352
		SELECT @WeekEarnShadeIn = 414
		SELECT @MedLevyFamThresh = 30926
		SELECT @AddlChild = 2865
		SELECT @ShadeOutMultiplier = .1000
		SELECT @ShadeOutDivisor = .0850
		SELECT @WeekLevyAdjust = 352.4800
		SELECT @MedicareLevy = .0150
	END
	IF @Scale IN (6, 61)
	BEGIN
		SELECT @WeekEarnThresh = 594
		SELECT @WeekEarnShadeIn = 699
		SELECT @MedLevyFamThresh = 30926
		SELECT @AddlChild = 2865
		SELECT @ShadeOutMultiplier = .0500
		SELECT @ShadeOutDivisor = .0425
		SELECT @WeekLevyAdjust = 594.7300
		SELECT @MedicareLevy = .0075
	END
	IF @Scale IN (7, 71)
	BEGIN
		SELECT @WeekEarnThresh = 355
		SELECT @WeekEarnShadeIn = 418
		SELECT @MedLevyFamThresh = 31196
		SELECT @AddlChild = 2865
		SELECT @ShadeOutMultiplier = .1000
		SELECT @ShadeOutDivisor = .0850
		SELECT @WeekLevyAdjust = 355.5400
		SELECT @MedicareLevy = .0150
	END

	-- compute Medicare Levy Adjustment if applicable (ie. employee has applied via Medicare levy variation declaration form (NAT 0929))
	--  @status = "M" if employee answered 'Yes' to question 9 on the NAT 0929; 'Do you have a spouse?'
	--  @addlexempts > 0 (# of children) if employee answered 'Yes' to question 12 on NAT 0929; 'Do you have dependent children?'
	--  where scale is 4 (no tax file number provided), Medicare levy is applicable for residents only
	IF @Scale IN (2,6,7,21,61,71) 
		AND (@status = 'M' OR @addlexempts > 0) 
		AND NOT (@Scale = 4 AND @nonresalienyn = 'Y')
		--AND NOT (@status <> 'M' AND @addlexempts > 0)
	BEGIN
		SELECT	@WFT = 0, 
				@SOP = 0, 
				@WLA = 0

		-- otherwise just compute WLA
		IF @x < @WeekEarnShadeIn
		BEGIN
			SELECT @WLA = (@x - @WeekLevyAdjust) * @ShadeOutMultiplier
		END

		ELSE -- earnings exceed the shade-in threshold so include Weekly Family Threshold (WFT)/Shading Out Point (SOP) in WLA computation 
		BEGIN
			-- Compute Weekly Family Threshold for employee Married with No Children 
			-- ('Yes' to NAT 0929 question 9 / 'No' to question 12)
			IF @status = 'M' AND @addlexempts = 0 
			BEGIN
				SELECT @WFT = ROUND(@MedLevyFamThresh / 52, 2) 
			END
			-- Compute Weekly Family Threshold for employee with Children (
			-- ('Yes' to NAT 0929 question 12)
			ELSE IF @addlexempts > 0 
			BEGIN
				SELECT @WFT = ROUND(((@addlexempts * @AddlChild) + @MedLevyFamThresh) / 52, 2) 
			END

			-- Compute Weekly Levy Adjustment  (Weekly Earnings Shade-in Threshold < x < Weekly Family Threshold)
			IF @x < @WFT 
			BEGIN
				SELECT @WLA = @x * @MedicareLevy
			END

			ELSE
			BEGIN
				-- Compute Shade-out Point
				SELECT @SOP = FLOOR((@WFT * @ShadeOutMultiplier) / @ShadeOutDivisor)

				-- Compute Weekly Levy Adjustment (Weekly Family Threshold < x < Shade-out Point)
				IF @x >= @WFT AND @x < @SOP SELECT @WLA = (@WFT * @MedicareLevy) - ((@x - @WFT) * @ShadeOutDivisor)
			END
		END

		SELECT @WLA = ROUND(@WLA, 0) --round WLA to the nearest dollar


		-- adjust WLA for pay frequency if not weekly
		IF @ppds = 26 SELECT @WLA = @WLA * 2
		IF @ppds = 12 SELECT @WLA = ROUND((@WLA * 13) / 3, 0)

		-- if weekly levy amount was computed, use it ... otherwise continue and attempt to apply FTB
		IF @WLA <> 0
		BEGIN
			-- reduce withholding amount by WLA to get net withholding amount
			SELECT @amt = @amt - @WLA
		END
	END
			
	-- compute Tax Offset (FTB) if employee has elected on Withholding declaration
	--  to use FTB or special tax offset to reduce the witholding amount
	if @ftb_offset > 0 and @Scale in (2,5,6,7,21,51,61,71)
	BEGIN
		IF @ppds = 52 SELECT @FTB = .019 * @ftb_offset
		IF @ppds = 26 SELECT @FTB = .038 * @ftb_offset
		IF @ppds = 12 SELECT @FTB = .083 * @ftb_offset
		SELECT @FTB = ROUND(@FTB, 0) --round to nearest dollar

		-- reduce withholding amount by FTB to get net withholding amount
		SELECT @amt = @amt - @FTB
	END


	bspexit:
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_PAYG10] TO [public]
GO
