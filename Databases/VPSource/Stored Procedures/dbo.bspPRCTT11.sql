SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRCTT11]    Script Date: 01/03/2008 16:16:03 ******/
  CREATE proc [dbo].[bspPRCTT11]
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
(@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
   @amt bDollar = 0 output, @msg varchar(255) = null output)
   
  AS
  SET NOCOUNT ON
  
  DECLARE @rcode int, @asubjamt bDollar, @exemptamt bDollar, @limit bDollar,
  @baseamt bDollar, @pcredits bDollar, @procname varchar(30), @rate bRate
  
  SELECT @rcode = 0, @procname = 'bspPRCTT11'
 
  -- #26244 set default status and/or exemptions IF passed in values are invalid
  IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('F','H','M','B','S')) SELECT @status = 'S'
  IF @exempts IS NULL SELECT @exempts = 0
 
  IF @ppds = 0
  	BEGIN
  	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  	RETURN @rcode
  	END
  
  /* annualize subject amount */
  SELECT @asubjamt = @subjamt * @ppds
  SELECT @amt = @asubjamt
  
  /* calculate exemptions */
  SELECT @exemptamt = 0
  IF @status = 'F' --aka. Conn. filing status 'A'
	BEGIN
	IF @asubjamt <= 24000 SELECT @exemptamt = 12000
	IF @asubjamt > 24000 AND @asubjamt <= 35000 SELECT @exemptamt = FLOOR ((36000 - @asubjamt) / 1000) * 1000
	END
  IF @status = 'H' --aka. Conn. filing status 'B'
	BEGIN
	IF @asubjamt <= 38000 SELECT @exemptamt = 19000
	IF @asubjamt > 38000 AND @asubjamt <= 56000 SELECT @exemptamt = FLOOR ((57000 - @asubjamt) / 1000) * 1000
	END
  IF @status = 'M' --aka. Conn. filing status 'C'
	BEGIN
	IF @asubjamt <= 48000 SELECT @exemptamt = 24000
	IF @asubjamt > 48000 AND @asubjamt <= 71000 SELECT @exemptamt = FLOOR ((72000 - @asubjamt) / 1000) * 1000
  	END
  IF @status = 'S' --aka. Conn. filing status 'F'
	BEGIN
	IF @asubjamt <= 26000 SELECT @exemptamt = 13500
	IF @asubjamt >= 26000 AND @asubjamt <= 38000 SELECT @exemptamt = FLOOR ((39000 - @asubjamt) / 1000) * 1000
	END
  
  /* subtract exemptions */
  SELECT @amt = @amt - @exemptamt
  IF @amt < 0 SELECT @amt = 0
  
  /* determine initial withholding amount */
  IF @status = 'F' OR @status = 'B' OR @status = 'S' 
	BEGIN
	IF @amt <= 10000 SELECT @limit = 0, @baseamt = 0, @rate = .03
	IF @amt > 10000 AND @amt <= 500000 SELECT @limit = 10000, @baseamt = 300, @rate = .05
    IF @amt > 500000 SELECT @limit = 500000, @baseamt = 24800, @rate = .065
	END
  IF @status = 'H'
	BEGIN
	IF @amt <= 16000 SELECT @limit = 0, @baseamt = 0, @rate = .03
	IF @amt > 16000 AND @amt <= 800000 SELECT @limit = 16000, @baseamt = 480, @rate = .05
	IF @amt > 800000 SELECT @limit = 800000, @baseamt = 39680, @rate = .065
	END
  IF @status = 'M' 
	BEGIN
	IF @amt <= 20000 SELECT @limit = 0, @baseamt = 0, @rate = .03
	IF @amt > 20000 AND @amt <= 1000000 SELECT @limit = 20000, @baseamt = 600, @rate = .05
	IF @amt >= 1000000 SELECT @limit = 1000000, @baseamt = 49600, @rate = .065
	END
  
  SELECT @amt = ((@amt - @limit) * @rate) + @baseamt
  
  /* calculate personal tax credits */
  SELECT @pcredits = 0
  IF @status = 'F'
  	BEGIN
  	 IF @asubjamt > 12000 AND @asubjamt <=15000 SELECT @pcredits = .75
  	 IF @asubjamt > 15000 AND @asubjamt <=15500 SELECT @pcredits = .7
  	 IF @asubjamt > 15500 AND @asubjamt <=16000 SELECT @pcredits = .65
  	 IF @asubjamt > 16000 AND @asubjamt <=16500 SELECT @pcredits = .6
  	 IF @asubjamt > 16500 AND @asubjamt <=17000 SELECT @pcredits = .55
  	 IF @asubjamt > 17000 AND @asubjamt <=17500 SELECT @pcredits = .5
  	 IF @asubjamt > 17500 AND @asubjamt <=18000 SELECT @pcredits = .45
  	 IF @asubjamt > 18000 AND @asubjamt <=18500 SELECT @pcredits = .4
  	 IF @asubjamt > 18500 AND @asubjamt <=20000 SELECT @pcredits = .35
  	 IF @asubjamt > 20000 AND @asubjamt <=20500 SELECT @pcredits = .3
  	 IF @asubjamt > 20500 AND @asubjamt <=21000 SELECT @pcredits = .25
  	 IF @asubjamt > 21000 AND @asubjamt <=21500 SELECT @pcredits = .2
  	 IF @asubjamt > 21500 AND @asubjamt <=25000 SELECT @pcredits = .15
  	 IF @asubjamt > 25000 AND @asubjamt <=25500 SELECT @pcredits = .14
  	 IF @asubjamt > 25500 AND @asubjamt <=26000 SELECT @pcredits = .13
  	 IF @asubjamt > 26000 AND @asubjamt <=26500 SELECT @pcredits = .12
  	 IF @asubjamt > 26500 AND @asubjamt <=27000 SELECT @pcredits = .11
  	 IF @asubjamt > 27000 AND @asubjamt <=48000 SELECT @pcredits = .1
  	 IF @asubjamt > 48000 AND @asubjamt <=48500 SELECT @pcredits = .09
  	 IF @asubjamt > 48500 AND @asubjamt <=49000 SELECT @pcredits = .08
  	 IF @asubjamt > 49000 AND @asubjamt <=49500 SELECT @pcredits = .07
  	 IF @asubjamt > 49500 AND @asubjamt <=50000 SELECT @pcredits = .06
  	 IF @asubjamt > 50000 AND @asubjamt <=50500 SELECT @pcredits = .05
  	 IF @asubjamt > 50500 AND @asubjamt <=51000 SELECT @pcredits = .04
  	 IF @asubjamt > 51000 AND @asubjamt <=51500 SELECT @pcredits = .03
  	 IF @asubjamt > 51500 AND @asubjamt <=52000 SELECT @pcredits = .02
  	 IF @asubjamt > 52000 AND @asubjamt <=52500 SELECT @pcredits = .01
  	 IF @asubjamt > 52500 SELECT @pcredits = 0
  	END
  
  IF @status = 'H'
  	BEGIN
  	 IF @asubjamt > 19000 AND @asubjamt <=24000 SELECT @pcredits = .75
  	 IF @asubjamt > 24000 AND @asubjamt <=24500 SELECT @pcredits = .7
  	 IF @asubjamt > 24500 AND @asubjamt <=25000 SELECT @pcredits = .65
  	 IF @asubjamt > 25000 AND @asubjamt <=25500 SELECT @pcredits = .6
  	 IF @asubjamt > 25500 AND @asubjamt <=26000 SELECT @pcredits = .55
  	 IF @asubjamt > 26000 AND @asubjamt <=26500 SELECT @pcredits = .5
  	 IF @asubjamt > 26500 AND @asubjamt <=27000 SELECT @pcredits = .45
  	 IF @asubjamt > 27000 AND @asubjamt <=27500 SELECT @pcredits = .4
  	 IF @asubjamt > 27500 AND @asubjamt <=34000 SELECT @pcredits = .35
  	 IF @asubjamt > 34000 AND @asubjamt <=34500 SELECT @pcredits = .3
  	 IF @asubjamt > 34500 AND @asubjamt <=35000 SELECT @pcredits = .25
  	 IF @asubjamt > 35000 AND @asubjamt <=35500 SELECT @pcredits = .2
  	 IF @asubjamt > 35500 AND @asubjamt <=44000 SELECT @pcredits = .15
  	 IF @asubjamt > 44000 AND @asubjamt <=44500 SELECT @pcredits = .14
  	 IF @asubjamt > 44500 AND @asubjamt <=45000 SELECT @pcredits = .13
  	 IF @asubjamt > 45000 AND @asubjamt <=45500 SELECT @pcredits = .12
  	 IF @asubjamt > 45500 AND @asubjamt <=46000 SELECT @pcredits = .11
  	 IF @asubjamt > 46000 AND @asubjamt <=74000 SELECT @pcredits = .1
  	 IF @asubjamt > 74000 AND @asubjamt <=74500 SELECT @pcredits = .09
  	 IF @asubjamt > 74500 AND @asubjamt <=75000 SELECT @pcredits = .08
  	 IF @asubjamt > 75000 AND @asubjamt <=75500 SELECT @pcredits = .07
  	 IF @asubjamt > 75500 AND @asubjamt <=76000 SELECT @pcredits = .06
  	 IF @asubjamt > 76000 AND @asubjamt <=76500 SELECT @pcredits = .05
  	 IF @asubjamt > 76500 AND @asubjamt <=77000 SELECT @pcredits = .04
  	 IF @asubjamt > 77000 AND @asubjamt <=77500 SELECT @pcredits = .03
  	 IF @asubjamt > 77500 AND @asubjamt <=78000 SELECT @pcredits = .02
  	 IF @asubjamt > 78000 AND @asubjamt <=78500 SELECT @pcredits = .01
  	 IF @asubjamt > 78500 SELECT @pcredits = 0
  	END
  
  IF @status = 'M'
  	BEGIN
  	 IF @asubjamt BETWEEN (24000 + .01) AND 30000 SELECT @pcredits = .75
  	 IF @asubjamt BETWEEN (30000 + .01) AND 30500 SELECT @pcredits = .7
  	 IF @asubjamt BETWEEN (30500 + .01) AND 31000 SELECT @pcredits = .65
  	 IF @asubjamt BETWEEN (31000 + .01) AND 31500 SELECT @pcredits = .6
  	 IF @asubjamt BETWEEN (31500 + .01) AND 35000 SELECT @pcredits = .55
  	 IF @asubjamt BETWEEN (32000 + .01) AND 32500 SELECT @pcredits = .5
  	 IF @asubjamt BETWEEN (32500 + .01) AND 33000 SELECT @pcredits = .45
  	 IF @asubjamt BETWEEN (33000 + .01) AND 33500 SELECT @pcredits = .4
  	 IF @asubjamt BETWEEN (33500 + .01) AND 40000 SELECT @pcredits = .35
  	 IF @asubjamt BETWEEN (40000 + .01) AND 40500 SELECT @pcredits = .3
  	 IF @asubjamt BETWEEN (40500 + .01) AND 41000 SELECT @pcredits = .25
  	 IF @asubjamt BETWEEN (41000 + .01) AND 41500 SELECT @pcredits = .2
  	 IF @asubjamt BETWEEN (41500 + .01) AND 50000 SELECT @pcredits = .15
  	 IF @asubjamt BETWEEN (50000 + .01) AND 50500 SELECT @pcredits = .14
  	 IF @asubjamt BETWEEN (50500 + .01) AND 51000 SELECT @pcredits = .13
  	 IF @asubjamt BETWEEN (51000 + .01) AND 51500 SELECT @pcredits = .12
  	 IF @asubjamt BETWEEN (51500 + .01) AND 52000 SELECT @pcredits = .11
  	 IF @asubjamt BETWEEN (52000 + .01) AND 96000 SELECT @pcredits = .1
  	 IF @asubjamt BETWEEN (96000 + .01) AND 96500 SELECT @pcredits = .09
  	 IF @asubjamt BETWEEN (96500 + .01) AND 97000 SELECT @pcredits = .08
  	 IF @asubjamt BETWEEN (97000 + .01) AND 97500 SELECT @pcredits = .07
  	 IF @asubjamt BETWEEN (97500 + .01) AND 98000 SELECT @pcredits = .06
  	 IF @asubjamt BETWEEN (98000 + .01) AND 98500 SELECT @pcredits = .05
  	 IF @asubjamt BETWEEN (98500 + .01) AND 99000 SELECT @pcredits = .04
  	 IF @asubjamt BETWEEN (99000 + .01) AND 99500 SELECT @pcredits = .03
  	 IF @asubjamt BETWEEN (99500 + .01) AND 100000 SELECT @pcredits = .02
  	 IF @asubjamt BETWEEN (100000 + .01) AND 100500 SELECT @pcredits = .01
  	 IF @asubjamt > 100500 SELECT @pcredits = 0
  	END
  
  IF @status = 'S'
	BEGIN
	IF @asubjamt BETWEEN (13000 + .01) AND 16300 SELECT @pcredits = .75
	IF @asubjamt BETWEEN (16300 + .01) AND 16800 SELECT @pcredits = .7
	IF @asubjamt BETWEEN (16800 + .01) AND 17300 SELECT @pcredits = .65
	IF @asubjamt BETWEEN (17300 + .01) AND 17800 SELECT @pcredits = .6
	IF @asubjamt BETWEEN (17800 + .01) AND 18300 SELECT @pcredits = .55
	IF @asubjamt BETWEEN (18300 + .01) AND 18800 SELECT @pcredits = .5
	IF @asubjamt BETWEEN (18800 + .01) AND 19300 SELECT @pcredits = .45
	IF @asubjamt BETWEEN (19300 + .01) AND 19800 SELECT @pcredits = .4
	IF @asubjamt BETWEEN (19800 + .01) AND 21700 SELECT @pcredits = .35
	IF @asubjamt BETWEEN (21700 + .01) AND 22200 SELECT @pcredits = .3
	IF @asubjamt BETWEEN (22200 + .01) AND 22700 SELECT @pcredits = .25
	IF @asubjamt BETWEEN (22700 + .01) AND 23200 SELECT @pcredits = .2
	IF @asubjamt BETWEEN (23200 + .01) AND 27100 SELECT @pcredits = .15
	IF @asubjamt BETWEEN (27100 + .01) AND 27600 SELECT @pcredits = .14
	IF @asubjamt BETWEEN (27600 + .01) AND 28100 SELECT @pcredits = .13
	IF @asubjamt BETWEEN (28100 + .01) AND 28600 SELECT @pcredits = .12
	IF @asubjamt BETWEEN (28600 + .01) AND 29100 SELECT @pcredits = .11
	IF @asubjamt BETWEEN (29100 + .01) AND 52000 SELECT @pcredits = .10
	IF @asubjamt BETWEEN (52000 + .01) AND 52500 SELECT @pcredits = .09
	IF @asubjamt BETWEEN (52500 + .01) AND 53000 SELECT @pcredits = .08
	IF @asubjamt BETWEEN (53000 + .01) AND 53500 SELECT @pcredits = .07
	IF @asubjamt BETWEEN (53500 + .01) AND 54000 SELECT @pcredits = .06
	IF @asubjamt BETWEEN (54000 + .01) AND 54500 SELECT @pcredits = .05
	IF @asubjamt BETWEEN (54500 + .01) AND 55000 SELECT @pcredits = .04
	IF @asubjamt BETWEEN (55000 + .01) AND 55500 SELECT @pcredits = .03
	IF @asubjamt BETWEEN (55500 + .01) AND 56000 SELECT @pcredits = .02
	IF @asubjamt BETWEEN (56000 + .01) AND 56500 SELECT @pcredits = .01
	IF @asubjamt > 56500 SELECT @pcredits = 0
	END
  
  /* adjust for personal tax credits */
  SELECT @amt = @amt * (1 - @pcredits)
  
  /* finish calculation */
  SELECT @amt = @amt / @ppds
  
  
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCTT11] TO [public]
GO
