SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRRIT99    Script Date: 8/28/99 9:33:34 AM ******/
   CREATE   proc [dbo].[bspPRRIT99]
   /********************************************************
   * CREATED BY: 	bc 6/4/98
   * MODIFIED BY:	EN 1/6/99
   *				EN 10/9/02 - issue 18877 change double quotes to single
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
   @procname varchar(30), @tax_addition int, @allowance bDollar, @wage_bracket int
   
   
   select @rcode = 0, @allowance = 2750, @procname = 'bspPRRIT99'
   
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
   	if @annualized_wage <= 2650 select @wage_bracket = 0, @rate = 0
   	if @annualized_wage > 2650 select @wage_bracket = 2650, @rate = .04
   	if @annualized_wage > 27300 select @tax_addition = 979.84, @wage_bracket = 27300, @rate = .074
   	if @annualized_wage > 58500 select @tax_addition = 3294.88, @wage_bracket = 58500, @rate = .082
   	if @annualized_wage > 131800 select @tax_addition = 9316.47, @wage_bracket = 131800, @rate = .095
   	if @annualized_wage > 284700 select @tax_addition = 23903.13, @wage_bracket = 284700, @rate = .105
   end
   
   if @status = 'M'
   begin
   	if @annualized_wage <= 6450 select @wage_bracket = 0, @rate = 0
   	if @annualized_wage > 6450 select @wage_bracket = 6450, @rate = .04
   	if @annualized_wage > 47500 select @tax_addition = 1631.74, @wage_bracket = 47500, @rate = .074
   	if @annualized_wage > 98500 select @tax_addition = 5415.94, @wage_bracket = 98500, @rate = .082
   	if @annualized_wage > 163000 select @tax_addition = 10714.61, @wage_bracket = 163000, @rate = .095
   	if @annualized_wage > 287600 select @tax_addition = 22601.45, @wage_bracket = 287600, @rate = .105
   end
   
   bspcalc: /* calculate Rhode Island Tax */
   
   
   select @amt = @tax_addition + (@annualized_wage - @wage_bracket) * @rate  / @ppds
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRIT99] TO [public]
GO
