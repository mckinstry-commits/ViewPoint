SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMNT052    Script Date: 8/28/99 9:33:28 AM ******/
     CREATE proc [dbo].[bspPRMNT052]
     /********************************************************
     * CREATED BY: 	EN 11/29/00 - this revision effective 1/1/2001
     * MODIFIED BY:	EN 1/8/02 - issue 15820 - update effective 1/1/2002
     *				EN 10/8/02 - issue 18877 change double quotes to single
     *				EN 11/05/02 issue 19249  update effective 1/1/03
     *				EN 11/30/04 issue 26187  update effective 1/1/05
     *				EN 1/4/05 - issue 26244  default status and exemptions
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
     
     select @rcode = 0, @dedn = 3200, @procname = 'bspPRMNT052'
    
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
     		if @annualized_wage <= 1800 goto bspexit
     		if @annualized_wage > 1800 select @wage_bracket = 1800, @rate = .0535
     		if @annualized_wage > 21690 select @tax_addition = 1064.12, @wage_bracket = 21690, @rate = .0705
     		if @annualized_wage > 67130 select @tax_addition = 4267.64, @wage_bracket = 67130, @rate = .0785
     end
     
     /* married wage table and tax */
     if @status = 'M'
     	begin
     		if @annualized_wage <= 5500 goto bspexit
     		if @annualized_wage > 5500 select @wage_bracket = 5500, @rate = .0535
     		if @annualized_wage > 34570 select @tax_addition = 1555.25, @wage_bracket = 34570, @rate = .0705
     		if @annualized_wage > 121010 select @tax_addition = 7649.27, @wage_bracket = 121010, @rate = .0785
     end
     
     
     bspcalc: /* calculate Minnesota Tax rounded to the nearest dollar */
     	select @amt = ROUND(((@tax_addition + (@annualized_wage - @wage_bracket) * @rate) / @ppds),0)
     
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMNT052] TO [public]
GO
