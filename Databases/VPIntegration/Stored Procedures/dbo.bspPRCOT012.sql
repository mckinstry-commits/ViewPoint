SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCOT012    Script Date: 8/28/99 9:33:14 AM ******/
   CREATE proc [dbo].[bspPRCOT012]
   /********************************************************
   * CREATED BY: 	EN 12/12/00 - tax update effective 1/1/2001
   * MODIFIED BY:	EN 10/7/02 - issue 18877 change double quotes to single
   *				EN 12/31/04 - issue 26244  default status and exemptions
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
   
   select @rcode = 0, @amt = 0, @a = 0, @limit = 0, @procname = 'bspPRCOT012'
   
   -- #26244 set default status and/or exemptions if passed in values are invalid
   if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
   if @exempts is null select @exempts = 0
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* calculate adjusted wages */
   select @a = @subjamt * @ppds - 2850 * @exempts
   
   /* get percentage limit */
   select @limit = 1650
   if @status = 'M' select @limit = 6150
   
   /* calculate tax (=0 if less than or equal to limit) */
   if @a > @limit select @amt = ((@a - @limit) * .0463) / @ppds
   
   select @amt = ROUND(@amt, 0)
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCOT012] TO [public]
GO
