SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCAT01    Script Date: 8/28/99 9:33:13 AM ******/
   CREATE  proc [dbo].[bspPRCAT01]
   /********************************************************
   * CREATED BY: 	EN 11/29/00 - this revision effective 1/1/2001
   * MODIFIED BY:	EN 10/7/02 - issue 18877 change double quotes to single
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
   
   select @rcode = 0, @lowexempt = 0, @stddedn = 0, @taxable = 0, @estdedn = 1000
   select @basetax = 0, @limit = 0, @rate = 0
   select @rate1 = .01, @rate2 = .02, @rate3 = .04, @rate4 = .06, @rate5 = .08, @rate6 = .093
   select @procname = 'bspPRCAT01'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine low income exemption and standard deduction */
   if (@status = 'M' and @regexempts >= 2) or @status = 'H'
   	select @lowexempt = 18582, @stddedn = 5622
   else
   	select @lowexempt = 9291, @stddedn = 2811
   
   /* determine taxable amount */
   if @subjamt * @ppds < @lowexempt goto bspexit
   select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
   
   /* determine base tax amounts and rates */
   /* married */
   if @status = 'M'
   	begin
   	 if @taxable <= 10918 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 10918 and @taxable <= 25878 select @basetax = 109.18, @limit = 10918, @rate = @rate2
   	 if @taxable > 25878 and @taxable <= 40842 select @basetax = 408.38, @limit = 25878, @rate = @rate3
   	 if @taxable > 40842 and @taxable <= 56696 select @basetax = 1006.94, @limit = 40842, @rate = @rate4
   	 if @taxable > 56696 and @taxable <= 71652 select @basetax = 1958.18, @limit = 56696, @rate = @rate5
   	 if @taxable > 71652 select @basetax = 3154.66, @limit = 71652, @rate = @rate6
   	end
   /* head of household */
   if @status = 'H'
   	begin
   	 if @taxable <= 10921 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 10921 and @taxable <= 25878 select @basetax = 109.21, @limit = 10921, @rate = @rate2
   	 if @taxable > 25878 and @taxable <= 33358 select @basetax = 408.35, @limit = 25878, @rate = @rate3
   	 if @taxable > 33358 and @taxable <= 41285 select @basetax = 707.55, @limit = 33358, @rate = @rate4
   	 if @taxable > 41285 and @taxable <= 48765 select @basetax = 1183.17, @limit = 41285, @rate = @rate5
   	 if @taxable > 48765 select @basetax = 1781.57, @limit = 48765, @rate = @rate6
   	end
   
   
   /* single */
   if @status <> 'M' and @status <> 'H'
   	begin
   	 if @taxable <= 5459 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 5459 and @taxable <= 12939 select @basetax = 54.59, @limit = 5459, @rate = @rate2
   	 if @taxable > 12939 and @taxable <= 20421 select @basetax = 204.19, @limit = 12939, @rate = @rate3
   	 if @taxable > 20421 and @taxable <= 28348 select @basetax = 503.47, @limit = 20421, @rate = @rate4
   	 if @taxable > 28348 and @taxable <= 35826 select @basetax = 979.09, @limit = 28348, @rate = @rate5
   	 if @taxable > 35826 select @basetax = 1577.33, @limit = 35826, @rate = @rate6
   	end
   
   /* calculate tax */
   select @amt = (@basetax + (@taxable - @limit) * @rate)
   
   /* adjust for personal exemption */
   select @amt = @amt - (@regexempts * 75)
   
   /* finish calculation */
   if @amt < 0 select @amt = 0
   select @amt = @amt / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT01] TO [public]
GO
