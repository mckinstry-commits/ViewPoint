SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRCAT10]    Script Date: 11/14/2007 10:31:02 ******/
  CREATE  proc [dbo].[bspPRCAT11]
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
*				EN 11/30/2009 #136817  update effective 1/1/2010
*				CHS 11/11/2010 #142042  update effective 1/1/2011
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
  select @rate1 = .01100, @rate2 = .0220, @rate3 = .0440, @rate4 = .0660, @rate5 = .0880, @rate6 = .1023, @rate7 = .1133
  select @procname = 'bspPRCAT11'
  
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
  	select @lowexempt = 24364, @stddedn = 7340 -- lowexempt is from Table 1 and stddedn is from Table 3
  else
  	select @lowexempt = 12182, @stddedn = 3670 -- lowexempt is from Table 1 and stddedn is from Table 3
  
  /* determine taxable amount */
  if @subjamt * @ppds < @lowexempt goto bspexit
  select @taxable = (@subjamt * @ppds) - @stddedn - (@addexempts * @estdedn)
  
  /* determine base tax amounts and rates */
  /* married */
  if @status = 'M' -- from Table 5 Married
  	begin
  	 if @taxable <= 14248                      select @basetax = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 14248 and @taxable <= 33780 select @basetax = 156.73, @limit = 14248, @rate = @rate2
  	 if @taxable > 33780 and @taxable <= 53314 select @basetax = 586.43, @limit = 33780, @rate = @rate3
  	 if @taxable > 53314 and @taxable <= 74010 select @basetax = 1445.93, @limit = 53314, @rate = @rate4
  	 if @taxable > 74010 and @taxable <= 93532 select @basetax = 2811.87, @limit = 74010, @rate = @rate5
  	 if @taxable > 93532 and @taxable <= 1000000 select @basetax = 4529.81, @limit = 93532, @rate = @rate6
  	 if @taxable > 1000000                       select @basetax = 97261.49, @limit = 1000000, @rate = @rate7
  	end
  	
  /* head of household */
  if @status = 'H' -- from Table 5 Head of household
  	begin
  	 if @taxable <= 14257                      select @basetax = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 14257 and @taxable <= 33780 select @basetax = 156.83, @limit = 14257, @rate = @rate2
   	 if @taxable > 33780 and @taxable <= 43545 select @basetax = 586.34, @limit = 33780, @rate = @rate3
 	 if @taxable > 43545 and @taxable <= 53893 select @basetax = 1016.00, @limit = 43545, @rate = @rate4
  	 if @taxable > 53893 and @taxable <= 63657 select @basetax = 1698.97, @limit = 53893, @rate = @rate5
  	 if @taxable > 63657 and @taxable <= 1000000 select @basetax = 2558.20, @limit = 63657, @rate = @rate6
  	 if @taxable > 1000000                       select @basetax = 98346.09, @limit = 1000000, @rate = @rate7
  	end
  
  /* single */
  if @status <> 'M' and @status <> 'H' -- from Table 5 single
  	begin
  	 if @taxable <= 7124                      select @basetax = 0, @limit = 0, @limit = 0, @rate = @rate1
  	 if @taxable > 7124 and @taxable <= 16890 select @basetax = 78.36, @limit = 7124, @rate = @rate2
  	 if @taxable > 16890 and @taxable <= 26657 select @basetax = 293.21, @limit = 16890, @rate = @rate3
  	 if @taxable > 26657 and @taxable <= 37005 select @basetax = 722.96, @limit = 26657, @rate = @rate4
  	 if @taxable > 37005 and @taxable <= 46766 select @basetax = 1405.93, @limit = 37005, @rate = @rate5
  	 if @taxable > 46766 and @taxable <= 1000000 select @basetax = 2264.90, @limit = 46766, @rate = @rate6
  	 if @taxable > 1000000                       select @basetax = 99780.74, @limit = 1000000, @rate = @rate7
  	end
  

  /* calculate tax */
  select @amt = (@basetax + (@taxable - @limit) * @rate)
  
  /* adjust for personal exemption */
  select @amt = @amt - (@regexempts * 108.90) -- multiply regexempts by exemption allowance from Table 4
  
  /* finish calculation */
  if @amt < 0 select @amt = 0
  select @amt = @amt / @ppds
  
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCAT11] TO [public]
GO
