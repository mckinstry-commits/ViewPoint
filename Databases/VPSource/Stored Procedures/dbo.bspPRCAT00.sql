SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCAT00    Script Date: 8/28/99 9:33:13 AM ******/
   CREATE  proc [dbo].[bspPRCAT00]
   /********************************************************
   * CREATED BY: 	EN 6/3/98
   * MODIFIED BY:	EN 12/16/98
   * MODIFIED BY:  EN 11/30/99 - tax table update effective 1/1/2000
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
   select @procname = 'bspPRCAT00'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine low income exemption and standard deduction */
   if (@status = 'M' and @regexempts >= 2) or @status = 'H'
   	select @lowexempt = 16810, @stddedn = 5422
   else
   	select @lowexempt = 8405, @stddedn = 2711
   
   /* determine taxable amount */
   if @subjamt * @ppds < @lowexempt goto bspexit
   select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
   
   /* determine base tax amounts and rates */
   /* married */
   if @status = 'M'
   	begin
   	 if @taxable <= 10528 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 10528 and @taxable <= 24954 select @basetax = 105.28, @limit = 10528, @rate = @rate2
   	 if @taxable > 24954 and @taxable <= 39384 select @basetax = 393.80, @limit = 24954, @rate = @rate3
   	 if @taxable > 39384 and @taxable <= 54674 select @basetax = 971.00, @limit = 39384, @rate = @rate4
   	 if @taxable > 54674 and @taxable <= 69096 select @basetax = 1888.40, @limit = 54674, @rate = @rate5
   	 if @taxable > 69096 select @basetax = 3042.16, @limit = 69096, @rate = @rate6
   	end
   /* head of household */
   if @status = 'H'
   	begin
   	 if @taxable <= 10531 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 10531 and @taxable <= 24955 select @basetax = 105.31, @limit = 10531, @rate = @rate2
   	 if @taxable > 24955 and @taxable <= 32168 select @basetax = 393.79, @limit = 24955, @rate = @rate3
   	 if @taxable > 32168 and @taxable <= 39812 select @basetax = 682.31, @limit = 32168, @rate = @rate4
   	 if @taxable > 39812 and @taxable <= 47025 select @basetax = 1140.95, @limit = 39812, @rate = @rate5
   	 if @taxable > 47025 select @basetax = 1717.99, @limit = 47025, @rate = @rate6
   	end
   
   
   /* single */
   if @status <> 'M' and @status <> 'H'
   	begin
   	 if @taxable <= 5264 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
   	 if @taxable > 5264 and @taxable <= 12477 select @basetax = 52.64, @limit = 5264, @rate = @rate2
   	 if @taxable > 12477 and @taxable <= 19692 select @basetax = 196.90, @limit = 12477, @rate = @rate3
   	 if @taxable > 19692 and @taxable <= 27337 select @basetax = 485.50, @limit = 19692, @rate = @rate4
   	 if @taxable > 27337 and @taxable <= 34548 select @basetax = 944.20, @limit = 27337, @rate = @rate5
   	 if @taxable > 34548 select @basetax = 1521.08, @limit = 34548, @rate = @rate6
   	end
   
   /* calculate tax */
   select @amt = (@basetax + (@taxable - @limit) * @rate)
   
   
   /* adjust for personal exemption */
   select @amt = @amt - (@regexempts * 72)
   
   /* finish calculation */
   if @amt < 0 select @amt = 0
   select @amt = @amt / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT00] TO [public]
GO
