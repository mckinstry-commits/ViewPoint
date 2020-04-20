SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRIDT08    Script Date: 8/28/99 9:33:22 AM ******/
   CREATE  proc [dbo].[bspPRIDT08]
   /********************************************************
   * CREATED BY: 	EN 11/28/00 - this revision effective 1/1/2001
   * MODIFIED BY:  EN 5/29/01 - update effective retroactive to 1/1/2001
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 4/28/04 - issue 24459 update effective 7/1/2004
   *				EN 1/4/05 - issue 26244  default status and exemptions
   *				EN 5/27/05 - issue 28794  update for 5/1/05 retroactive to beginning of year
   *				EN 4/29/08 - issue 128107  update for 4/1/2008 effective immediately
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
   select @procname = 'bspPRIDT08'
   
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
   	 if @taxincome > 1950 and @taxincome <= 3222 select @basetax = 0, @limit = 1950, @rate = @rate1
   	 if @taxincome > 3222 and @taxincome <= 4494 select @basetax = 20, @limit = 3222, @rate = @rate2
   	 if @taxincome > 4494 and @taxincome <= 5766 select @basetax = 66, @limit = 4494, @rate = @rate3
   	 if @taxincome > 5766 and @taxincome <= 7038 select @basetax = 118, @limit = 5766, @rate = @rate4
   	 if @taxincome > 7038 and @taxincome <= 8310 select @basetax = 183, @limit = 7038, @rate = @rate5
   	 if @taxincome > 8310 and @taxincome <= 11490 select @basetax = 261, @limit = 8310, @rate = @rate6
   	 if @taxincome > 11490 and @taxincome <= 27391 select @basetax = 487, @limit = 11490, @rate = @rate7
   	 if @taxincome > 27391 select @basetax = 1664, @limit = 27391, @rate = @rate8
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome > 7400 and @taxincome <= 9944 select @basetax = 0, @limit = 7400, @rate = @rate1
   	 if @taxincome > 9944 and @taxincome <= 12488 select @basetax = 41, @limit = 9944, @rate = @rate2
   	 if @taxincome > 12488 and @taxincome <= 15032 select @basetax = 133, @limit = 12488, @rate = @rate3
   	 if @taxincome > 15032 and @taxincome <= 17576 select @basetax = 237, @limit = 15032, @rate = @rate4
   	 if @taxincome > 17576 and @taxincome <= 20120 select @basetax = 367, @limit = 17576, @rate = @rate5
   	 if @taxincome > 20120 and @taxincome <= 26480 select @basetax = 522, @limit = 20120, @rate = @rate6
   	 if @taxincome > 26480 and @taxincome <= 58282 select @basetax = 974, @limit = 26480, @rate = @rate7
   	 if @taxincome > 58282 select @basetax = 3327, @limit = 58282, @rate = @rate8
   	end
   
   /* calculate tax */
   select @amt = ROUND(((@basetax + ((@taxincome - @limit) * @rate)) / @ppds),0)
   
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRIDT08] TO [public]
GO
