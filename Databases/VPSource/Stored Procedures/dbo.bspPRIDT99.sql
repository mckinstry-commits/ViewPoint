SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRIDT99    Script Date: 8/28/99 9:33:22 AM ******/
   CREATE   proc [dbo].[bspPRIDT99]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY:	EN 12/16/98
   * MODIFIED BY:  EN 11/08/99 - fixed to round by whole dollars
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Idaho Income Tax
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
   
   declare @rcode int, @taxincome bDollar, @allowance bDollar, @basetax bDollar,
   @limit bDollar, @rate bRate, @rate1 bRate, @rate2 bRate, @rate3 bRate,
   @rate4 bRate, @rate5 bRate, @rate6 bRate, @rate7 bRate, @rate8 bRate,
   @procname varchar(30)
   
   select @rcode = 0, @allowance = 2750
   select @rate1 = .02, @rate2 = .04, @rate3 = .045, @rate4 = .055, @rate5 = .065
   select @rate6 = .075, @rate7 = .078, @rate8 = .082
   select @procname = 'bspPRIDT99'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   
   /* determine taxable income */
   select @taxincome = (@subjamt * @ppds) - (@exempts * @allowance)
   if @taxincome < 0 select @taxincome = 0
   
   /* determine base tax and rate */
   select @basetax = 0, @limit = 0, @rate = 0
   
   if @status = 'S'
   	begin
   	 if @taxincome > 1550 and @taxincome <= 2550 select @basetax = 0, @limit = 1550, @rate = @rate1
   	 if @taxincome > 2550 and @taxincome <= 3550 select @basetax = 20, @limit = 2550, @rate = @rate2
   	 if @taxincome > 3550 and @taxincome <= 4550 select @basetax = 60, @limit = 3550, @rate = @rate3
   	 if @taxincome > 4550 and @taxincome <= 5550 select @basetax = 105, @limit = 4550, @rate = @rate4
   	 if @taxincome > 5550 and @taxincome <= 6550 select @basetax = 160, @limit = 5550, @rate = @rate5
   	 if @taxincome > 6550 and @taxincome <= 9050 select @basetax = 225, @limit = 6550, @rate = @rate6
   	 if @taxincome > 9050 and @taxincome <= 21550 select @basetax = 412.5, @limit = 9050, @rate = @rate7
   	 if @taxincome > 21550 select @basetax = 1387.5, @limit = 21500, @rate = @rate8
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome > 4450 and @taxincome <= 640 select @basetax = 0, @limit = 4450, @rate = @rate1
   	 if @taxincome > 6450 and @taxincome <= 8450 select @basetax = 40, @limit = 6450, @rate = @rate2
   	 if @taxincome > 8450 and @taxincome <= 10450 select @basetax = 120, @limit = 8450, @rate = @rate3
   	 if @taxincome > 10450 and @taxincome <= 12450 select @basetax = 210, @limit = 10450, @rate = @rate4
   	 if @taxincome > 12450 and @taxincome <= 14450 select @basetax = 320, @limit = 12450, @rate = @rate5
   	 if @taxincome > 14450 and @taxincome <= 19450 select @basetax = 450, @limit = 14450, @rate = @rate6
   	 if @taxincome > 19450 and @taxincome <= 44450 select @basetax = 825, @limit = 19450, @rate = @rate7
   	 if @taxincome > 44450 select @basetax = 2775, @limit = 44000, @rate = @rate8
   	end
   
   /* calculate tax */
   select @amt = ROUND(((@basetax + ((@taxincome - @limit) * @rate)) / @ppds),0)
   
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRIDT99] TO [public]
GO
