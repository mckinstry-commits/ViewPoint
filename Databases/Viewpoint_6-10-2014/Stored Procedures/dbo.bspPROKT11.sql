SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].[bspPROKT10]    Script Date: 12/18/2007 10:31:21 ******/
 CREATE  proc [dbo].[bspPROKT11]
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
  *				MV 12/21/10 - #142572 updated effective 1/1/2011
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
  GRANT EXECUTE ON bspPROKT11 TO public;
	GO
  **********************************************************/
  (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
  @amt bDollar = 0 output, @msg varchar(255) = null output)
  as
  set nocount on
 
  declare @rcode int, @annualized_wage bDollar, @rate bRate,
  @procname varchar(30), @tax_addition bDollar, @wage_bracket int,
  @deduction_1 int, @deduction_2 int
 
 
  select @rcode = 0, @procname = 'bspPROKT11'
 
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
  	if @annualized_wage >= 11600 select @tax_addition = 0, @wage_bracket = 11600, @rate = .05
  	if @annualized_wage >= 13600 select @tax_addition = 10, @wage_bracket = 13600, @rate = .01
  	if @annualized_wage >= 16600 select @tax_addition = 40, @wage_bracket = 16600, @rate = .02
  	if @annualized_wage >= 19100 select @tax_addition = 90, @wage_bracket = 19100, @rate = .03
  	if @annualized_wage >= 21400 select @tax_addition = 159, @wage_bracket = 21400, @rate = .04
  	if @annualized_wage >= 23800 select @tax_addition = 255, @wage_bracket = 23800, @rate = .05
  	if @annualized_wage >= 26600 select @tax_addition = 395, @wage_bracket = 26600, @rate = .055
  end
 
  /* select calculation elements for everybody else */
  if @status = 'S' or @status = 'H'
  begin
  	if @annualized_wage >= 5800 select @tax_addition = 0, @wage_bracket = 5800, @rate = .05
  	if @annualized_wage >= 6800 select @tax_addition = 5, @wage_bracket = 6800, @rate = .01
  	if @annualized_wage >= 8300 select @tax_addition = 20, @wage_bracket = 8300, @rate = .02
  	if @annualized_wage >= 9550 select @tax_addition = 45, @wage_bracket = 9550, @rate = .03
  	if @annualized_wage >= 10700 select @tax_addition = 79.5, @wage_bracket = 10700, @rate = .04
  	if @annualized_wage >= 13000 select @tax_addition = 171.5, @wage_bracket = 13000, @rate = .05
  	if @annualized_wage >= 14500 select @tax_addition = 246.5, @wage_bracket = 14500, @rate = .055
  end
 
  /* calculate Oklahoma Tax */
  select @amt = @tax_addition + (@annualized_wage - @wage_bracket) * @rate
  select @amt = ROUND((@amt/ @ppds),0)
 
 
  bspexit:
  	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPROKT11] TO [public]
GO
