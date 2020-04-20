SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRCTT112]    Script Date: 01/03/2008 16:16:03 ******/
  CREATE proc [dbo].[bspPRCTT112]
/********************************************************
* CREATED BY: 	EN 6/5/98
* MODIFIED BY:	GG 8/11/98
*               EN 6/16/00 - update effective 7/1/00
*               EN 7/5/00 - update to last update; Connecticut modified the personal exemption income thresholds for filing status 'F'
*               EN 7/20/00 - modified formula for calculating exemption to fix problem with calculating really high pay scales
*				EN 12/19/01 - update effective 1/1/2002
*				EN 8/20/02 - issue 18326 made changes to single filer exemptions effective 7/1/02
*				EN 10/7/02 - issue 18877 change double quotes to single
*				EN 3/4/03 - issue 20595  update effective 3/1/03
*				EN 6/19/03 - issue 21565  update effective 7/1/03 **changes tax rate to 5%**
*				EN 12/30/03 - issue 23421  update effective 1/1/04
*				EN 12/31/04 - issue 26244  default status AND exemptions
*				EN 12/21/06 - issue 123373  update effective 1/1/07
*				EN 1/04/08 - issue 126646 update effective 1/1/08
*				EN 12/31/08 - #131593  update effective 1/1/2009
*				EN 11/08/2009 - #136465  update effective ASAP
*				CHS	12/10/2010	- #0142442 fix S (F) brackets
*				EN/KK 6/14/2011 TK-05851 / #144005 updated effective 8/1/2011 (added Tables D and E, 3 addl brackets, and assorted fixes)
*
* USAGE:
* 	Calculates Connecticut Income Tax
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status
*	@exempts	# of exemptions
*
* OUTPUT PARAMETERS:
*	@amt		calculated tax amount
*	@msg		error message IF failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
*
* Note: Status translation
* VP Status		CT Code
*	F	<--		A
*	H	<--		B
*	M	<--		C
*	B	<--		D
*	S	<--		F
**********************************************************/
(@subjamt bDollar = 0, 
 @ppds tinyint = 0, 
 @status char(1) = 'S', 
 @exempts tinyint = 0,
 @amt bDollar = 0 output, 
 @msg varchar(255) = null output)
   
AS
SET NOCOUNT ON

DECLARE @asubjamt bDollar, 
		@exemptamt bDollar, 
		@limit bDollar,
		@baseamt bDollar, 
		@pcredits bDollar, 
		@rate bRate, 
		@addback bDollar, 
		@recaptureamt bDollar

-- #26244 set default status and/or exemptions IF passed in values are invalid
IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('F','H','M','B','S')) 
BEGIN
	SELECT @status = 'S'
END

IF @exempts IS NULL SELECT @exempts = 0

IF @ppds = 0
BEGIN
	SELECT @msg = ':  Missing # of Pay Periods per year!'
	RETURN 1
END
  
/* annualize subject amount */
SELECT @asubjamt = @subjamt * @ppds
SELECT @amt = @asubjamt

/* calculate exemptions (Table A) */
SELECT @exemptamt = 0
IF @status = 'F' --aka. Conn. filing status 'A'
BEGIN
	IF @asubjamt <= 24000 SELECT @exemptamt = 12000
	IF @asubjamt > 24000 AND @asubjamt <= 35000 
	BEGIN
		SELECT @exemptamt = FLOOR ((36000 - @asubjamt) / 1000) * 1000
	END
END
IF @status = 'H' --aka. Conn. filing status 'B'
BEGIN
	IF @asubjamt <= 38000 SELECT @exemptamt = 19000
	IF @asubjamt > 38000 AND @asubjamt <= 56000 
	BEGIN
		SELECT @exemptamt = FLOOR ((57000 - @asubjamt) / 1000) * 1000
	END
END
IF @status = 'M' --aka. Conn. filing status 'C'
BEGIN
	IF @asubjamt <= 48000 SELECT @exemptamt = 24000
	IF @asubjamt > 48000 AND @asubjamt <= 71000 
	BEGIN
		SELECT @exemptamt = FLOOR ((72000 - @asubjamt) / 1000) * 1000
	END
