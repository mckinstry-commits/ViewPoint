
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPRIDT13]
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
*				CHS	03/27/2013	- 44998 update effective 3/25/13
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
   
   select @rcode = 0, @allowance = 3900
   
   select @rate1 = .016, @rate2 = .036, @rate3 = .041, @rate4 = .051, @rate5 = .061
   select @rate6 = .071, @rate7 = .074
   select @procname = 'bspPRIDT13'
   
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
   	 if @taxincome >     1 and @taxincome <=  2200 select @basetax =    0, @limit =     0, @rate = 0
   	 if @taxincome >  2200 and @taxincome <=  3609 select @basetax =    0, @limit =  2200, @rate = @rate1
   	 if @taxincome >  3609 and @taxincome <=  5018 select @basetax =   23, @limit =  3609, @rate = @rate2
   	 if @taxincome >  5018 and @taxincome <=  6427 select @basetax =   74, @limit =  5018, @rate = @rate3
   	 if @taxincome >  6427 and @taxincome <=  7836 select @basetax =  132, @limit =  6427, @rate = @rate4
   	 if @taxincome >  7836 and @taxincome <=  9245 select @basetax =  204, @limit =  7836, @rate = @rate5
   	 if @taxincome >  9245 and @taxincome <= 12768 select @basetax =  290, @limit =  9245, @rate = @rate6
   	 if @taxincome > 12768						   select @basetax =  540, @limit = 12768, @rate = @rate7   	 
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome >     1 and @taxincome <=  8300 select @basetax =    0, @limit =     0, @rate = 0
   	 if @taxincome >  8300 and @taxincome <= 11118 select @basetax =    0, @limit =  8300, @rate = @rate1
   	 if @taxincome > 11118 and @taxincome <= 13936 select @basetax =   45, @limit = 11118, @rate = @rate2
   	 if @taxincome > 13936 and @taxincome <= 16754 select @basetax =  146, @limit = 13936, @rate = @rate3
   	 if @taxincome > 16754 and @taxincome <= 19572 select @basetax =  262, @limit = 16754, @rate = @rate4
   	 if @taxincome > 19572 and @taxincome <= 22390 select @basetax =  406, @limit = 19572, @rate = @rate5
   	 if @taxincome > 22390 and @taxincome <= 29436 select @basetax =  578, @limit = 22390, @rate = @rate6
   	 if @taxincome > 29436						   select @basetax = 1078, @limit = 29436, @rate = @rate7
   	end
   
   /* calculate tax */
   select @amt = ROUND(((@basetax + ((@taxincome - @limit) * @rate)) / @ppds),0)
   
   if @amt < 0 select @amt = 0
      
   bspexit:
   	return @rcode
GO

GRANT EXECUTE ON  [dbo].[bspPRIDT13] TO [public]
GO
