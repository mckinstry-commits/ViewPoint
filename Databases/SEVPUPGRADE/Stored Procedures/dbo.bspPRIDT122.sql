SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPRIDT122]
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
*				MV	07/03/2012 - D-05266/TK-16125 update effective 4/20/12
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
   
   select @rcode = 0, @allowance = 3800
   
   select @rate1 = .016, @rate2 = .036, @rate3 = .041, @rate4 = .051, @rate5 = .061
   select @rate6 = .071, @rate7 = .074, @rate8 = .078
   select @procname = 'bspPRIDT122'
   
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
   	 if @taxincome >     1 and @taxincome <=  2150 select @basetax =    0, @limit =     0, @rate = 0
   	 if @taxincome >  2150 and @taxincome <=  3530 select @basetax =    0, @limit =  2150, @rate = @rate1
   	 if @taxincome >  3530 and @taxincome <=  4910 select @basetax =   22, @limit =  3530, @rate = @rate2
   	 if @taxincome >  4910 and @taxincome <=  6290 select @basetax =   72, @limit =  4910, @rate = @rate3
   	 if @taxincome >  6290 and @taxincome <=  7670 select @basetax =  129, @limit =  6290, @rate = @rate4
   	 if @taxincome >  7670 and @taxincome <=  9050 select @basetax =  199, @limit =  7670, @rate = @rate5
   	 if @taxincome >  9050 and @taxincome <= 12500 select @basetax =  283, @limit =  9050, @rate = @rate6
   	 if @taxincome > 12500						   select @basetax =  528, @limit = 12500, @rate = @rate7   	 
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome >     1 and @taxincome <=  8100 select @basetax =    0, @limit =     0, @rate = 0
   	 if @taxincome >  8100 and @taxincome <= 10860 select @basetax =    0, @limit =  8100, @rate = @rate1
   	 if @taxincome > 10860 and @taxincome <= 13620 select @basetax =   44, @limit = 10860, @rate = @rate2
   	 if @taxincome > 13620 and @taxincome <= 16380 select @basetax =  143, @limit = 13620, @rate = @rate3
   	 if @taxincome > 16380 and @taxincome <= 19140 select @basetax =  256, @limit = 16380, @rate = @rate4
   	 if @taxincome > 19140 and @taxincome <= 21900 select @basetax =  397, @limit = 19140, @rate = @rate5
   	 if @taxincome > 21900 and @taxincome <= 28800 select @basetax =  565, @limit = 21900, @rate = @rate6
   	 if @taxincome > 28800						   select @basetax = 1055, @limit = 28800, @rate = @rate7
   	end
   
   /* calculate tax */
   select @amt = ROUND(((@basetax + ((@taxincome - @limit) * @rate)) / @ppds),0)
   
   if @amt < 0 select @amt = 0
   
   --select @amt = (@taxincome - @limit) * @rate
   
   bspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRIDT122] TO [public]
GO
