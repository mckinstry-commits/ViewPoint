SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRKST98    Script Date: 8/28/99 9:33:24 AM ******/
   CREATE   proc [dbo].[bspPRKST98]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY:	EN 11/10/98
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Kansas Income Tax
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
   @limit bDollar, @rate bRate, @procname varchar(30)
   
   select @rcode = 0, @allowance = 2000
   select @procname = 'bspPRKST98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine taxable income */
   select @taxincome = (@subjamt * @ppds) - (@exempts * @allowance)
   if @taxincome < 0 select @taxincome = 0
   
   /* determine base tax and rate */
   select @basetax = 0, @limit = 0, @rate = 0
   
   if @status = 'S'
   	begin
   	 if @taxincome > 3000 and @taxincome <= 18000 select @basetax = 0, @limit = 3000, @rate = .035
   	 if @taxincome > 18000 and @taxincome <= 33000 select @basetax = 525, @limit = 18000, @rate = .0575
   	 if @taxincome > 33000 select @basetax = 1387.5, @limit = 33000, @rate = .0515
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome > 5000 and @taxincome <= 35000 select @basetax = 0, @limit = 5000, @rate = .035
   	 if @taxincome > 35000 and @taxincome <= 65000 select @basetax = 1050, @limit = 35000, @rate = .0625
   	 if @taxincome > 65000 select @basetax = 2925, @limit = 65000, @rate = .0645
   	end
   	
   /* calculate tax */
   select @amt = round((@basetax + (@taxincome - @limit) * @rate) / @ppds,2)
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRKST98] TO [public]
GO
