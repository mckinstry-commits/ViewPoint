SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRRIT08]    Script Date: 12/18/2007 08:04:43 ******/
  CREATE  proc [dbo].[bspPRRIT08]
  /********************************************************
  * CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
  * MODIFIED BY:	EN 12/18/01 - update effective 1/1/2002
  *				EN 10/9/02 - issue 18877 change double quotes to single
  *				EN 12/2/02 - issue 19517  update effective 1/1/2003
  *				EN 12/09/03 - issue 23230  update effective 1/1/2004
  *				EN 12/15/05 - issue 26538  update effective 1/1/2005
  *				EN 1/11/05 - issue 26244  default status and exemptions
  *				EN 12/27/05 - issue 119724  update effective 1/1/2006
  *				EN 12/22/06 - issue 123385  update effective 1/1/2007
  *				EN 12/18/07 - issue 126525  update effective 1/1/2008
  *
  * USAGE:
  * 	Calculates Rhode Island Income Tax
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
  @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
  
  
  select @rcode = 0, @allowance = 3500, @procname = 'bspPRRIT08'
  
  -- #26244 set default status and/or exemptions if passed in values are invalid
  if (@status is null) or (@status is not null and @status not in ('S','M','H')) select @status = 'S'
  if @exempts is null select @exempts = 0
 
  if @ppds = 0
  	begin
  	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  
  	goto bspexit
  	end
  
  
  /* annualize taxable income less standard deductions */
  select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
  
  
  /* select calculation elements for singles and heads of households */
  if @status = 'S' or @status = 'H'
  begin
  	if @annualized_wage <= 2650 select @tax_addition = 0, @wage_bracket = 0, @rate = 0
  	if @annualized_wage > 2650 select @tax_addition = 0, @wage_bracket = 2650, @rate = .0375
  	if @annualized_wage > 34500 select @tax_addition = 1194.38, @wage_bracket = 34500, @rate = .07
  	if @annualized_wage > 75500 select @tax_addition = 4064.38, @wage_bracket = 75500, @rate = .0775
  	if @annualized_wage > 166500 select @tax_addition = 11116.88, @wage_bracket = 166500, @rate = .09
  	if @annualized_wage > 359650 select @tax_addition = 28500.38, @wage_bracket = 359650, @rate = .099
  end
  
  if @status = 'M'
  begin
  	if @annualized_wage <= 6450 select @tax_addition = 0, @wage_bracket = 0, @rate = 0
  	if @annualized_wage > 6450 select @tax_addition = 0, @wage_bracket = 6450, @rate = .0375
  	if @annualized_wage > 60000 select @tax_addition = 2008.13, @wage_bracket = 60000, @rate = .07
  	if @annualized_wage > 127750 select @tax_addition = 6750.63, @wage_bracket = 127750, @rate = .0775
  	if @annualized_wage > 205950 select @tax_addition = 12811.13, @wage_bracket = 205950, @rate = .09
  	if @annualized_wage > 363300 select @tax_addition = 26972.63, @wage_bracket = 363300, @rate = .099
  end
  
  bspcalc: /* calculate Rhode Island Tax */
  
  
  select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
  
  
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRIT08] TO [public]
GO
