SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRMAT08]    Script Date: 01/17/2008 15:43:05 ******/
  CREATE  proc [dbo].[bspPRMAT08]
  /********************************************************
  * CREATED BY: 	bc 6/1/98
  * MODIFIED BY:  EN 12/20/00 - tax update effective 1/1/2001
  *				GG 08/06/01 - tax amount cannot be negative
  *				 EN 12/19/01 - update effective 1/1/2002
  *				EN 10/8/02 - issue 18877 change double quotes to single
  *				EN 12/16/04 - issue 26562  update effective 1/1/2005
  *				EN 1/4/05 - issue 26244  default exemptions
  *				EN 12/27/05 - issue 119721  update effective 1/1/2006
  *				EN 12/14/06 - issue 123311  update effective 1/1/2007
  *				EN 1/17/08 - issue 126795  updated effective 1/1/2008
  *
  * USAGE:
  * 	Calculates Massachusettes Income Tax
  *
  * INPUT PARAMETERS:
  *	@subjamt 	subject earnings
  *	@ppds		# of pay pds per year
  *	@exempts	# of exemptions (0-99)
  *	@addtl_exempts	# additional exemptions (for disabilities)
  *
  * OUTPUT PARAMETERS:
  *	@amt		calculated tax amount
  *	@msg		error message if failure
  *
  * RETURN VALUE:
  * 	0 	    	success
  *	1 		failure
  **********************************************************/
  (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = null, @exempts tinyint = 0,
  @addtl_exempts tinyint = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
  as
 
  set nocount on
 
  declare @rcode int, @annualized_wage bDollar, @dedn bDollar, @rate bRate,
  @procname varchar(30), @total_exempts tinyint, @FICArate bRate
 
  select @rcode = 0, @rate = .053, @procname = 'bspPRMAT08', @FICArate = .0765
 
  -- #26244 set default exemptions if passed in values are invalid
  if @exempts is null select @exempts = 0
  if @addtl_exempts is null select @addtl_exempts = 0
 
  -- Note: @FICArate = social security rate + medicare rate
 
  if @ppds = 0
  	begin
  	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  	goto bspexit
  	end
 
  /* annualize earnings  */
  select @annualized_wage = (@subjamt * @ppds)
 
 
  /* not eligable for state tax if earnings below 8K */
  if @exempts >= 1 and @annualized_wage <= 8000 goto bspexit
 
  if (@annualized_wage * @FICArate) < 2000
  	select @annualized_wage = @annualized_wage - (@annualized_wage * @FICArate)
  else
  	select @annualized_wage = @annualized_wage - 2000
 
 
  select @total_exempts = @exempts + @addtl_exempts
 
 
  if @total_exempts = 1
  	select @annualized_wage = @annualized_wage - 4400
 
  if @total_exempts >1
  	select @annualized_wage = @annualized_wage - (@total_exempts * 1000) - 3400
 
  -- subtract extra deduction if head of household
  if @status = 'H' select @annualized_wage = @annualized_wage - 2400
 
  bspcalc: /* calculate Massachusettes Tax */
  	select @amt = (@annualized_wage * @rate) / @ppds
 
  bspexit:
 	if @amt < 0 select @amt = 0	-- tax amount should not be negative
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMAT08] TO [public]
GO
