SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  create  proc [dbo].[bspPRNDT11]
  /********************************************************
  * CREATED BY: 	bc 6/15/98
  * MODIFIED BY:	GG 8/11/98
  *				EN 11/13/01 - issue 15016 - effective 1/1/2002
  *				EN 10/8/02 - issue 18877 change double quotes to single
  *				EN 11/11/02 issue 24562  update effective 1/1/2003
  *			 	EN 12/17/02 issue 24562  allowance changed back to 2002 value ($3,050.00)
  *				EN 12/01/03 issue 23129  update effective 1/1/2004
  *				EN 11/24/04 issue 26310  update effective 1/1/2005
  *				EN 1/10/05 - issue 26244  default status and exemptions
  *				EN 11/28/05 issue 30674  update effective 1/1/2006
  *				EN 11/06/06 issue 123018  update effective 1/1/2007
  *				EN 11/19/07 issue 126270  update effective 1/1/2008
  *				EN 12/18/08 #131519  update effective 1/1/2009
  *				EN 7/21/2009 #134844  update effective 1/1/2009 (ASAP)
  *				EN 12/2/2009 #136872  update effective 1/1/2010
  *				MV 12/23/10 #142570 updates effective 1/1/2011
  *
  * USAGE:
  * 	Calculates North Dakota Income Tax
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
  @rate4 bRate, @rate5 bRate, @procname varchar(30)
  
  select @rcode = 0, @procname = 'bspPRNDT11'
  select @allowance = 3700
  select @rate1 = .0184, @rate2 = .0344, @rate3 = .0381, @rate4 = .0442, @rate5 = .0486
  
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
  if @taxincome < 1 select @taxincome = 0
  
  /* determine base tax and rate */
  select @basetax = 0, @limit = 0, @rate = 0
  
  if @status = 'S'
  	begin
  	 if @taxincome > 3900 and @taxincome <= 37000 select @basetax = 0, @limit = 3900, @rate = @rate1
  	 if @taxincome > 37000 and @taxincome <= 77000 select @basetax = 609.04, @limit = 37000, @rate = @rate2
  	 if @taxincome > 77000 and @taxincome <= 176000 select @basetax = 1985.04, @limit = 77000, @rate = @rate3
  	 if @taxincome > 176000 and @taxincome <= 380000 select @basetax = 5756.94, @limit = 176000, @rate = @rate4
  	 if @taxincome > 380000 select @basetax = 14773.74, @limit = 380000, @rate = @rate5
  	end
  
  if @status = 'M'
  	begin
  	 if @taxincome > 9400 and @taxincome <= 65000 select @basetax = 0, @limit = 9400, @rate = @rate1
  	 if @taxincome > 65000 and @taxincome <= 124000 select @basetax = 1023.04, @limit = 65000, @rate = @rate2
  	 if @taxincome > 124000 and @taxincome <= 220000 select @basetax = 3052.64, @limit = 124000, @rate = @rate3
  	 if @taxincome > 220000 and @taxincome <= 386000 select @basetax = 6710.24, @limit = 220000, @rate = @rate4
  	 if @taxincome > 386000 select @basetax = 14047.44, @limit = 386000, @rate = @rate5
  	end
  
  /* calculate tax */
  select @amt = ROUND((@basetax + ((@taxincome - @limit) * @rate)) / @ppds, 0)
  
  if @amt < 0 select @amt = 0
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNDT11] TO [public]
GO
