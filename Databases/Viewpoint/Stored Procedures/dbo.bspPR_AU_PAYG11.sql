SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_AU_PAYG11]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE PROC [dbo].[bspPR_AU_PAYG11]
/********************************************************
* CREATED BY: 	EN 6/04/08
* MODIFIED BY:	EN 9/17/08  for payments made on or after 1 July 2008
*				EN 9/8/09  #134853  update effective as of 1 July 2009
*				EN 2/2/2010 #137909 (version 092) add ability to compute HELP component
*				EN 9/8/09  #134853  update effective as of 1 July 2009
*				KK 6/15/2011 TK-06162 update effective as of 1 July 2011
*				KK/EN 7/14/2011 TK-06805 #144283 Fixed amount typos Scale: 2, 51, and 7
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
* 	0 	    success
*	1 		failure
**********************************************************/
(@subjamt bDollar = 0, 
 @ppds TINYINT = 0, 
 @Scale TINYINT = 0, 
 @status CHAR(1) = 'S', 
 @addlexempts TINYINT = 0, 
 @nonresalienyn bYN = 'N', 
 @ftb_offset bDollar = 0, 
 @amt bDollar = 0 OUTPUT, 
 @msg VARCHAR(255) = NULL OUTPUT)
AS
SET NOCOUNT ON

DECLARE @x bDollar, --Adjusted earnings 
	    @a bUnitCost, --Rate coefficient for computing weekly withholding amount
	    @b bUnitCost, --Deduction coefficient for computing weekly withholding amount
   	    @y bDollar, --Weekly withholding amount
	    @FTB bDollar, --Family Tax Benefit
	    @WeekEarnThresh bDollar, --Weekly earnings threshold for medicare levy
	    @WeekEarnShadeIn bDollar, --Weekly earnings shade-in threshold for medicare levy
	    @MedLevyFamThresh bDollar, --Medicare levy family threshold
	    @AddlChild bDollar, --Additional child allowance for medicare levy
	    @ShadeOutMultiplier bUnitCost, --Shading out point multiplier for medicare levy
	    @ShadeOutDivisor bUnitCost, --Shading out point divisor for medicare levy
	    @WeekLevyAdjust bUnitCost, --Weekly levy adjustment factor
	    @MedicareLevy bUnitCost, --Medicare levy
	    @WFT bDollar, --Weekly Family Threshold
	    @SOP bDollar, --Shading Out Point
	    @WLA bDollar --Weekly Levy Adjustment

SELECT @x = 0, 
	   @a = 0, 
	   @b = 0, 
	   @y = 0, 
	   @FTB = 0, 
	   @WeekEarnThresh = 0, 
	   @WeekEarnShadeIn = 0,
	   @MedLevyFamThresh = 0, 
	   @AddlChild = 0, 
	   @ShadeOutMultiplier = 0, 
	   @ShadeOutDivisor = 0, 
	   @WeekLevyAdjust = 0

-- Validate pay periods
IF @ppds = 0
BEGIN
	SELECT @msg = 'Missing # of Pay Periods per year!'
	RETURN 1
END
IF @ppds NOT IN (52,26,12)
BEGIN
	SELECT @msg = 'Pay Frequency must be Weekly, Biweekly (Fortnightly), or Monthly.'
	RETURN 1
END
-- Validate scale
IF @Scale NOT IN (1,2,3,4,5,6,7,11,21,31,51,61,71)
BEGIN
	SELECT @msg = 'Valid scales are 1-7, 11, 21, 31, 51, 61, 71.'
	RETURN 1
END

-- Compute x
IF @ppds = 52 SELECT @x = FLOOR(@subjamt) + .99 --Weekly
IF @ppds = 26 SELECT @x = FLOOR(@subjamt/2) + .99 --Fortnightly
IF @ppds = 12 
BEGIN
	IF @subjamt - FLOOR(@subjamt) = .33 SELECT @x = @subjamt + .01 --Monthly
	SELECT @x = FLOOR((@subjamt * 3) / 13) + .99
END

-- If there is no amount to calculate, return 0
IF @x < 1 
BEGIN
	SELECT @amt = 0
	RETURN 0
