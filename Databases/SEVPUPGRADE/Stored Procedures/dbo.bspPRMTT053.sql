SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMTT053    Script Date: 8/28/99 9:33:29 AM ******/
    CREATE  proc [dbo].[bspPRMTT053]
    /********************************************************
    * CREATED BY: 	bc 6/3/98
    * MODIFIED BY:	bc 6/3/98
    * MODIFIED BY:  EN 1/17/00 - @tax_addition was dimensioned to int which would throw off tax calculation slightly
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 1/9/04 - issue 23470  update effective 1/1/2004
    *				EN 2/23/04 - issue 23823  negative tax amount calculated
    *				EN 11/11/04 - issue 26151  update effective 1/1/2005
    *				EN 1/4/05 - issue 26244  default exemptions
    *				EN 1/17/05 - issue 26821  revised 2005 tax update
    *
    * USAGE:
    * 	Calculates Montana Income Tax
    *
    * INPUT PARAMETERS:
    *	@subjamt 	subject earnings
    *	@ppds		# of pay pds per year
    *	@status		filing status, tax is currently figured the same for 'S' and 'M'
    *	@exempts	# of regular exemptions
    *
    * OUTPUT PARAMETERS:
    *	@amt		calculated tax amount
    *	@msg		error message if failure
    *
    * RETURN VALUE:
    * 	0 	    	success
    *	1 		failure
    **********************************************************/
    (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts bDollar = 0,
    @amt bDollar = 0 output, @msg varchar(255) = null output)
    as
    set nocount on
    
    
    declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
    @procname varchar(30), @wage_bracket int, @tax_addition bDollar
    
    select @rcode = 0, @deduction = 1900, @procname = 'bspPRMTT053'
    
    -- #26244 set default exemptions if passed in values are invalid
    if @exempts is null select @exempts = 0
   
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    
    	goto bspexit
    	end
    
    
    /* annualize earnings then subtract deductions */
    select @annualized_wage = @subjamt * @ppds - @exempts * @deduction
    
    --issue 23823 prevent negative tax calculations
    if @annualized_wage < 0 select @annualized_wage = 0
    
    /* determine tax factors used to calculate the withholding */
    if @annualized_wage <= 7000 select @tax_addition = 0, @wage_bracket = 0, @rate = .018
    if @annualized_wage > 7000 select @tax_addition = 126, @wage_bracket = 7000, @rate = .044
    if @annualized_wage > 15000 select @tax_addition = 478, @wage_bracket = 15000, @rate = .06
    if @annualized_wage > 120000 select @tax_addition = 6778, @wage_bracket = 120000, @rate = .066
    
    
    bspcalc: /* calculate Montana Tax  */
    
    	select @amt = ROUND((@tax_addition + (@rate * (@annualized_wage - @wage_bracket))) / @ppds,0)
    
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMTT053] TO [public]
GO
