SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCAT02    Script Date: 8/28/99 9:33:13 AM ******/
   CREATE  proc [dbo].[bspPRCAT02]
   /********************************************************
   * CREATED BY: 	EN 11/29/00 - this revision effective 1/1/2001
   * MODIFIED BY:  EN 12/11/01 - change effective 1/1/2002
   *				EN 10/7/02 - issue 18877 change double quotes to single
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
   select @procname = 'bspPRCAT02'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine low income exemption and standard deduction */
   if (@status = 'M' and @regexempts >= 2) or @status = 'H'
   	select @lowexempt = 19571, @stddedn = 5920
   else
   	select @lowexempt = 9811, @stddedn = 2960
   
   /* determine taxable amount */
   if @subjamt * @ppds < @lowexempt goto bspexit
   select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
   
   /* determine base tax amounts and rates */
   /* married */
   if @status = 'M'
   	begin
   	 if @taxable <= 11496 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 11496 and @taxable <= 27250 select @basetax = 114.96, @limit = 11496, @rate = @rate2
   	 if @taxable > 27250 and @taxable <= 43006 select @basetax = 430.04, @limit = 27250, @rate = @rate3
   	 if @taxable > 43006 and @taxable <= 59700 select @basetax = 1060.28, @limit = 43006, @rate = @rate4
   	 if @taxable > 59700 and @taxable <= 75450 select @basetax = 2061.92, @limit = 59700, @rate = @rate5
   	 if @taxable > 75450 select @basetax = 3321.92, @limit = 75450, @rate = @rate6
   	end
   /* head of household */
   if @status = 'H'
   	begin
   	 if @taxable <= 11500 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 11500 and @taxable <= 27250 select @basetax = 115.00, @limit = 11500, @rate = @rate2
   	 if @taxable > 27250 and @taxable <= 35126 select @basetax = 430.00, @limit = 27250, @rate = @rate3
   	 if @taxable > 35126 and @taxable <= 43473 select @basetax = 745.04, @limit = 35126, @rate = @rate4
   	 if @taxable > 43473 and @taxable <= 51350 select @basetax = 1245.86, @limit = 43473, @rate = @rate5
   	 if @taxable > 51350 select @basetax = 1876.02, @limit = 51350, @rate = @rate6
   	end
   
   
   /* single */
   if @status <> 'M' and @status <> 'H'
   	begin
   	 if @taxable <= 5748 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 5748 and @taxable <= 13625 select @basetax = 57.48, @limit = 5748, @rate = @rate2
   	 if @taxable > 13625 and @taxable <= 21503 select @basetax = 215.02, @limit = 13625, @rate = @rate3
   	 if @taxable > 21503 and @taxable <= 29850 select @basetax = 530.14, @limit = 21503, @rate = @rate4
   	 if @taxable > 29850 and @taxable <= 37725 select @basetax = 1030.96, @limit = 29850, @rate = @rate5
   	 if @taxable > 37725 select @basetax = 1660.96, @limit = 37725, @rate = @rate6
   	end
   
   /* calculate tax */
   select @amt = (@basetax + (@taxable - @limit) * @rate)
   
   /* adjust for personal exemption */
   select @amt = @amt - (@regexempts * 79)
   
   /* finish calculation */
   if @amt < 0 select @amt = 0
   select @amt = @amt / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT02] TO [public]
GO
