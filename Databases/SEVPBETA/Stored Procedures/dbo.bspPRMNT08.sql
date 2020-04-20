SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRMNT08]    Script Date: 11/16/2007 15:30:08 ******/
    CREATE proc [dbo].[bspPRMNT08]
    /********************************************************
    * CREATED BY: 	EN 11/29/00 - this revision effective 1/1/2001
    * MODIFIED BY:	EN 1/8/02 - issue 15820 - update effective 1/1/2002
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 11/05/02 issue 19249  update effective 1/1/03
    *				EN 11/30/04 issue 26187  update effective 1/1/05
    *				EN 1/4/05 - issue 26244  default status and exemptions
    *				EN 10/27/05 - issue 30192  update effective 1/1/06
    *				EN 11/13/06 - issue 123073  update effective 1/1/07
	*				EN 11/16/07 - issue 126263  update effective 1/1/08
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
    
    select @rcode = 0, @dedn = 3500, @procname = 'bspPRMNT08'
   
    -- #26244 set default status and/or exemptions if passed in values are invalid
    if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
    if @exempts is null select @exempts = 0
   
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
    		if @annualized_wage <= 1950 goto bspexit
    		if @annualized_wage > 1950 select @wage_bracket = 1950, @rate = .0535
    		if @annualized_wage > 23750 select @tax_addition = 1166.30, @wage_bracket = 23750, @rate = .0705
    		if @annualized_wage > 73540 select @tax_addition = 4676.50, @wage_bracket = 73540, @rate = .0785
    end
    
    /* married wage table and tax */
    if @status = 'M'
    	begin
    		if @annualized_wage <= 7400 goto bspexit
    		if @annualized_wage > 7400 select @wage_bracket = 7400, @rate = .0535
    		if @annualized_wage > 39260 select @tax_addition = 1704.51, @wage_bracket = 39260, @rate = .0705
    		if @annualized_wage > 133980 select @tax_addition = 8382.27, @wage_bracket = 133980, @rate = .0785
    end
    
    
    bspcalc: /* calculate Minnesota Tax rounded to the nearest dollar */
    	select @amt = ROUND(((@tax_addition + (@annualized_wage - @wage_bracket) * @rate) / @ppds),0)
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMNT08] TO [public]
GO
