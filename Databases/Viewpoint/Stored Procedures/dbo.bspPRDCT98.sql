SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRDCT98    Script Date: 8/28/99 9:33:16 AM ******/
   CREATE  proc [dbo].[bspPRDCT98]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY:	GG 8/11/98
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates District of Columbia Income Tax
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
   
   declare @rcode int, @a bDollar, @procname varchar(30)
   
   select @rcode = 0, @procname = 'bspPRDCT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize subject amount and subtract exemption amt */
   select @a = (@subjamt * @ppds) - (1370 * @exempts)
   
   /* calculate tax */
   select @amt = 0
   if @a >= 2000 and @a < 10000 select @amt = ((@a - 2000) * .06)
   if @a >= 10000 and @a < 20000 select @amt = (480 + (@a - 10000) * .08)
   if @a >= 20000 select @amt = (1280 + (@a - 20000) * .095)
   select @amt = @amt / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDCT98] TO [public]
GO
