SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 CREATE  proc [dbo].[bspPRCOT11]
 /********************************************************
 * CREATED BY: 	EN 12/12/00 - tax update effective 1/1/2001
 * MODIFIED BY:	EN 10/7/02 - issue 18877 change double quotes to single
 *				EN 12/31/04 - issue 26244  default status and exemptions
 *				EN 10/27/06 - issue 30201  tax update effective 1/1/2006
 *				EN 12/14/06 - issue 123313  tax update effective 1/1/2007
 *				EN 5/04/09 #133558  tax update effective 1/1/2009
 *				MV 12/23/10 - #142590 tax updates effective 1/1/2011
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
 * GRANT EXECUTE ON bspPRCOT11 TO public;
 **********************************************************/
 (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
  @amt bDollar = 0 output, @msg varchar(255) = null output)
 as
 set nocount on
 
 declare @rcode int, @a bDollar, @limit bDollar, @procname varchar(30)
 
 select @rcode = 0, @amt = 0, @a = 0, @limit = 0, @procname = 'bspPRCOT11'
 
 -- #26244 set default status and/or exemptions if passed in values are invalid
 if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
 if @exempts is null select @exempts = 0
 
 if @ppds = 0
 	begin
 	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
 	goto bspexit
 	end
 
 /* calculate adjusted wages */
 select @a = @subjamt * @ppds - 3700 * @exempts
 
 /* get percentage limit */
 select @limit = 2100
 if @status = 'M' select @limit = 7900
 
 /* calculate tax (=0 if less than or equal to limit) */
 if @a > @limit select @amt = ((@a - @limit) * .0463) / @ppds
 
 select @amt = ROUND(@amt, 0)
 
 bspexit:
 	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPRCOT11] TO [public]
GO
