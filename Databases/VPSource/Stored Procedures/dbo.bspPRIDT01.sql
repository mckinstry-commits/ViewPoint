SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRIDT01    Script Date: 8/28/99 9:33:22 AM ******/
   CREATE   proc [dbo].[bspPRIDT01]
   /********************************************************
   * CREATED BY: 	EN 11/28/00 - this revision effective 1/1/2001
   * MODIFIED BY:  EN 5/29/01 - update effective retroactive to 1/1/2001
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
   
   select @rcode = 0, @allowance = 2900
   select @rate1 = .016, @rate2 = .036, @rate3 = .041, @rate4 = .051, @rate5 = .061
   select @rate6 = .071, @rate7 = .074, @rate8 = .078
   select @procname = 'bspPRIDT01'
   
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
   	 if @taxincome > 1650 and @taxincome <= 2706 select @basetax = 0, @limit = 1650, @rate = @rate1
   	 if @taxincome > 2706 and @taxincome <= 3763 select @basetax = 17, @limit = 2706, @rate = @rate2
   	 if @taxincome > 3763 and @taxincome <= 4819 select @basetax = 55, @limit = 3763, @rate = @rate3
   	 if @taxincome > 4819 and @taxincome <= 5876 select @basetax = 98, @limit = 4819, @rate = @rate4
   	 if @taxincome > 5876 and @taxincome <= 6932 select @basetax = 152, @limit = 5876, @rate = @rate5
   	 if @taxincome > 6932 and @taxincome <= 9573 select @basetax = 216, @limit = 6932, @rate = @rate6
   	 if @taxincome > 9573 and @taxincome <= 22779 select @basetax = 404, @limit = 9573, @rate = @rate7
   	 if @taxincome > 22779 select @basetax = 1381, @limit = 22779, @rate = @rate8
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome > 6200 and @taxincome <= 8312 select @basetax = 0, @limit = 4550, @rate = @rate1
   	 if @taxincome > 8312 and @taxincome <= 10426 select @basetax = 34, @limit = 8312, @rate = @rate2
   	 if @taxincome > 10426 and @taxincome <= 12538 select @basetax = 110, @limit = 10426, @rate = @rate3
   	 if @taxincome > 12538 and @taxincome <= 14652 select @basetax = 197, @limit = 12538, @rate = @rate4
   	 if @taxincome > 14652 and @taxincome <= 16764 select @basetax = 305, @limit = 14652, @rate = @rate5
   	 if @taxincome > 16764 and @taxincome <= 22046 select @basetax = 434, @limit = 16764, @rate = @rate6
   	 if @taxincome > 22046 and @taxincome <= 48458 select @basetax = 809, @limit = 22046, @rate = @rate7
   	 if @taxincome > 48458 select @basetax = 2763, @limit = 48458, @rate = @rate8
   	end
   
   /* calculate tax */
   select @amt = ROUND(((@basetax + ((@taxincome - @limit) * @rate)) / @ppds),0)
   
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRIDT01] TO [public]
GO