END
IF @status = 'S' --aka. Conn. filing status 'F'
BEGIN
	IF @asubjamt <= 26000 SELECT @exemptamt = 13000
	IF @asubjamt > 26000 AND @asubjamt <= 38000 
	BEGIN
		SELECT @exemptamt = FLOOR ((39000 - @asubjamt) / 1000) * 1000
	END
END

/* subtract exemptions */
SELECT @amt = @amt - @exemptamt
IF @amt < 0 SELECT @amt = 0

/* determine initial withholding amount (Table C) */
IF @status = 'F' OR @status = 'B' OR @status = 'S' --aka. Conn. filing status 'A', 'D', 'F'
BEGIN
	IF @amt <= 10000 SELECT @limit = 0, @baseamt = 0, @rate = .03
	IF @amt > 10000 AND @amt <= 50000 SELECT @limit = 10000, @baseamt = 300, @rate = .05
	IF @amt > 50000 AND @amt <= 100000 SELECT @limit = 50000, @baseamt = 2300, @rate = .055
	IF @amt > 100000 AND @amt <= 200000 SELECT @limit = 100000, @baseamt = 5050, @rate = .06
	IF @amt > 200000 AND @amt <= 250000 SELECT @limit = 200000, @baseamt = 11050, @rate = .065
	IF @amt > 250000 SELECT @limit = 250000, @baseamt = 14300, @rate = .067
END
IF @status = 'H' --aka. Conn. filing status 'B'
BEGIN
	IF @amt <= 16000 SELECT @limit = 0, @baseamt = 0, @rate = .03
	IF @amt > 16000 AND @amt <= 80000 SELECT @limit = 16000, @baseamt = 480, @rate = .05
	IF @amt > 80000 AND @amt <= 160000 SELECT @limit = 80000, @baseamt = 3680, @rate = .055
	IF @amt > 160000 AND @amt <= 320000 SELECT @limit = 160000, @baseamt = 8080, @rate = .06
	IF @amt > 320000 AND @amt <= 400000 SELECT @limit = 320000, @baseamt = 17680, @rate = .065
	IF @amt > 400000 SELECT @limit = 400000, @baseamt = 22880, @rate = .067
END
IF @status = 'M'  --aka. Conn. filing status 'C'
BEGIN
	IF @amt <= 20000 SELECT @limit = 0, @baseamt = 0, @rate = .03
	IF @amt > 20000 AND @amt <= 100000 SELECT @limit = 20000, @baseamt = 600, @rate = .05
	IF @amt > 100000 AND @amt <= 200000 SELECT @limit = 100000, @baseamt = 4600, @rate = .055
	IF @amt > 200000 AND @amt <= 400000 SELECT @limit = 200000, @baseamt = 10100, @rate = .06
	IF @amt > 400000 AND @amt <= 500000 SELECT @limit = 400000, @baseamt = 22100, @rate = .065
	IF @amt >= 500000 SELECT @limit = 500000, @baseamt = 28600, @rate = .067
END

SELECT @amt = ((@amt - @limit) * @rate) + @baseamt

-- compute 3% Phase-Out Add Back (Table D)
IF @status in ('F', 'B') --aka. Conn. filing status 'A', 'D'
BEGIN
	IF @asubjamt > 0 AND @asubjamt <= 50250 SELECT @addback = 0
	IF @asubjamt > 50250 AND @asubjamt <= 52750 SELECT @addback = 20
	IF @asubjamt > 52750 AND @asubjamt <= 55250 SELECT @addback = 40
	IF @asubjamt > 55250 AND @asubjamt <= 57750 SELECT @addback = 60
	IF @asubjamt > 57750 AND @asubjamt <= 60250 SELECT @addback = 80
	IF @asubjamt > 60250 AND @asubjamt <= 62750 SELECT @addback = 100
	IF @asubjamt > 62750 AND @asubjamt <= 65250 SELECT @addback = 120
	IF @asubjamt > 65250 AND @asubjamt <= 67750 SELECT @addback = 140
	IF @asubjamt > 67750 AND @asubjamt <= 70250 SELECT @addback = 160
	IF @asubjamt > 70250 AND @asubjamt <= 72750 SELECT @addback = 180
	IF @asubjamt > 72750 SELECT @addback = 200
