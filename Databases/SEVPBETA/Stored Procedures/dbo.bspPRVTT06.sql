SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRVTT06    Script Date: 8/28/99 9:33:36 AM ******/
  CREATE  proc [dbo].[bspPRVTT06]
   /********************************************************
   * CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
   * MODIFIED BY:	EN 10/9/02 - issue 18877 change double quotes to single
   *				EN 12/2/02 - issue 19527  update effective 1/1/2003
   *				EN 11/14/03 - issue 23021  update effective 1/1/2004
   *				EN 12/08/04 - issue 26448  update effective 1/1/2005
   *				EN 1/11/05 - issue 26244  default status and exemptions
   *				EN 12/12/05 - issue 119629  update effective 1/1/2006
   *
   * USAGE:
   * 	Calculates Vermont Income Tax
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
  
   declare @rcode int, @annualized_wage bDollar, @rate bRate, @wage_bracket int,
   @procname varchar(30), @tax_addition bDollar
  
  
   select @rcode = 0, @procname = 'bspPRVTT06'
  
   -- #26244 set default status and/or exemptions if passed in values are invalid
   if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
   if @exempts is null select @exempts = 0
 
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  
   	goto bspexit
   	end
  
  
   /* annualize taxable income  */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * 3300)
  
  
   /* select calculation elements for single folk */
   if @status = 'S'
   begin
   	if @annualized_wage <= 2650 goto bspexit
   	if @annualized_wage > 2650 select @tax_addition = 0, @rate = .036, @wage_bracket = 2650
   	if @annualized_wage > 32240 select @tax_addition = 1065.24, @rate = .072, @wage_bracket = 32240
   	if @annualized_wage > 73250 select @tax_addition = 4017.96,  @rate = .085, @wage_bracket = 73250
   	if @annualized_wage > 156650 select @tax_addition = 11106.96, @rate = .09, @wage_bracket = 156650
   	if @annualized_wage > 338400 select @tax_addition = 27464.46, @rate = .095, @wage_bracket = 338400
   end
  
   /* select calculation elements for married folk */
   if @status = 'M'
   begin
   	if @annualized_wage <= 8000 goto bspexit
   	if @annualized_wage > 8000 select @tax_addition = 0, @rate = .036, @wage_bracket = 8000
   	if @annualized_wage > 56800 select @tax_addition = 1756.8, @rate = .072, @wage_bracket = 56800
   	if @annualized_wage > 126900 select @tax_addition = 6804,  @rate = .085, @wage_bracket = 126900
   	if @annualized_wage > 195450 select @tax_addition = 12630.75, @rate = .09, @wage_bracket = 195450
   	if @annualized_wage > 343550 select @tax_addition = 25959.75, @rate = .095, @wage_bracket = 343550
   end
  
   bspcalc: /* calculate Vermont Tax */
  
   select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
  
  
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRVTT06] TO [public]
GO
