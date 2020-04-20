SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRART98    Script Date: 8/28/99 9:33:12 AM ******/
   CREATE    proc [dbo].[bspPRART98]
   /********************************************************
   * CREATED BY: 	EN 6/1/98
   * MODIFIED BY:	GG 8/11/98
   *				EN 10/7/02 - issue 18877 change double quotes to single
   *				EN 12/03/03 - issue 23061  added isnull check
   *
   * USAGE:
   * 	Calculates Arkansas Income Tax
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
   
   declare @rcode int, @a1 bDollar, @a2 bDollar, @stddedn bDollar, @maxdedn bDollar,
   @pcredits bDollar, @procname varchar(30)
   
   select @rcode = 0, @a1 = 0, @a2 = 0, @stddedn = 0, @maxdedn = 0, @pcredits = 0
   select @procname = 'bspPRART98'
   
   /* validate pay periods */
   if @ppds = 0
   	begin
   	select @msg = isnull(@procname,'') + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize earnings */
   select @a1 = @subjamt * @ppds
   
   /* calculate standard deductions */
   select @stddedn = @a1 * .1
   
   /* set standard deductions limit */
   if @status = 'M' and @exempts = 1 select maxdedn = 500
   if @status = 'M' and @exempts > 1 select maxdedn = 1000
   if @status = 'S' and @exempts > 0 select maxdedn = 1000
   
   if @maxdedn < @stddedn select @stddedn = @maxdedn
   if @exempts = 0 select @stddedn = 0
   
   /* subtract standard deduction from annualized earnings */
   select @a1 = @a1 - @stddedn
   
   /* calculate tax */
   if @a1 < 3000
   	begin
    	 select @amt = .01 * @a1
    	 goto end_loop
   	end
   select @amt = (.01 * 3000)
   select @a1 = @a1 - 3000
   if @a1 < 3000
   	begin
    	 select @amt = @amt + (.025 * @a1)
    	 goto end_loop
   	end
   select @amt = @amt + (.025 * 3000)
   select @a1 = @a1 - 3000
   if @a1 < 3000
   	begin
   	 select @amt = @amt + (.035 * @a1)
   	 goto end_loop
   	end
   select @amt = @amt + (.035 * 3000)
   select @a1 = @a1 - 3000
   if @a1 < 6000
   	begin
   	 select @amt = @amt + (.045 * @a1)
   	 goto end_loop
   	end
   select @amt = @amt + (.045 * 6000)
   select @a1 = @a1 - 6000
   if @a1 < 10000
   	begin
   	 select @amt = @amt + (.06 * @a1)
   	 goto end_loop
   	end
   select @amt = @amt + (.06 * 10000)
   select @a1 = @a1 - 10000
   select @amt = @amt + (.07 * @a1)
   
   end_loop:
   
   /* calculate & subtract personal tax credits */
   if @status = 'S' and @exempts > 0 select @pcredits = 17.5
   if @status = 'S' and @exempts > 1 select @pcredits = @pcredits + (@exempts - 1) * 6
   if @status = 'M' and @exempts = 1 select @pcredits = 17.5
   if @status = 'M' and @exempts > 1 select @pcredits = 2 * 17.5
   if @status = 'M' and @exempts > 2 select @pcredits = @pcredits + (@exempts - 2) * 6
   select @amt = (@amt - @pcredits) / @ppds
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRART98] TO [public]
GO