END

-- Determine a & b coefficients based on scale (@addlexempts)
IF @Scale = 1
BEGIN
	IF @x BETWEEN 0 AND 258.99 SELECT @a = .1650, @b = .1650
	ELSE IF @x BETWEEN 259 AND 393.99 SELECT @a = .2284, @b = 16.4596
	ELSE IF @x BETWEEN 394 AND 643.99 SELECT @a = .3430, @b = 61.6385
	ELSE IF @x BETWEEN 644 AND 979.99 SELECT @a = .3480, @b = 64.8596
	ELSE IF @x BETWEEN 980 AND 1220.99 SELECT @a = .3200, @b = 37.3981
	ELSE IF @x BETWEEN 1221 AND 1604.99 SELECT @a = .3900, @b = 122.8788
	ELSE IF @x BETWEEN 1605 AND 3143.99 SELECT @a = .3950, @b = 130.9077	
	ELSE SELECT @a = .4750, @b = 382.4462
END
ELSE IF @Scale = 11
BEGIN
	IF @x BETWEEN 0 AND 258.99 SELECT @a = .1650, @b = .1650
	ELSE IF @x BETWEEN 259 AND 393.99 SELECT @a = .2284, @b = 16.4596
	ELSE IF @x BETWEEN 394 AND 589.99 SELECT @a = .3430, @b = 61.6385
	ELSE IF @x BETWEEN 590 AND 643.99 SELECT @a = .3830, @b = 61.6385
	ELSE IF @x BETWEEN 644 AND 692.99 SELECT @a = .3880, @b = 64.8596
	ELSE IF @x BETWEEN 693 AND 796.99 SELECT @a = .3930, @b = 64.8596
	ELSE IF @x BETWEEN 797 AND 854.99 SELECT @a = .3980, @b = 64.8596
	ELSE IF @x BETWEEN 855 AND 942.99 SELECT @a = .4030, @b = 64.8596
	ELSE IF @x BETWEEN 943 AND 979.99 SELECT @a = .4080, @b = 64.8596
	ELSE IF @x BETWEEN 980 AND 1047.99 SELECT @a = .3800, @b = 37.3981
	ELSE IF @x BETWEEN 1048 AND 1119.99 SELECT @a = .3850, @b = 37.3981
	ELSE IF @x BETWEEN 1120 AND 1220.99 SELECT @a = .3900, @b = 37.3981
	ELSE IF @x BETWEEN 1221 AND 1263.99 SELECT @a = .4600, @b = 122.8788
	ELSE IF @x BETWEEN 1264 AND 1367.99 SELECT @a = .4650, @b = 122.8788
	ELSE IF @x BETWEEN 1368 AND 1604.99 SELECT @a = .4700, @b = 122.8788
	ELSE IF @x BETWEEN 1605 AND 3143.99 SELECT @a = .4750, @b = 130.9077
	ELSE SELECT @a = .5550, @b = 382.4462
END
ELSE IF @Scale = 2
BEGIN
	IF @x BETWEEN 0 AND 243.99 SELECT @a = 0, @b = 0
	ELSE IF @x BETWEEN 244 AND 358.99 SELECT @a = .1513, @b = 36.9231
	ELSE IF @x BETWEEN 359 AND 421.99 SELECT @a = .2522, @b = 73.1519
	ELSE IF @x BETWEEN 422 AND 570.99 SELECT @a = .1664, @b = 36.9239
	ELSE IF @x BETWEEN 571 AND 704.99 SELECT @a = .1947, @b = 53.0778
	ELSE IF @x BETWEEN 705 AND 954.99 SELECT @a = .3430, @b = 157.6978
	ELSE IF @x BETWEEN 955 AND 1290.99 SELECT @a = .3480, @b = 162.4747
	ELSE IF @x BETWEEN 1291 AND 1531.99 SELECT @a = .3200, @b = 126.3009 /*kk/en @b*/
	ELSE IF @x BETWEEN 1532 AND 1915.99 SELECT @a = .3900, @b = 233.5624
	ELSE IF @x BETWEEN 1916 AND 3454.99 SELECT @a = .3950, @b = 243.1470
	ELSE SELECT @a = .4750, @b = 519.5778
