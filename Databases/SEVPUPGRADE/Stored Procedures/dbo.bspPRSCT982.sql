SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPRSCT982]
     /********************************************************
     * CREATED BY: 	bc 6/5/98
     * MODIFIED BY:	bc 6/5/98
     *                 GG 9/8/99 - fixed for 0 exemptions
     *                 GG 6/26/00 - do not return tax amt < 0
     *					EN 10/9/02 - issue 18877 change double quotes to single
     *					EN 1/11/05 - issue 26244  default exemptions
     *
     * USAGE:
     * 	Calculates South Carolina Income Tax
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
     @procname varchar(30), @tax_subtraction bDollar, @allowance bDollar, @deduction int
   
     select @rcode = 0, @allowance = 2300, @procname = 'bspPRSCT982'
   
     -- #26244 set default exemptions if passed in values are invalid
     if @exempts is null select @exempts = 0
   
     if @ppds = 0
     	begin
     	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
     	goto bspexit
     	end
   
   
     /* annualize taxable income  */
     select @annualized_wage = @subjamt * @ppds
   
     /* determine standard deduction */
     select @deduction = 0
     if @exempts > 0
     	begin
     	select @deduction = @annualized_wage * .1
     	if @deduction > 2600 select @deduction = 2600
     	end
   
     /* determine personal exemption */
     select  @deduction = @deduction + (@exempts * @allowance)
   
     /* subtract deductions from gross taxable income */
     select @annualized_wage = @annualized_wage - @deduction
     if @annualized_wage < 0 select @annualized_wage = 0
   
     /* select calculation elements  */
   
     	if @annualized_wage <= 2000 select @tax_subtraction = 0, @rate = .02
     	if @annualized_wage > 2000 select @tax_subtraction = 20, @rate = .03
     	if @annualized_wage > 4000 select @tax_subtraction = 60, @rate = .04
     	if @annualized_wage > 6000 select @tax_subtraction = 120,  @rate = .05
     	if @annualized_wage > 8000 select @tax_subtraction = 200, @rate = .06
     	if @annualized_wage > 10000 select @tax_subtraction = 300, @rate = .07
   
     bspcalc: /* calculate South Carolina Tax */
   
   
     select @amt = ((@annualized_wage * @rate) - @tax_subtraction)  / @ppds
   
   
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRSCT982] TO [public]
GO
