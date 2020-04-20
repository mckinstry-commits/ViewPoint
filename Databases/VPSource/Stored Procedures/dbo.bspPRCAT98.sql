SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCAT98    Script Date: 8/28/99 9:33:13 AM ******/
   CREATE  proc [dbo].[bspPRCAT98]
   /********************************************************
   * CREATED BY: 	EN 6/3/98
   * MODIFIED BY:	GG 8/11/98
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
   @addexempts tinyint = 0, @amt bDollar = 0 output, @msg varchar(255) = null output) as
   set nocount on
   
   declare @rcode int, @lowexempt bDollar, @stddedn bDollar, @taxable bDollar, 
   @estdedn bDollar, @basetax bDollar, @limit bDollar, @rate bRate,
   @rate1 bRate, @rate2 bRate, @rate3 bRate, @rate4 bRate, @rate5 bRate, @rate6 bRate,
   @procname varchar(30)
   
   select @rcode = 0, @lowexempt = 0, @stddedn = 0, @taxable = 0, @estdedn = 1000
   select @basetax = 0, @limit = 0, @rate = 0
   select @rate1 = .01, @rate2 = .02, @rate3 = .04, @rate4 = .06, @rate5 = .08, @rate6 = .093
   select @procname = 'bspPRCAT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine low income exemption and standard deduction */
   if (@status = 'M' and @regexempts >= 2) or @status = 'H'
   	select @lowexempt = 16080, @stddedn = 5166
   else
   	select @lowexempt = 8010, @stddedn = 2583
   	
   /* determine taxable amount */
   if @subjamt * @ppds < @lowexempt goto bspexit
   select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
   
   /* determine base tax amounts and rates */
   /* married */
   if @status = 'M'
   	begin
   	 if @taxable <= 10032 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 10032 and @taxable <= 23776 select @basetax = 100.32, @limit = 10032, @rate = @rate2
   	 if @taxable > 23776 and @taxable <= 37522 select @basetax = 375.20, @limit = 23776, @rate = @rate3
   	 if @taxable > 37522 and @taxable <= 52090 select @basetax = 925.04, @limit = 37522, @rate = @rate4
   	 if @taxable > 52090 and @taxable <= 65832 select @basetax = 1799.12, @limit = 52090, @rate = @rate5
   	 if @taxable > 65832 select @basetax = 2898.48, @limit = 65832, @rate = @rate6
   	end
   /* head of household */
   if @status = 'H'
   	begin
   	 if @taxable <= 10033 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 10033 and @taxable <= 23776 select @basetax = 100.33, @limit = 10033, @rate = @rate2
   	 if @taxable > 23776 and @taxable <= 30648 select @basetax = 375.19, @limit = 23776, @rate = @rate3
   	 if @taxable > 30648 and @taxable <= 37931 select @basetax = 650.07, @limit = 30648, @rate = @rate4
   	 if @taxable > 37931 and @taxable <= 44803 select @basetax = 1087.05, @limit = 37931, @rate = @rate5
   	 if @taxable > 44803 select @basetax = 1636.81, @limit = 44803, @rate = @rate6
   	end
    /* single */
   if @status <> 'M' and @status <> 'H'
   	begin	
   	 if @taxable <= 5016 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 5016 and @taxable <= 11888 select @basetax = 50.16, @limit = 5016, @rate = @rate2
   	 if @taxable > 11888 and @taxable <= 18761 select @basetax = 187.60, @limit = 11888, @rate = @rate3
   	 if @taxable > 18761 and @taxable <= 26045 select @basetax = 462.52, @limit = 18761, @rate = @rate4
   	 if @taxable > 26045 and @taxable <= 32916 select @basetax = 899.56, @limit = 26045, @rate = @rate5
   	 if @taxable > 32916 select @basetax = 1449.24, @limit = 32916, @rate = @rate6
   	end
   
   /* calculate tax */
   select @amt = (@basetax + (@taxable - @limit) * @rate)
   
   /* adjust for personal exemption */
   select @amt = @amt - (@regexempts * 68)
   
   /* finish calculation */
   if @amt < 0 select @amt = 0
   select @amt = @amt / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT98] TO [public]
GO