END
ELSE IF @Scale = 21
BEGIN
	IF @x BETWEEN 0 AND 243.99 SELECT @a = 0, @b = 0
	ELSE IF @x BETWEEN 244 AND 358.99 SELECT @a = .1513, @b = 36.9231
	ELSE IF @x BETWEEN 359 AND 421.99 SELECT @a = .2522, @b = 73.1519
	ELSE IF @x BETWEEN 422 AND 570.99 SELECT @a = .1664, @b = 36.9239
	ELSE IF @x BETWEEN 571 AND 704.99 SELECT @a = .1947, @b = 53.0778
	ELSE IF @x BETWEEN 705 AND 906.99 SELECT @a = .3430, @b = 157.6978
	ELSE IF @x BETWEEN 907 AND 954.99 SELECT @a = .3830, @b = 157.6978
	ELSE IF @x BETWEEN 955 AND 1010.99 SELECT @a = .3880, @b = 162.4747
	ELSE IF @x BETWEEN 1011 AND 1113.99 SELECT @a = .3930, @b = 162.4747
	ELSE IF @x BETWEEN 1114 AND 1171.99 SELECT @a = .3980, @b = 162.4747
	ELSE IF @x BETWEEN 1172 AND 1259.99 SELECT @a = .4030, @b = 162.4747
	ELSE IF @x BETWEEN 1260 AND 1290.99 SELECT @a = .4080, @b = 162.4747
	ELSE IF @x BETWEEN 1291 AND 1364.99 SELECT @a = .3800, @b = 126.3009
	ELSE IF @x BETWEEN 1365 AND 1436.99 SELECT @a = .3850, @b = 126.3009
	ELSE IF @x BETWEEN 1437 AND 1531.99 SELECT @a = .3900, @b = 126.3009
	ELSE IF @x BETWEEN 1532 AND 1580.99 SELECT @a = .4600, @b = 233.5624
	ELSE IF @x BETWEEN 1581 AND 1684.99 SELECT @a = .4650, @b = 233.5624
	ELSE IF @x BETWEEN 1685 AND 1915.99 SELECT @a = .4700, @b = 233.5624
	ELSE IF @x BETWEEN 1916 AND 3454.99 SELECT @a = .4750, @b = 243.1470
	ELSE SELECT @a = .5550, @b = 519.5778
END
ELSE IF @Scale = 3
BEGIN
	IF @x BETWEEN 0 AND 710.99 SELECT @a = .2900, @b = .2900
	ELSE IF @x BETWEEN 711 AND 960.99 SELECT @a = .3000, @b = 7.1154
	ELSE IF @x BETWEEN 961 AND 1537.99 SELECT @a = .3050, @b = 11.9231
	ELSE IF @x BETWEEN 1538 AND 1922.99 SELECT @a = .3750, @b = 119.6154
	ELSE IF @x BETWEEN 1923 AND 3460.99 SELECT @a = .3800, @b = 129.2308
	ELSE SELECT @a = .4600, @b = 406.1538
END
ELSE IF @Scale = 31
BEGIN
	IF @x BETWEEN 0 AND 710.99 SELECT @a = .2900, @b = .2900
	ELSE IF @x BETWEEN 711 AND 906.99 SELECT @a = .3000, @b = 7.1154
	ELSE IF @x BETWEEN 907 AND 960.99 SELECT @a = .3400, @b = 7.1154
	ELSE IF @x BETWEEN 961 AND 1010.99 SELECT @a = .3450, @b = 11.9231
	ELSE IF @x BETWEEN 1011 AND 1113.99 SELECT @a = .3500, @b = 11.9231
	ELSE IF @x BETWEEN 1114 AND 1171.99 SELECT @a = .3550, @b = 11.9231
	ELSE IF @x BETWEEN 1172 AND 1259.99 SELECT @a = .3600, @b = 11.9231
	ELSE IF @x BETWEEN 1260 AND 1364.99 SELECT @a = .3650, @b = 11.9231
	ELSE IF @x BETWEEN 1365 AND 1436.99 SELECT @a = .3700, @b = 11.9231
	ELSE IF @x BETWEEN 1437 AND 1537.99 SELECT @a = .3750, @b = 11.9231
	ELSE IF @x BETWEEN 1538 AND 1580.99 SELECT @a = .4450, @b = 119.6154
	ELSE IF @x BETWEEN 1581 AND 1684.99 SELECT @a = .4500, @b = 119.6154
	ELSE IF @x BETWEEN 1685 AND 1922.99 SELECT @a = .4550, @b = 119.6154
	ELSE IF @x BETWEEN 1923 AND 3460.99 SELECT @a = .4600, @b = 129.2308
	ELSE SELECT @a = .5400, @b = 406.1538
