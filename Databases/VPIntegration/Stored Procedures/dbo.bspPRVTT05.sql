SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRVTT05    Script Date: 8/28/99 9:33:36 AM ******/
    CREATE proc [dbo].[bspPRVTT05]
     /********************************************************
     * CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
     * MODIFIED BY:	EN 10/9/02 - issue 18877 change double quotes to single
     *				EN 12/2/02 - issue 19527  update effective 1/1/2003
     *				EN 11/14/03 - issue 23021  update effective 1/1/2004
     *				EN 12/08/04 - issue 26448  update effective 1/1/2005
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
    
    
     select @rcode = 0, @procname = 'bspPRVTT05'
    
     if @ppds = 0
     	begin
     	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    
     	goto bspexit
     	end
    
    
     /* annualize taxable income  */
     select @annualized_wage = (@subjamt * @ppds) - (@exempts * 3200)
    
    
     /* select calculation elements for single folk */
     if @status = 'S'
     begin
     	if @annualized_wage <= 2650 goto bspexit
     	if @annualized_wage > 2650 select @tax_addition = 0, @rate = .036, @wage_bracket = 2650
     	if @annualized_wage > 31500 select @tax_addition = 1038.6, @rate = .072, @wage_bracket = 31500
     	if @annualized_wage > 69750 select @tax_addition = 3792.6,  @rate = .085, @wage_bracket = 69750
     	if @annualized_wage > 151950 select @tax_addition = 10779.6, @rate = .09, @wage_bracket = 151950
     	if @annualized_wage > 328250 select @tax_addition = 26646.6, @rate = .095, @wage_bracket = 328250
     end
    
     /* select calculation elements for married folk */
     if @status = 'M'
     begin
     	if @annualized_wage <= 8000 goto bspexit
     	if @annualized_wage > 8000 select @tax_addition = 0, @rate = .036, @wage_bracket = 8000
     	if @annualized_wage > 55300 select @tax_addition = 1702.8, @rate = .072, @wage_bracket = 55300
     	if @annualized_wage > 120750 select @tax_addition = 6415.2,  @rate = .085, @wage_bracket = 120750
     	if @annualized_wage > 189600 select @tax_addition = 12267.45, @rate = .09, @wage_bracket = 189600
     	if @annualized_wage > 333250 select @tax_addition = 25195.95, @rate = .095, @wage_bracket = 333250
     end
    
     bspcalc: /* calculate Vermont Tax */
    
     select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
    
    
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRVTT05] TO [public]
GO
