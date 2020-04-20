SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRVTT02    Script Date: 8/28/99 9:33:36 AM ******/
   CREATE   proc [dbo].[bspPRVTT02]
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
   
   
    select @rcode = 0, @procname = 'bspPRVTT02'
   
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
    	goto bspexit
    	end
   
   
    /* annualize taxable income  */
    select @annualized_wage = (@subjamt * @ppds) - (@exempts * 3000)
   
   
    /* select calculation elements for single folk */
    if @status = 'S'
    begin
    	if @annualized_wage <= 2650 goto bspexit
    	if @annualized_wage > 2650 select @tax_addition = 0, @rate = .036, @wage_bracket = 2650
    	if @annualized_wage > 29650 select @tax_addition = 972, @rate = .0672, @wage_bracket = 29650
    	if @annualized_wage > 64820 select @tax_addition = 3335.42,  @rate = .0744, @wage_bracket = 64820
    	if @annualized_wage > 142950 select @tax_addition = 9148.3, @rate = .0864, @wage_bracket = 142950
    	if @annualized_wage > 308750 select @tax_addition = 23473.42, @rate = .095, @wage_bracket = 308750
    end
   
    /* select calculation elements for married folk */
    if @status = 'M'
    begin
    	if @annualized_wage <= 6450 goto bspexit
    	if @annualized_wage > 6450 select @tax_addition = 0, @rate = .036, @wage_bracket = 6450
    	if @annualized_wage > 51550 select @tax_addition = 1623.6, @rate = .0672, @wage_bracket = 51550
    	if @annualized_wage > 109700 select @tax_addition = 5531.28,  @rate = .0744, @wage_bracket = 109700
    	if @annualized_wage > 176800 select @tax_addition = 10523.52, @rate = .0864, @wage_bracket = 176800
    	if @annualized_wage > 311900 select @tax_addition = 22196.16, @rate = .095, @wage_bracket = 311900
    end
   
    bspcalc: /* calculate Vermont Tax */
   
    select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
   
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRVTT02] TO [public]
GO
