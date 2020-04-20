SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRNDT08]    Script Date: 11/19/2007 09:17:07 ******/
  CREATE  proc [dbo].[bspPRNDT08]
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
  
  select @rcode = 0, @procname = 'bspPRNDT08'
  select @allowance = 3500
  select @rate1 = .021, @rate2 = .0392, @rate3 = .0434, @rate4 = .0504, @rate5 = .0554
  
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
  	 if @taxincome > 3700 and @taxincome <= 34600 select @basetax = 0, @limit = 3700, @rate = @rate1
  	 if @taxincome > 34600 and @taxincome <= 72800 select @basetax = 648.90, @limit = 34600, @rate = @rate2
  	 if @taxincome > 72800 and @taxincome <= 166300 select @basetax = 2146.34, @limit = 72800, @rate = @rate3
  	 if @taxincome > 166300 and @taxincome <= 359200 select @basetax = 6204.24, @limit = 166300, @rate = @rate4
  	 if @taxincome > 359200 select @basetax = 15926.40, @limit = 359200, @rate = @rate5
  	end
  
  if @status = 'M'
  	begin
  	 if @taxincome > 9000 and @taxincome <= 61600 select @basetax = 0, @limit = 9000, @rate = @rate1
  	 if @taxincome > 61600 and @taxincome <= 116900 select @basetax = 1104.60, @limit = 61600, @rate = @rate2
  	 if @taxincome > 116900 and @taxincome <= 208200 select @basetax = 3272.36, @limit = 116900, @rate = @rate3
  	 if @taxincome > 208200 and @taxincome <= 364700 select @basetax = 7234.78, @limit = 208200, @rate = @rate4
  	 if @taxincome > 364700 select @basetax = 15122.38, @limit = 364700, @rate = @rate5
  	end
  
  /* calculate tax */
  select @amt = ROUND((@basetax + ((@taxincome - @limit) * @rate)) / @ppds, 0)
  
  if @amt < 0 select @amt = 0
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNDT08] TO [public]
GO
