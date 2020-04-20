SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRART99    Script Date: 8/28/99 9:33:12 AM ******/
   CREATE    proc [dbo].[bspPRART99]
   /********************************************************
   * CREATED BY: 	EN 6/1/98
   * MODIFIED BY:	EN 1/12/99
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
   
   declare @rcode int, @a1 bDollar, @procname varchar(30)
   
   
   select @rcode = 0, @a1 = 0
   select @procname = 'bspPRART99'
   
   /* validate pay periods */
   if @ppds = 0
   	begin
   	select @msg = isnull(@procname,'') + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize earnings */
   select @a1 = @subjamt * @ppds
   
   /* subtract standard deduction from annualized earnings */
   select @a1 = @a1 - 2000
   
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
   
   /* subtract personal tax credits and de-annualize */
   select @amt = (@amt - (@exempts * 20)) / @ppds
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRART99] TO [public]
GO
