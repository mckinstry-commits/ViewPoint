SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNMT06    Script Date: 8/28/99 9:33:30 AM ******/
  CREATE  proc [dbo].[bspPRNMT06]
  /********************************************************
  * CREATED BY: 	EN 10/26/00 - this revision effective 1/1/2001
  * MODIFIED BY:  EN 11/29/00 - lowest tax bracket not being calculated correctly
  * 				EN 11/26/01 - issue 15183 - revision effective 1/1/2002
  *				EN 10/8/02 - issue 18877 change double quotes to single
  *				EN 10/28/02 issue 19131  tax update effective 1/1/2003
  *				EN 5/13/03 - issue 21259  tax update effective retroactive 1/1/2003
  *				EN 10/13/03 - issue 22712  update effective retroactive to 7/1/03
  *				EN 11/21/03 - issue 23079  update effective 1/1/2004
  *				EN 12/17/04 - issue 26566  update effective 1/1/2005
  *				EN 1/10/05 - issue 26244  default status and exemptions
  *				EN 11/18/05 - issue 30404  update effective 1/1/2006
  *
  * USAGE:
  * 	Calculates New Mexico Income Tax
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
  
  declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
  @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
  
  select @rcode = 0, @allowance = 3350, @procname = 'bspPRNMT06'
  
  -- #26244 set default status and/or exemptions if passed in values are invalid
  if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
  if @exempts is null select @exempts = 0
 
  if @ppds = 0
  	begin
  	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  	goto bspexit
  	end
  
  
  
  /* annualize taxable income */
  select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
  
  
  /* initialize calculation elements */
  
  if @status = 'S'
  	begin
  
  	if @annualized_wage <= 1800 goto bspexit
  
  
  	if @annualized_wage <= 7300 select @tax_addition = 0, @wage_bracket = 1800, @rate = .017
  	if @annualized_wage > 7300 select @tax_addition = 93.50, @wage_bracket = 7300, @rate = .032
  	if @annualized_wage > 12800 select @tax_addition = 269.50, @wage_bracket = 12800, @rate = .047
  	if @annualized_wage > 17800 select @tax_addition = 504.5, @wage_bracket = 17800, @rate = .053
  end
  
  if @status = 'M'
  	begin
  
  	if @annualized_wage <= 6950 goto bspexit
  
  
  	if @annualized_wage <= 14950 select @tax_addition = 0, @wage_bracket = 6950, @rate = .017
  	if @annualized_wage > 14950 select @tax_addition = 136, @wage_bracket = 14950, @rate = .032
  	if @annualized_wage > 22950 select @tax_addition = 392, @wage_bracket = 22950, @rate = .047
  	if @annualized_wage > 30950 select @tax_addition = 768, @wage_bracket = 30950, @rate = .053
  end
  
  bspcalc: /* calculate New Mexico Tax */
  
  select @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate)
  if @amt < 29 select @amt = 0 /*annual withholding amounts under $29.00 need not be deducted or withheld */
  select @amt = @amt / @ppds
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNMT06] TO [public]
GO