END
IF @status = 'H' --aka. Conn. filing status 'B'
BEGIN
	IF @asubjamt > 0 AND @asubjamt <= 78500 SELECT @addback = 0
	IF @asubjamt > 78500 AND @asubjamt <= 82500 SELECT @addback = 32
	IF @asubjamt > 82500 AND @asubjamt <= 86500 SELECT @addback = 64
	IF @asubjamt > 86500 AND @asubjamt <= 90500 SELECT @addback = 96
	IF @asubjamt > 90500 AND @asubjamt <= 94500 SELECT @addback = 128
	IF @asubjamt > 94500 AND @asubjamt <= 98500 SELECT @addback = 160
	IF @asubjamt > 98500 AND @asubjamt <= 102500 SELECT @addback = 192
	IF @asubjamt > 102500 AND @asubjamt <= 106500 SELECT @addback = 224
	IF @asubjamt > 106500 AND @asubjamt <= 110500 SELECT @addback = 256
	IF @asubjamt > 110500 AND @asubjamt <= 114500 SELECT @addback = 288
	IF @asubjamt > 114500 SELECT @addback = 320
END
IF @status = 'M'  --aka. Conn. filing status 'C'
BEGIN
	IF @asubjamt > 0 AND @asubjamt <= 100500 SELECT @addback = 0
	IF @asubjamt > 100500 AND @asubjamt <= 105500 SELECT @addback = 40
	IF @asubjamt > 105500 AND @asubjamt <= 110500 SELECT @addback = 80
	IF @asubjamt > 110500 AND @asubjamt <= 115500 SELECT @addback = 120
	IF @asubjamt > 115500 AND @asubjamt <= 120500 SELECT @addback = 160
	IF @asubjamt > 120500 AND @asubjamt <= 125500 SELECT @addback = 200
	IF @asubjamt > 125500 AND @asubjamt <= 130500 SELECT @addback = 240
	IF @asubjamt > 130500 AND @asubjamt <= 135500 SELECT @addback = 280
	IF @asubjamt > 135500 AND @asubjamt <= 140500 SELECT @addback = 320
	IF @asubjamt > 140500 AND @asubjamt <= 145500 SELECT @addback = 360
	IF @asubjamt > 145500 SELECT @addback = 400
END
IF @status = 'S' --aka. Conn. filing status 'F'
BEGIN
	IF @asubjamt > 0 AND @asubjamt <= 56500 SELECT @addback = 0
	IF @asubjamt > 56500 AND @asubjamt <= 61500 SELECT @addback = 20
	IF @asubjamt > 61500 AND @asubjamt <= 66500 SELECT @addback = 40
	IF @asubjamt > 66500 AND @asubjamt <= 71500 SELECT @addback = 60
	IF @asubjamt > 71500 AND @asubjamt <= 76500 SELECT @addback = 80
	IF @asubjamt > 76500 AND @asubjamt <= 81500 SELECT @addback = 100
	IF @asubjamt > 81500 AND @asubjamt <= 86500 SELECT @addback = 120
	IF @asubjamt > 86500 AND @asubjamt <= 91500 SELECT @addback = 140
	IF @asubjamt > 91500 AND @asubjamt <= 96500 SELECT @addback = 160
	IF @asubjamt > 96500 AND @asubjamt <= 101500 SELECT @addback = 180
	IF @asubjamt > 101500 SELECT @addback = 200
END

SELECT @amt = @amt + @addback

