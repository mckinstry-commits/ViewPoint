SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRMIT08]    Script Date: 11/09/2007 11:13:02 ******/
  CREATE  proc [dbo].[bspPRMIT08]
  /********************************************************
  * CREATED BY: 	bc 5/29/98
  * MODIFIED BY:	GG 6/01/98
  * 		 EN 12/21/99 - update for tax table change effective 1/1/2000
  *		GG 04/14/00 - reduced tax rate to 4.2%, retro to 1/1/00
  *        EN 12/11/01 - update effective 1/1/2002
  *		EN 10/8/02 - issue 18877 change double quotes to single
  *		EN 12/06/02 - issue 19589  update effective 1/1/2003
  *		EN 10/31/03 - issue 22902  update effective 1/1/2004
  *		EN 1/12/04 - issue 23481  update effective 1/1/2004 retracts previous 1/1/2004 change for issue 22902
  *		EN 6/21/04 - issue 23482  update effective 7/1/2004 change rate from 4% to 3.9%
  *		EN 11/11/04 - issue 26150  update effective 1/1/2005 to change allowance from $3100 to $3200
  *		EN 1/4/05 - issue 26244  default exemptions
  *		EN 10/27/05 - issue 30203  update effecitve 1/1/2006
  *		EN 11/15/06 - issue 123103  update effective 1/1/2007
  *		EN 10/2/07 - issue 125642  rate update effective 10/1/2007
  *		EN 11/9/07 - issue 126154  allowance update effective 1/1/2008
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
  
  select @rcode = 0, @rate = .0435,  @procname = 'bspPRMIT08'
  
  -- #26244 set default exemptions if passed in values are invalid
  if @exempts is null select @exempts = 0
  if @addtl_exempts is null select @addtl_exempts = 0
 
  if @ppds = 0
  	begin
  	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  	goto bspexit
  	end
  
  /* annualize earnings and deduct allowance for exemptions */
  select @annualized_wage = (@subjamt * @ppds) - ((@exempts + @addtl_exempts) * 3500)
  
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
GRANT EXECUTE ON  [dbo].[bspPRMIT08] TO [public]
GO