END
ELSE IF @Scale = 4
BEGIN
	IF @nonresalienyn = 'N' SELECT @a = .4650
	ELSE IF @nonresalienyn = 'Y' SELECT @a = .4500
END
ELSE IF @Scale = 5
BEGIN
	IF @x BETWEEN 0 AND 243.99 SELECT @a = 0, @b = 0
	ELSE IF @x BETWEEN 244 AND 570.99 SELECT @a = .1513, @b = 36.9231
	ELSE IF @x BETWEEN 571 AND 704.99 SELECT @a = .1796, @b = 53.0769
	ELSE IF @x BETWEEN 705 AND 954.99 SELECT @a = .3280, @b = 157.7892
	ELSE IF @x BETWEEN 955 AND 1290.99 SELECT @a = .3330, @b = 162.5662
	ELSE IF @x BETWEEN 1291 AND 1531.99 SELECT @a = .3050, @b = 126.3923
	ELSE IF @x BETWEEN 1532 AND 1915.99 SELECT @a = .3750, @b = 233.6538
	ELSE IF @x BETWEEN 1916 AND 3454.99 SELECT @a = .3800, @b = 243.2385
	ELSE SELECT @a = .4600, @b = 519.6692
END
ELSE IF @Scale = 51
BEGIN
	IF @x BETWEEN 0 AND 243.99 SELECT @a = 0, @b = 0
	ELSE IF @x BETWEEN 244 AND 570.99 SELECT @a = .1513, @b = 36.9231
	ELSE IF @x BETWEEN 571 AND 704.99 SELECT @a = .1796, @b = 53.0769
	ELSE IF @x BETWEEN 705 AND 906.99 SELECT @a = .3280, @b = 157.7892
	ELSE IF @x BETWEEN 907 AND 954.99 SELECT @a = .3680, @b = 157.7892
	ELSE IF @x BETWEEN 955 AND 1010.99 SELECT @a = .3730, @b = 162.5662
	ELSE IF @x BETWEEN 1011 AND 1113.99 SELECT @a = .3780, @b = 162.5662
	ELSE IF @x BETWEEN 1114 AND 1171.99 SELECT @a = .3830, @b = 162.5662
	ELSE IF @x BETWEEN 1172 AND 1259.99 SELECT @a = .3880, @b = 162.5662 /*kk/en Upper limit*/
	ELSE IF @x BETWEEN 1260 AND 1290.99 SELECT @a = .3930, @b = 162.5662
	ELSE IF @x BETWEEN 1291 AND 1364.99 SELECT @a = .3650, @b = 126.3923
	ELSE IF @x BETWEEN 1365 AND 1436.99 SELECT @a = .3700, @b = 126.3923
	ELSE IF @x BETWEEN 1437 AND 1531.99 SELECT @a = .3750, @b = 126.3923
	ELSE IF @x BETWEEN 1532 AND 1580.99 SELECT @a = .4450, @b = 233.6538
	ELSE IF @x BETWEEN 1581 AND 1684.99 SELECT @a = .4500, @b = 233.6538
	ELSE IF @x BETWEEN 1685 AND 1915.99 SELECT @a = .4550, @b = 233.6538
	ELSE IF @x BETWEEN 1916 AND 3454.99 SELECT @a = .4600, @b = 243.2385
	ELSE SELECT @a = .5400, @b = 519.6692