-- compute additional recapture amount (Table E)
IF @status IN ('F', 'B', 'S') --aka. Conn. filing status 'A', 'D', 'F'
BEGIN
	IF @asubjamt >= 0 AND @asubjamt < 205000 SELECT @recaptureamt = 0
	IF @asubjamt >= 205000 AND @asubjamt < 210000 SELECT @recaptureamt = 75
	IF @asubjamt >= 210000 AND @asubjamt < 215000 SELECT @recaptureamt = 150
	IF @asubjamt >= 215000 AND @asubjamt < 220000 SELECT @recaptureamt = 225
	IF @asubjamt >= 220000 AND @asubjamt < 225000 SELECT @recaptureamt = 300
	IF @asubjamt >= 225000 AND @asubjamt < 230000 SELECT @recaptureamt = 375
	IF @asubjamt >= 230000 AND @asubjamt < 235000 SELECT @recaptureamt = 450
	IF @asubjamt >= 235000 AND @asubjamt < 240000 SELECT @recaptureamt = 525
	IF @asubjamt >= 240000 AND @asubjamt < 245000 SELECT @recaptureamt = 600
	IF @asubjamt >= 245000 AND @asubjamt < 250000 SELECT @recaptureamt = 675
	IF @asubjamt >= 250000 AND @asubjamt < 255000 SELECT @recaptureamt = 750
	IF @asubjamt >= 255000 AND @asubjamt < 260000 SELECT @recaptureamt = 825
	IF @asubjamt >= 260000 AND @asubjamt < 265000 SELECT @recaptureamt = 900
	IF @asubjamt >= 265000 AND @asubjamt < 270000 SELECT @recaptureamt = 975
	IF @asubjamt >= 270000 AND @asubjamt < 275000 SELECT @recaptureamt = 1050
	IF @asubjamt >= 275000 AND @asubjamt < 280000 SELECT @recaptureamt = 1125
	IF @asubjamt >= 280000 AND @asubjamt < 285000 SELECT @recaptureamt = 1200
	IF @asubjamt >= 285000 AND @asubjamt < 290000 SELECT @recaptureamt = 1275
	IF @asubjamt >= 290000 AND @asubjamt < 295000 SELECT @recaptureamt = 1350
	IF @asubjamt >= 295000 AND @asubjamt < 300000 SELECT @recaptureamt = 1425
	IF @asubjamt >= 300000 AND @asubjamt < 305000 SELECT @recaptureamt = 1500
	IF @asubjamt >= 305000 AND @asubjamt < 310000 SELECT @recaptureamt = 1575
	IF @asubjamt >= 310000 AND @asubjamt < 315000 SELECT @recaptureamt = 1650
	IF @asubjamt >= 315000 AND @asubjamt < 320000 SELECT @recaptureamt = 1725
	IF @asubjamt >= 320000 AND @asubjamt < 325000 SELECT @recaptureamt = 1800
	IF @asubjamt >= 325000 AND @asubjamt < 330000 SELECT @recaptureamt = 1875
	IF @asubjamt >= 330000 AND @asubjamt < 335000 SELECT @recaptureamt = 1950
	IF @asubjamt >= 335000 AND @asubjamt < 340000 SELECT @recaptureamt = 2025
	IF @asubjamt >= 340000 AND @asubjamt < 345000 SELECT @recaptureamt = 2100
	IF @asubjamt >= 345000 AND @asubjamt < 350000 SELECT @recaptureamt = 2175
	IF @asubjamt >= 350000 SELECT @recaptureamt = 2250
END
IF @status = 'H' --aka. Conn. filing status 'B'
BEGIN
	IF @asubjamt >= 0 AND @asubjamt < 328000 SELECT @recaptureamt = 0
	IF @asubjamt >= 328000 AND @asubjamt < 336000 SELECT @recaptureamt = 120
	IF @asubjamt >= 336000 AND @asubjamt < 344000 SELECT @recaptureamt = 240
	IF @asubjamt >= 344000 AND @asubjamt < 352000 SELECT @recaptureamt = 360
	IF @asubjamt >= 352000 AND @asubjamt < 360000 SELECT @recaptureamt = 480
	IF @asubjamt >= 360000 AND @asubjamt < 368000 SELECT @recaptureamt = 600
	IF @asubjamt >= 368000 AND @asubjamt < 376000 SELECT @recaptureamt = 720
	IF @asubjamt >= 376000 AND @asubjamt < 384000 SELECT @recaptureamt = 840
	IF @asubjamt >= 384000 AND @asubjamt < 392000 SELECT @recaptureamt = 960
	IF @asubjamt >= 392000 AND @asubjamt < 400000 SELECT @recaptureamt = 1080
	IF @asubjamt >= 400000 AND @asubjamt < 408000 SELECT @recaptureamt = 1200
	IF @asubjamt >= 408000 AND @asubjamt < 416000 SELECT @recaptureamt = 1320
	IF @asubjamt >= 416000 AND @asubjamt < 424000 SELECT @recaptureamt = 1440
	IF @asubjamt >= 424000 AND @asubjamt < 432000 SELECT @recaptureamt = 1560
	IF @asubjamt >= 432000 AND @asubjamt < 440000 SELECT @recaptureamt = 1680
	IF @asubjamt >= 440000 AND @asubjamt < 448000 SELECT @recaptureamt = 1800
	IF @asubjamt >= 448000 AND @asubjamt < 456000 SELECT @recaptureamt = 1920
	IF @asubjamt >= 456000 AND @asubjamt < 464000 SELECT @recaptureamt = 2040
	IF @asubjamt >= 464000 AND @asubjamt < 472000 SELECT @recaptureamt = 2160
	IF @asubjamt >= 472000 AND @asubjamt < 480000 SELECT @recaptureamt = 2280
	IF @asubjamt >= 480000 AND @asubjamt < 488000 SELECT @recaptureamt = 2400
	IF @asubjamt >= 488000 AND @asubjamt < 496000 SELECT @recaptureamt = 2520
	IF @asubjamt >= 496000 AND @asubjamt < 504000 SELECT @recaptureamt = 2640
	IF @asubjamt >= 504000 AND @asubjamt < 512000 SELECT @recaptureamt = 2760
	IF @asubjamt >= 512000 AND @asubjamt < 520000 SELECT @recaptureamt = 2880
	IF @asubjamt >= 520000 AND @asubjamt < 528000 SELECT @recaptureamt = 3000
	IF @asubjamt >= 528000 AND @asubjamt < 536000 SELECT @recaptureamt = 3120
	IF @asubjamt >= 536000 AND @asubjamt < 544000 SELECT @recaptureamt = 3240
	IF @asubjamt >= 544000 AND @asubjamt < 552000 SELECT @recaptureamt = 3360
	IF @asubjamt >= 552000 AND @asubjamt < 560000 SELECT @recaptureamt = 3480
	IF @asubjamt >= 560000 SELECT @recaptureamt = 3600
