SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRHIT98    Script Date: 8/28/99 9:33:22 AM ******/
   CREATE   proc [dbo].[bspPRHIT98]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY:	GG 8/11/98
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
   @rate4 bRate, @rate5 bRate, @procname varchar(30)
   
   select @rcode = 0, @allowance = 1040
   select @rate1 = .02, @rate2 = .04, @rate3 = .06, @rate4 = .0725, @rate5 = .08
   select @procname = 'bspPRHIT98'
   
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
   	 if @taxincome <= 1500 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxincome > 1500 and @taxincome <= 2500 select @basetax = 30, @limit = 1500, @rate = @rate2
   	 if @taxincome > 2500 and @taxincome <= 3500 select @basetax = 70, @limit = 2500, @rate = @rate3
   	 if @taxincome > 3500 and @taxincome <= 5500 select @basetax = 130, @limit = 3500, @rate = @rate4
   	 if @taxincome > 5500 select @basetax = 275, @limit = 5500, @rate = @rate5
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome <= 3000 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxincome > 3000 and @taxincome <= 5000 select @basetax = 60, @limit = 3000, @rate = @rate2
   	 if @taxincome > 5000 and @taxincome <= 7000 select @basetax = 140, @limit = 5000, @rate = @rate3
   	 if @taxincome > 7000 and @taxincome <= 11000 select @basetax = 260, @limit = 7000, @rate = @rate4
   	 if @taxincome > 11000 select @basetax = 550, @limit = 11000, @rate = @rate5
   	end
   	
   /* calculate tax */
   select @amt = (@basetax + ((@taxincome - @limit) * @rate)) / @ppds
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRHIT98] TO [public]
GO
