SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNYY052    Script Date: 8/28/99 9:33:31 AM ******/
     CREATE proc [dbo].[bspPRNYY052]
     /********************************************************
     * CREATED BY: 	bc 6/12/98
     * MODIFIED BY:	EN 1/27/99
     * MODIFIED BY:  EN 1/17/00 - tax addition amount wasn't being initialized for the lowest resident tax bracket which would have causeed no tax to be calculated
     * MODIFIED BY:  EN 1/27/00 - nonresident tax rate changed from 50% to 25%
     *               EN 2/2/00 - fixed nonresident tax rates which were coded as .025 and should have been .0025
     *               EN 2/9/00 - fixed nonresident part of routine to correctly calc highest tax bracket ... replaced else with if
     *				EN 10/8/02 - issue 18877 change double quotes to single
     *				EN 7/7/03 - issue 21772 update effective 7/1/03
     *				EN 12/01/03 issue 22943  update effective 7/1/04
     *				EN 11/11/04 issue 25796  update effective 1/1/05
     *				EN 1/10/05 - issue 26244  default status and exemptions
     *
     * USAGE:
     * 	Calculates Yonkers City Tax
     *
     * INPUT PARAMETERS:
     *	@subjamt 	subject earnings
     *	@ppds		# of pay pds per year
     *	@status		filing status
     *	@exempts	# of exemptions
     *	@resident	Yes or No whether they're lost in Yonkers or not
     *
     * OUTPUT PARAMETERS:
     *	@amt		calculated Yonkers tax amount
     *	@msg		error message if failure
     *
     * RETURN VALUE:
     * 	0 	    	success
     *	1 		failure
     **********************************************************/
     (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0, @resident bYN = null,
     @amt bDollar = 0 output, @msg varchar(255) = null output)
     as
     set nocount on
    
     declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
     @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
    
     select @rcode = 0, @allowance = 1000, @procname = 'bspPRNYY052'
    
     -- #26244 set default status and/or exemptions if passed in values are invalid
     if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
     if @exempts is null select @exempts = 0
   
     if @ppds = 0
     	begin
     	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
     	goto bspexit
     	end
    
    
     if @status = 'S' select @deduction = 6975
     if @status = 'M' select @deduction = 7475
    
    
     /* single and married code for residents of Yonkers */
     if @resident ='Y'
     begin
    
     /* annualize taxable income */
     select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance) - @deduction
     if @annualized_wage <= 0 goto bspexit
    
     /* initialize calculation elements */
     if @status = 'S'
    	begin
     	if @annualized_wage <= 8000 select @tax_addition = 0, @wage_bracket = 0, @rate = .04
     	if @annualized_wage > 8000 select @tax_addition = 320, @wage_bracket = 8000, @rate = .045
     	if @annualized_wage > 11000 select @tax_addition = 455, @wage_bracket = 11000, @rate = .0525
     	if @annualized_wage > 13000 select @tax_addition = 560, @wage_bracket = 13000, @rate = .059
     	if @annualized_wage > 20000 select @tax_addition = 973, @wage_bracket = 20000, @rate = .0685
     	if @annualized_wage > 90000 select @tax_addition = 5768, @wage_bracket = 90000, @rate = .0764
     	if @annualized_wage > 100000 select @tax_addition = 6532, @wage_bracket = 100000, @rate = .0854
     	if @annualized_wage > 150000 select @tax_addition = 10802, @wage_bracket = 150000, @rate = .0855
     	if @annualized_wage > 200000 select @tax_addition = 15077, @wage_bracket = 200000, @rate = .0775
     	if @annualized_wage > 500000 select @tax_addition = 38327, @wage_bracket = 500000, @rate = .0820
    	end
     if @status = 'M'
    	begin
     	if @annualized_wage <= 8000 select @tax_addition = 0, @wage_bracket = 0, @rate = .04
     	if @annualized_wage > 8000 select @tax_addition = 320, @wage_bracket = 8000, @rate = .045
     	if @annualized_wage > 11000 select @tax_addition = 455, @wage_bracket = 11000, @rate = .0525
     	if @annualized_wage > 13000 select @tax_addition = 560, @wage_bracket = 13000, @rate = .059
     	if @annualized_wage > 20000 select @tax_addition = 973, @wage_bracket = 20000, @rate = .0685
     	if @annualized_wage > 90000 select @tax_addition = 5768, @wage_bracket = 90000, @rate = .0764
     	if @annualized_wage > 100000 select @tax_addition = 6532, @wage_bracket = 100000, @rate = .0814
     	if @annualized_wage > 150000 select @tax_addition = 10604, @wage_bracket = 150000, @rate = .0895
     	if @annualized_wage > 200000 select @tax_addition = 15077, @wage_bracket = 200000, @rate = .0775
     	if @annualized_wage > 500000 select @tax_addition = 38327, @wage_bracket = 500000, @rate = .0820
    	end
    
     res_calc: /* calculate Yonkers City Tax for residents */
    
     select @amt = ((@tax_addition + (@annualized_wage - @wage_bracket) * @rate) / @ppds) * .05
     goto bspexit
    
     end
    
    
     /* code for anyone who works in NYC but doesn't live there */
    
     if @resident = 'N'
     begin
    
     /* annualize taxable income */
     select @annualized_wage = (@subjamt * @ppds)
    
     /* initialize calculation elements */
    
     	if @annualized_wage < 4000 goto bspexit
     	if @annualized_wage > 4000 select @wage_bracket = 3000, @rate = .0025
     	if @annualized_wage > 10000 select @wage_bracket = 2000, @rate = .0025
     	if @annualized_wage > 20000 select @wage_bracket = 1000, @rate = .0025
     	if @annualized_wage > 30000 select @wage_bracket = 0, @rate = .0025
    
     nonres_calc: /* calculate Yonkers Tax for nonresidents */
    
     select @amt = (@annualized_wage - @wage_bracket) * @rate  / @ppds
     goto bspexit
    
     end
    
    
    
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNYY052] TO [public]
GO
