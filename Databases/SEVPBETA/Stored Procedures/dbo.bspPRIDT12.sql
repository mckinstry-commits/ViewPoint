SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPRIDT12]
/********************************************************
* CREATED BY: 	EN	11/28/2000 - this revision effective 1/1/2001
* MODIFIED BY:  EN	05/29/2001 - update effective retroactive to 1/1/2001
*				EN	10/08/2002 - issue 18877 change double quotes to single
*				EN	04/28/2004 - issue 24459 update effective 7/1/2004
*				EN	01/04/2005 - issue 26244  default status and exemptions
*				EN	05/27/2005 - issue 28794  update for 5/1/05 retroactive to beginning of year
*				EN	04/29/2008 - issue 128107  update for 4/1/2008 effective immediately
*				EN	04/21/2009 #133238 update was effective 1/1/2009
*				CHS	12/26/2011	- B-08258 update effective 1/1/2012
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
   
   select @rcode = 0, @allowance = 3700
   
   select @rate1 = .016, @rate2 = .036, @rate3 = .041, @rate4 = .051, @rate5 = .061
   select @rate6 = .071, @rate7 = .074, @rate8 = .078
   select @procname = 'bspPRIDT12'
   
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
   	 if @taxincome >     1 and @taxincome <=  2100 select @basetax =    0, @limit =     0, @rate = 0
   	 if @taxincome >  2100 and @taxincome <=  3438 select @basetax =    0, @limit =  2100, @rate = @rate1
   	 if @taxincome >  3438 and @taxincome <=  4776 select @basetax =   21, @limit =  3438, @rate = @rate2
   	 if @taxincome >  4776 and @taxincome <=  6114 select @basetax =   69, @limit =  4776, @rate = @rate3
   	 if @taxincome >  6114 and @taxincome <=  7452 select @basetax =  124, @limit =  6114, @rate = @rate4
   	 if @taxincome >  7452 and @taxincome <=  8790 select @basetax =  192, @limit =  7452, @rate = @rate5
   	 if @taxincome >  8790 and @taxincome <= 12135 select @basetax =  274, @limit =  8790, @rate = @rate6
   	 if @taxincome > 12135 and @taxincome <= 28860 select @basetax =  511, @limit = 12135, @rate = @rate7   	 
   	 if @taxincome > 28860                         select @basetax = 1749, @limit = 28860, @rate = @rate8
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome >     1 and @taxincome <=  7900 select @basetax =    0, @limit =     0, @rate = 0
   	 if @taxincome >  7900 and @taxincome <= 10576 select @basetax =    0, @limit =  7900, @rate = @rate1
   	 if @taxincome > 10576 and @taxincome <= 13252 select @basetax =   43, @limit = 10576, @rate = @rate2
   	 if @taxincome > 13252 and @taxincome <= 15928 select @basetax =  139, @limit = 13252, @rate = @rate3
   	 if @taxincome > 15928 and @taxincome <= 18604 select @basetax =  249, @limit = 15928, @rate = @rate4
   	 if @taxincome > 18604 and @taxincome <= 21280 select @basetax =  385, @limit = 18604, @rate = @rate5
   	 if @taxincome > 21280 and @taxincome <= 27970 select @basetax =  548, @limit = 21280, @rate = @rate6
   	 if @taxincome > 27970 and @taxincome <= 61420 select @basetax = 1023, @limit = 27970, @rate = @rate7
   	 if @taxincome > 61420                         select @basetax = 3498, @limit = 61420, @rate = @rate8
   	end
   
   /* calculate tax */
   select @amt = ROUND(((@basetax + ((@taxincome - @limit) * @rate)) / @ppds),0)
   
   if @amt < 0 select @amt = 0
   
   --select @amt = (@taxincome - @limit) * @rate
   
   bspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRIDT12] TO [public]
GO
