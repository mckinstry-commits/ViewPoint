SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRUTT07    Script Date: 8/28/99 9:33:36 AM ******/
   CREATE proc [dbo].[bspPRUTT07]
   /********************************************************
   * CREATED BY: 	bc 6/8/98
   * MODIFIED BY:	bc 6/8/98
   *				EN 12/18/01 - update effective 1/1/2002
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *				EN 1/11/05 - issue 26244  default status and exemptions
   *				EN 11/1/06 - issue 122963 update effective 1/1/2007
   *
   * USAGE:
   * 	Calculates Utah Income Tax
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
   
   declare @rcode int, @annualized_wage bDollar, @rate bRate, @wage_bracket int,
   @procname varchar(30), @tax_addition int
   
   
   select @rcode = 0, @procname = 'bspPRUTT07'
   
   -- #26244 set default status and/or exemptions if passed in values are invalid
   if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
   if @exempts is null select @exempts = 0
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize taxable income  */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * 2040)
   
   
   /* select calculation elements for single folk */
   if @status = 'S'
   begin
   	if @annualized_wage < 2630 goto bspexit
   	if @annualized_wage >= 2630 select @tax_addition = 0, @rate = .023, @wage_bracket = 2630
   	if @annualized_wage >= 3630 select @tax_addition = 23, @rate = .031, @wage_bracket = 3630
   	if @annualized_wage >= 4630 select @tax_addition = 54,  @rate = .04, @wage_bracket = 4630
   	if @annualized_wage >= 5630 select @tax_addition = 94, @rate = .049, @wage_bracket = 5630
   	if @annualized_wage >= 6630 select @tax_addition = 143, @rate = .057, @wage_bracket = 6630
   	if @annualized_wage >= 8130 select @tax_addition = 229, @rate = .065, @wage_bracket = 8130
   end
   
   /* select calculation elements for married folk */
   if @status = 'M'
   begin
   	if @annualized_wage < 2630 goto bspexit
   	if @annualized_wage >= 2630 select @tax_addition = 0, @rate = .023, @wage_bracket = 2630
   	if @annualized_wage >= 4630 select @tax_addition = 46, @rate = .031, @wage_bracket = 4630
   	if @annualized_wage >= 6630 select @tax_addition = 108,  @rate = .04, @wage_bracket = 6630
   	if @annualized_wage >= 8630 select @tax_addition = 188, @rate = .049, @wage_bracket = 8630
   	if @annualized_wage >= 10630 select @tax_addition = 286, @rate = .057, @wage_bracket = 10630
   	if @annualized_wage >= 13630 select @tax_addition = 457, @rate = .065, @wage_bracket = 13630
   end
   
   bspcalc: /* calculate Utah Tax */
   
   
   select @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate) / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUTT07] TO [public]
GO
