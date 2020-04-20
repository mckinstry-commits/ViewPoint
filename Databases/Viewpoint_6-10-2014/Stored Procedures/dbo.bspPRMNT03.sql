SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMNT03    Script Date: 8/28/99 9:33:28 AM ******/
    CREATE    proc [dbo].[bspPRMNT03]
    /********************************************************
    * CREATED BY: 	EN 11/29/00 - this revision effective 1/1/2001
    * MODIFIED BY:	EN 1/8/02 - issue 15820 - update effective 1/1/2002
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 11/05/02 issue 19249  update effective 1/1/03
    *
    * USAGE:
    * 	Calculates Minnesota Income Tax
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
    
    select @rcode = 0, @dedn = 3050, @procname = 'bspPRMNT03'
    
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
    		if @annualized_wage <= 1700 goto bspexit
    		if @annualized_wage > 1700 select @wage_bracket = 1700, @rate = .0535
    		if @annualized_wage > 20710 select @tax_addition = 1017.04, @wage_bracket = 20710, @rate = .0705
    		if @annualized_wage > 64140 select @tax_addition = 4078.85, @wage_bracket = 64140, @rate = .0785
    end
    
    /* married wage table and tax */
    if @status = 'M'
    	begin
    		if @annualized_wage <= 4900 goto bspexit
    		if @annualized_wage > 4900 select @wage_bracket = 4900, @rate = .0535
    		if @annualized_wage > 32680 select @tax_addition = 1486.23, @wage_bracket = 32680, @rate = .0705
    		if @annualized_wage > 115290 select @tax_addition = 7310.24, @wage_bracket = 115290, @rate = .0785
    end
    
    
    bspcalc: /* calculate Minnesota Tax rounded to the nearest dollar */
    	select @amt = ROUND(((@tax_addition + (@annualized_wage - @wage_bracket) * @rate) / @ppds),0)
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMNT03] TO [public]
GO
