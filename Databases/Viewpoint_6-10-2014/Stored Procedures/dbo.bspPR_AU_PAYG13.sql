SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE PROC [dbo].[bspPR_AU_PAYG13]
/********************************************************
* CREATED BY: 	EN 6/04/08
* MODIFIED BY:	EN 9/17/08  for payments made on or after 1 July 2008
*				EN 9/8/09  #134853  update effective as of 1 July 2009
*				EN 2/2/2010 #137909 (version 092) add ability to compute HELP component
*				EN 9/8/09  #134853  update effective as of 1 July 2009
*				KK 6/15/2011 TK-06162 update effective as of 1 July 2011
*				KK/EN 7/14/2011 TK-06805 #144283 Fixed amount typos Scale: 2, 51, and 7
*				EN/KK 7/21/2011 TK-07060 Added scales for PAYG with flood levy exemption (12, 22, 32, 52, 62, 72)
*										 and for PAYG with HELP component and flood levy exemption (13, 23, 33, 53, 53, 73)
*				EN/CS 5/24/2012 B-08624/TK-15173 (V6-2012_13) Australian 7/1/2012 tax update
*													1) Removed all scale 7 code (it's being rolled in with scale 2)
*													2) Removed scales for regular and HELP flood levy exemption
*													   (12,22,32,52,62 and 13,23,33,53,63)
*													3) Added scales for SFSS (14,24,34,54,64) and SFSS plus HELP (15,25,35,55,65)
*													4) Updated bracket amount ranges, a, and b values for all regular and 
*													   HELP scales.
*				CHS	06/21/2013	TFS 53733 Tax update effective 07/01/2013
*				KK  06/27/2013  TFS 53733 Modified the monthly conversion. It was never working right. 
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
IF @Scale NOT IN (1,2,3,4,5,6,11,21,31,51,61,14,24,34,54,64,15,25,35,55,65)
BEGIN
	SELECT @msg = 'Invalid scale.'
	RETURN 1
END

-- Compute x
IF @ppds = 52 SELECT @x = FLOOR(@subjamt) + .99 --Weekly
IF @ppds = 26 SELECT @x = FLOOR(@subjamt/2) + .99 --Fortnightly
IF @ppds = 12 
BEGIN
	IF @subjamt - FLOOR(@subjamt) = .33 SELECT @subjamt = @subjamt + .01 --Monthly
	SELECT @x = FLOOR((@subjamt * 3) / 13) + .99 --TFS 53733
END

-- If there is no amount to calculate, return 0
IF @x < 1 
BEGIN
	SELECT @amt = 0
	RETURN 0
END

-- Determine a & b coefficients based on scale (@addlexempts)
IF @Scale = 1 -- Regular: tax-free threshold not claimed in Tax file number declaration
BEGIN
	IF		@x BETWEEN    0 AND   44.99 SELECT @a = .1900, @b =    .1900
	ELSE IF @x BETWEEN   45 AND  360.99 SELECT @a = .2216, @b =   1.4232
	ELSE IF @x BETWEEN  361 AND  931.99 SELECT @a = .3427, @b =  45.2055
	ELSE IF @x BETWEEN  932 AND 1187.99 SELECT @a = .3400, @b =  42.6890
	ELSE IF @x BETWEEN 1188 AND 3110.99 SELECT @a = .3850, @b =  96.1698
	ELSE SELECT								   @a = .4650, @b = 345.0928
END
ELSE IF @Scale = 11 -- HELP: tax-free threshold not claimed in Tax file number declaration
BEGIN
	IF		@x BETWEEN    0 AND   44.99 SELECT @a = .1900, @b =    .1900
	ELSE IF @x BETWEEN   45 AND  360.99 SELECT @a = .2216, @b =   1.4232
	ELSE IF @x BETWEEN  361 AND  635.99 SELECT @a = .3427, @b =  45.2055
	ELSE IF @x BETWEEN  636 AND  748.99 SELECT @a = .3827, @b =  45.2055
	ELSE IF @x BETWEEN  749 AND  860.99 SELECT @a = .3877, @b =  45.2055
	ELSE IF @x BETWEEN  861 AND  924.99 SELECT @a = .3927, @b =  45.2055
	ELSE IF @x BETWEEN  925 AND  931.99 SELECT @a = .3977, @b =  45.2055
	ELSE IF @x BETWEEN  932 AND 1019.99 SELECT @a = .3950, @b =  42.6890
	ELSE IF @x BETWEEN 1020 AND 1133.99 SELECT @a = .4000, @b =  42.6890
	ELSE IF @x BETWEEN 1134 AND 1187.99 SELECT @a = .4050, @b =  42.6890
	ELSE IF @x BETWEEN 1188 AND 1211.99 SELECT @a = .4500, @b =  96.1698
	ELSE IF @x BETWEEN 1212 AND 1368.99 SELECT @a = .4550, @b =  96.1698
	ELSE IF @x BETWEEN 1369 AND 1481.99 SELECT @a = .4600, @b =  96.1698
	ELSE IF @x BETWEEN 1482 AND 3110.99 SELECT @a = .4650, @b =  96.1698
	ELSE SELECT								   @a = .5450, @b = 345.0928
END
ELSE IF @Scale = 14 -- SFSS: tax-free threshold not claimed in Tax file number declaration
BEGIN
	IF		@x BETWEEN	  0 AND   44.99 SELECT @a = .1900, @b =    .1900
	ELSE IF @x BETWEEN   45 AND  360.99 SELECT @a = .2216, @b =   1.4232
	ELSE IF @x BETWEEN  361 AND  635.99 SELECT @a = .3427, @b =  45.2055
	ELSE IF @x BETWEEN  636 AND  860.99 SELECT @a = .3627, @b =  45.2055
	ELSE IF @x BETWEEN  861 AND  931.99 SELECT @a = .3727, @b =  45.2055
	ELSE IF @x BETWEEN  932 AND 1187.99 SELECT @a = .3700, @b =  42.6890
	ELSE IF @x BETWEEN 1188 AND 1368.99 SELECT @a = .4150, @b =  96.1698
	ELSE IF @x BETWEEN 1369 AND 3110.99 SELECT @a = .4250, @b =  96.1698
	ELSE SELECT								   @a = .5050, @b = 345.0928
END
ELSE IF @Scale = 15 -- SFSS & HELP: tax-free threshold not claimed in Tax file number declaration
BEGIN
	IF		@x BETWEEN    0 AND   44.99 SELECT @a = .1900, @b =    .1900
	ELSE IF @x BETWEEN   45 AND  360.99 SELECT @a = .2216, @b =   1.4232
	ELSE IF @x BETWEEN  361 AND  635.99 SELECT @a = .3427, @b =  45.2055
	ELSE IF @x BETWEEN  636 AND  748.99 SELECT @a = .4027, @b =  45.2055
	ELSE IF @x BETWEEN  749 AND  860.99 SELECT @a = .4077, @b =  45.2055
	ELSE IF @x BETWEEN  861 AND  924.99 SELECT @a = .4227, @b =  45.2055
	ELSE IF @x BETWEEN  925 AND  931.99 SELECT @a = .4277, @b =  45.2055
	ELSE IF @x BETWEEN  932 AND 1019.99 SELECT @a = .4250, @b =  42.6890
	ELSE IF @x BETWEEN 1020 AND 1133.99 SELECT @a = .4300, @b =  42.6890
	ELSE IF @x BETWEEN 1134 AND 1187.99 SELECT @a = .4350, @b =  42.6890
	ELSE IF @x BETWEEN 1188 AND 1210.99 SELECT @a = .4800, @b =  96.1698
	ELSE IF @x BETWEEN 1212 AND 1368.99 SELECT @a = .4850, @b =  96.1698
	ELSE IF @x BETWEEN 1369 AND 1481.99 SELECT @a = .5000, @b =  96.1698
	ELSE IF @x BETWEEN 1482 AND 3110.99 SELECT @a = .5050, @b =  96.1698
	ELSE SELECT								   @a = .5850, @b = 345.0928
END
ELSE IF @Scale = 2 -- Regular: payee claimed the tax-free threshold with or without leave loading
BEGIN
	IF		@x BETWEEN    0 AND  354.99 SELECT @a = 0,	   @b = 0
	ELSE IF @x BETWEEN  355 AND  394.99 SELECT @a = .1900, @b =  67.4635
	ELSE IF @x BETWEEN  395 AND  463.99 SELECT @a = .2900, @b = 106.9673
	ELSE IF @x BETWEEN  464 AND  710.99 SELECT @a = .2050, @b =  67.4636
	ELSE IF @x BETWEEN  711 AND 1281.99 SELECT @a = .3427, @b = 165.4424
	ELSE IF @x BETWEEN 1282 AND 1537.99 SELECT @a = .3400, @b = 161.9809
	ELSE IF @x BETWEEN 1538 AND 3460.99 SELECT @a = .3850, @b = 231.2116
	ELSE SELECT								   @a = .4650, @b = 508.1347
END
ELSE IF @Scale = 21 -- HELP: payee has claimed the tax-free threshold in Tax file number declaration with or without leave loading
BEGIN
	IF		@x BETWEEN    0 AND  354.99 SELECT @a = 0,	   @b = 0
	ELSE IF @x BETWEEN  355 AND  394.99 SELECT @a = .1900, @b =  67.4635
	ELSE IF @x BETWEEN  395 AND  463.99 SELECT @a = .2900, @b = 106.9673
	ELSE IF @x BETWEEN  464 AND  710.99 SELECT @a = .2050, @b =  67.4636
	ELSE IF @x BETWEEN  711 AND  985.99 SELECT @a = .3427, @b = 165.4424
	ELSE IF @x BETWEEN  986 AND 1098.99 SELECT @a = .3827, @b = 165.4424
	ELSE IF @x BETWEEN 1099 AND 1210.99 SELECT @a = .3877, @b = 165.4424
	ELSE IF @x BETWEEN 1211 AND 1274.99 SELECT @a = .3927, @b = 165.4424
	ELSE IF @x BETWEEN 1275 AND 1281.99 SELECT @a = .3977, @b = 165.4424
	ELSE IF @x BETWEEN 1282 AND 1369.99 SELECT @a = .3950, @b = 161.9809
	ELSE IF @x BETWEEN 1370 AND 1483.99 SELECT @a = .4000, @b = 161.9809
	ELSE IF @x BETWEEN 1484 AND 1537.99 SELECT @a = .4050, @b = 161.9809
	ELSE IF @x BETWEEN 1538 AND 1561.99 SELECT @a = .4500, @b = 231.2116
	ELSE IF @x BETWEEN 1562 AND 1718.99 SELECT @a = .4550, @b = 231.2116
	ELSE IF @x BETWEEN 1719 AND 1831.99 SELECT @a = .4600, @b = 231.2116
	ELSE IF @x BETWEEN 1832 AND 3460.99 SELECT @a = .4650, @b = 231.2116
	ELSE SELECT								   @a = .5450, @b = 508.1347
END
ELSE IF @Scale = 24 -- SFSS: payee has claimed the tax-free threshold in Tax file number declaration with or without leave loading
BEGIN
	IF		@x BETWEEN    0 AND  354.99 SELECT @a = 0,	   @b = 0
	ELSE IF @x BETWEEN  355 AND  394.99 SELECT @a = .1900, @b =  67.4635
	ELSE IF @x BETWEEN  395 AND  463.99 SELECT @a = .2900, @b = 106.9673
	ELSE IF @x BETWEEN  464 AND  710.99 SELECT @a = .2050, @b =  67.4636
	ELSE IF @x BETWEEN  711 AND  985.99 SELECT @a = .3427, @b = 165.4424
	ELSE IF @x BETWEEN  986 AND 1210.99 SELECT @a = .3627, @b = 165.4424
	ELSE IF @x BETWEEN 1211 AND 1281.99 SELECT @a = .3727, @b = 165.4424
	ELSE IF @x BETWEEN 1282 AND 1537.99 SELECT @a = .3700, @b = 161.9809
	ELSE IF @x BETWEEN 1538 AND 1718.99 SELECT @a = .4150, @b = 231.2116
	ELSE IF @x BETWEEN 1719 AND 3460.99 SELECT @a = .4250, @b = 231.2116
	ELSE SELECT								   @a = .5050, @b = 508.1347
END
ELSE IF @Scale = 25 -- SFSS & HELP: payee has claimed the tax-free threshold in Tax file number declaration with or without leave loading
BEGIN
	IF		@x BETWEEN    0 AND  354.99 SELECT @a = 0,	   @b = 0
	ELSE IF @x BETWEEN  355 AND  394.99 SELECT @a = .1900, @b =  67.4635
	ELSE IF @x BETWEEN  395 AND  463.99 SELECT @a = .2900, @b = 106.9673
	ELSE IF @x BETWEEN  464 AND  710.99 SELECT @a = .2050, @b =  67.4636
	ELSE IF @x BETWEEN  711 AND  985.99 SELECT @a = .3427, @b = 165.4424
	ELSE IF @x BETWEEN  986 AND 1098.99 SELECT @a = .4027, @b = 165.4424
	ELSE IF @x BETWEEN 1099 AND 1210.99 SELECT @a = .4077, @b = 165.4424
	ELSE IF @x BETWEEN 1211 AND 1274.99 SELECT @a = .4227, @b = 165.4424
	ELSE IF @x BETWEEN 1275 AND 1281.99 SELECT @a = .4277, @b = 165.4424
	ELSE IF @x BETWEEN 1282 AND 1369.99 SELECT @a = .4250, @b = 161.9809
	ELSE IF @x BETWEEN 1370 AND 1483.99 SELECT @a = .4300, @b = 161.9809
	ELSE IF @x BETWEEN 1484 AND 1537.99 SELECT @a = .4350, @b = 161.9809
	ELSE IF @x BETWEEN 1538 AND 1561.99 SELECT @a = .4800, @b = 231.2116
	ELSE IF @x BETWEEN 1562 AND 1718.99 SELECT @a = .4850, @b = 231.2116
	ELSE IF @x BETWEEN 1719 AND 1831.99 SELECT @a = .5000, @b = 231.2116
	ELSE IF @x BETWEEN 1832 AND 3460.99 SELECT @a = .5050, @b = 231.2116
	ELSE SELECT								   @a = .5850, @b = 508.1347
END
ELSE IF @Scale = 3 -- Regular: Foreign residents
BEGIN
	IF		@x BETWEEN    0 AND 1537.99 SELECT @a = .3250, @b =    .3250
	ELSE IF @x BETWEEN 1538 AND 3460.99 SELECT @a = .3700, @b =  69.2308
	ELSE SELECT								   @a = .4500, @b = 346.1538
END
ELSE IF @Scale = 31 -- HELP: Foreign residents
BEGIN
	IF		@x BETWEEN    0 AND  985.99 SELECT @a = .3250, @b =    .3250
	ELSE IF @x BETWEEN  986 AND 1098.99 SELECT @a = .3650, @b =    .3250
	ELSE IF @x BETWEEN 1099 AND 1210.99 SELECT @a = .3700, @b =    .3250
	ELSE IF @x BETWEEN 1211 AND 1274.99 SELECT @a = .3750, @b =    .3250
	ELSE IF @x BETWEEN 1275 AND 1369.99 SELECT @a = .3800, @b =    .3250
	ELSE IF @x BETWEEN 1370 AND 1483.99 SELECT @a = .3850, @b =    .3250
	ELSE IF @x BETWEEN 1484 AND 1537.99 SELECT @a = .3900, @b =    .3250
	ELSE IF @x BETWEEN 1538 AND 1561.99 SELECT @a = .4350, @b =  69.2308
	ELSE IF @x BETWEEN 1562 AND 1718.99 SELECT @a = .4400, @b =  69.2308
	ELSE IF @x BETWEEN 1719 AND 1831.99 SELECT @a = .4450, @b =  69.2308
	ELSE IF @x BETWEEN 1832 AND 3460.99 SELECT @a = .4500, @b =  69.2308
	ELSE SELECT								   @a = .5300, @b = 346.1538
END
ELSE IF @Scale = 34 -- SFSS: Foreign residents
BEGIN
	IF	    @x BETWEEN    0 AND  985.99 SELECT @a = .3250, @b =    .3250
	ELSE IF @x BETWEEN  986 AND 1210.99 SELECT @a = .3450, @b =    .3250
	ELSE IF @x BETWEEN 1211 AND 1537.99 SELECT @a = .3550, @b =    .3250
	ELSE IF @x BETWEEN 1538 AND 1718.99 SELECT @a = .4000, @b =  69.2308
	ELSE IF @x BETWEEN 1719 AND 3460.99 SELECT @a = .4100, @b =  69.2308
	ELSE SELECT								   @a = .4900, @b = 346.1538
END
ELSE IF @Scale = 35 -- SSFS & HELP: Foreign residents
BEGIN
	IF		@x BETWEEN    0 AND  986.99 SELECT @a = .3250, @b =    .3250
	ELSE IF @x BETWEEN  986 AND 1098.99 SELECT @a = .3850, @b =    .3250
	ELSE IF @x BETWEEN 1099 AND 1210.99 SELECT @a = .3900, @b =    .3250
	ELSE IF @x BETWEEN 1211 AND 1274.99 SELECT @a = .4050, @b =    .3250
	ELSE IF @x BETWEEN 1275 AND 1369.99 SELECT @a = .4100, @b =    .3250
	ELSE IF @x BETWEEN 1370 AND 1483.99 SELECT @a = .4150, @b =    .3250
	ELSE IF @x BETWEEN 1484 AND 1537.99 SELECT @a = .4200, @b =    .3250
	ELSE IF @x BETWEEN 1538 AND 1561.99 SELECT @a = .4650, @b =  69.2308
	ELSE IF @x BETWEEN 1562 AND 1718.99 SELECT @a = .4700, @b =  69.2308
	ELSE IF @x BETWEEN 1719 AND 1831.99 SELECT @a = .4850, @b =  69.2308
	ELSE IF @x BETWEEN 1832 AND 3460.99 SELECT @a = .4900, @b =  69.2308
	ELSE SELECT								   @a = .5700, @b = 346.1538
END
ELSE IF @Scale = 4 -- Regular: a tax file number (TFN) was not provided by payee
BEGIN
	IF @nonresalienyn = 'N' SELECT @a = .4650
	ELSE IF @nonresalienyn = 'Y' SELECT @a = .4500
END
ELSE IF @Scale = 5 -- Regular: payee claimed the FULL exemption from Medicare levy in Medicare levy variation declaration
BEGIN
	IF		@x BETWEEN    0 AND  354.99 SELECT @a = 0,	   @b = 0
	ELSE IF @x BETWEEN  355 AND  710.99 SELECT @a = .1900, @b =  67.4635
	ELSE IF @x BETWEEN  711 AND 1281.99 SELECT @a = .3277, @b = 165.4423
	ELSE IF @x BETWEEN 1282 AND 1537.99 SELECT @a = .3250, @b = 161.9808
	ELSE IF @x BETWEEN 1538 AND 3460.99 SELECT @a = .3700, @b = 231.2115
	ELSE SELECT								   @a = .4500, @b = 508.1346
END
ELSE IF @Scale = 51 -- HELP: payee claimed FULL exemption from Medicare levy in Medicare levy variation declaration
BEGIN
	IF		@x BETWEEN    0 AND  354.99 SELECT @a = 0,	   @b = 0
	ELSE IF @x BETWEEN  355 AND  710.99 SELECT @a = .1900, @b =  67.4635
	ELSE IF @x BETWEEN  711 AND  985.99 SELECT @a = .3277, @b = 165.4423
	ELSE IF @x BETWEEN  986 AND 1098.99 SELECT @a = .3677, @b = 165.4423
	ELSE IF @x BETWEEN 1099 AND 1210.99 SELECT @a = .3727, @b = 165.4423
	ELSE IF @x BETWEEN 1211 AND 1274.99 SELECT @a = .3777, @b = 165.4423
	ELSE IF @x BETWEEN 1275 AND 1281.99 SELECT @a = .3827, @b = 165.4423
	ELSE IF @x BETWEEN 1282 AND 1369.99 SELECT @a = .3800, @b = 161.9808
	ELSE IF @x BETWEEN 1370 AND 1483.99 SELECT @a = .3850, @b = 161.9808
	ELSE IF @x BETWEEN 1484 AND 1537.99 SELECT @a = .3900, @b = 161.9808
	ELSE IF @x BETWEEN 1538 AND 1561.99 SELECT @a = .4350, @b = 231.2115
	ELSE IF @x BETWEEN 1562 AND 1718.99 SELECT @a = .4400, @b = 231.2115
	ELSE IF @x BETWEEN 1719 AND 1831.99 SELECT @a = .4450, @b = 231.2115
	ELSE IF @x BETWEEN 1832 AND 3460.99 SELECT @a = .4500, @b = 231.2115
	ELSE SELECT								   @a = .5300, @b = 508.1346
END
ELSE IF @Scale = 54 -- SFSS: payee claimed FULL exemption from Medicare levy in Medicare levy variation declaration
BEGIN
	IF		@x BETWEEN    0 AND  354.99 SELECT @a = 0,	   @b = 0
	ELSE IF @x BETWEEN  355 AND  710.99 SELECT @a = .1900, @b =  67.4635
	ELSE IF @x BETWEEN  711 AND  985.99 SELECT @a = .3277, @b = 165.4423
	ELSE IF @x BETWEEN  986 AND 1210.99 SELECT @a = .3477, @b = 165.4423
	ELSE IF @x BETWEEN 1211 AND 1281.99 SELECT @a = .3577, @b = 165.4423
	ELSE IF @x BETWEEN 1282 AND 1537.99 SELECT @a = .3550, @b = 161.9808
	ELSE IF @x BETWEEN 1538 AND 1718.99 SELECT @a = .4000, @b = 231.2115
	ELSE IF @x BETWEEN 1719 AND 3460.99 SELECT @a = .4100, @b = 231.2115
	ELSE SELECT								   @a = .4900, @b = 508.1346
END
ELSE IF @Scale = 55 -- SFSS & HELP: payee claimed FULL exemption from Medicare levy in Medicare levy variation declaration
BEGIN
	IF		@x BETWEEN    0 AND  354.99 SELECT @a = 0,	   @b = 0
	ELSE IF @x BETWEEN  355 AND  710.99 SELECT @a = .1900, @b =  67.4635
	ELSE IF @x BETWEEN  711 AND  985.99 SELECT @a = .3277, @b = 165.4423
	ELSE IF @x BETWEEN  986 AND 1098.99 SELECT @a = .3877, @b = 165.4423
	ELSE IF @x BETWEEN 1099 AND 1210.99 SELECT @a = .3927, @b = 165.4423
	ELSE IF @x BETWEEN 1211 AND 1274.99 SELECT @a = .4077, @b = 165.4423
	ELSE IF @x BETWEEN 1275 AND 1281.99 SELECT @a = .4127, @b = 165.4423
	ELSE IF @x BETWEEN 1282 AND 1369.99 SELECT @a = .4100, @b = 161.9808
	ELSE IF @x BETWEEN 1370 AND 1483.99 SELECT @a = .4150, @b = 161.9808
	ELSE IF @x BETWEEN 1484 AND 1537.99 SELECT @a = .4200, @b = 161.9808
	ELSE IF @x BETWEEN 1538 AND 1561.99 SELECT @a = .4650, @b = 231.2115
	ELSE IF @x BETWEEN 1562 AND 1718.99 SELECT @a = .4700, @b = 231.2115
	ELSE IF @x BETWEEN 1719 AND 1831.99 SELECT @a = .4850, @b = 231.2115
	ELSE IF @x BETWEEN 1832 AND 3460.99 SELECT @a = .4900, @b = 231.2115
	ELSE SELECT								   @a = .5700, @b = 508.1346
END
ELSE IF @Scale = 6 -- Regular: payee claimed the HALF exemption from Medicare levy in Medicare levy variation declaration
BEGIN
	IF		@x BETWEEN    0 AND  354.99 SELECT @a = 0,	   @b = 0
	ELSE IF @x BETWEEN  355 AND  628.99 SELECT @a = .1900, @b =  67.4635
	ELSE IF @x BETWEEN  629 AND  710.99 SELECT @a = .2400, @b =  98.9471
	ELSE IF @x BETWEEN  711 AND  739.99 SELECT @a = .3777, @b = 196.9260
	ELSE IF @x BETWEEN  740 AND 1281.99 SELECT @a = .3352, @b = 165.4425
	ELSE IF @x BETWEEN 1282 AND 1537.99 SELECT @a = .3325, @b = 161.9809
	ELSE IF @x BETWEEN 1538 AND 3460.99 SELECT @a = .3775, @b = 231.2117
	ELSE SELECT								   @a = .4575, @b = 508.1348
END
ELSE IF @Scale = 61 -- HELP: payee claimed HALF exemption from Medicare levy in Medicare levy variation declaration
BEGIN
	IF		@x BETWEEN    0 AND  354.99 SELECT @a = 0,	   @b = 0
	ELSE IF @x BETWEEN  355 AND  628.99 SELECT @a = .1900, @b =  67.4635
	ELSE IF @x BETWEEN  629 AND  710.99 SELECT @a = .2400, @b =  98.9471
	ELSE IF @x BETWEEN  711 AND  739.99 SELECT @a = .3777, @b = 196.9260
	ELSE IF @x BETWEEN  740 AND  985.99 SELECT @a = .3352, @b = 165.4425
	ELSE IF @x BETWEEN  986 AND 1098.99 SELECT @a = .3752, @b = 165.4425
	ELSE IF @x BETWEEN 1099 AND 1210.99 SELECT @a = .3802, @b = 165.4425
	ELSE IF @x BETWEEN 1211 AND 1274.99 SELECT @a = .3852, @b = 165.4425
	ELSE IF @x BETWEEN 1275 AND 1281.99 SELECT @a = .3902, @b = 165.4425
	ELSE IF @x BETWEEN 1282 AND 1369.99 SELECT @a = .3875, @b = 161.9809
	ELSE IF @x BETWEEN 1370 AND 1483.99 SELECT @a = .3925, @b = 161.9809
	ELSE IF @x BETWEEN 1484 AND 1537.99 SELECT @a = .3975, @b = 161.9809
	ELSE IF @x BETWEEN 1538 AND 1561.99 SELECT @a = .4425, @b = 231.2117
	ELSE IF @x BETWEEN 1562 AND 1718.99 SELECT @a = .4475, @b = 231.2117
	ELSE IF @x BETWEEN 1719 AND 1831.99 SELECT @a = .4525, @b = 231.2117
	ELSE IF @x BETWEEN 1832 AND 3460.99 SELECT @a = .4575, @b = 231.2117
	ELSE SELECT								   @a = .5375, @b = 508.1348
	END
ELSE IF @Scale = 64 -- SFSS: payee claimed HALF exemption from Medicare levy in Medicare levy variation declaration
BEGIN
	IF		@x BETWEEN    0 AND  354.99 SELECT @a = 0,	   @b = 0
	ELSE IF @x BETWEEN  355 AND  628.99 SELECT @a = .1900, @b =  67.4635
	ELSE IF @x BETWEEN  629 AND  710.99 SELECT @a = .2400, @b =  98.9471
	ELSE IF @x BETWEEN  711 AND  739.99 SELECT @a = .3777, @b = 196.9260
	ELSE IF @x BETWEEN  740 AND  985.99 SELECT @a = .3352, @b = 165.4425
	ELSE IF @x BETWEEN  986 AND 1210.99 SELECT @a = .3552, @b = 165.4425
	ELSE IF @x BETWEEN 1211 AND 1281.99 SELECT @a = .3652, @b = 165.4425
	ELSE IF @x BETWEEN 1282 AND 1537.99 SELECT @a = .3625, @b = 161.9809
	ELSE IF @x BETWEEN 1538 AND 1718.99 SELECT @a = .4075, @b = 231.2117
	ELSE IF @x BETWEEN 1719 AND 3460.99 SELECT @a = .4175, @b = 231.2117
	ELSE SELECT								   @a = .4975, @b = 508.1348
END
ELSE IF @Scale = 65 -- SFSS & HELP: payee claimed HALF exemption from Medicare levy in Medicare levy variation declaration
BEGIN
	IF		@x BETWEEN    0 AND  354.99 SELECT @a = 0,	   @b = 0
	ELSE IF @x BETWEEN  355 AND  628.99 SELECT @a = .1900, @b =  67.4635
	ELSE IF @x BETWEEN  629 AND  710.99 SELECT @a = .2400, @b =  98.9471
	ELSE IF @x BETWEEN  711 AND  739.99 SELECT @a = .3777, @b = 196.9260
	ELSE IF @x BETWEEN  740 AND  985.99 SELECT @a = .3352, @b = 165.4425
	ELSE IF @x BETWEEN  986 AND 1098.99 SELECT @a = .3952, @b = 165.4425
	ELSE IF @x BETWEEN 1099 AND 1210.99 SELECT @a = .4002, @b = 165.4425
	ELSE IF @x BETWEEN 1211 AND 1274.99 SELECT @a = .4152, @b = 165.4425
	ELSE IF @x BETWEEN 1275 AND 1281.99 SELECT @a = .4202, @b = 165.4425
	ELSE IF @x BETWEEN 1282 AND 1369.99 SELECT @a = .4175, @b = 161.9809
	ELSE IF @x BETWEEN 1370 AND 1483.99 SELECT @a = .4225, @b = 161.9809
	ELSE IF @x BETWEEN 1484 AND 1537.99 SELECT @a = .4275, @b = 161.9809
	ELSE IF @x BETWEEN 1538 AND 1561.99 SELECT @a = .4725, @b = 231.2117
	ELSE IF @x BETWEEN 1562 AND 1718.99 SELECT @a = .4775, @b = 231.2117
	ELSE IF @x BETWEEN 1719 AND 1831.99 SELECT @a = .4925, @b = 231.2117
	ELSE IF @x BETWEEN 1832 AND 3460.99 SELECT @a = .4975, @b = 231.2117
	ELSE SELECT								   @a = .5775, @b = 508.1348
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
IF @Scale IN (2, 21, 24, 25)
BEGIN
	SELECT @WeekEarnThresh = 395
	SELECT @WeekEarnShadeIn = 464
	SELECT @MedLevyFamThresh = 32743
	SELECT @AddlChild = 3007
	SELECT @ShadeOutMultiplier = .1000
	SELECT @ShadeOutDivisor = .0850
	SELECT @WeekLevyAdjust = 395.0400
	SELECT @MedicareLevy = .0150
END
IF @Scale IN (6, 61, 64, 65)
BEGIN
	SELECT @WeekEarnThresh = 629
	SELECT @WeekEarnShadeIn = 740
	SELECT @MedLevyFamThresh = 32743
	SELECT @AddlChild = 3007
	SELECT @ShadeOutMultiplier = .0500
	SELECT @ShadeOutDivisor = .0425
	SELECT @WeekLevyAdjust = 629.6700
	SELECT @MedicareLevy = .0075
END

-- Compute Medicare Levy Adjustment if applicable (ie. employee has applied via Medicare levy variation declaration form (NAT 0929))
--  @status = "M" if employee answered 'Yes' to question 9 on the NAT 0929; 'Do you have a spouse?'
--  @addlexempts > 0 (# of children) if employee answered 'Yes' to question 12 on NAT 0929; 'Do you have dependent children?'
--  where scale is 4 (no tax file number provided), Medicare levy is applicable for residents only
IF @Scale IN (2,4,6,21,61,24,64,25,65) 
	AND (@status = 'M' OR @addlexempts > 0) 
	AND NOT (@Scale = 4 AND @nonresalienyn = 'Y')
	AND (@Scale IN (2,21,24,25,6,61,64,65) AND @x >= @WeekEarnThresh)
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
IF @ftb_offset > 0 AND @Scale IN (2,5,6,21,51,61,24,54,64,25,55,65)
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
GRANT EXECUTE ON  [dbo].[bspPR_AU_PAYG13] TO [public]
GO