END
ELSE IF @Scale = 6
BEGIN
	IF @x BETWEEN 0 AND 243.99 SELECT @a = 0, @b = 0
	ELSE IF @x BETWEEN 244 AND 570.99 SELECT @a = .1513, @b = 36.9231
	ELSE IF @x BETWEEN 571 AND 605.99 SELECT @a = .1796, @b = 53.0769
	ELSE IF @x BETWEEN 606 AND 704.99 SELECT @a = .2300, @b = 83.6433
	ELSE IF @x BETWEEN 705 AND 712.99 SELECT @a = .3780, @b = 188.0479
	ELSE IF @x BETWEEN 713 AND 954.99 SELECT @a = .3355, @b = 157.7438
	ELSE IF @x BETWEEN 955 AND 1290.99 SELECT @a = .3405, @b = 162.5207
	ELSE IF @x BETWEEN 1291 AND 1531.99 SELECT @a = .3125, @b = 126.3468
	ELSE IF @x BETWEEN 1532 AND 1915.99 SELECT @a = .3825, @b = 233.6084
	ELSE IF @x BETWEEN 1916 AND 3454.99 SELECT @a = .3875, @b = 243.1930
	ELSE SELECT @a = .4675, @b = 519.6238
END
ELSE IF @Scale = 61
BEGIN
	IF @x BETWEEN 0 AND 243.99 SELECT @a = 0, @b = 0
	ELSE IF @x BETWEEN 244 AND 570.99 SELECT @a = .1513, @b = 36.9231
	ELSE IF @x BETWEEN 571 AND 605.99 SELECT @a = .1796, @b = 53.0769
	ELSE IF @x BETWEEN 606 AND 704.99 SELECT @a = .2300, @b = 83.6433
	ELSE IF @x BETWEEN 705 AND 712.99 SELECT @a = .3780, @b = 188.0479
	ELSE IF @x BETWEEN 713 AND 906.99 SELECT @a = .3355, @b = 157.7438
	ELSE IF @x BETWEEN 907 AND 954.99 SELECT @a = .3755, @b = 157.7438
	ELSE IF @x BETWEEN 955 AND 1010.99 SELECT @a = .3805, @b = 162.5207
	ELSE IF @x BETWEEN 1011 AND 1113.99 SELECT @a = .3855, @b = 162.5207
	ELSE IF @x BETWEEN 1114 AND 1171.99 SELECT @a = .3905, @b = 162.5207
	ELSE IF @x BETWEEN 1172 AND 1259.99 SELECT @a = .3955, @b = 162.5207
	ELSE IF @x BETWEEN 1260 AND 1290.99 SELECT @a = .4005, @b = 162.5207
	ELSE IF @x BETWEEN 1291 AND 1364.99 SELECT @a = .3725, @b = 126.3468
	ELSE IF @x BETWEEN 1365 AND 1436.99 SELECT @a = .3775, @b = 126.3468
	ELSE IF @x BETWEEN 1437 AND 1531.99 SELECT @a = .3825, @b = 126.3468
	ELSE IF @x BETWEEN 1532 AND 1580.99 SELECT @a = .4525, @b = 233.6084
	ELSE IF @x BETWEEN 1581 AND 1684.99 SELECT @a = .4575, @b = 233.6084
	ELSE IF @x BETWEEN 1685 AND 1915.99 SELECT @a = .4625, @b = 233.6084
	ELSE IF @x BETWEEN 1916 AND 3454.99 SELECT @a = .4675, @b = 243.1930
	ELSE SELECT @a = .5475, @b = 519.6238
	END
