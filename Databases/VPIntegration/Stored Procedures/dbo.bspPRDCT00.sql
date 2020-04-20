SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRDCT00    Script Date: 8/28/99 9:33:16 AM ******/
   CREATE  proc [dbo].[bspPRDCT00]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY:	GG 8/11/98
   * MODIFIED BY:  EN 11/02/99 - modify base tax amts & rates / add calcs for married filing separately - effective 1/1/2000
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
   
   select @rcode = 0, @procname = 'bspPRDCT00'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize subject amount and subtract exemption amt */
   select @a = (@subjamt * @ppds) - (1370 * @exempts)
   
   /* calculate tax */
   select @amt = 0
   if @status <> 'F'
       begin
       if @a >= 2000 and @a < 10000 select @amt = ((@a - 2000) * .05)
       if @a >= 10000 and @a < 20000 select @amt = (400 + (@a - 10000) * .075)
       if @a >= 20000 select @amt = (1150 + (@a - 20000) * .095)
       end
   if @status = 'F'
       begin
       if @a >= 2000 and @a < 10000 select @amt = ((@a - 1000) * .05)
       if @a >= 10000 and @a < 20000 select @amt = (450 + (@a - 10000) * .075)
       if @a >= 20000 select @amt = (12010 + (@a - 20000) * .095)
       end
   select @amt = @amt / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDCT00] TO [public]
GO
