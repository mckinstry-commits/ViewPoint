SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRUTT98    Script Date: 8/28/99 9:33:36 AM ******/
   CREATE  proc [dbo].[bspPRUTT98]
   /********************************************************
   * CREATED BY: 	bc 6/8/98
   * MODIFIED BY:	bc 6/8/98
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 Utah Income Tax
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
   
   
   select @rcode = 0, @procname = 'bspPRUTT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize taxable income  */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * 1620)
   
   
   /* select calculation elements for single folk */
   if @status = 'S'
   begin
   	if @annualized_wage < 2090 goto bspexit
   	if @annualized_wage >= 2090 select @tax_addition = 0, @rate = .023, @wage_bracket = 2090
   	if @annualized_wage >= 2840 select @tax_addition = 17, @rate = .031, @wage_bracket = 2840
   	if @annualized_wage >= 3590 select @tax_addition = 40,  @rate = .039, @wage_bracket = 3590
   	if @annualized_wage >= 4340 select @tax_addition = 69, @rate = .048, @wage_bracket = 4340
   	if @annualized_wage >= 5090 select @tax_addition = 105, @rate = .056, @wage_bracket = 5090
   	if @annualized_wage >= 5840 select @tax_addition = 147, @rate = .065, @wage_bracket = 5840
   end
   
   /* select calculation elements for married folk */
   if @status = 'M'
   begin
   	if @annualized_wage < 2090 goto bspexit
   	if @annualized_wage >= 2090 select @tax_addition = 0, @rate = .023, @wage_bracket = 2090
   	if @annualized_wage >= 3590 select @tax_addition = 35, @rate = .031, @wage_bracket = 3590
   	if @annualized_wage >= 5090 select @tax_addition = 82,  @rate = .039, @wage_bracket = 5090
   	if @annualized_wage >= 6590 select @tax_addition = 141, @rate = .048, @wage_bracket = 6590
   	if @annualized_wage >= 8090 select @tax_addition = 213, @rate = .056, @wage_bracket = 8090
   	if @annualized_wage >= 9590 select @tax_addition = 297, @rate = .065, @wage_bracket = 9590
   end
   
   bspcalc: /* calculate Utah Tax */
   
   
   select @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate) / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUTT98] TO [public]
GO