END
IF @status = 'M'  --aka. Conn. filing status 'C'
BEGIN
	IF @asubjamt >= 0 AND @asubjamt < 410000 SELECT @recaptureamt = 0
	IF @asubjamt >= 410000 AND @asubjamt < 420000 SELECT @recaptureamt = 150
	IF @asubjamt >= 420000 AND @asubjamt < 430000 SELECT @recaptureamt = 300
	IF @asubjamt >= 430000 AND @asubjamt < 440000 SELECT @recaptureamt = 450
	IF @asubjamt >= 440000 AND @asubjamt < 450000 SELECT @recaptureamt = 600
	IF @asubjamt >= 450000 AND @asubjamt < 460000 SELECT @recaptureamt = 750
	IF @asubjamt >= 460000 AND @asubjamt < 470000 SELECT @recaptureamt = 900
	IF @asubjamt >= 470000 AND @asubjamt < 480000 SELECT @recaptureamt = 1050
	IF @asubjamt >= 480000 AND @asubjamt < 490000 SELECT @recaptureamt = 1200
	IF @asubjamt >= 490000 AND @asubjamt < 500000 SELECT @recaptureamt = 1350
	IF @asubjamt >= 500000 AND @asubjamt < 510000 SELECT @recaptureamt = 1500
	IF @asubjamt >= 510000 AND @asubjamt < 520000 SELECT @recaptureamt = 1650
	IF @asubjamt >= 520000 AND @asubjamt < 530000 SELECT @recaptureamt = 1800
	IF @asubjamt >= 530000 AND @asubjamt < 540000 SELECT @recaptureamt = 1950
	IF @asubjamt >= 540000 AND @asubjamt < 550000 SELECT @recaptureamt = 2100
	IF @asubjamt >= 550000 AND @asubjamt < 560000 SELECT @recaptureamt = 2250
	IF @asubjamt >= 560000 AND @asubjamt < 570000 SELECT @recaptureamt = 2400
	IF @asubjamt >= 570000 AND @asubjamt < 580000 SELECT @recaptureamt = 2550
	IF @asubjamt >= 580000 AND @asubjamt < 590000 SELECT @recaptureamt = 2700
	IF @asubjamt >= 590000 AND @asubjamt < 600000 SELECT @recaptureamt = 2850
	IF @asubjamt >= 600000 AND @asubjamt < 610000 SELECT @recaptureamt = 3000
	IF @asubjamt >= 610000 AND @asubjamt < 620000 SELECT @recaptureamt = 3150
	IF @asubjamt >= 620000 AND @asubjamt < 630000 SELECT @recaptureamt = 3300
	IF @asubjamt >= 630000 AND @asubjamt < 640000 SELECT @recaptureamt = 3450
	IF @asubjamt >= 640000 AND @asubjamt < 650000 SELECT @recaptureamt = 3600
	IF @asubjamt >= 650000 AND @asubjamt < 660000 SELECT @recaptureamt = 3750
	IF @asubjamt >= 660000 AND @asubjamt < 670000 SELECT @recaptureamt = 3900
	IF @asubjamt >= 670000 AND @asubjamt < 680000 SELECT @recaptureamt = 4050
	IF @asubjamt >= 680000 AND @asubjamt < 690000 SELECT @recaptureamt = 4200
	IF @asubjamt >= 690000 AND @asubjamt < 700000 SELECT @recaptureamt = 4350
	IF @asubjamt >= 700000 SELECT @recaptureamt = 4500
