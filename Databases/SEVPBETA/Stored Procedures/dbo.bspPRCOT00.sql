SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCOT00    Script Date: 8/28/99 9:33:14 AM ******/
   CREATE  proc [dbo].[bspPRCOT00]
   /********************************************************
   * CREATED BY: 	EN 6/4/98
   * MODIFIED BY:	EN 12/31/98
   * MODIFIED BY:  EN 7/9/99  change effective 1/1/99
   * MODIFIED BY:  EN 12/2/99 - round tax to nearest dollar
   *               EN 7/7/00 - tax rate changed from 4.75% to 4.63% - effective 1/1/2000
   *				EN 10/7/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Colorado Income Tax
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
   
   declare @rcode int, @a bDollar, @limit bDollar, @procname varchar(30)
   
   select @rcode = 0, @amt = 0, @a = 0, @limit = 0, @procname = 'bspPRCOT00'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* calculate adjusted wages */
   select @a = @subjamt * @ppds - 2750 * @exempts
   
   /* get percentage limit */
   select @limit = 1550
   if @status = 'M' select @limit = 4450
   
   /* calculate tax (=0 if less than or equal to limit) */
   if @a > @limit select @amt = ((@a - @limit) * .0463) / @ppds
   
   select @amt = ROUND(@amt, 0)
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCOT00] TO [public]
GO
