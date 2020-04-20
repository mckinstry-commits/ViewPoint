SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRHIT09    Script Date: 8/28/99 9:33:22 AM ******/
 CREATE proc [dbo].[bspPRHIT09]
 /********************************************************
 * CREATED BY: 	EN 10/26/00 - this revision effective 1/1/2001
 * MODIFIED BY:  EN 10/30/00 - not using correct rates for the 2 highest Married and Single brackets
 *				EN 12/18/01 - update effective 1/1/2002
 *				EN 10/8/02 - issue 18877 change double quotes to single
 *				EN 1/4/05 - issue 26244  default status and exemptions
 *				EN 11/06/06 - issue 123014  update effective 1/1/2007
 *				EN 6/12/2009 #133757 updated effective 1/1/2009 (retroactive)
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
 @rate4 bRate, @rate5 bRate, @rate6 bRate, @rate7 bRate, @rate8 bRate, @procname varchar(30)
 
 select @rcode = 0, @allowance = 1040
 select @rate1 = .014, @rate2 = .032, @rate3 = .055, @rate4 = .064, @rate5 = .068, 
		@rate6 = .072, @rate7 = .076, @rate8 = .079
 select @procname = 'bspPRHIT09'
 
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
 	 if @taxincome <= 2400 select @basetax = 0, @limit = 0, @rate = @rate1
 	 if @taxincome > 2400 and @taxincome <= 4800 select @basetax = 34, @limit = 2400, @rate = @rate2
 	 if @taxincome > 4800 and @taxincome <= 9600 select @basetax = 110, @limit = 4800, @rate = @rate3
 	 if @taxincome > 9600 and @taxincome <= 14400 select @basetax = 374, @limit = 9600, @rate = @rate4
 	 if @taxincome > 14400 and @taxincome <= 19200 select @basetax = 682, @limit = 14400, @rate = @rate5
 	 if @taxincome > 19200 and @taxincome <= 24000 select @basetax = 1008, @limit = 19200, @rate = @rate6
 	 if @taxincome > 24000 and @taxincome <= 36000 select @basetax = 1354, @limit = 24000, @rate = @rate7
 	 if @taxincome > 36000 select @basetax = 2266, @limit = 36000, @rate = @rate8
 	end
 
 if @status = 'M'
 	begin
 	 if @taxincome <= 4800 select @basetax = 0, @limit = 0, @rate = @rate1
 	 if @taxincome > 4800 and @taxincome <= 9600 select @basetax = 67, @limit = 4800, @rate = @rate2
 	 if @taxincome > 9600 and @taxincome <= 19200 select @basetax = 221, @limit = 9600, @rate = @rate3
 	 if @taxincome > 19200 and @taxincome <= 28800 select @basetax = 749, @limit = 19200, @rate = @rate4
 	 if @taxincome > 28800 and @taxincome <= 38400 select @basetax = 1363, @limit = 28800, @rate = @rate5
 	 if @taxincome > 38400 and @taxincome <= 48000 select @basetax = 2016, @limit = 38400, @rate = @rate6
 	 if @taxincome > 48000 and @taxincome <= 72000 select @basetax = 2707, @limit = 48000, @rate = @rate7
 	 if @taxincome > 72000 select @basetax = 4531, @limit = 72000, @rate = @rate8
 	end
 
 /* calculate tax */
 select @amt = (@basetax + ((@taxincome - @limit) * @rate)) / @ppds
 if @amt < 0 select @amt = 0
 
 
 bspexit:
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRHIT09] TO [public]
GO
