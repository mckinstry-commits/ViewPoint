SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRHIT99    Script Date: 8/28/99 9:33:22 AM ******/
   CREATE   proc [dbo].[bspPRHIT99]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY:	EN 12/16/98
   *				EN 10/8/02 - issue 18877 change double quotes to single
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
   @rate4 bRate, @rate5 bRate, @rate6 bRate, @procname varchar(30)
   
   select @rcode = 0, @allowance = 1040
   select @rate1 = .016, @rate2 = .039, @rate3 = .068, @rate4 = .072, @rate5 = .075, @rate6 = .078
   select @procname = 'bspPRHIT99'
   
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
   	 if @taxincome > 2000 and @taxincome <= 4000 select @basetax = 32, @limit = 2000, @rate = @rate2
   	 if @taxincome > 4000 and @taxincome <= 8000 select @basetax = 110, @limit = 4000, @rate = @rate3
   	 if @taxincome > 8000 and @taxincome <= 12000 select @basetax = 382, @limit = 8000, @rate = @rate4
   	 if @taxincome > 12000 and @taxincome <= 16000 select @basetax = 670, @limit = 12000, @rate = @rate4
   	 if @taxincome > 16000 select @basetax = 970, @limit = 16000, @rate = @rate6
   
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome <= 4000 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxincome > 4000 and @taxincome <= 8000 select @basetax = 64, @limit = 4000, @rate = @rate2
   	 if @taxincome > 8000 and @taxincome <= 16000 select @basetax = 220, @limit = 8000, @rate = @rate3
   	 if @taxincome > 16000 and @taxincome <= 24000 select @basetax = 764, @limit = 16000, @rate = @rate4
   	 if @taxincome > 24000 and @taxincome <= 32000 select @basetax = 1340, @limit = 24000, @rate = @rate4
   	 if @taxincome > 32000 select @basetax = 1940, @limit = 32000, @rate = @rate5
   	end
   	
   /* calculate tax */
   select @amt = (@basetax + ((@taxincome - @limit) * @rate)) / @ppds
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRHIT99] TO [public]
GO
