SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRVTT08]    Script Date: 12/13/2007 08:31:44 ******/
  CREATE  proc [dbo].[bspPRVTT08]
   /********************************************************
   * CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
   * MODIFIED BY:	EN 10/9/02 - issue 18877 change double quotes to single
   *				EN 12/2/02 - issue 19527  update effective 1/1/2003
   *				EN 11/14/03 - issue 23021  update effective 1/1/2004
   *				EN 12/08/04 - issue 26448  update effective 1/1/2005
   *				EN 1/11/05 - issue 26244  default status and exemptions
   *				EN 12/12/05 - issue 119629  update effective 1/1/2006
   *				EN 12/08/06 - issue 123285
   *				EN 12/13/07 - issue 126486 update effective 1/1/2008
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
  
  
   select @rcode = 0, @procname = 'bspPRVTT08'
  
   -- #26244 set default status and/or exemptions if passed in values are invalid
   if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
   if @exempts is null select @exempts = 0
 
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  
   	goto bspexit
   	end
  
  
   /* annualize taxable income  */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * 3500)
  
  
   /* select calculation elements for single folk */
   if @status = 'S'
   begin
   	if @annualized_wage <= 2650 goto bspexit
   	if @annualized_wage > 2650 select @tax_addition = 0, @rate = .036, @wage_bracket = 2650
   	if @annualized_wage > 33960 select @tax_addition = 1127.16, @rate = .072, @wage_bracket = 33960
   	if @annualized_wage > 79725 select @tax_addition = 4422.24,  @rate = .085, @wage_bracket = 79725
   	if @annualized_wage > 166500 select @tax_addition = 11798.12, @rate = .09, @wage_bracket = 166500
   	if @annualized_wage > 359650 select @tax_addition = 29181.62, @rate = .095, @wage_bracket = 359650
   end
  
   /* select calculation elements for married folk */
   if @status = 'M'
   begin
   	if @annualized_wage <= 8000 goto bspexit
   	if @annualized_wage > 8000 select @tax_addition = 0, @rate = .036, @wage_bracket = 8000
   	if @annualized_wage > 60200 select @tax_addition = 1879.20, @rate = .072, @wage_bracket = 60200
   	if @annualized_wage > 137850 select @tax_addition = 7470.00,  @rate = .085, @wage_bracket = 137850
   	if @annualized_wage > 207700 select @tax_addition = 13407.25, @rate = .09, @wage_bracket = 207700
   	if @annualized_wage > 365100 select @tax_addition = 27573.25, @rate = .095, @wage_bracket = 365100
   end
  
   bspcalc: /* calculate Vermont Tax */
  
   select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
  
  
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRVTT08] TO [public]
GO
