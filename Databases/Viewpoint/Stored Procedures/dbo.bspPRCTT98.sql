SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCTT98    Script Date: 8/28/99 9:33:14 AM ******/
   CREATE  proc [dbo].[bspPRCTT98]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY:	GG 8/11/98
   *				EN 10/7/02 - issue 18877 change double quotes to single
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
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
    @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @asubjamt bDollar, @exemptamt bDollar, @limit bDollar,
   @baseamt bDollar, @pcredits bDollar, @procname varchar(30)
   
   select @rcode = 0, @procname = 'bspPRCTT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize subject amount */
   select @asubjamt = @subjamt * @ppds
   select @amt = @asubjamt
   
   /* calculate exemptions */
   select @exemptamt = 0
   if @status = 'S'
   	begin
   	 if @asubjamt >= 24000 select @exemptamt = floor ((36000 - @asubjamt) / 1000) * 1000
   	 else select @exemptamt = 12000
   	end
   if @status = 'H'
   	begin
   	 if @asubjamt >= 38000  select @exemptamt = floor ((57000 - @asubjamt) / 1000) * 1000	 
   	 else select @exemptamt = 19000
   	end
   if @status = 'M'
   	begin
   	 if @asubjamt >= 48000  select @exemptamt = floor ((72000 - @asubjamt) / 1000) * 1000
   	 else select @exemptamt = 24000
   	end
   
   /* subtract exemptions */	 
   select @amt = @amt - @exemptamt
   if @amt < 0 select @amt = 0
   
   /* determine initial withholding amount */
   if @status = 'S' or @status = 'F' select @limit = 10000, @baseamt = 300
   if @status = 'H' select @limit = 16000, @baseamt = 480
   if @status = 'M' select @limit = 20000, @baseamt = 600
   
   if @amt <= @limit select @amt = @amt * .03
   if @amt > @limit select @amt = (@amt - @limit) * .045 + @baseamt
   
   /* calculate personal tax credits */
   select @pcredits = 0
   if @status = 'S'
   	begin
   	 if @asubjamt > 12000 and @asubjamt <=15000 select @pcredits = .75
   	 if @asubjamt > 15000 and @asubjamt <=15500 select @pcredits = .7
   	 if @asubjamt > 15500 and @asubjamt <=16000 select @pcredits = .65
   	 if @asubjamt > 16000 and @asubjamt <=16500 select @pcredits = .6
   	 if @asubjamt > 16500 and @asubjamt <=17000 select @pcredits = .55
   	 if @asubjamt > 17000 and @asubjamt <=17500 select @pcredits = .5
   	 if @asubjamt > 17500 and @asubjamt <=18000 select @pcredits = .45
   	 if @asubjamt > 18000 and @asubjamt <=18500 select @pcredits = .4
   	 if @asubjamt > 18500 and @asubjamt <=20000 select @pcredits = .35
   	 if @asubjamt > 20000 and @asubjamt <=20500 select @pcredits = .3
   	 if @asubjamt > 20500 and @asubjamt <=21000 select @pcredits = .25
   	 if @asubjamt > 21000 and @asubjamt <=21500 select @pcredits = .2
   	 if @asubjamt > 21500 and @asubjamt <=25000 select @pcredits = .15
   	 if @asubjamt > 25000 and @asubjamt <=25500 select @pcredits = .14
   	 if @asubjamt > 25500 and @asubjamt <=26000 select @pcredits = .13
   	 if @asubjamt > 26000 and @asubjamt <=26500 select @pcredits = .12
   	 if @asubjamt > 26500 and @asubjamt <=27000 select @pcredits = .11
   	 if @asubjamt > 27000 and @asubjamt <=48000 select @pcredits = .1
   	 if @asubjamt > 48000 and @asubjamt <=48500 select @pcredits = .09
   	 if @asubjamt > 48500 and @asubjamt <=49000 select @pcredits = .08
   	 if @asubjamt > 49000 and @asubjamt <=49500 select @pcredits = .07
   	 if @asubjamt > 49500 and @asubjamt <=50000 select @pcredits = .06
   	 if @asubjamt > 50000 and @asubjamt <=50500 select @pcredits = .05
   	 if @asubjamt > 50500 and @asubjamt <=51000 select @pcredits = .04
   	 if @asubjamt > 51000 and @asubjamt <=51500 select @pcredits = .03
   	 if @asubjamt > 51500 and @asubjamt <=52000 select @pcredits = .02
   	 if @asubjamt > 52000 and @asubjamt <=52500 select @pcredits = .01
   	 if @asubjamt > 52500 select @pcredits = 0
   	end
   	
   if @status = 'H'
   	begin
   	 if @asubjamt > 19000 and @asubjamt <=24000 select @pcredits = .75
   	 if @asubjamt > 24000 and @asubjamt <=24500 select @pcredits = .7
   	 if @asubjamt > 24500 and @asubjamt <=25000 select @pcredits = .65
   	 if @asubjamt > 25000 and @asubjamt <=25500 select @pcredits = .6
   	 if @asubjamt > 25500 and @asubjamt <=26000 select @pcredits = .55
   	 if @asubjamt > 26000 and @asubjamt <=26500 select @pcredits = .5
   	 if @asubjamt > 26500 and @asubjamt <=27000 select @pcredits = .45
   	 if @asubjamt > 27000 and @asubjamt <=27500 select @pcredits = .4
   	 if @asubjamt > 27500 and @asubjamt <=34000 select @pcredits = .35
   	 if @asubjamt > 34000 and @asubjamt <=34500 select @pcredits = .3
   	 if @asubjamt > 34500 and @asubjamt <=35000 select @pcredits = .25
   	 if @asubjamt > 35000 and @asubjamt <=35500 select @pcredits = .2
   	 if @asubjamt > 35500 and @asubjamt <=44000 select @pcredits = .15
   	 if @asubjamt > 44000 and @asubjamt <=44500 select @pcredits = .14
   	 if @asubjamt > 44500 and @asubjamt <=45000 select @pcredits = .13
   	 if @asubjamt > 45000 and @asubjamt <=45500 select @pcredits = .12
   	 if @asubjamt > 45500 and @asubjamt <=46000 select @pcredits = .11
   	 if @asubjamt > 46000 and @asubjamt <=74000 select @pcredits = .1
   	 if @asubjamt > 74000 and @asubjamt <=74500 select @pcredits = .09
   	 if @asubjamt > 74500 and @asubjamt <=75000 select @pcredits = .08
   	 if @asubjamt > 75000 and @asubjamt <=75500 select @pcredits = .07
   	 if @asubjamt > 75500 and @asubjamt <=76000 select @pcredits = .06
   	 if @asubjamt > 76000 and @asubjamt <=76500 select @pcredits = .05
   	 if @asubjamt > 76500 and @asubjamt <=77000 select @pcredits = .04
   	 if @asubjamt > 77000 and @asubjamt <=77500 select @pcredits = .03
   	 if @asubjamt > 77500 and @asubjamt <=78000 select @pcredits = .02
   	 if @asubjamt > 78000 and @asubjamt <=78500 select @pcredits = .01
   	 if @asubjamt > 78500 select @pcredits = 0
   	end
   
   if @status = 'M'
   	begin
   	 if @asubjamt > 24000 and @asubjamt <=30000 select @pcredits = .75
   	 if @asubjamt > 30000 and @asubjamt <=30500 select @pcredits = .7
   	 if @asubjamt > 30500 and @asubjamt <=31000 select @pcredits = .65
   	 if @asubjamt > 31000 and @asubjamt <=31500 select @pcredits = .6
   	 if @asubjamt > 31500 and @asubjamt <=35000 select @pcredits = .55
   	 if @asubjamt > 32000 and @asubjamt <=32500 select @pcredits = .5
   	 if @asubjamt > 32500 and @asubjamt <=33000 select @pcredits = .45
   	 if @asubjamt > 33000 and @asubjamt <=33500 select @pcredits = .4
   	 if @asubjamt > 33500 and @asubjamt <=40000 select @pcredits = .35
   	 if @asubjamt > 40000 and @asubjamt <=40500 select @pcredits = .3
   	 if @asubjamt > 40500 and @asubjamt <=41000 select @pcredits = .25
   	 if @asubjamt > 41000 and @asubjamt <=41500 select @pcredits = .2
   	 if @asubjamt > 41500 and @asubjamt <=50000 select @pcredits = .15
   	 if @asubjamt > 50000 and @asubjamt <=50500 select @pcredits = .14
   	 if @asubjamt > 50500 and @asubjamt <=51000 select @pcredits = .13
   	 if @asubjamt > 51000 and @asubjamt <=51500 select @pcredits = .12
   	 if @asubjamt > 51500 and @asubjamt <=52000 select @pcredits = .11
   	 if @asubjamt > 52000 and @asubjamt <=96000 select @pcredits = .1
   	 if @asubjamt > 96000 and @asubjamt <=96500 select @pcredits = .09
   	 if @asubjamt > 96500 and @asubjamt <=97000 select @pcredits = .08
   	 if @asubjamt > 97000 and @asubjamt <=97500 select @pcredits = .07
   	 if @asubjamt > 97500 and @asubjamt <=98000 select @pcredits = .06
   	 if @asubjamt > 98000 and @asubjamt <=98500 select @pcredits = .05
   	 if @asubjamt > 98500 and @asubjamt <=99000 select @pcredits = .04
  
   	 if @asubjamt > 99000 and @asubjamt <=99500 select @pcredits = .03
   	 if @asubjamt > 99500 and @asubjamt <=100000 select @pcredits = .02
   	 if @asubjamt > 100000 and @asubjamt <=100500 select @pcredits = .01
   	 if @asubjamt > 100500 select @pcredits = 0
   	end
   	
   /* adjust for personal tax credits */
   select @amt = @amt * (1 - @pcredits)
   
   /* finish calculation */
   select @amt = @amt / @ppds 
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCTT98] TO [public]
GO
