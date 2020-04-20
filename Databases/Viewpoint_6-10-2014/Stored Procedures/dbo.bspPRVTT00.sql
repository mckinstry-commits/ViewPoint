SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRVTT00    Script Date: 8/28/99 9:33:36 AM ******/
    CREATE  proc [dbo].[bspPRVTT00]
    /********************************************************
    * CREATED BY: 	bc 6/8/98
    * MODIFIED BY:	EN 12/31/98
    * MODIFIED BY:  EN 12/22/99 - tax routine update effective 1/1/2000
    * MODIFIED BY:  EN 12/28/99 - missing some parenthesis in tax calculation so that amount was coming out wrong
    * MODIFIED BY:  EN 1/6/00 - fixed tax amount for highest tax bracket which was off slightly
    *				EN 10/9/02 - issue 18877 change double quotes to single
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
   
   
    select @rcode = 0, @procname = 'bspPRVTT00'
   
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
    	goto bspexit
    	end
   
   
    /* annualize taxable income  */
    select @annualized_wage = (@subjamt * @ppds) - (@exempts * 2800)
   
   
    /* select calculation elements for single folk */
    if @status = 'S'
    begin
    	if @annualized_wage <= 2650 goto bspexit
    	if @annualized_wage > 2650 select @tax_addition = 0, @rate = .036, @wage_bracket = 2650
    	if @annualized_wage > 27850 select @tax_addition = 907.2, @rate = .0672, @wage_bracket = 27850
    	if @annualized_wage > 59900 select @tax_addition = 3060.96,  @rate = .0744, @wage_bracket = 59900
    	if @annualized_wage > 134200 select @tax_addition = 8588.88, @rate = .0864, @wage_bracket = 134200
    	if @annualized_wage > 289950 select @tax_addition = 22045.68, @rate = .095, @wage_bracket = 289950
    end
   
    /* select calculation elements for married folk */
    if @status = 'M'
    begin
    	if @annualized_wage <= 6450 goto bspexit
    	if @annualized_wage > 6450 select @tax_addition = 0, @rate = .036, @wage_bracket = 6450
    	if @annualized_wage > 48400 select @tax_addition = 1510.2, @rate = .0672, @wage_bracket = 48400
    	if @annualized_wage > 101000 select @tax_addition = 5044.92,  @rate = .0744, @wage_bracket = 101000
    	if @annualized_wage > 166000 select @tax_addition = 9880.92, @rate = .0864, @wage_bracket = 166000
    	if @annualized_wage > 292900 select @tax_addition = 20845.08, @rate = .095, @wage_bracket = 292900
    end
   
    bspcalc: /* calculate Vermont Tax */
   
    select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
   
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRVTT00] TO [public]
GO
