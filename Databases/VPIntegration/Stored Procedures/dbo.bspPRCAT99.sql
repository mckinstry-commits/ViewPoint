SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCAT99    Script Date: 8/28/99 9:33:13 AM ******/
   CREATE  proc [dbo].[bspPRCAT99]
   /********************************************************
   * CREATED BY: 	EN 6/3/98
   * MODIFIED BY:	EN 12/16/98
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
   select @procname = 'bspPRCAT99'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine low income exemption and standard deduction */
   if (@status = 'M' and @regexempts >= 2) or @status = 'H'
   	select @lowexempt = 16380, @stddedn = 5284
   else
   	select @lowexempt = 8190, @stddedn = 2642
   	
   /* determine taxable amount */
   if @subjamt * @ppds < @lowexempt goto bspexit
   select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
   
   /* determine base tax amounts and rates */
   /* married */
   if @status = 'M'
   	begin
   	 if @taxable <= 10262 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 10262 and @taxable <= 24322 select @basetax = 102.62, @limit = 10262, @rate = @rate2
   	 if @taxable > 24322 and @taxable <= 38386 select @basetax = 383.82, @limit = 24322, @rate = @rate3
   	 if @taxable > 38386 and @taxable <= 53288 select @basetax = 946.38, @limit = 38386, @rate = @rate4
   	 if @taxable > 53288 and @taxable <= 67346 select @basetax = 1840.50, @limit = 53288, @rate = @rate5
   	 if @taxable > 67346 select @basetax = 2965.14, @limit = 67346, @rate = @rate6
   	end
   /* head of household */
   if @status = 'H'
   	begin
   	 if @taxable <= 10264 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 10264 and @taxable <= 24323 select @basetax = 102.64, @limit = 10264, @rate = @rate2
   	 if @taxable > 24323 and @taxable <= 31353 select @basetax = 383.82, @limit = 24323, @rate = @rate3
   	 if @taxable > 31353 and @taxable <= 38803 select @basetax = 665.02, @limit = 31353, @rate = @rate4
   	 if @taxable > 38803 and @taxable <= 45833 select @basetax = 1112.02, @limit = 38803, @rate = @rate5
   	 if @taxable > 45833 select @basetax = 1674.42, @limit = 45833, @rate = @rate6
   	end
    /* single */
   if @status <> 'M' and @status <> 'H'
   	begin	
   	 if @taxable <= 5131 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 5131 and @taxable <= 12161 select @basetax = 50.31, @limit = 5131, @rate = @rate2
   	 if @taxable > 12161 and @taxable <= 19193 select @basetax = 191.91, @limit = 12161, @rate = @rate3
   	 if @taxable > 19193 and @taxable <= 26644 select @basetax = 473.19, @limit = 19193, @rate = @rate4
   	 if @taxable > 26644 and @taxable <= 33673 select @basetax = 920.25, @limit = 26644, @rate = @rate5
   	 if @taxable > 33673 select @basetax = 1482.57, @limit = 33673, @rate = @rate6
   	end
   
   /* calculate tax */
   select @amt = (@basetax + (@taxable - @limit) * @rate)
   
   /* adjust for personal exemption */
   select @amt = @amt - (@regexempts * 70)
   
   /* finish calculation */
   if @amt < 0 select @amt = 0
   select @amt = @amt / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT99] TO [public]
GO