END

SELECT @amt = @amt + @recaptureamt

/* calculate personal tax credits (Table B) */
SELECT @pcredits = 0
IF @status = 'F' --aka. Conn. filing status 'A'
BEGIN
	IF @asubjamt > 12000 AND @asubjamt <= 15000 SELECT @pcredits = .75
	IF @asubjamt > 15000 AND @asubjamt <= 15500 SELECT @pcredits = .7
	IF @asubjamt > 15500 AND @asubjamt <= 16000 SELECT @pcredits = .65
	IF @asubjamt > 16000 AND @asubjamt <= 16500 SELECT @pcredits = .6
	IF @asubjamt > 16500 AND @asubjamt <= 17000 SELECT @pcredits = .55
	IF @asubjamt > 17000 AND @asubjamt <= 17500 SELECT @pcredits = .5
	IF @asubjamt > 17500 AND @asubjamt <= 18000 SELECT @pcredits = .45
	IF @asubjamt > 18000 AND @asubjamt <= 18500 SELECT @pcredits = .4
	IF @asubjamt > 18500 AND @asubjamt <= 20000 SELECT @pcredits = .35
	IF @asubjamt > 20000 AND @asubjamt <= 20500 SELECT @pcredits = .3
	IF @asubjamt > 20500 AND @asubjamt <= 21000 SELECT @pcredits = .25
	IF @asubjamt > 21000 AND @asubjamt <= 21500 SELECT @pcredits = .2
	IF @asubjamt > 21500 AND @asubjamt <= 25000 SELECT @pcredits = .15
	IF @asubjamt > 25000 AND @asubjamt <= 25500 SELECT @pcredits = .14
	IF @asubjamt > 25500 AND @asubjamt <= 26000 SELECT @pcredits = .13
	IF @asubjamt > 26000 AND @asubjamt <= 26500 SELECT @pcredits = .12
	IF @asubjamt > 26500 AND @asubjamt <= 27000 SELECT @pcredits = .11
	IF @asubjamt > 27000 AND @asubjamt <= 48000 SELECT @pcredits = .1
	IF @asubjamt > 48000 AND @asubjamt <= 48500 SELECT @pcredits = .09
	IF @asubjamt > 48500 AND @asubjamt <= 49000 SELECT @pcredits = .08
	IF @asubjamt > 49000 AND @asubjamt <= 49500 SELECT @pcredits = .07
	IF @asubjamt > 49500 AND @asubjamt <= 50000 SELECT @pcredits = .06
	IF @asubjamt > 50000 AND @asubjamt <= 50500 SELECT @pcredits = .05
	IF @asubjamt > 50500 AND @asubjamt <= 51000 SELECT @pcredits = .04
	IF @asubjamt > 51000 AND @asubjamt <= 51500 SELECT @pcredits = .03
	IF @asubjamt > 51500 AND @asubjamt <= 52000 SELECT @pcredits = .02
	IF @asubjamt > 52000 AND @asubjamt <= 52500 SELECT @pcredits = .01
	IF @asubjamt > 52500 SELECT @pcredits = 0