ELSE IF @Scale = 7
BEGIN
	IF @x BETWEEN 0 AND 245.99 SELECT @a = 0, @b = 0
	ELSE IF @x BETWEEN 246 AND 361.99 SELECT @a = .1500, @b = 36.9231
	ELSE IF @x BETWEEN 362 AND 425.99 SELECT @a = .2500, @b = 73.1519
	ELSE IF @x BETWEEN 426 AND 575.99 SELECT @a = .1650, @b = 36.9239
	ELSE IF @x BETWEEN 576 AND 710.99 SELECT @a = .1930, @b = 53.0778
	ELSE IF @x BETWEEN 711 AND 960.99 SELECT @a = .3430, @b = 159.8086
	ELSE IF @x BETWEEN 961 AND 1297.99 SELECT @a = .3480, @b = 164.6163 /*kk/en Upper limit*/
	ELSE IF @x BETWEEN 1298 AND 1537.99 SELECT @a = .3200, @b = 128.2701
	ELSE IF @x BETWEEN 1538 AND 1922.99 SELECT @a = .3900, @b = 235.9624
	ELSE IF @x BETWEEN 1923 AND 3460.99 SELECT @a = .3950, @b = 245.5778
	ELSE SELECT @a = .4750, @b = 522.5009
END
ELSE IF @Scale = 71
BEGIN
	IF @x BETWEEN 0 AND 245.99 SELECT @a = 0, @b = 0
	ELSE IF @x BETWEEN 246 AND 361.99 SELECT @a = .1500, @b = 36.9231
	ELSE IF @x BETWEEN 362 AND 425.99 SELECT @a = .2500, @b = 73.1519
	ELSE IF @x BETWEEN 426 AND 575.99 SELECT @a = .1650, @b = 36.9239
	ELSE IF @x BETWEEN 576 AND 710.99 SELECT @a = .1930, @b = 53.0778
	ELSE IF @x BETWEEN 711 AND 906.99 SELECT @a = .3430, @b = 159.8086
	ELSE IF @x BETWEEN 907 AND 960.99 SELECT @a = .3830, @b = 159.8086
	ELSE IF @x BETWEEN 961 AND 1010.99 SELECT @a = .3880, @b = 164.6163
	ELSE IF @x BETWEEN 1011 AND 1113.99 SELECT @a = .3930, @b = 164.6163
	ELSE IF @x BETWEEN 1114 AND 1171.99 SELECT @a = .3980, @b = 164.6163
	ELSE IF @x BETWEEN 1172 AND 1259.99 SELECT @a = .4030, @b = 164.6163
	ELSE IF @x BETWEEN 1260 AND 1297.99 SELECT @a = .4080, @b = 164.6163
	ELSE IF @x BETWEEN 1298 AND 1364.99 SELECT @a = .3800, @b = 128.2701
	ELSE IF @x BETWEEN 1365 AND 1436.99 SELECT @a = .3850, @b = 128.2701
	ELSE IF @x BETWEEN 1437 AND 1537.99 SELECT @a = .3900, @b = 128.2701
	ELSE IF @x BETWEEN 1538 AND 1580.99 SELECT @a = .4600, @b = 235.9624
	ELSE IF @x BETWEEN 1581 AND 1684.99 SELECT @a = .4650, @b = 235.9624
	ELSE IF @x BETWEEN 1685 AND 1922.99 SELECT @a = .4700, @b = 235.9624
	ELSE IF @x BETWEEN 1923 AND 3460.99 SELECT @a = .4750, @b = 245.5778
	ELSE SELECT @a = .5550, @b = 522.5009
END

-- Compute y (weekly withholding amount)
SELECT @y = ROUND((@a * @x) - @b, 0)

-- Convert y to pay frequency equivalent if pay freq is not weekly to get withholding amount
IF @ppds = 52 SELECT @amt = @y
IF @ppds = 26 SELECT @amt = @y * 2
IF @ppds = 12 SELECT @amt = ROUND((@y * 13) / 3, 0)

-- If scale 4 is used (no tax file number provided) apply straight tax rate to earnings
IF @Scale = 4 SELECT @amt = ROUND(@subjamt * @a, 0)

-- Determine medicare levy parameters based on scale (@addlexempts)
IF @Scale IN (2, 21)
BEGIN
	SELECT @WeekEarnThresh = 359/*6/11*/
	SELECT @WeekEarnShadeIn = 422/*6/11*/
	SELECT @MedLevyFamThresh = 31514/*6/11*/
	SELECT @AddlChild = 2919/*6/11*/
	SELECT @ShadeOutMultiplier = .1000
	SELECT @ShadeOutDivisor = .0850
	SELECT @WeekLevyAdjust = 359.1700/*6/11*/
	SELECT @MedicareLevy = .0150
