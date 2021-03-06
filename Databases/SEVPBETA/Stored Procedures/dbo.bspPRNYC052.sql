SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNYC052    Script Date: 8/28/99 9:33:30 AM ******/
    CREATE proc [dbo].[bspPRNYC052]
    /********************************************************
    * CREATED BY: 	EN 12/06/00 - effective 1/1/2001
    * MODIFIED BY:  EN 9/25/01 - effective 10/1/2001
    *				EN 5/17/02 - effective 6/1/2002
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 7/7/03 - issue 21771  update effective 7/1/03
    *				EN 12/01/03 issue 22943  update effective 7/1/04
    *				EN 11/11/04 issue 25796  update effective 1/1/05
    *				EN 1/10/05 - issue 26244  default status and exemptions
    *
    * USAGE:
    * 	Calculates New York City Tax
    *
    * INPUT PARAMETERS:
    *	@subjamt 	subject earnings
    *	@ppds		# of pay pds per year
    *	@status		filing status
    *	@exempts	# of exemptions
    *	@resident	Y or N whether they live in the Big Apple or not
    *
    * OUTPUT PARAMETERS:
    *	@amt		calculated NYC tax amount
    *	@msg		error message if failure
    *
    * RETURN VALUE:
    * 	0 	    	success
    *	1 		failure
    **********************************************************/
    	(@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
    	 @resident bYN = null, @amt bDollar = 0 output, @msg varchar(255) = null output)
    as
    set nocount on
    
    declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
    @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
    
    select @rcode = 0, @allowance = 1000, @procname = 'bspPRNYC052'
    
    -- #26244 set default status and/or exemptions if passed in values are invalid
    if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
    if @exempts is null select @exempts = 0
   
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    	goto bspexit
    	end
    
    
    if @status = 'S' select @deduction = 5000
    if @status = 'M' select @deduction = 5500
    
    
    /* single and married code for residents of NYC */
    if @resident ='Y'
    begin
    
    /* annualize taxable income */
    select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance) - @deduction
    if @annualized_wage <= 0 goto bspexit
    
    /* initialize calculation elements */
    
    if @status = 'S'
    	begin
    	if @annualized_wage <= 8000 select @tax_addition = 0, @wage_bracket = 0, @rate = .019
    	if @annualized_wage > 8000 select @tax_addition = 152, @wage_bracket = 8000, @rate = .0265
    	if @annualized_wage > 8700 select @tax_addition = 171, @wage_bracket = 8700, @rate = .031
    	if @annualized_wage > 15000 select @tax_addition = 366, @wage_bracket = 15000, @rate = .037
    	if @annualized_wage > 25000 select @tax_addition = 736, @wage_bracket = 25000, @rate = .039
    	if @annualized_wage > 60000 select @tax_addition = 2101, @wage_bracket = 60000, @rate = .04
    	if @annualized_wage > 100000 select @tax_addition = 3701, @wage_bracket = 100000, @rate = .044
    	if @annualized_wage > 150000 select @tax_addition = 5901, @wage_bracket = 150000, @rate = .0544
    	if @annualized_wage > 200000 select @tax_addition = 8621, @wage_bracket = 200000, @rate = .044
    	if @annualized_wage > 500000 select @tax_addition = 21821, @wage_bracket = 500000, @rate = .0480
    	end
    if @status = 'M'
    	begin
    	if @annualized_wage <= 8000 select @tax_addition = 0, @wage_bracket = 0, @rate = .019
    	if @annualized_wage > 8000 select @tax_addition = 152, @wage_bracket = 8000, @rate = .0265
    	if @annualized_wage > 8700 select @tax_addition = 171, @wage_bracket = 8700, @rate = .031
    	if @annualized_wage > 15000 select @tax_addition = 366, @wage_bracket = 15000, @rate = .037
    	if @annualized_wage > 25000 select @tax_addition = 736, @wage_bracket = 25000, @rate = .039
    	if @annualized_wage > 60000 select @tax_addition = 2101, @wage_bracket = 60000, @rate = .04
    	if @annualized_wage > 100000 select @tax_addition = 3701, @wage_bracket = 100000, @rate = .0400
    	if @annualized_wage > 150000 select @tax_addition = 5701, @wage_bracket = 150000, @rate = .0603
    	if @annualized_wage > 200000 select @tax_addition = 8716, @wage_bracket = 200000, @rate = .044
    	if @annualized_wage > 500000 select @tax_addition = 21916, @wage_bracket = 500000, @rate = .0480
    	end
    
    res_calc: /* calculate New York City Tax for residents */
    
    
    select @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate)  / @ppds
    goto bspexit
    
    end
    
    
    /* code for anyone who works in NYC but doesn't live there */
    if @resident = 'N'
    begin
    
    /* annualize taxable income */
    select @annualized_wage = (@subjamt * @ppds)
    
    /* initialize calculation elements */
    
    	if @annualized_wage <= 4000 goto bspexit
    
    	if @annualized_wage > 4000 select @wage_bracket = 3000, @rate = .0025
    	if @annualized_wage > 10000 select @wage_bracket = 2000, @rate = .0025
    	if @annualized_wage > 20000 select @wage_bracket = 1000, @rate = .0025
    	if @annualized_wage > 30000 select @wage_bracket = 0, @rate = .0025
    
    
    nonres_calc: /* calculate New York City Tax for nonresidents */
    
    select @amt = (@annualized_wage - @wage_bracket) * @rate  / @ppds
    goto bspexit
    
    end
    
    
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNYC052] TO [public]
GO
