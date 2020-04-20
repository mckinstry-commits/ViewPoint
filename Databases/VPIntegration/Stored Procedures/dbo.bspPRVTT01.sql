SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRVTT01    Script Date: 8/28/99 9:33:36 AM ******/
     CREATE   proc [dbo].[bspPRVTT01]
     /********************************************************
     * CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
     * MODIFIED BY:	EN 10/9/02 - issue 18877 change double quotes to single
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
    
    
     select @rcode = 0, @procname = 'bspPRVTT01'
    
     if @ppds = 0
     	begin
     	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    
     	goto bspexit
     	end
    
    
     /* annualize taxable income  */
     select @annualized_wage = (@subjamt * @ppds) - (@exempts * 2900)
    
    
     /* select calculation elements for single folk */
     if @status = 'S'
     begin
     	if @annualized_wage <= 2650 goto bspexit
     	if @annualized_wage > 2650 select @tax_addition = 0, @rate = .036, @wage_bracket = 2650
     	if @annualized_wage > 28700 select @tax_addition = 937.8, @rate = .0672, @wage_bracket = 28700
     	if @annualized_wage > 62200 select @tax_addition = 3189.00,  @rate = .0744, @wage_bracket = 62200
     	if @annualized_wage > 138400 select @tax_addition = 8858.28, @rate = .0864, @wage_bracket = 138400
     	if @annualized_wage > 299000 select @tax_addition = 22734.12, @rate = .095, @wage_bracket = 299000
     end
    
     /* select calculation elements for married folk */
     if @status = 'M'
     begin
     	if @annualized_wage <= 6450 goto bspexit
     	if @annualized_wage > 6450 select @tax_addition = 0, @rate = .036, @wage_bracket = 6450
     	if @annualized_wage > 49900 select @tax_addition = 1564.2, @rate = .0672, @wage_bracket = 49900
     	if @annualized_wage > 105200 select @tax_addition = 5280.36,  @rate = .0744, @wage_bracket = 105200
     	if @annualized_wage > 171200 select @tax_addition = 10190.76, @rate = .0864, @wage_bracket = 171200
     	if @annualized_wage > 302050 select @tax_addition = 21496.2, @rate = .095, @wage_bracket = 302050
     end
    
     bspcalc: /* calculate Vermont Tax */
    
     select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
    
    
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRVTT01] TO [public]
GO
