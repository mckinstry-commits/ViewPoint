SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCAT05    Script Date: 8/28/99 9:33:13 AM ******/
    CREATE proc [dbo].[bspPRCAT05]
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
    @rate1 bRate, @rate2 bRate, @rate3 bRate, @rate4 bRate, @rate5 bRate, @rate6 bRate, @rate7 bRate,
    @procname varchar(30)
    
    select @rcode = 0, @lowexempt = 0, @stddedn = 0, @taxable = 0, @estdedn = 1000 -- estdedn is from Table 2
    select @basetax = 0, @limit = 0, @rate = 0
    select @rate1 = .01, @rate2 = .02, @rate3 = .04, @rate4 = .06, @rate5 = .08, @rate6 = .093, @rate7 = .103
    select @procname = 'bspPRCAT05'
    
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    	goto bspexit
    	end
    
    /* determine low income exemption and standard deduction */
    if (@status = 'M' and @regexempts >= 2) or @status = 'H'
    	select @lowexempt = 20931, @stddedn = 6330 -- lowexempt is from Table 1 and stddedn is from Table 3
    else
    	select @lowexempt = 10492, @stddedn = 3165 -- lowexempt is from Table 1 and stddedn is from Table 3
    
    /* determine taxable amount */
    if @subjamt * @ppds < @lowexempt goto bspexit
    select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
    
    /* determine base tax amounts and rates */
    /* married */
    if @status = 'M'
    	begin
    	 if @taxable <= 12294 select @basetax = 0, @limit = 0, @rate = @rate1
    	 if @taxable > 12294 and @taxable <= 29142 select @basetax = 122.94, @limit = 12294, @rate = @rate2
    	 if @taxable > 29142 and @taxable <= 45994 select @basetax = 459.9, @limit = 29142, @rate = @rate3
    	 if @taxable > 45994 and @taxable <= 63850 select @basetax = 1133.98, @limit = 45994, @rate = @rate4
    	 if @taxable > 63850 and @taxable <= 80692 select @basetax = 2205.34, @limit = 63850, @rate = @rate5
    	 if @taxable > 80692 and @taxable <= 999999 select @basetax = 3552.7, @limit = 80692, @rate = @rate6
    	 if @taxable > 999999 select @basetax = 89048.25, @limit = 999999, @rate = @rate7
    	end
    /* head of household */
    if @status = 'H'
    	begin
    	 if @taxable <= 12300 select @basetax = 0, @limit = 0, @rate = @rate1
    	 if @taxable > 12300 and @taxable <= 29143 select @basetax = 123.00, @limit = 12300, @rate = @rate2
    	 if @taxable > 29143 and @taxable <= 37567 select @basetax = 459.86, @limit = 29143, @rate = @rate3
    	 if @taxable > 37567 and @taxable <= 46494 select @basetax = 796.82, @limit = 37567, @rate = @rate4
    	 if @taxable > 46494 and @taxable <= 54918 select @basetax = 1332.44, @limit = 46494, @rate = @rate5
    	 if @taxable > 54918 and @taxable <= 999999 select @basetax = 2006.36, @limit = 54918, @rate = @rate6
    	 if @taxable > 999999 select @basetax = 89898.89, @limit = 999999, @rate = @rate7
    	end
    
    
    /* single */
    if @status <> 'M' and @status <> 'H'
    	begin
    	 if @taxable <= 6147 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
    	 if @taxable > 6147 and @taxable <= 14571 select @basetax = 61.47, @limit = 6147, @rate = @rate2
    	 if @taxable > 14571 and @taxable <= 22997 select @basetax = 229.95, @limit = 14571, @rate = @rate3
    	 if @taxable > 22997 and @taxable <= 31925 select @basetax = 566.99, @limit = 22997, @rate = @rate4
    	 if @taxable > 31925 and @taxable <= 40346 select @basetax = 1102.67, @limit = 31925, @rate = @rate5
    	 if @taxable > 40346 and @taxable <= 999999 select @basetax = 1776.35, @limit = 40346, @rate = @rate6
    	 if @taxable > 999999 select @basetax = 91024.08, @limit = 999999, @rate = @rate7
    	end
    
    /* calculate tax */
    select @amt = (@basetax + (@taxable - @limit) * @rate)
    
    /* adjust for personal exemption */
    select @amt = @amt - (@regexempts * 85) -- multiply regexempts by exemption allowance from Table 4
    
    /* finish calculation */
    if @amt < 0 select @amt = 0
    select @amt = @amt / @ppds
    
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT05] TO [public]
GO