END
IF @status = 'H' --aka. Conn. filing status 'B'
BEGIN
	IF @asubjamt > 19000 AND @asubjamt <= 24000 SELECT @pcredits = .75
	IF @asubjamt > 24000 AND @asubjamt <= 24500 SELECT @pcredits = .7
	IF @asubjamt > 24500 AND @asubjamt <= 25000 SELECT @pcredits = .65
	IF @asubjamt > 25000 AND @asubjamt <= 25500 SELECT @pcredits = .6
	IF @asubjamt > 25500 AND @asubjamt <= 26000 SELECT @pcredits = .55
	IF @asubjamt > 26000 AND @asubjamt <= 26500 SELECT @pcredits = .5
	IF @asubjamt > 26500 AND @asubjamt <= 27000 SELECT @pcredits = .45
	IF @asubjamt > 27000 AND @asubjamt <= 27500 SELECT @pcredits = .4
	IF @asubjamt > 27500 AND @asubjamt <= 34000 SELECT @pcredits = .35
	IF @asubjamt > 34000 AND @asubjamt <= 34500 SELECT @pcredits = .3
	IF @asubjamt > 34500 AND @asubjamt <= 35000 SELECT @pcredits = .25
	IF @asubjamt > 35000 AND @asubjamt <= 35500 SELECT @pcredits = .2
	IF @asubjamt > 35500 AND @asubjamt <= 44000 SELECT @pcredits = .15
	IF @asubjamt > 44000 AND @asubjamt <= 44500 SELECT @pcredits = .14
	IF @asubjamt > 44500 AND @asubjamt <= 45000 SELECT @pcredits = .13
	IF @asubjamt > 45000 AND @asubjamt <= 45500 SELECT @pcredits = .12
	IF @asubjamt > 45500 AND @asubjamt <= 46000 SELECT @pcredits = .11
	IF @asubjamt > 46000 AND @asubjamt <= 74000 SELECT @pcredits = .1
	IF @asubjamt > 74000 AND @asubjamt <= 74500 SELECT @pcredits = .09
	IF @asubjamt > 74500 AND @asubjamt <= 75000 SELECT @pcredits = .08
	IF @asubjamt > 75000 AND @asubjamt <= 75500 SELECT @pcredits = .07
	IF @asubjamt > 75500 AND @asubjamt <= 76000 SELECT @pcredits = .06
	IF @asubjamt > 76000 AND @asubjamt <= 76500 SELECT @pcredits = .05
	IF @asubjamt > 76500 AND @asubjamt <= 77000 SELECT @pcredits = .04
	IF @asubjamt > 77000 AND @asubjamt <= 77500 SELECT @pcredits = .03
	IF @asubjamt > 77500 AND @asubjamt <= 78000 SELECT @pcredits = .02
	IF @asubjamt > 78000 AND @asubjamt <= 78500 SELECT @pcredits = .01
	IF @asubjamt > 78500 SELECT @pcredits = 0
END
IF @status = 'M'  --aka. Conn. filing status 'C'
BEGIN
	IF @asubjamt > 24000 AND @asubjamt <= 30000 SELECT @pcredits = .75
	IF @asubjamt > 30000 AND @asubjamt <= 30500 SELECT @pcredits = .7
	IF @asubjamt > 30500 AND @asubjamt <= 31000 SELECT @pcredits = .65
	IF @asubjamt > 31000 AND @asubjamt <= 31500 SELECT @pcredits = .6
	IF @asubjamt > 31500 AND @asubjamt <= 35000 SELECT @pcredits = .55
	IF @asubjamt > 32000 AND @asubjamt <= 32500 SELECT @pcredits = .5
	IF @asubjamt > 32500 AND @asubjamt <= 33000 SELECT @pcredits = .45
	IF @asubjamt > 33000 AND @asubjamt <= 33500 SELECT @pcredits = .4
	IF @asubjamt > 33500 AND @asubjamt <= 40000 SELECT @pcredits = .35
	IF @asubjamt > 40000 AND @asubjamt <= 40500 SELECT @pcredits = .3
	IF @asubjamt > 40500 AND @asubjamt <= 41000 SELECT @pcredits = .25
	IF @asubjamt > 41000 AND @asubjamt <= 41500 SELECT @pcredits = .2
	IF @asubjamt > 41500 AND @asubjamt <= 50000 SELECT @pcredits = .15
	IF @asubjamt > 50000 AND @asubjamt <= 50500 SELECT @pcredits = .14
	IF @asubjamt > 50500 AND @asubjamt <= 51000 SELECT @pcredits = .13
	IF @asubjamt > 51000 AND @asubjamt <= 51500 SELECT @pcredits = .12
	IF @asubjamt > 51500 AND @asubjamt <= 52000 SELECT @pcredits = .11
	IF @asubjamt > 52000 AND @asubjamt <= 96000 SELECT @pcredits = .1
	IF @asubjamt > 96000 AND @asubjamt <= 96500 SELECT @pcredits = .09
	IF @asubjamt > 96500 AND @asubjamt <= 97000 SELECT @pcredits = .08
	IF @asubjamt > 97000 AND @asubjamt <= 97500 SELECT @pcredits = .07
	IF @asubjamt > 97500 AND @asubjamt <= 98000 SELECT @pcredits = .06
	IF @asubjamt > 98000 AND @asubjamt <= 98500 SELECT @pcredits = .05
	IF @asubjamt > 98500 AND @asubjamt <= 99000 SELECT @pcredits = .04
	IF @asubjamt > 99000 AND @asubjamt <= 99500 SELECT @pcredits = .03
	IF @asubjamt > 99500 AND @asubjamt <= 100000 SELECT @pcredits = .02
	IF @asubjamt > 100000 AND @asubjamt <= 100500 SELECT @pcredits = .01
	IF @asubjamt > 100500 SELECT @pcredits = 0
