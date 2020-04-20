SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRRIT052    Script Date: 8/28/99 9:33:34 AM ******/
    CREATE proc [dbo].[bspPRRIT052]
    /********************************************************
    * CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
    * MODIFIED BY:	EN 12/18/01 - update effective 1/1/2002
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 12/2/02 - issue 19517  update effective 1/1/2003
    *				EN 12/09/03 - issue 23230  update effective 1/1/2004
    *				EN 12/15/05 - issue 26538  update effective 1/1/2005
    *				EN 1/11/05 - issue 26244  default status and exemptions
    *
    * USAGE:
    * 	Calculates Rhode Island Income Tax
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
    
    declare @rcode int, @annualized_wage bDollar, @rate bRate,
    @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
    
    
    select @rcode = 0, @allowance = 3200, @procname = 'bspPRRIT052'
    
    -- #26244 set default status and/or exemptions if passed in values are invalid
    if (@status is null) or (@status is not null and @status not in ('S','M','H')) select @status = 'S'
    if @exempts is null select @exempts = 0
   
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    
    	goto bspexit
    	end
    
    
    /* annualize taxable income less standard deductions */
    select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
    
    
    /* select calculation elements for singles and heads of households */
    if @status = 'S' or @status = 'H'
    begin
    	if @annualized_wage <= 2650 select @tax_addition = 0, @wage_bracket = 0, @rate = 0
    	if @annualized_wage > 2650 select @tax_addition = 0, @wage_bracket = 2650, @rate = .0375
    	if @annualized_wage > 31500 select @tax_addition = 1081.88, @wage_bracket = 31500, @rate = .07
    	if @annualized_wage > 69750 select @tax_addition = 3759.38, @wage_bracket = 69750, @rate = .0775
    	if @annualized_wage > 151950 select @tax_addition = 10129.88, @wage_bracket = 151950, @rate = .09
    	if @annualized_wage > 328250 select @tax_addition = 25996.88, @wage_bracket = 328250, @rate = .099
    end
    
    if @status = 'M'
    begin
    	if @annualized_wage <= 6450 select @tax_addition = 0, @wage_bracket = 0, @rate = 0
    	if @annualized_wage > 6450 select @tax_addition = 0, @wage_bracket = 6450, @rate = .0375
    	if @annualized_wage > 54750 select @tax_addition = 1811.25, @wage_bracket = 54750, @rate = .07
    	if @annualized_wage > 116600 select @tax_addition = 6140.75, @wage_bracket = 116600, @rate = .0775
    	if @annualized_wage > 187900 select @tax_addition = 11666.50, @wage_bracket = 187900, @rate = .09
    	if @annualized_wage > 331500 select @tax_addition = 24590.50, @wage_bracket = 331500, @rate = .099
    end
    
    bspcalc: /* calculate Rhode Island Tax */
    
    
    select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
    
    
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRIT052] TO [public]
GO
