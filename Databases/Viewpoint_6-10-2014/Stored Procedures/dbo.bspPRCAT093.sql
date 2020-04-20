SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRCAT093]    Script Date: 11/14/2007 10:31:02 ******/
  CREATE  proc [dbo].[bspPRCAT093]
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
  *				EN 12/03/08 - #131308  update effective 1/1/2009
  *				EN 4/20/2009 #133341  update effective ASAP
  *				EN 10/5/2009 #135373  update effective 11/1/2009
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
  select @rate1 = .01375, @rate2 = .02475, @rate3 = .04675, @rate4 = .06875, @rate5 = .09075, @rate6 = .10505, @rate7 = .11605
  select @procname = 'bspPRCAT093'
  
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
  	select @lowexempt = 22556, @stddedn = 7384 -- lowexempt is from Table 1 and stddedn is from Table 3
  else
  	select @lowexempt = 11278, @stddedn = 3692 -- lowexempt is from Table 1 and stddedn is from Table 3
  
  /* determine taxable amount */
  if @subjamt * @ppds < @lowexempt goto bspexit
  select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
  
  /* determine base tax amounts and rates */
  /* married */
  if @status = 'M'
  	begin
  	 if @taxable <= 14336 select @basetax = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 14336 and @taxable <= 33988 select @basetax = 197.12, @limit = 14336, @rate = @rate2
  	 if @taxable > 33988 and @taxable <= 53642 select @basetax = 683.51, @limit = 33988, @rate = @rate3
  	 if @taxable > 53642 and @taxable <= 74466 select @basetax = 1602.33, @limit = 53642, @rate = @rate4
  	 if @taxable > 74466 and @taxable <= 94110 select @basetax = 3033.98, @limit = 74466, @rate = @rate5
  	 if @taxable > 94110 and @taxable <= 1000000 select @basetax = 4816.67, @limit = 94110, @rate = @rate6
  	 if @taxable > 1000000 select @basetax = 99980.41, @limit = 1000000, @rate = @rate7
  	end
  /* head of household */
  if @status = 'H'
  	begin
  	 if @taxable <= 14345 select @basetax = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 14345 and @taxable <= 33989 select @basetax = 197.24, @limit = 14345, @rate = @rate2
  	 if @taxable > 33989 and @taxable <= 43814 select @basetax = 683.43, @limit = 33989, @rate = @rate3
  	 if @taxable > 43814 and @taxable <= 54225 select @basetax = 1142.75, @limit = 43814, @rate = @rate4
  	 if @taxable > 54225 and @taxable <= 64050 select @basetax = 1858.51, @limit = 54225, @rate = @rate5
  	 if @taxable > 64050 and @taxable <= 1000000 select @basetax = 2750.13, @limit = 64050, @rate = @rate6
  	 if @taxable > 1000000 select @basetax = 101071.68, @limit = 1000000, @rate = @rate7
  	end
  
  
  /* single */
  if @status <> 'M' and @status <> 'H'
  	begin
  	 if @taxable <= 7168 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 7168 and @taxable <= 16994 select @basetax = 98.56, @limit = 7168, @rate = @rate2
  	 if @taxable > 16994 and @taxable <= 26821 select @basetax = 341.75, @limit = 16994, @rate = @rate3
  	 if @taxable > 26821 and @taxable <= 37233 select @basetax = 801.16, @limit = 26821, @rate = @rate4
  	 if @taxable > 37233 and @taxable <= 47055 select @basetax = 1516.99, @limit = 37233, @rate = @rate5
  	 if @taxable > 47055 and @taxable <= 1000000 select @basetax = 2408.34, @limit = 47055, @rate = @rate6
  	 if @taxable > 1000000 select @basetax = 102515.21, @limit = 1000000, @rate = @rate7
  	end
  
  /* calculate tax */
  select @amt = (@basetax + (@taxable - @limit) * @rate)
  
  /* adjust for personal exemption */
  select @amt = @amt - (@regexempts * 108.90) -- multiply regexempts by exemption allowance from Table 4
  
  /* finish calculation */
  if @amt < 0 select @amt = 0
  select @amt = @amt / @ppds
  
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT093] TO [public]
GO
