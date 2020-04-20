SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNDT02    Script Date: 8/28/99 9:33:29 AM ******/
   CREATE    proc [dbo].[bspPRNDT02]
   /********************************************************
   * CREATED BY: 	bc 6/15/98
   * MODIFIED BY:	GG 8/11/98
   *				EN 11/13/01 - issue 15016 - effective 1/1/2002
   *				EN 10/8/02 - issue 18877 change double quotes to single
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
   
   select @rcode = 0, @procname = 'bspPRNDT02'
   select @allowance = 3000
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
   	 if @taxincome > 3200 and @taxincome <= 29650 select @basetax = 0, @limit = 3200, @rate = @rate1
   	 if @taxincome > 29650 and @taxincome <= 61900 select @basetax = 555.45, @limit = 29650, @rate = @rate2
   	 if @taxincome > 61900 and @taxincome <= 142950 select @basetax = 1819.65, @limit = 61900, @rate = @rate3
   	 if @taxincome > 142950 and @taxincome <= 308750 select @basetax = 5337.22, @limit = 142950, @rate = @rate4
   	 if @taxincome > 308750 select @basetax = 13693.54, @limit = 308750, @rate = @rate5
   	end
   
   if @status = 'M'
   	begin
   	 if @taxincome > 7850 and @taxincome <= 51550 select @basetax = 0, @limit = 7850, @rate = @rate1
   	 if @taxincome > 51550 and @taxincome <= 102700 select @basetax = 917.7, @limit = 51550, @rate = @rate2
   	 if @taxincome > 102700 and @taxincome <= 176800 select @basetax = 2922.78, @limit = 102700, @rate = @rate3
   	 if @taxincome > 176800 and @taxincome <= 311900 select @basetax = 6138.72, @limit = 176800, @rate = @rate4
   	 if @taxincome > 311900 select @basetax = 12947.76, @limit = 311900, @rate = @rate5
   	end
   
   /* calculate tax */
   select @amt = (@basetax + ((@taxincome - @limit) * @rate)) / @ppds
   
   if @amt < 0 select @amt = 0
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNDT02] TO [public]
GO
