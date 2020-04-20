SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRIDT042    Script Date: 8/28/99 9:33:22 AM ******/
   CREATE proc [dbo].[bspPRIDT042]
   /********************************************************
   * CREATED BY: 	EN 11/28/00 - this revision effective 1/1/2001
   * MODIFIED BY:  EN 5/29/01 - update effective retroactive to 1/1/2001
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 4/28/04 - issue 24459 update effective 7/1/2004
   *				EN 1/4/05 - issue 26244  default status and exemptions
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
   select @procname = 'bspPRIDT042'
   
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
   	 if @taxincome > 1750 and @taxincome <= 2879 select @basetax = 0, @limit = 1750, @rate = @rate1
   	 if @taxincome > 2879 and @taxincome <= 4008 select @basetax = 18, @limit = 2879, @rate = @rate2
   	 if @taxincome > 4008 and @taxincome <= 5137 select @basetax = 59, @limit = 4008, @rate = @rate3
   	 if @taxincome > 5137 and @taxincome <= 6265 select @basetax = 105, @limit = 5137, @rate = @rate4
   	 if @taxincome > 6265 and @taxincome <= 7394 select @basetax = 163, @limit = 6265, @rate = @rate5
   	 if @taxincome > 7394 and @taxincome <= 10216 select @basetax = 232, @limit = 7394, @rate = @rate6
   	 if @taxincome > 10216 and @taxincome <= 24327 select @basetax = 432, @limit = 10216, @rate = @rate7
   	 if @taxincome > 24327 select @basetax = 1476, @limit = 24327, @rate = @rate8
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome > 6600 and @taxincome <= 8858 select @basetax = 0, @limit = 6600, @rate = @rate1
   	 if @taxincome > 8858 and @taxincome <= 11116 select @basetax = 36, @limit = 8858, @rate = @rate2
   	 if @taxincome > 11116 and @taxincome <= 13374 select @basetax = 117, @limit = 11116, @rate = @rate3
   	 if @taxincome > 13374 and @taxincome <= 15630 select @basetax = 210, @limit = 13374, @rate = @rate4
   	 if @taxincome > 15630 and @taxincome <= 17888 select @basetax = 325, @limit = 15630, @rate = @rate5
   	 if @taxincome > 17888 and @taxincome <= 23532 select @basetax = 463, @limit = 17888, @rate = @rate6
   	 if @taxincome > 23532 and @taxincome <= 51754 select @basetax = 864, @limit = 23532, @rate = @rate7
   	 if @taxincome > 51754 select @basetax = 2952, @limit = 51754, @rate = @rate8
   	end
   
   /* calculate tax */
   select @amt = ROUND(((@basetax + ((@taxincome - @limit) * @rate)) / @ppds),0)
   
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRIDT042] TO [public]
GO
