SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRKYT02    Script Date: 8/28/99 9:33:25 AM ******/
   CREATE   proc [dbo].[bspPRKYT02]
   /********************************************************
   * CREATED BY: EN 10/26/00 - this revision effective 1/1/2001
   * MODIFIED BY: EN 4/11/02 - issue 16966  Std dedn changed from $1750 (year 2001) to $1800
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Kentucky Income Tax
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
   (@subjamt bDollar = 0, @ppds tinyint = 0, @exempts tinyint = 0,
    @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @taxincome bDollar, @stddedn bDollar, @creditamt bDollar,
   @procname varchar(30)
   
   select @rcode = 0, @stddedn = 1800, @creditamt = 20
   select @procname = 'bspPRKYT02'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine taxable income */
   select @taxincome = (@subjamt * @ppds) - @stddedn
   if @taxincome < 0 select @taxincome = 0
   
   /* calculate tax */
   if @taxincome < 3000
   	begin
    	 select @amt = .02 * @taxincome
    	 goto end_loop
   	end
   select @amt = (.02 * 3000)
   select @taxincome = @taxincome - 3000
   
   
   if @taxincome < 1000
   	begin
    	 select @amt = @amt + (.03 * @taxincome)
    	 goto end_loop
   	end
   select @amt = @amt + (.03 * 1000)
   select @taxincome = @taxincome - 1000
   
   if @taxincome < 1000
   	begin
   	 select @amt = @amt + (.04 * @taxincome)
   	 goto end_loop
   	end
   select @amt = @amt + (.04 * 1000)
   select @taxincome = @taxincome - 1000
   
   if @taxincome < 3000
   	begin
   	 select @amt = @amt + (.05 * @taxincome)
   	 goto end_loop
   	end
   select @amt = @amt + (.05 * 3000)
   select @taxincome = @taxincome - 3000
   
   select @amt = @amt + (.06 * @taxincome)
   
   end_loop:
   
   /* subtract credits */
   select @amt = @amt - (@exempts * @creditamt)
   
   /* de-annualize */
   select @amt = @amt / @ppds
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRKYT02] TO [public]
GO
