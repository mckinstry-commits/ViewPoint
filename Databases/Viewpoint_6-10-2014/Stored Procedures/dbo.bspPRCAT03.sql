SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCAT03    Script Date: 8/28/99 9:33:13 AM ******/
   CREATE   proc [dbo].[bspPRCAT03]
   /********************************************************
   * CREATED BY: 	EN 11/29/00 - this revision effective 1/1/2001
   * MODIFIED BY:  EN 12/11/01 - change effective 1/1/2002
   *				EN 10/7/02 - issue 18877 change double quotes to single
   *				EN 10/19/02 - issue 19393  change effective 1/1/2003
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
   select @procname = 'bspPRCAT03'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine low income exemption and standard deduction */
   if (@status = 'M' and @regexempts >= 2) or @status = 'H'
   	select @lowexempt = 19865, @stddedn = 6008 -- lowexempt is from Table 1 and stddedn is from Table 3
   else
   	select @lowexempt = 9958, @stddedn = 3004 -- lowexempt is from Table 1 and stddedn is from Table 3
   
   /* determine taxable amount */
   if @subjamt * @ppds < @lowexempt goto bspexit
   select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
   
   /* determine base tax amounts and rates */
   /* married */
   if @status = 'M'
   	begin
   	 if @taxable <= 11668 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 11668 and @taxable <= 27658 select @basetax = 116.68, @limit = 11668, @rate = @rate2
   	 if @taxable > 27658 and @taxable <= 43652 select @basetax = 436.48, @limit = 27658, @rate = @rate3
   	 if @taxable > 43652 and @taxable <= 60596 select @basetax = 1076.24, @limit = 43652, @rate = @rate4
   	 if @taxable > 60596 and @taxable <= 76582 select @basetax = 2092.88, @limit = 60596, @rate = @rate5
   	 if @taxable > 76582 select @basetax = 3371.76, @limit = 76582, @rate = @rate6
   	end
   /* head of household */
   if @status = 'H'
   	begin
   	 if @taxable <= 11673 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 11673 and @taxable <= 27659 select @basetax = 116.73, @limit = 11673, @rate = @rate2
   	 if @taxable > 27659 and @taxable <= 35653 select @basetax = 436.45, @limit = 27659, @rate = @rate3
   	 if @taxable > 35653 and @taxable <= 44125 select @basetax = 756.21, @limit = 35653, @rate = @rate4
   	 if @taxable > 44125 and @taxable <= 52120 select @basetax = 1264.53, @limit = 44125, @rate = @rate5
   	 if @taxable > 52120 select @basetax = 1904.13, @limit = 52120, @rate = @rate6
   	end
   
   
   /* single */
   if @status <> 'M' and @status <> 'H'
   	begin
   	 if @taxable <= 5834 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 5834 and @taxable <= 13829 select @basetax = 58.34, @limit = 5834, @rate = @rate2
   	 if @taxable > 13829 and @taxable <= 21826 select @basetax = 218.24, @limit = 13829, @rate = @rate3
   	 if @taxable > 21826 and @taxable <= 30298 select @basetax = 538.12, @limit = 21826, @rate = @rate4
   	 if @taxable > 30298 and @taxable <= 38291 select @basetax = 1046.44, @limit = 30298, @rate = @rate5
   	 if @taxable > 38291 select @basetax = 1685.88, @limit = 38291, @rate = @rate6
   	end
   
   /* calculate tax */
   select @amt = (@basetax + (@taxable - @limit) * @rate)
   
   /* adjust for personal exemption */
   select @amt = @amt - (@regexempts * 80) -- multiply regexempts by exemption allowance from Table 4
   
   /* finish calculation */
   if @amt < 0 select @amt = 0
   select @amt = @amt / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT03] TO [public]
GO
