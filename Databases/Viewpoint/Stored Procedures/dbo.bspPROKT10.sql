SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPROKT10]    Script Date: 12/18/2007 10:31:21 ******/
 CREATE  proc [dbo].[bspPROKT10]
  /********************************************************
  * CREATED BY: 	bc 6/4/98
  * MODIFIED BY:	EN 12/17/98
  * MODIFIED BY:  EN 12/22/99 - fixed to round tax to nearest dollar
  *				 EN 12/18/01 - update effective 1/1/2002 - Fixed
  *				 EN 1/18/02 - issue 15955 - changed tax rate on wages over $22,560 from .0665 to .07
  *				EN 10/8/02 - issue 18877 change double quotes to single
  *				EN 12/30/02 - issue 19786  update effective 1/1/2003
  *				EN 12/30/03 - issue 23419  update effective 1/1/2004
  *				EN 12/23/04 - issue 26631  update effective 1/1/2005
  *				EN 1/10/05 - issue 26244  default status and exemptions
  *				EN 12/22/05 - issue 119715  update effective 1/1/2006
  *				EN 12/11/06 - issue 123295  update effective 1/1/2007
  *				EN 12/18/07 - issue 126532  update effective 1/1/2008
  *				EN 12/11/08 - #131413  update effective 1/1/2009
  *				EN 12/18/09 #137167  updated effective 1/1/2010
  *
  * USAGE:
  * 	Calculates Oklahoma Income Tax
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
 
  declare @rcode int, @annualized_wage bDollar, @rate bRate,
  @procname varchar(30), @tax_addition bDollar, @wage_bracket int,
  @deduction_1 int, @deduction_2 int
 
 
  select @rcode = 0, @procname = 'bspPROKT10'
 
  -- #26244 set default status and/or exemptions if passed in values are invalid
  if (@status is null) or (@status is not null and @status not in ('S','M','H')) select @status = 'S'
  if @exempts is null select @exempts = 0
 
  if @ppds = 0
  	begin
  	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  	goto bspexit
  	end
 
 
  /* annualize taxable income and subtract per exemption allowance */
  select @annualized_wage = (@subjamt * @ppds) - (@exempts * 1000)
 
  if @annualized_wage < 0 goto bspexit
  
  /* select calculation elements for married people */
  if @status = 'M'
  begin
  	if @annualized_wage >= 11400 select @tax_addition = 0, @wage_bracket = 11400, @rate = .05
  	if @annualized_wage >= 13400 select @tax_addition = 10, @wage_bracket = 13400, @rate = .01
  	if @annualized_wage >= 16400 select @tax_addition = 40, @wage_bracket = 16400, @rate = .02
  	if @annualized_wage >= 18900 select @tax_addition = 90, @wage_bracket = 18900, @rate = .03
  	if @annualized_wage >= 21200 select @tax_addition = 159, @wage_bracket = 21200, @rate = .04
  	if @annualized_wage >= 23600 select @tax_addition = 255, @wage_bracket = 23600, @rate = .05
  	if @annualized_wage >= 26400 select @tax_addition = 395, @wage_bracket = 26400, @rate = .055
  end
 
  /* select calculation elements for everybody else */
  if @status = 'S' or @status = 'H'
  begin
  	if @annualized_wage >= 5700 select @tax_addition = 0, @wage_bracket = 5700, @rate = .05
  	if @annualized_wage >= 6700 select @tax_addition = 5, @wage_bracket = 6700, @rate = .01
  	if @annualized_wage >= 8200 select @tax_addition = 20, @wage_bracket = 8200, @rate = .02
  	if @annualized_wage >= 9450 select @tax_addition = 45, @wage_bracket = 9450, @rate = .03
  	if @annualized_wage >= 10600 select @tax_addition = 79.5, @wage_bracket = 10600, @rate = .04
  	if @annualized_wage >= 12900 select @tax_addition = 171.5, @wage_bracket = 12900, @rate = .05
  	if @annualized_wage >= 14400 select @tax_addition = 246.5, @wage_bracket = 14400, @rate = .055
  end
 
  /* calculate Oklahoma Tax */
  select @amt = @tax_addition + (@annualized_wage - @wage_bracket) * @rate
  select @amt = ROUND((@amt/ @ppds),0)
 
 
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPROKT10] TO [public]
GO
