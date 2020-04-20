SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRCAT10]    Script Date: 11/14/2007 10:31:02 ******/
  CREATE  proc [dbo].[bspPRCAT10]
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
  *				EN 11/30/2010 #136817  update effective 1/1/2010
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
  select @procname = 'bspPRCAT10'
  
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
  	select @lowexempt = 22261, @stddedn = 7274 -- lowexempt is from Table 1 and stddedn is from Table 3
  else
  	select @lowexempt = 11130, @stddedn = 3637 -- lowexempt is from Table 1 and stddedn is from Table 3
  
  /* determine taxable amount */
  if @subjamt * @ppds < @lowexempt goto bspexit
  select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
  
  /* determine base tax amounts and rates */
  /* married */
  if @status = 'M'
  	begin
  	 if @taxable <= 14120 select @basetax = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 14120 and @taxable <= 33478 select @basetax = 194.15, @limit = 14120, @rate = @rate2
  	 if @taxable > 33478 and @taxable <= 52838 select @basetax = 673.26, @limit = 33478, @rate = @rate3
  	 if @taxable > 52838 and @taxable <= 73350 select @basetax = 1578.34, @limit = 52838, @rate = @rate4
  	 if @taxable > 73350 and @taxable <= 92698 select @basetax = 2988.54, @limit = 73350, @rate = @rate5
  	 if @taxable > 92698 and @taxable <= 1000000 select @basetax = 4744.37, @limit = 92698, @rate = @rate6
  	 if @taxable > 1000000 select @basetax = 100056.45, @limit = 1000000, @rate = @rate7
  	end
  /* head of household */
  if @status = 'H'
  	begin
  	 if @taxable <= 14130 select @basetax = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 14130 and @taxable <= 33479 select @basetax = 194.29, @limit = 14130, @rate = @rate2
   	 if @taxable > 33479 and @taxable <= 43157 select @basetax = 673.18, @limit = 33479, @rate = @rate3
 	 if @taxable > 43157 and @taxable <= 53412 select @basetax = 1125.63, @limit = 43157, @rate = @rate4
  	 if @taxable > 53412 and @taxable <= 63089 select @basetax = 1830.66, @limit = 53412, @rate = @rate5
  	 if @taxable > 63089 and @taxable <= 1000000 select @basetax = 2708.85, @limit = 63089, @rate = @rate6
  	 if @taxable > 1000000 select @basetax = 101131.35, @limit = 1000000, @rate = @rate7
  	end
  
  
  /* single */
  if @status <> 'M' and @status <> 'H'
  	begin
  	 if @taxable <= 7060 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 7060 and @taxable <= 16739 select @basetax = 97.08, @limit = 7060, @rate = @rate2
  	 if @taxable > 16739 and @taxable <= 26419 select @basetax = 336.64, @limit = 16739, @rate = @rate3
  	 if @taxable > 26419 and @taxable <= 36675 select @basetax = 789.18, @limit = 26419, @rate = @rate4
  	 if @taxable > 36675 and @taxable <= 46349 select @basetax = 1494.28, @limit = 36675, @rate = @rate5
  	 if @taxable > 46349 and @taxable <= 1000000 select @basetax = 2372.20, @limit = 46349, @rate = @rate6
  	 if @taxable > 1000000 select @basetax = 102553.24, @limit = 1000000, @rate = @rate7
  	end
  
  /* calculate tax */
  select @amt = (@basetax + (@taxable - @limit) * @rate)
  
  /* adjust for personal exemption */
  select @amt = @amt - (@regexempts * 107.80) -- multiply regexempts by exemption allowance from Table 4
  
  /* finish calculation */
  if @amt < 0 select @amt = 0
  select @amt = @amt / @ppds
  
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT10] TO [public]
GO