END
IF @Scale IN (6, 61)
BEGIN
	SELECT @WeekEarnThresh = 606/*6/11*/
	SELECT @WeekEarnShadeIn = 713/*6/11*/
	SELECT @MedLevyFamThresh = 31514/*6/11*/
	SELECT @AddlChild = 2919/*6/11*/
	SELECT @ShadeOutMultiplier = .0500/*6/11*/
	SELECT @ShadeOutDivisor = .0425
	SELECT @WeekLevyAdjust = 606.0400/*6/11*/
	SELECT @MedicareLevy = .0075
END
IF @Scale IN (7, 71)
BEGIN
	SELECT @WeekEarnThresh = 362/*6/11*/
	SELECT @WeekEarnShadeIn = 426/*6/11*/
	SELECT @MedLevyFamThresh = 31789/*6/11*/
	SELECT @AddlChild = 2919/*6/11*/
	SELECT @ShadeOutMultiplier = .1000
	SELECT @ShadeOutDivisor = .0850
	SELECT @WeekLevyAdjust = 362.2900/*6/11*/
	SELECT @MedicareLevy = .0150
END

-- Compute Medicare Levy Adjustment if applicable (ie. employee has applied via Medicare levy variation declaration form (NAT 0929))
--  @status = "M" if employee answered 'Yes' to question 9 on the NAT 0929; 'Do you have a spouse?'
--  @addlexempts > 0 (# of children) if employee answered 'Yes' to question 12 on NAT 0929; 'Do you have dependent children?'
--  where scale is 4 (no tax file number provided), Medicare levy is applicable for residents only
IF @Scale IN (2,6,7,21,61,71) 
	AND (@status = 'M' OR @addlexempts > 0) 
	AND NOT (@Scale = 4 AND @nonresalienyn = 'Y')
	AND ((@Scale = 2 AND @x >= 359) OR (@Scale = 6 AND @x >= 606) OR (@Scale = 7 AND @x >= 362))
	-- KK- Added test to allow when one of the above conditions are true in the final and statement
BEGIN
	SELECT	@WFT = 0, 
			@SOP = 0, 
			@WLA = 0
	-- Otherwise just compute WLA
	IF @x < @WeekEarnShadeIn
	BEGIN
		SELECT @WLA = (@x - @WeekLevyAdjust) * @ShadeOutMultiplier
	END
	ELSE -- Earnings exceed the shade-in threshold so include Weekly Family Threshold (WFT)/Shading Out Point (SOP) in WLA computation 
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
	-- Adjust WLA for pay frequency if not weekly
	IF @ppds = 26 SELECT @WLA = @WLA * 2
	IF @ppds = 12 SELECT @WLA = ROUND((@WLA * 13) / 3, 0)

	-- If weekly levy amount was computed, use it ... otherwise continue and attempt to apply FTB
	IF @WLA <> 0
	BEGIN
		-- Reduce withholding amount by WLA to get net withholding amount
		SELECT @amt = @amt - @WLA
	END
END

-- Compute Tax Offset (FTB) if employee has elected on Withholding declaration
--  to use FTB or special tax offset to reduce the witholding amount
IF @ftb_offset > 0 AND @Scale IN (2,5,6,7,21,51,61,71)
BEGIN
	IF @ppds = 52 SELECT @FTB = .019 * @ftb_offset
	IF @ppds = 26 SELECT @FTB = .038 * @ftb_offset
	IF @ppds = 12 SELECT @FTB = .083 * @ftb_offset
	SELECT @FTB = ROUND(@FTB, 0) --round to nearest dollar

	-- Reduce withholding amount by FTB to get net withholding amount
	SELECT @amt = @amt - @FTB
END

-- Do not return a negative amount
IF @amt < 0 SELECT @amt = 0
		
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_PAYG11] TO [public]
GO
