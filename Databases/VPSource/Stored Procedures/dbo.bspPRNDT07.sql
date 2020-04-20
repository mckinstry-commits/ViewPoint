SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNDT07    Script Date: 8/28/99 9:33:29 AM ******/
  CREATE  proc [dbo].[bspPRNDT07]
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
  
  select @rcode = 0, @procname = 'bspPRNDT07'
  select @allowance = 3400
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
  	 if @taxincome > 3600 and @taxincome <= 33800 select @basetax = 0, @limit = 3600, @rate = @rate1
  	 if @taxincome > 33800 and @taxincome <= 71200 select @basetax = 634.20, @limit = 33800, @rate = @rate2
  	 if @taxincome > 71200 and @taxincome <= 162600 select @basetax = 2100.28, @limit = 71200, @rate = @rate3
  	 if @taxincome > 162600 and @taxincome <= 351200 select @basetax = 6067.04, @limit = 162600, @rate = @rate4
  	 if @taxincome > 351200 select @basetax = 15572.48, @limit = 351200, @rate = @rate5
  	end
  
  if @status = 'M'
  	begin
  	 if @taxincome > 8800 and @taxincome <= 60200 select @basetax = 0, @limit = 8800, @rate = @rate1
  	 if @taxincome > 60200 and @taxincome <= 114300 select @basetax = 1079.40, @limit = 60200, @rate = @rate2
  	 if @taxincome > 114300 and @taxincome <= 203600 select @basetax = 3200.12, @limit = 114300, @rate = @rate3
  	 if @taxincome > 203600 and @taxincome <= 356600 select @basetax = 7075.74, @limit = 203600, @rate = @rate4
  	 if @taxincome > 356600 select @basetax = 14786.94, @limit = 356600, @rate = @rate5
  	end
  
  /* calculate tax */
  select @amt = ROUND((@basetax + ((@taxincome - @limit) * @rate)) / @ppds, 0)
  
  if @amt < 0 select @amt = 0
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNDT07] TO [public]
GO
