SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPROKT02    Script Date: 8/28/99 9:33:32 AM ******/
   CREATE    proc [dbo].[bspPROKT02]
    /********************************************************
    * CREATED BY: 	bc 6/4/98
    * MODIFIED BY:	EN 12/17/98
    * MODIFIED BY:  EN 12/22/99 - fixed to round tax to nearest dollar
    *				 EN 12/18/01 - update effective 1/1/2002 - Fixed
    *				 EN 1/18/02 - issue 15955 - changed tax rate on wages over $22,560 from .0665 to .07
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * 	Calculates Oklahoma Income Tax
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
    @procname varchar(30), @tax_addition bDollar, @wage_bracket int,
    @deduction_1 int, @deduction_2 int
   
   
    select @rcode = 0, @procname = 'bspPROKT02'
   
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
    	goto bspexit
    	end
   
   
    /* annualize taxable income */
    select @annualized_wage = (@subjamt * @ppds)
    if @annualized_wage > 22560 select @annualized_wage = 22560
   
    /* determine taxable income for tables
     *
     * gross wage - exemptions * 1000
     * - (larger of 1,000 or .15% * gross wages, not to exceed 2,000)   ---> @deduction_1
     * - .15% * (larger of 0 or (gross wages - exemptions * federal exemption amount - federal deduction amount)   ---> @deduction_2
     *
     */
   
    select @deduction_1 = @annualized_wage * .15
    if @deduction_1 < 1000 select @deduction_1 = 1000
    if @deduction_1 > 2000 select @deduction_1 = 2000
   
    if @status = 'M' or @status = 'H'
    	begin
   	select @deduction_2 = @annualized_wage - (@exempts * 3000) - 7850
       if @deduction_2 <= 12000
   		select @deduction_2 = @deduction_2 * .1
   	else
   		select @deduction_2 = ((@deduction_2 - 12000) * .15) + 1200
           --select @deduction_2 = @deduction_2 - 12000 * .15 + 1200 danf
   	end
    else
   	begin
    	select @deduction_2 = @annualized_wage - (@exempts * 3000) - 4700
   	if @deduction_2 <= 6000
   		select @deduction_2 = @deduction_2 * .1
   	else
       	 select @deduction_2 = ((@deduction_2 - 6000) * .15) + 600
   		--select @deduction_2 = @deduction_2 - 6000 * .15 + 600 danf
   	end
   
    if @deduction_2 < 0 select @deduction_2 = 0
   
    select @annualized_wage = @annualized_wage - (@exempts * 1000) - @deduction_1 - @deduction_2
   
    if @annualized_wage < 0 goto bspexit
   
   
   
    /* select calculation elements for married people or heads of households */
    if @status = 'H'
    begin
    	if @annualized_wage <= 2000 select @tax_addition = 0, @wage_bracket = 0, @rate = .05
    	if @annualized_wage > 2000 select @tax_addition = 10, @wage_bracket = 2000, @rate = .01
    	if @annualized_wage > 5000 select @tax_addition = 40, @wage_bracket = 5000, @rate = .02
    	if @annualized_wage > 7500 select @tax_addition = 90, @wage_bracket = 7500, @rate = .03
    	if @annualized_wage > 8900 select @tax_addition = 132, @wage_bracket = 8900, @rate = .04
    	if @annualized_wage > 10400 select @tax_addition = 192, @wage_bracket = 10400, @rate = .05
    	if @annualized_wage > 12000 select @tax_addition = 272, @wage_bracket = 12000, @rate = .06
    	if @annualized_wage > 13250 select @tax_addition = 347, @wage_bracket = 13250, @rate = .07
    	if @annualized_wage > 15000 select @tax_addition = 469.5, @wage_bracket = 15000, @rate = .08
    	if @annualized_wage > 18000 select @tax_addition = 709.5, @wage_bracket = 18000, @rate = .09
    end
   
    /* select calculation elements for everybody else */
    if @status = 'S' or @status = 'M'
    begin
    	if @annualized_wage <= 1000 select @tax_addition = 0, @wage_bracket = 0, @rate = .05
    	if @annualized_wage > 1000 select @tax_addition = 5, @wage_bracket = 1000, @rate = .01
    	if @annualized_wage > 2500 select @tax_addition = 20, @wage_bracket = 2500, @rate = .02
    	if @annualized_wage > 3750 select @tax_addition = 45, @wage_bracket = 3750, @rate = .03
    	if @annualized_wage > 4900 select @tax_addition = 79.5, @wage_bracket = 4900, @rate = .04
    	if @annualized_wage > 6100 select @tax_addition = 127, @wage_bracket = 6100, @rate = .05
    	if @annualized_wage > 7500 select @tax_addition = 197, @wage_bracket = 7500, @rate = .06
    	if @annualized_wage > 9000 select @tax_addition = 287.5, @wage_bracket = 9000, @rate = .07
    	if @annualized_wage > 10500 select @tax_addition = 392.5, @wage_bracket = 10500, @rate = .08
    	if @annualized_wage > 12500 select @tax_addition = 552.5, @wage_bracket = 12500, @rate = .09
    	if @annualized_wage > 16000 select @tax_addition = 867.5, @wage_bracket = 16000, @rate = .1
    end
   
   
    bspcalc: /* calculate Oklahoma Tax */
   
   
    select @amt = @tax_addition + (@annualized_wage - @wage_bracket) * @rate
   
    if @status = 'M' select @amt = @amt * 1.16
   
    /* if gross wages exceed $22,560 compute withholding amount on $22,560 and add
     * 7% * (gross wage - $22,560) to determine total withholding */
   
    if @subjamt * @ppds > 22560 select @amt = @amt + (@subjamt * @ppds - 22560) * .07
   
    select @amt = ROUND((@amt/ @ppds),0)
   
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPROKT02] TO [public]
GO