END
IF @status = 'S' --aka. Conn. filing status 'F'
BEGIN
	IF @asubjamt > 13000 AND @asubjamt <= 16300 SELECT @pcredits = .75
	IF @asubjamt > 16300 AND @asubjamt <= 16800 SELECT @pcredits = .7
	IF @asubjamt > 16800 AND @asubjamt <= 17300 SELECT @pcredits = .65
	IF @asubjamt > 17300 AND @asubjamt <= 17800 SELECT @pcredits = .6
	IF @asubjamt > 17800 AND @asubjamt <= 18300 SELECT @pcredits = .55
	IF @asubjamt > 18300 AND @asubjamt <= 18800 SELECT @pcredits = .5
	IF @asubjamt > 18800 AND @asubjamt <= 19300 SELECT @pcredits = .45
	IF @asubjamt > 19300 AND @asubjamt <= 19800 SELECT @pcredits = .4
	IF @asubjamt > 19800 AND @asubjamt <= 21700 SELECT @pcredits = .35
	IF @asubjamt > 21700 AND @asubjamt <= 22200 SELECT @pcredits = .3
	IF @asubjamt > 22200 AND @asubjamt <= 22700 SELECT @pcredits = .25
	IF @asubjamt > 22700 AND @asubjamt <= 23200 SELECT @pcredits = .2
	IF @asubjamt > 23200 AND @asubjamt <= 27100 SELECT @pcredits = .15
	IF @asubjamt > 27100 AND @asubjamt <= 27600 SELECT @pcredits = .14
	IF @asubjamt > 27600 AND @asubjamt <= 28100 SELECT @pcredits = .13
	IF @asubjamt > 28100 AND @asubjamt <= 28600 SELECT @pcredits = .12
	IF @asubjamt > 28600 AND @asubjamt <= 29100 SELECT @pcredits = .11
	IF @asubjamt > 29100 AND @asubjamt <= 52000 SELECT @pcredits = .10
	IF @asubjamt > 52000 AND @asubjamt <= 52500 SELECT @pcredits = .09
	IF @asubjamt > 52500 AND @asubjamt <= 53000 SELECT @pcredits = .08
	IF @asubjamt > 53000 AND @asubjamt <= 53500 SELECT @pcredits = .07
	IF @asubjamt > 53500 AND @asubjamt <= 54000 SELECT @pcredits = .06
	IF @asubjamt > 54000 AND @asubjamt <= 54500 SELECT @pcredits = .05
	IF @asubjamt > 54500 AND @asubjamt <= 55000 SELECT @pcredits = .04
	IF @asubjamt > 55000 AND @asubjamt <= 55500 SELECT @pcredits = .03
	IF @asubjamt > 55500 AND @asubjamt <= 56000 SELECT @pcredits = .02
	IF @asubjamt > 56000 AND @asubjamt <= 56500 SELECT @pcredits = .01
	IF @asubjamt > 56500 SELECT @pcredits = 0
END

/* adjust for personal tax credits */
SELECT @amt = @amt * (1 - @pcredits)

/* finish calculation */
SELECT @amt = @amt / @ppds


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspPRCTT112] TO [public]
GO
