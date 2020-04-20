SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCAT04    Script Date: 8/28/99 9:33:13 AM ******/
   CREATE    proc [dbo].[bspPRCAT04]
   /********************************************************
   * CREATED BY: 	EN 11/29/00 - this revision effective 1/1/2001
   * MODIFIED BY:  EN 12/11/01 - change effective 1/1/2002
   *				EN 10/7/02 - issue 18877 change double quotes to single
   *				EN 10/19/02 - issue 19393  change effective 1/1/2003
   *				EN 11/19/03 - issue 23040  change effective 1/1/2004
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
   @rate1 bRate, @rate2 bRate, @rate3 bRate, @rate4 bRate, @rate5 bRate, @rate6 bRate,
   @procname varchar(30)
   
   select @rcode = 0, @lowexempt = 0, @stddedn = 0, @taxable = 0, @estdedn = 1000 -- estdedn is from Table 2
   select @basetax = 0, @limit = 0, @rate = 0
   select @rate1 = .01, @rate2 = .02, @rate3 = .04, @rate4 = .06, @rate5 = .08, @rate6 = .093
   select @procname = 'bspPRCAT04'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine low income exemption and standard deduction */
   if (@status = 'M' and @regexempts >= 2) or @status = 'H'
   	select @lowexempt = 20302, @stddedn = 6140 -- lowexempt is from Table 1 and stddedn is from Table 3
   else
   	select @lowexempt = 10177, @stddedn = 3070 -- lowexempt is from Table 1 and stddedn is from Table 3
   
   /* determine taxable amount */
   if @subjamt * @ppds < @lowexempt goto bspexit
   select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
   
   /* determine base tax amounts and rates */
   /* married */
   if @status = 'M'
   	begin
   	 if @taxable <= 11924 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 11924 and @taxable <= 28266 select @basetax = 119.24, @limit = 11924, @rate = @rate2
   	 if @taxable > 28266 and @taxable <= 44612 select @basetax = 446.08, @limit = 28266, @rate = @rate3
   	 if @taxable > 44612 and @taxable <= 61930 select @basetax = 1099.92, @limit = 44612, @rate = @rate4
   	 if @taxable > 61930 and @taxable <= 78266 select @basetax = 2139.00, @limit = 61930, @rate = @rate5
   	 if @taxable > 78266 select @basetax = 3445.88, @limit = 78266, @rate = @rate6
   	end
   /* head of household */
   if @status = 'H'
   	begin
   	 if @taxable <= 11930 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 11930 and @taxable <= 28267 select @basetax = 119.30, @limit = 11930, @rate = @rate2
   	 if @taxable > 28267 and @taxable <= 36437 select @basetax = 446.04, @limit = 28267, @rate = @rate3
   	 if @taxable > 36437 and @taxable <= 45096 select @basetax = 772.84, @limit = 36437, @rate = @rate4
   	 if @taxable > 45096 and @taxable <= 53267 select @basetax = 1292.38, @limit = 45096, @rate = @rate5
   	 if @taxable > 53267 select @basetax = 1946.06, @limit = 53267, @rate = @rate6
   	end
   
   
   /* single */
   if @status <> 'M' and @status <> 'H'
   	begin
   	 if @taxable <= 5962 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 5962 and @taxable <= 14133 select @basetax = 59.62, @limit = 5962, @rate = @rate2
   	 if @taxable > 14133 and @taxable <= 22306 select @basetax = 223.04, @limit = 14133, @rate = @rate3
   	 if @taxable > 22306 and @taxable <= 30965 select @basetax = 549.96, @limit = 22306, @rate = @rate4
   	 if @taxable > 30965 and @taxable <= 39133 select @basetax = 1069.50, @limit = 30965, @rate = @rate5
   	 if @taxable > 39133 select @basetax = 1722.94, @limit = 39133, @rate = @rate6
   	end
   
   /* calculate tax */
   select @amt = (@basetax + (@taxable - @limit) * @rate)
   
   /* adjust for personal exemption */
   select @amt = @amt - (@regexempts * 82) -- multiply regexempts by exemption allowance from Table 4
   
   /* finish calculation */
   if @amt < 0 select @amt = 0
   select @amt = @amt / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT04] TO [public]
GO
