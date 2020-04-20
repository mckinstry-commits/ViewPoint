SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRVTT03    Script Date: 8/28/99 9:33:36 AM ******/
   CREATE    proc [dbo].[bspPRVTT03]
    /********************************************************
    * CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
    * MODIFIED BY:	EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 12/2/02 - issue 19527  update effective 1/1/2003
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
   
   
    select @rcode = 0, @procname = 'bspPRVTT03'
   
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
    	goto bspexit
    	end
   
   
    /* annualize taxable income  */
    select @annualized_wage = (@subjamt * @ppds) - (@exempts * 3050)
   
   
    /* select calculation elements for single folk */
    if @status = 'S'
    begin
    	if @annualized_wage <= 2650 goto bspexit
    	if @annualized_wage > 2650 select @tax_addition = 0, @rate = .036, @wage_bracket = 2650
    	if @annualized_wage > 30100 select @tax_addition = 988.2, @rate = .072, @wage_bracket = 30100
    	if @annualized_wage > 65920 select @tax_addition = 3567.24,  @rate = .085, @wage_bracket = 65920
    	if @annualized_wage > 145200 select @tax_addition = 10306.04, @rate = .09, @wage_bracket = 145200
    	if @annualized_wage > 313650 select @tax_addition = 25466.54, @rate = .095, @wage_bracket = 313650
    end
   
    /* select calculation elements for married folk */
    if @status = 'M'
    begin
    	if @annualized_wage <= 6450 goto bspexit
    	if @annualized_wage > 6450 select @tax_addition = 0, @rate = .036, @wage_bracket = 6450
    	if @annualized_wage > 52350 select @tax_addition = 1652.4, @rate = .072, @wage_bracket = 52350
    	if @annualized_wage > 111800 select @tax_addition = 5932.8,  @rate = .085, @wage_bracket = 111800
    	if @annualized_wage > 179600 select @tax_addition = 11695.8, @rate = .09, @wage_bracket = 179600
    	if @annualized_wage > 316850 select @tax_addition = 24048.3, @rate = .095, @wage_bracket = 316850
    end
   
    bspcalc: /* calculate Vermont Tax */
   
    select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
   
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRVTT03] TO [public]
GO
