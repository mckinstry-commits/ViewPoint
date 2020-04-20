SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRIDT05    Script Date: 8/28/99 9:33:22 AM ******/
   CREATE  proc [dbo].[bspPRIDT05]
   /********************************************************
   * CREATED BY: 	EN 11/28/00 - this revision effective 1/1/2001
   * MODIFIED BY:  EN 5/29/01 - update effective retroactive to 1/1/2001
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 4/28/04 - issue 24459 update effective 7/1/2004
   *				EN 1/4/05 - issue 26244  default status and exemptions
   *				EN 5/27/05 - issue 28794  update for 5/1/05 retroactive to beginning of year
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
   
   select @rcode = 0, @allowance = 3200
   select @rate1 = .016, @rate2 = .036, @rate3 = .041, @rate4 = .051, @rate5 = .061
   select @rate6 = .071, @rate7 = .074, @rate8 = .078
   select @procname = 'bspPRIDT05'
   
   -- #26244 set default status and/or exemptions if passed in values are invalid
   if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
   if @exempts is null select @exempts = 0
   
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
   	 if @taxincome > 1800 and @taxincome <= 2959 select @basetax = 0, @limit = 1800, @rate = @rate1
   	 if @taxincome > 2959 and @taxincome <= 4118 select @basetax = 19, @limit = 2959, @rate = @rate2
   	 if @taxincome > 4118 and @taxincome <= 5277 select @basetax = 61, @limit = 4118, @rate = @rate3
   	 if @taxincome > 5277 and @taxincome <= 6436 select @basetax = 109, @limit = 5277, @rate = @rate4
   	 if @taxincome > 6436 and @taxincome <= 7594 select @basetax = 168, @limit = 6436, @rate = @rate5
   	 if @taxincome > 7594 and @taxincome <= 10492 select @basetax = 239, @limit = 7594, @rate = @rate6
   	 if @taxincome > 10492 and @taxincome <= 24978 select @basetax = 445, @limit = 10492, @rate = @rate7
   	 if @taxincome > 24978 select @basetax = 1517, @limit = 24978, @rate = @rate8
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome > 6800 and @taxincome <= 9118 select @basetax = 0, @limit = 6800, @rate = @rate1
   	 if @taxincome > 9118 and @taxincome <= 11436 select @basetax = 37, @limit = 9118, @rate = @rate2
   	 if @taxincome > 11436 and @taxincome <= 13754 select @basetax = 120, @limit = 11436, @rate = @rate3
   	 if @taxincome > 13754 and @taxincome <= 16072 select @basetax = 215, @limit = 13754, @rate = @rate4
   	 if @taxincome > 16072 and @taxincome <= 18388 select @basetax = 333, @limit = 16072, @rate = @rate5
   	 if @taxincome > 18388 and @taxincome <= 24184 select @basetax = 474, @limit = 18388, @rate = @rate6
   	 if @taxincome > 24184 and @taxincome <= 53156 select @basetax = 886, @limit = 24184, @rate = @rate7
   	 if @taxincome > 53156 select @basetax = 3030, @limit = 53156, @rate = @rate8
   	end
   
   /* calculate tax */
   select @amt = ROUND(((@basetax + ((@taxincome - @limit) * @rate)) / @ppds),0)
   
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRIDT05] TO [public]
GO
