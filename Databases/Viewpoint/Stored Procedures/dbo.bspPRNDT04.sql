SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNDT04    Script Date: 8/28/99 9:33:29 AM ******/
   CREATE        proc [dbo].[bspPRNDT04]
   /********************************************************
   * CREATED BY: 	bc 6/15/98
   * MODIFIED BY:	GG 8/11/98
   *				EN 11/13/01 - issue 15016 - effective 1/1/2002
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 11/11/02 issue 24562  update effective 1/1/2003
   *			 	EN 12/17/02 issue 24562  allowance changed back to 2002 value ($3,050.00)
   *				EN 12/01/03 issue 23129  update effective 1/1/2004
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
   
   select @rcode = 0, @procname = 'bspPRNDT04'
   select @allowance = 3100
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
   	 if @taxincome > 3300 and @taxincome <= 30800 select @basetax = 0, @limit = 3300, @rate = @rate1
   	 if @taxincome > 30800 and @taxincome <= 65000 select @basetax = 577.50, @limit = 30800, @rate = @rate2
   	 if @taxincome > 65000 and @taxincome <= 148700 select @basetax = 1918.14, @limit = 65000, @rate = @rate3
   	 if @taxincome > 148700 and @taxincome <= 321000 select @basetax = 5550.72, @limit = 148700, @rate = @rate4
   	 if @taxincome > 321000 select @basetax = 14234.64, @limit = 321000, @rate = @rate5
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome > 8050 and @taxincome <= 55000 select @basetax = 0, @limit = 8050, @rate = @rate1
   	 if @taxincome > 55000 and @taxincome <= 104500 select @basetax = 985.95, @limit = 55000, @rate = @rate2
   	 if @taxincome > 104500 and @taxincome <= 185550 select @basetax = 2926.35, @limit = 104500, @rate = @rate3
   	 if @taxincome > 185550 and @taxincome <= 326000 select @basetax = 6443.92, @limit = 185550, @rate = @rate4
   	 if @taxincome > 326000 select @basetax = 13522.60, @limit = 326000, @rate = @rate5
   	end
   
   /* calculate tax */
   select @amt = ROUND((@basetax + ((@taxincome - @limit) * @rate)) / @ppds, 0)
   
   if @amt < 0 select @amt = 0
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNDT04] TO [public]
GO
