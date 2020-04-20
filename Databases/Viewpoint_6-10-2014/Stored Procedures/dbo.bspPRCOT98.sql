SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCOT98    Script Date: 8/28/99 9:33:14 AM ******/
   CREATE  proc [dbo].[bspPRCOT98]
   /********************************************************
   * CREATED BY: 	EN 6/4/98
   * MODIFIED BY:	GG 8/11/98
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
   
   select @rcode = 0, @a = 0, @limit = 0, @procname = 'bspPRCOT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* calculate adjusted wages */
   select @a = @subjamt * @ppds - 2350 * @exempts
   
   /* get percentage limit */
   select @limit = 1350
   if @status = 'M' select @limit = 3850
   
   /* calculate tax (=0 if less than or equal to limit) */
   if @a > @limit select @amt = ((@a - @limit) * .05) / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCOT98] TO [public]
GO
