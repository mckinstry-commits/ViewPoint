SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNJT09    Script Date: 8/28/99 9:33:29 AM ******/
    CREATE proc [dbo].[bspPRNJT09]
    /********************************************************
    * CREATED BY: 	bc 6/4/98
    * MODIFIED BY:	bc 6/4/98
    * MODIFIED BY:  EN 1/17/00 - variable for tax addition amount wasn't being initialized if the lowest tax bracket was hit
    *               GH 3/14/01 - 'error converting numeric to char' when processing employees with NJ State Tax
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 7/20/04 - issue 25038  update tax routine effective 9/1/2004
    *				EN 11/09/04 - issue 25170 update tax routine effective 1/1/05
    *				EN 1/10/05 - issue 26244  default status and exemptions
	*				EN 9/03/2009 #135409  tax update effective 10/1/2009
    * USAGE:
    * 	Calculates New Jersey Income Tax
    *
    * INPUT PARAMETERS:
    *	@subjamt 	subject earnings
    *	@ppds		# of pay pds per year
    *	@status		filing status
    *	@exempts	# of exemptions
    *	@wage_chart	Letter of which table the employee has choosen to work with (Line 3 of NJ-W4)
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
    @wage_chart bRate = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
    as
    set nocount on
    
    declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
    @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
    
    select @rcode = 0, @allowance = 1000, @procname = 'bspPRNJT09'
    select @wage_chart = isnull(@wage_chart,0.00)
    
   -- #26244 set default status and/or exemptions if passed in values are invalid
   if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
   if @exempts is null select @exempts = 0
   
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    
    	goto bspexit
    	end
    
    if @wage_chart <> 0 goto taxroutine
    	else
    	begin
    	if @status = 'S' select @wage_chart = 1
    		else select @wage_chart = 2
    	end
    
    
    taxroutine:
    
    /* annualize taxable income */
    select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
    if @annualized_wage <= 0 goto bspexit
    
    /* initialize calculation elements */
    select @tax_addition = 0
    
    if @wage_chart = 1 -- Rate "A"
    begin
    
    	if @annualized_wage <= 20000 select @wage_bracket = 0, @rate = .015
    	if @annualized_wage > 20000 select @tax_addition = 300, @wage_bracket = 20000, @rate = .02
    	if @annualized_wage > 35000 select @tax_addition = 600, @wage_bracket = 35000, @rate = .039
    	if @annualized_wage > 40000 select @tax_addition = 795, @wage_bracket = 40000, @rate = .061
    	if @annualized_wage > 75000 select @tax_addition = 2930, @wage_bracket = 75000, @rate = .07
    	if @annualized_wage > 400000 select @tax_addition = 25680, @wage_bracket = 400000, @rate = .12
    end
    
    
    if @wage_chart = 2 -- Rate "B"
    begin
    
    	if @annualized_wage <= 20000 select @wage_bracket = 0, @rate = .015
    	if @annualized_wage > 20000 select @tax_addition = 300, @wage_bracket = 20000, @rate = .02
    	if @annualized_wage > 50000 select @tax_addition = 900, @wage_bracket = 50000, @rate = .027
    	if @annualized_wage > 70000 select @tax_addition = 1440, @wage_bracket = 70000, @rate = .039
    	if @annualized_wage > 80000 select @tax_addition = 1830, @wage_bracket = 80000, @rate = .061
    	if @annualized_wage > 150000 select @tax_addition = 6100, @wage_bracket = 150000, @rate = .07
    	if @annualized_wage > 400000 select @tax_addition = 23600, @wage_bracket = 400000, @rate = .12
    end
    
    if @wage_chart = 3 -- Rate "C"
    begin
    
    	if @annualized_wage <= 20000 select @wage_bracket = 0, @rate = .015
    	if @annualized_wage > 20000 select @tax_addition = 300, @wage_bracket = 20000, @rate = .023
    	if @annualized_wage > 40000 select @tax_addition = 760, @wage_bracket = 40000, @rate = .028
    	if @annualized_wage > 50000 select @tax_addition = 1040, @wage_bracket = 50000, @rate = .035
    	if @annualized_wage > 60000 select @tax_addition = 1390, @wage_bracket = 60000, @rate = .056
    	if @annualized_wage > 150000 select @tax_addition = 6430, @wage_bracket = 150000, @rate = .066
    	if @annualized_wage > 400000 select @tax_addition = 22930, @wage_bracket = 400000, @rate = .12
    end
    
    if @wage_chart = 4 -- Rate "D"
    begin
    
    	if @annualized_wage <= 20000 select @wage_bracket = 0, @rate = .015
    	if @annualized_wage > 20000 select @tax_addition = 300, @wage_bracket = 20000, @rate = .027
    	if @annualized_wage > 40000 select @tax_addition = 840, @wage_bracket = 40000, @rate = .034
    	if @annualized_wage > 50000 select @tax_addition = 1180, @wage_bracket = 50000, @rate = .043
    
    	if @annualized_wage > 60000 select @tax_addition = 1610, @wage_bracket = 60000, @rate = .056
    	if @annualized_wage > 150000 select @tax_addition = 6650, @wage_bracket = 150000, @rate = .065
    	if @annualized_wage > 400000 select @tax_addition = 22900, @wage_bracket = 400000, @rate = .12
    end
    
    
    if @wage_chart = 5 -- Rate "E"
    begin
    
    	if @annualized_wage <= 20000 select @wage_bracket = 0, @rate = .015
    	if @annualized_wage > 20000 select @tax_addition = 300, @wage_bracket = 20000, @rate = .02
    	if @annualized_wage > 35000 select @tax_addition = 600, @wage_bracket = 35000, @rate = .058
    	if @annualized_wage > 100000 select @tax_addition = 4370, @wage_bracket = 100000, @rate = .065
    	if @annualized_wage > 400000 select @tax_addition = 23870, @wage_bracket = 400000, @rate = .12
    end
    
    bspcalc: /* calculate New Jersey Tax */
    
    
    select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNJT09] TO [public]
GO
