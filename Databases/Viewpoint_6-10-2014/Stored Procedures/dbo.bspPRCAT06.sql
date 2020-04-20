SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCAT06    Script Date: 8/28/99 9:33:13 AM ******/
  CREATE  proc [dbo].[bspPRCAT06]
  /********************************************************
  * CREATED BY: 	EN 11/29/00 - this revision effective 1/1/2001
  * MODIFIED BY:  EN 12/11/01 - change effective 1/1/2002
  *				EN 10/7/02 - issue 18877 change double quotes to single
  *				EN 10/19/02 - issue 19393  change effective 1/1/2003
  *				EN 11/19/03 - issue 23040  change effective 1/1/2004
  *				EN 12/31/04 - issue 26244  default status and exemptions
  *				EN 11/28/05 - issue 30680  change effective 1/1/2006
  *
  * USAGE:
  * 	Calculates California Income Tax
  *
  * INPUT PARAMETERS:
  *	@subjamt 	subject earnings
  *	@ppds		# of pay pds per year
  *	@status		filing status
  *	@regexempts	# of regular exemptions
  *	@addexempts	# of additional exemptions
  *
  * OUTPUT PARAMETERS:
  *	@amt		calculated tax amount
  *	@msg		error message if failure
  *
  * RETURN VALUE:
  * 	0 	    	success
  *	1 		failure
  **********************************************************/
  (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @regexempts tinyint = 0,
  @addexempts tinyint = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
  
  as
  set nocount on
  
  declare @rcode int, @lowexempt bDollar, @stddedn bDollar, @taxable bDollar,
  @estdedn bDollar, @basetax bDollar, @limit bDollar, @rate bRate,
  @rate1 bRate, @rate2 bRate, @rate3 bRate, @rate4 bRate, @rate5 bRate, @rate6 bRate, @rate7 bRate,
  @procname varchar(30)
  
  select @rcode = 0, @lowexempt = 0, @stddedn = 0, @taxable = 0, @estdedn = 1000 -- estdedn is from Table 2
  select @basetax = 0, @limit = 0, @rate = 0
  select @rate1 = .01, @rate2 = .02, @rate3 = .04, @rate4 = .06, @rate5 = .08, @rate6 = .093, @rate7 = .103
  select @procname = 'bspPRCAT06'
  
  -- #26244 set default status and/or exemptions if passed in values are invalid
  if (@status is null) or (@status is not null and @status not in ('S','M','H')) select @status = 'S'
  if @regexempts is null select @regexempts = 0
  if @addexempts is null select @addexempts = 0
 
  if @ppds = 0
  	begin
  	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  	goto bspexit
  	end
  
  /* determine low income exemption and standard deduction */
  if (@status = 'M' and @regexempts >= 2) or @status = 'H'
  	select @lowexempt = 21527, @stddedn = 6508 -- lowexempt is from Table 1 and stddedn is from Table 3
  else
  	select @lowexempt = 10764, @stddedn = 3254 -- lowexempt is from Table 1 and stddedn is from Table 3
  
  /* determine taxable amount */
  if @subjamt * @ppds < @lowexempt goto bspexit
  select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
  
  /* determine base tax amounts and rates */
  /* married */
  if @status = 'M'
  	begin
  	 if @taxable <= 12638 select @basetax = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 12638 and @taxable <= 29958 select @basetax = 126.38, @limit = 12638, @rate = @rate2
  	 if @taxable > 29958 and @taxable <= 47282 select @basetax = 472.78, @limit = 29958, @rate = @rate3
  	 if @taxable > 47282 and @taxable <= 65638 select @basetax = 1165.74, @limit = 47282, @rate = @rate4
  	 if @taxable > 65638 and @taxable <= 82952 select @basetax = 2267.10, @limit = 65638, @rate = @rate5
  	 if @taxable > 82952 and @taxable <= 999999 select @basetax = 3652.22, @limit = 82952, @rate = @rate6
  	 if @taxable > 999999 select @basetax = 88937.59, @limit = 999999, @rate = @rate7
  	end
  /* head of household */
  if @status = 'H'
  	begin
  	 if @taxable <= 12644 select @basetax = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 12644 and @taxable <= 29959 select @basetax = 126.44, @limit = 12644, @rate = @rate2
  	 if @taxable > 29959 and @taxable <= 38619 select @basetax = 472.74, @limit = 29959, @rate = @rate3
  	 if @taxable > 38619 and @taxable <= 47796 select @basetax = 819.14, @limit = 38619, @rate = @rate4
  	 if @taxable > 47796 and @taxable <= 56456 select @basetax = 1369.76, @limit = 47796, @rate = @rate5
  	 if @taxable > 56456 and @taxable <= 999999 select @basetax = 2062.56, @limit = 56456, @rate = @rate6
  	 if @taxable > 999999 select @basetax = 89812.06, @limit = 999999, @rate = @rate7
  	end
  
  
  /* single */
  if @status <> 'M' and @status <> 'H'
  	begin
  	 if @taxable <= 6319 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 6319 and @taxable <= 14979 select @basetax = 63.19, @limit = 6319, @rate = @rate2
  	 if @taxable > 14979 and @taxable <= 23641 select @basetax = 236.39, @limit = 14979, @rate = @rate3
  	 if @taxable > 23641 and @taxable <= 32819 select @basetax = 582.87, @limit = 23641, @rate = @rate4
  	 if @taxable > 32819 and @taxable <= 41476 select @basetax = 1133.55, @limit = 32819, @rate = @rate5
  	 if @taxable > 41476 and @taxable <= 999999 select @basetax = 1826.11, @limit = 41476, @rate = @rate6
  	 if @taxable > 999999 select @basetax = 90968.75, @limit = 999999, @rate = @rate7
  	end
  
  /* calculate tax */
  select @amt = (@basetax + (@taxable - @limit) * @rate)
  
  /* adjust for personal exemption */
  select @amt = @amt - (@regexempts * 87) -- multiply regexempts by exemption allowance from Table 4
  
  /* finish calculation */
  if @amt < 0 select @amt = 0
  select @amt = @amt / @ppds
  
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT06] TO [public]
GO
