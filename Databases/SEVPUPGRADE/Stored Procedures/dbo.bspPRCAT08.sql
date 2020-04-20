SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRCAT08]    Script Date: 11/14/2007 10:31:02 ******/
  CREATE  proc [dbo].[bspPRCAT08]
  /********************************************************
  * CREATED BY: 	EN 11/29/00 - this revision effective 1/1/2001
  * MODIFIED BY:  EN 12/11/01 - change effective 1/1/2002
  *				EN 10/7/02 - issue 18877 change double quotes to single
  *				EN 10/19/02 - issue 19393  change effective 1/1/2003
  *				EN 11/19/03 - issue 23040  change effective 1/1/2004
  *				EN 12/31/04 - issue 26244  default status and exemptions
  *				EN 11/28/05 - issue 30680  change effective 1/1/2006
  *				EN 11/13/06 - issue 123075  update effective 1/1/2007
  *				EN 11/14/07 - issue 125988  update effective 1/1/2008
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
  select @procname = 'bspPRCAT08'
  
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
  	select @lowexempt = 23259, @stddedn = 7032 -- lowexempt is from Table 1 and stddedn is from Table 3
  else
  	select @lowexempt = 11630, @stddedn = 3516 -- lowexempt is from Table 1 and stddedn is from Table 3
  
  /* determine taxable amount */
  if @subjamt * @ppds < @lowexempt goto bspexit
  select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
  
  /* determine base tax amounts and rates */
  /* married */
  if @status = 'M'
  	begin
  	 if @taxable <= 13654 select @basetax = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 13654 and @taxable <= 32370 select @basetax = 136.54, @limit = 13654, @rate = @rate2
  	 if @taxable > 32370 and @taxable <= 51088 select @basetax = 510.86, @limit = 32370, @rate = @rate3
  	 if @taxable > 51088 and @taxable <= 70920 select @basetax = 1259.58, @limit = 51088, @rate = @rate4
  	 if @taxable > 70920 and @taxable <= 89628 select @basetax = 2449.50, @limit = 70920, @rate = @rate5
  	 if @taxable > 89628 and @taxable <= 999999 select @basetax = 3946.14, @limit = 89628, @rate = @rate6
  	 if @taxable > 999999 select @basetax = 88610.64, @limit = 999999, @rate = @rate7
  	end
  /* head of household */
  if @status = 'H'
  	begin
  	 if @taxable <= 13662 select @basetax = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 13662 and @taxable <= 32370 select @basetax = 136.62, @limit = 13662, @rate = @rate2
  	 if @taxable > 32370 and @taxable <= 41728 select @basetax = 510.78, @limit = 32370, @rate = @rate3
  	 if @taxable > 41728 and @taxable <= 51643 select @basetax = 885.10, @limit = 41728, @rate = @rate4
  	 if @taxable > 51643 and @taxable <= 61000 select @basetax = 1480.00, @limit = 51643, @rate = @rate5
  	 if @taxable > 61000 and @taxable <= 999999 select @basetax = 2228.56, @limit = 61000, @rate = @rate6
  	 if @taxable > 999999 select @basetax = 89555.47, @limit = 999999, @rate = @rate7
  	end
  
  
  /* single */
  if @status <> 'M' and @status <> 'H'
  	begin
  	 if @taxable <= 6827 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 6827 and @taxable <= 16185 select @basetax = 68.27, @limit = 6827, @rate = @rate2
  	 if @taxable > 16185 and @taxable <= 25544 select @basetax = 255.43, @limit = 16185, @rate = @rate3
  	 if @taxable > 25544 and @taxable <= 35460 select @basetax = 629.79, @limit = 25544, @rate = @rate4
  	 if @taxable > 35460 and @taxable <= 44814 select @basetax = 1224.75, @limit = 35460, @rate = @rate5
  	 if @taxable > 44814 and @taxable <= 999999 select @basetax = 1973.07, @limit = 44814, @rate = @rate6
  	 if @taxable > 999999 select @basetax = 90805.28, @limit = 999999, @rate = @rate7
  	end
  
  /* calculate tax */
  select @amt = (@basetax + (@taxable - @limit) * @rate)
  
  /* adjust for personal exemption */
  select @amt = @amt - (@regexempts * 94) -- multiply regexempts by exemption allowance from Table 4
  
  /* finish calculation */
  if @amt < 0 select @amt = 0
  select @amt = @amt / @ppds
  
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT08] TO [public]
GO
