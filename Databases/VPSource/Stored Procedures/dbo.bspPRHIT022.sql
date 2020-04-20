SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRHIT022    Script Date: 8/28/99 9:33:22 AM ******/
   CREATE proc [dbo].[bspPRHIT022]
   /********************************************************
   * CREATED BY: 	EN 10/26/00 - this revision effective 1/1/2001
   * MODIFIED BY:  EN 10/30/00 - not using correct rates for the 2 highest Married and Single brackets
   *				EN 12/18/01 - update effective 1/1/2002
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 1/4/05 - issue 26244  default status and exemptions
   *
   * USAGE:
   * 	Calculates Hawaii Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status
   *	@exempts	# of exemptions
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
    @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @taxincome bDollar, @allowance bDollar, @basetax bDollar,
   @limit bDollar, @rate bRate, @rate1 bRate, @rate2 bRate, @rate3 bRate,
   @rate4 bRate, @rate5 bRate, @rate6 bRate, @rate7 bRate, @procname varchar(30)
   
   select @rcode = 0, @allowance = 1040
   select @rate1 = .014, @rate2 = .032, @rate3 = .055, @rate4 = .064, @rate5 = .068, @rate6 = .072, @rate7 = .076
   select @procname = 'bspPRHIT022'
   
   -- #26244 set default status and/or exemptions if passed in values are invalid
   if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
   if @exempts is null select @exempts = 0
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine taxable income */
   select @taxincome = (@subjamt * @ppds) - (@allowance * @exempts)
   if @taxincome < 0 select @taxincome = 0
   
   /* determine base tax and rate */
   select @basetax = 0, @limit = 0, @rate = 0
   
   if @status = 'S'
   	begin
   	 if @taxincome <= 2000 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxincome > 2000 and @taxincome <= 4000 select @basetax = 28, @limit = 2000, @rate = @rate2
   	 if @taxincome > 4000 and @taxincome <= 8000 select @basetax = 92, @limit = 4000, @rate = @rate3
   	 if @taxincome > 8000 and @taxincome <= 12000 select @basetax = 312, @limit = 8000, @rate = @rate4
   	 if @taxincome > 12000 and @taxincome <= 16000 select @basetax = 568, @limit = 12000, @rate = @rate5
   	 if @taxincome > 16000 and @taxincome <= 20000 select @basetax = 840, @limit = 16000, @rate = @rate6
   	 if @taxincome > 20000 select @basetax = 1128, @limit = 20000, @rate = @rate6
   
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome <= 4000 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxincome > 4000 and @taxincome <= 8000 select @basetax = 56, @limit = 4000, @rate = @rate2
   	 if @taxincome > 8000 and @taxincome <= 16000 select @basetax = 184, @limit = 8000, @rate = @rate3
   	 if @taxincome > 16000 and @taxincome <= 24000 select @basetax = 624, @limit = 16000, @rate = @rate4
   	 if @taxincome > 24000 and @taxincome <= 32000 select @basetax = 1136, @limit = 24000, @rate = @rate5
   	 if @taxincome > 32000 and @taxincome <= 40000 select @basetax = 1680, @limit = 32000, @rate = @rate6
   	 if @taxincome > 40000 select @basetax = 2256, @limit = 40000, @rate = @rate6
   	end
   
   /* calculate tax */
   select @amt = (@basetax + ((@taxincome - @limit) * @rate)) / @ppds
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRHIT022] TO [public]
GO
