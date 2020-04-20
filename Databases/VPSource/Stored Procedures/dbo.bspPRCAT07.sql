SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCAT07    Script Date: 8/28/99 9:33:13 AM ******/
  CREATE  proc [dbo].[bspPRCAT07]
  /********************************************************
  * CREATED BY: 	EN 11/29/00 - this revision effective 1/1/2001
  * MODIFIED BY:  EN 12/11/01 - change effective 1/1/2002
  *				EN 10/7/02 - issue 18877 change double quotes to single
  *				EN 10/19/02 - issue 19393  change effective 1/1/2003
  *				EN 11/19/03 - issue 23040  change effective 1/1/2004
  *				EN 12/31/04 - issue 26244  default status and exemptions
  *				EN 11/28/05 - issue 30680  change effective 1/1/2006
  *				EN 11/13/06 - issue 123075  update effective 1/1/2007
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
  select @procname = 'bspPRCAT07'
  
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
  	select @lowexempt = 22542, @stddedn = 6820 -- lowexempt is from Table 1 and stddedn is from Table 3
  else
  	select @lowexempt = 11271, @stddedn = 3410 -- lowexempt is from Table 1 and stddedn is from Table 3
  
  /* determine taxable amount */
  if @subjamt * @ppds < @lowexempt goto bspexit
  select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
  
  /* determine base tax amounts and rates */
  /* married */
  if @status = 'M'
  	begin
  	 if @taxable <= 13244 select @basetax = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 13244 and @taxable <= 31396 select @basetax = 132.44, @limit = 13244, @rate = @rate2
  	 if @taxable > 31396 and @taxable <= 49552 select @basetax = 495.48, @limit = 31396, @rate = @rate3
  	 if @taxable > 49552 and @taxable <= 68788 select @basetax = 1221.72, @limit = 49552, @rate = @rate4
  	 if @taxable > 68788 and @taxable <= 86934 select @basetax = 2375.88, @limit = 68788, @rate = @rate5
  	 if @taxable > 86934 and @taxable <= 999999 select @basetax = 3827.56, @limit = 86934, @rate = @rate6
  	 if @taxable > 999999 select @basetax = 88742.61, @limit = 999999, @rate = @rate7
  	end
  /* head of household */
  if @status = 'H'
  	begin
  	 if @taxable <= 13251 select @basetax = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 13251 and @taxable <= 31397 select @basetax = 132.51, @limit = 13251, @rate = @rate2
  	 if @taxable > 31397 and @taxable <= 40473 select @basetax = 495.43, @limit = 31397, @rate = @rate3
  	 if @taxable > 40473 and @taxable <= 50090 select @basetax = 858.47, @limit = 40473, @rate = @rate4
  	 if @taxable > 50090 and @taxable <= 59166 select @basetax = 1435.49, @limit = 50090, @rate = @rate5
  	 if @taxable > 59166 and @taxable <= 999999 select @basetax = 2161.57, @limit = 59166, @rate = @rate6
  	 if @taxable > 999999 select @basetax = 89659.04, @limit = 999999, @rate = @rate7
  	end
  
  
  /* single */
  if @status <> 'M' and @status <> 'H'
  	begin
  	 if @taxable <= 6622 select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 6622 and @taxable <= 15698 select @basetax = 66.22, @limit = 6622, @rate = @rate2
  	 if @taxable > 15698 and @taxable <= 24776 select @basetax = 247.74, @limit = 15698, @rate = @rate3
  	 if @taxable > 24776 and @taxable <= 34394 select @basetax = 610.86, @limit = 24776, @rate = @rate4
  	 if @taxable > 34394 and @taxable <= 43467 select @basetax = 1187.94, @limit = 34394, @rate = @rate5
  	 if @taxable > 43467 and @taxable <= 999999 select @basetax = 1913.78, @limit = 43467, @rate = @rate6
  	 if @taxable > 999999 select @basetax = 90871.26, @limit = 999999, @rate = @rate7
  	end
  
  /* calculate tax */
  select @amt = (@basetax + (@taxable - @limit) * @rate)
  
  /* adjust for personal exemption */
  select @amt = @amt - (@regexempts * 91) -- multiply regexempts by exemption allowance from Table 4
  
  /* finish calculation */
  if @amt < 0 select @amt = 0
  select @amt = @amt / @ppds
  
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT07] TO [public]
GO
