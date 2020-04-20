SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMET05   Script Date: 8/28/99 9:33:27 AM ******/
    CREATE proc [dbo].[bspPRMET05]
    /********************************************************
    * CREATED BY: 	EN 12/13/00 - tax update effective 1/1/2001
    * MODIFIED BY:  EN 11/13/01 - issue 15015
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 12/09/02 - issue 19593  tax update effective 1/1/2003
    *				EN 10/29/03 - issue 22881 tax update effective 1/1/2004
    *				EN 11/16/04 - issue 26218 tax update effective 1/1/2005
    *
    * USAGE:
    * 	Calculates Maine Income Tax
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
    
    declare @rcode int, @annualized_wage bDollar, @dedn bDollar, @rate bRate,
    @procname varchar(30), @tax_addition bDollar, @wage_bracket int
    
    select @rcode = 0, @dedn = 2850, @procname = 'bspPRMET05'
    
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    	goto bspexit
    	end
    
    
    /* annualize earnings then subtract standard deductions */
    select @annualized_wage = (@subjamt * @ppds) - (@dedn * @exempts)
    
    /* calculation defaults */
    select @tax_addition = 0, @wage_bracket = 0, @rate = 0
    
    
    /* single wage table and tax */
    if @status = 'S'
    	begin
    		if @annualized_wage <= 2150 goto bspcalc
    		if @annualized_wage > 2150 select @wage_bracket = 2150, @rate = .02
    		if @annualized_wage > 6600 select @tax_addition = 89, @wage_bracket = 6600, @rate = .045
    		if @annualized_wage > 11000 select @tax_addition = 287, @wage_bracket = 11000, @rate = .07
    		if @annualized_wage > 19850 select @tax_addition = 907, @wage_bracket = 19850, @rate = .085
    end
    
    /* married wage table and tax */
    if @status = 'M'
    	begin
    		if @annualized_wage <= 5450 goto bspcalc
    		if @annualized_wage > 5450 select @wage_bracket = 5450, @rate = .02
    		if @annualized_wage > 14350 select @tax_addition = 178, @wage_bracket = 14350, @rate = .045
    		if @annualized_wage > 23150 select @tax_addition = 574, @wage_bracket = 23150, @rate = .07
    		if @annualized_wage > 40900 select @tax_addition = 1817, @wage_bracket = 40900, @rate = .085
    end
    
    
    /* married with two incomes, wage table and tax */
    if @status = 'B'
    	begin
    		if @annualized_wage <= 2725 goto bspcalc
    		if @annualized_wage > 2725 select @wage_bracket = 2725, @rate = .02
    		if @annualized_wage > 7175 select @tax_addition = 89, @wage_bracket = 7175, @rate = .045
    		if @annualized_wage > 11575 select @tax_addition = 287, @wage_bracket = 11575, @rate = .07
    		if @annualized_wage > 20450 select @tax_addition = 908, @wage_bracket = 20450, @rate = .085
    end
    
    
    bspcalc: /* calculate Maine Tax */
    	select @amt = round(((@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds),0)
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMET05] TO [public]
GO
