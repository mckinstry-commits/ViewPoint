SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRNET12]    Script Date: 11/07/2007 10:08:51 ******/
CREATE proc [dbo].[bspPRNET12]
/********************************************************
* CREATED BY: 	bc	06/02/1998
* MODIFIED BY:	bc	06/02/1998
* MODIFIED BY:  EN	01/17/2000	- @tax_addition was dimensioned to int which would throw off tax calculation slightly
*				EN	10/08/2002	- issue 18877 change double quotes to single
*				EN	01/10/2005	- issue 26244  default status and exemptions
*				EN	11/17/2006	- issue 123148  update effective 1/1/2007
*				EN	11/07/2007	- issue 126098  update effective 1/1/2008
*				CHS	12/07/2011	- update effective 1/1/2012
*
* USAGE:
* 	Calculates Nebraska Income Tax
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
    
    declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
    @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
    
    select @rcode = 0, @allowance = 1700, @procname = 'bspPRNET12'
    
    -- #26244 set default status and/or exemptions if passed in values are invalid
    if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
    if @exempts is null select @exempts = 0
    
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    
    	goto bspexit
    	end
    
    
    /* annualize earnings */
    select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
    
    /* calculation defaults */
    select @tax_addition = 0, @rate = 0, @amt = 0
    
    /* swingin' single */
    if @status = 'S'
    	begin
    
    	if @annualized_wage <= 2200 goto bspexit
    
    	if @annualized_wage > 2200 select @wage_bracket = 2200, @rate = .0235
    	if @annualized_wage > 4400 select @tax_addition = 51.7, @wage_bracket = 4400, @rate = .0327
    	if @annualized_wage > 15500 select @tax_addition = 414.67, @wage_bracket = 15500, @rate = .0502
    	if @annualized_wage > 22750 select @tax_addition = 778.62, @wage_bracket = 22750, @rate = .062
    	if @annualized_wage > 29000 select @tax_addition = 1166.12, @wage_bracket = 29000, @rate = .0659
    	if @annualized_wage > 55000 select @tax_addition = 2879.52, @wage_bracket = 55000, @rate = .0695
    end
    
    /* Married */
    if @status = 'M'
    	begin
    
    	if @annualized_wage <= 6450 goto bspexit
    
    	if @annualized_wage > 6450 select @wage_bracket = 6450, @rate = .0235
    	if @annualized_wage > 9450 select @tax_addition = 70.5, @wage_bracket = 9450, @rate = .0327
    	if @annualized_wage > 23750 select @tax_addition = 538.11, @wage_bracket = 23750, @rate = .0502
    	if @annualized_wage > 37000 select @tax_addition = 1203.26, @wage_bracket = 37000, @rate = .062
    	if @annualized_wage > 46000 select @tax_addition = 1761.26, @wage_bracket = 46000, @rate = .0659
    	if @annualized_wage > 61000 select @tax_addition = 2749.76, @wage_bracket = 61000, @rate = .0695
    end
    
    
    bspcalc: /* calculate Nebraska Tax */
    
    
    select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
    
    bspexit:
    	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRNET12] TO [public]
GO
