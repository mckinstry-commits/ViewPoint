SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRVTT04    Script Date: 8/28/99 9:33:36 AM ******/
   CREATE     proc [dbo].[bspPRVTT04]
    /********************************************************
    * CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
    * MODIFIED BY:	EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 12/2/02 - issue 19527  update effective 1/1/2003
    *				EN 11/14/03 - issue 23021  update effective 1/1/2004
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
   
   
    select @rcode = 0, @procname = 'bspPRVTT04'
   
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
    	goto bspexit
    	end
   
   
    /* annualize taxable income  */
    select @annualized_wage = (@subjamt * @ppds) - (@exempts * 3100)
   
   
    /* select calculation elements for single folk */
    if @status = 'S'
    begin
    	if @annualized_wage <= 2650 goto bspexit
    	if @annualized_wage > 2650 select @tax_addition = 0, @rate = .036, @wage_bracket = 2650
    	if @annualized_wage > 30800 select @tax_addition = 1013.4, @rate = .072, @wage_bracket = 30800
    	if @annualized_wage > 68500 select @tax_addition = 3727.8,  @rate = .085, @wage_bracket = 68500
    	if @annualized_wage > 148700 select @tax_addition = 10544.8, @rate = .09, @wage_bracket = 148700
    	if @annualized_wage > 321200 select @tax_addition = 26069.8, @rate = .095, @wage_bracket = 321200
    end
   
    /* select calculation elements for married folk */
    if @status = 'M'
    begin
    	if @annualized_wage <= 8000 goto bspexit
    	if @annualized_wage > 8000 select @tax_addition = 0, @rate = .036, @wage_bracket = 8000
    	if @annualized_wage > 53550 select @tax_addition = 1639.8, @rate = .072, @wage_bracket = 53550
    	if @annualized_wage > 118050 select @tax_addition = 6283.8,  @rate = .085, @wage_bracket = 118050
    	if @annualized_wage > 185550 select @tax_addition = 12021.3, @rate = .09, @wage_bracket = 185550
    	if @annualized_wage > 326100 select @tax_addition = 24670.8, @rate = .095, @wage_bracket = 326100
    end
   
    bspcalc: /* calculate Vermont Tax */
   
    select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
   
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRVTT04] TO [public]
GO
