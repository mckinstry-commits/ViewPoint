SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRKYT10]    Script Date: 12/20/2007 07:54:34 ******/
  CREATE proc [dbo].[bspPRKYT10]
  /********************************************************
  * CREATED BY: EN 10/26/00 - this revision effective 1/1/2001
  * MODIFIED BY: EN 4/11/02 - issue 16966  Std dedn changed from $1750 (year 2001) to $1800
  *				EN 10/8/02 - issue 18877 change double quotes to single
  *				EN 11/11/03 - issue 22982  Std dedn changed from $1800 to $1870 (note that it should have been $1830 in 2003 but we did not have that info)
  *				EN 11/08/04 - issue 26052  Std dedn changed from $1870 to $1910
  *				EN 1/4/05 - issue 26244  default exemptions
  *				EN 7/5/5 - issue 29119  update effective 1/1/05 - added 5.8% tax bracket
  *				EN 12/13/05 - issue 30336  update effective 12/13/05 - changed std dedn from $1910 to $1970
  *				EN 12/11/06 - issue 123293  update effective 1/1/07 - changed std dedn from $1970 to $2050
  *				EN 12/20/07 - issue 126565  update effective 1/1/08 - changed std dedn from $2050 to $2100
  *				EN 12/17/08 - #131505  update effective 1/1/2009 - changed std dedn from $2100 to $2190
  *				EN 12/17/09 #137123  updated effective 1/1/2010 - changed std dedn from $2190 to $2210
  *
  * USAGE:
  * 	Calculates Kentucky Income Tax
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
  (@subjamt bDollar = 0, @ppds tinyint = 0, @exempts tinyint = 0,
   @amt bDollar = 0 output, @msg varchar(255) = null output)
  as
  set nocount on
  
  declare @rcode int, @taxincome bDollar, @stddedn bDollar, @creditamt bDollar,
  @procname varchar(30)
  
  select @rcode = 0, @stddedn = 2210, @creditamt = 20
  select @procname = 'bspPRKYT10'
  
  -- #26244 set default exemptions if passed in values are invalid
  if @exempts is null select @exempts = 0
 
  if @ppds = 0
  	begin
  	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  	goto bspexit
  	end
  
  /* determine taxable income */
  select @taxincome = (@subjamt * @ppds) - @stddedn
  if @taxincome < 0 select @taxincome = 0
  
  /* calculate tax */
  if @taxincome < 3000
  	begin
   	 select @amt = .02 * @taxincome
   	 goto end_loop
  	end
  select @amt = (.02 * 3000)
  select @taxincome = @taxincome - 3000
  
  
  if @taxincome < 1000
  	begin
   	 select @amt = @amt + (.03 * @taxincome)
   	 goto end_loop
  	end
  select @amt = @amt + (.03 * 1000)
  select @taxincome = @taxincome - 1000
  
  if @taxincome < 1000
  	begin
  	 select @amt = @amt + (.04 * @taxincome)
  	 goto end_loop
  	end
  select @amt = @amt + (.04 * 1000)
  select @taxincome = @taxincome - 1000
  
  if @taxincome < 3000
  	begin
  	 select @amt = @amt + (.05 * @taxincome)
  	 goto end_loop
  	end
  select @amt = @amt + (.05 * 3000)
  select @taxincome = @taxincome - 3000
 
  --issue 29119 added 5.8% tax bracket
  if @taxincome < 67000
  	begin
  	 select @amt = @amt + (.058 * @taxincome)
  	 goto end_loop
  	end
  select @amt = @amt + (.058 * 67000)
  select @taxincome = @taxincome - 67000
  
  select @amt = @amt + (.06 * @taxincome)
  
  end_loop:
  
  /* subtract credits */
  select @amt = @amt - (@exempts * @creditamt)
  
  /* de-annualize */
  select @amt = @amt / @ppds
  if @amt < 0 select @amt = 0
  
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRKYT10] TO [public]
GO
