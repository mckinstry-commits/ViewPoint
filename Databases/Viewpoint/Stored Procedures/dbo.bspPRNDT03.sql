SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNDT03    Script Date: 8/28/99 9:33:29 AM ******/
   CREATE      proc [dbo].[bspPRNDT03]
   /********************************************************
   * CREATED BY: 	bc 6/15/98
   * MODIFIED BY:	GG 8/11/98
   *				EN 11/13/01 - issue 15016 - effective 1/1/2002
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 11/11/02 issue 24562  update effective 1/1/2003
   *			 	EN 12/17/02 issue 24562  allowance changed back to 2002 value ($3,050.00)
   *
   * USAGE:
   * 	Calculates North Dakota Income Tax
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
   
   select @rcode = 0, @procname = 'bspPRNDT03'
   select @allowance = 3050
   select @rate1 = .021, @rate2 = .0392, @rate3 = .0434, @rate4 = .0504, @rate5 = .0554
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   
   /* determine taxable income */
   select @taxincome = (@subjamt * @ppds) - (@exempts * @allowance)
   if @taxincome < 1 select @taxincome = 0
   
   /* determine base tax and rate */
   select @basetax = 0, @limit = 0, @rate = 0
   
   if @status = 'S'
   	begin
   	 if @taxincome > 3200 and @taxincome <= 30100 select @basetax = 0, @limit = 3200, @rate = @rate1
   	 if @taxincome > 30100 and @taxincome <= 63000 select @basetax = 564.90, @limit = 30100, @rate = @rate2
   	 if @taxincome > 63000 and @taxincome <= 145200 select @basetax = 1854.58, @limit = 63000, @rate = @rate3
   	 if @taxincome > 145200 and @taxincome <= 313650 select @basetax = 5422.06, @limit = 145200, @rate = @rate4
   	 if @taxincome > 313650 select @basetax = 13911.94, @limit = 313650, @rate = @rate5
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome > 7850 and @taxincome <= 52300 select @basetax = 0, @limit = 7850, @rate = @rate1
   	 if @taxincome > 52300 and @taxincome <= 104500 select @basetax = 933.45, @limit = 52300, @rate = @rate2
   	 if @taxincome > 104500 and @taxincome <= 179550 select @basetax = 2979.69, @limit = 104500, @rate = @rate3
   	 if @taxincome > 179550 and @taxincome <= 316800 select @basetax = 6236.86, @limit = 179550, @rate = @rate4
   	 if @taxincome > 316800 select @basetax = 13154.26, @limit = 316800, @rate = @rate5
   	end
   
   /* calculate tax */
   select @amt = (@basetax + ((@taxincome - @limit) * @rate)) / @ppds
   
   if @amt < 0 select @amt = 0
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNDT03] TO [public]
GO
