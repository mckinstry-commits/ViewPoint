SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRIDT98    Script Date: 8/28/99 9:33:22 AM ******/
   CREATE   proc [dbo].[bspPRIDT98]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY:	GG 8/11/98
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
   
   select @rcode = 0, @allowance = 2500
   select @rate1 = .02, @rate2 = .04, @rate3 = .045, @rate4 = .055, @rate5 = .065
   select @rate6 = .075, @rate7 = .078, @rate8 = .082
   select @procname = 'bspPRIDT98'
   
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
   	 if @taxincome > 1500 and @taxincome <= 2500 select @basetax = 0, @limit = 1500, @rate = @rate1
   	 if @taxincome > 2500 and @taxincome <= 3500 select @basetax = 20, @limit = 2500, @rate = @rate2
   	 if @taxincome > 3500 and @taxincome <= 4500 select @basetax = 60, @limit = 3500, @rate = @rate3
   	 if @taxincome > 4500 and @taxincome <= 5500 select @basetax = 105, @limit = 4500, @rate = @rate4
   	 if @taxincome > 5500 and @taxincome <= 6500 select @basetax = 160, @limit = 5500, @rate = @rate5
   	 if @taxincome > 6500 and @taxincome <= 9000 select @basetax = 225, @limit = 6500, @rate = @rate6
   	 if @taxincome > 9000 and @taxincome <= 21500 select @basetax = 412.5, @limit = 9000, @rate = @rate7
   	 if @taxincome > 21500 select @basetax = 1387.5, @limit = 21500, @rate = @rate8
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome > 4000 and @taxincome <= 6000 select @basetax = 0, @limit = 4000, @rate = @rate1
   	 if @taxincome > 6000 and @taxincome <= 8000 select @basetax = 40, @limit = 6000, @rate = @rate2
   	 if @taxincome > 8000 and @taxincome <= 10000 select @basetax = 120, @limit = 8000, @rate = @rate3
   	 if @taxincome > 10000 and @taxincome <= 12000 select @basetax = 210, @limit = 10000, @rate = @rate4
   	 if @taxincome > 12000 and @taxincome <= 14000 select @basetax = 320, @limit = 12000, @rate = @rate5
   	 if @taxincome > 14000 and @taxincome <= 19000 select @basetax = 450, @limit = 14000, @rate = @rate6
   	 if @taxincome > 19000 and @taxincome <= 44000 select @basetax = 825, @limit = 19000, @rate = @rate7
   	 if @taxincome > 44000 select @basetax = 2775, @limit = 44000, @rate = @rate8
   	end
   	
   /* calculate tax */
   select @amt = (@basetax + ((@taxincome - @limit) * @rate)) / @ppds
   
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRIDT98] TO [public]
GO
