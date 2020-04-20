SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMIT00    Script Date: 8/28/99 9:33:27 AM ******/
   CREATE  proc [dbo].[bspPRMIT00]
   /********************************************************
   * CREATED BY: 	bc 5/29/98
   * MODIFIED BY:	GG 6/01/98
   * 		 EN 12/21/99 - update for tax table change effective 1/1/2000
   *		GG 04/14/00 - reduced tax rate to 4.2%, retro to 1/1/00
   *		EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Michigan (Home of the Red Wings) Income Tax
   *
   * INPUT PARAMETERS:
   
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@exempts	# of exemptions (0-99)
   * 	@addtl_exempts	additional exemptions (for disabilites)
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   (@subjamt bDollar = 0, @ppds tinyint = 0, @exempts tinyint = 0, @addtl_exempts tinyint = 0,
    @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @annualized_wage bDollar, @procname varchar(30), @rate bRate
   
   select @rcode = 0, @rate = .042,  @procname = 'bspPRMIT00'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize earnings and deduct allowance for exemptions */
   select @annualized_wage = (@subjamt * @ppds) - ((@exempts + @addtl_exempts) * 2900)
   
   /* make sure that @annualized_wage is not less than zero after calculation */
   if @annualized_wage < 0
   	begin
   	select @annualized_wage = 0
   	end
   
   bspcalc: /* calculate Michigan Tax */
   	select @amt = (@annualized_wage * @rate) / @ppds
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMIT00] TO [public]
GO
