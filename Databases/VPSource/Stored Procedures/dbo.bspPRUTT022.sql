SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRUTT022    Script Date: 8/28/99 9:33:36 AM ******/
   CREATE proc [dbo].[bspPRUTT022]
   /********************************************************
   * CREATED BY: 	bc 6/8/98
   * MODIFIED BY:	bc 6/8/98
   *				EN 12/18/01 - update effective 1/1/2002
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *				EN 1/11/05 - issue 26244  default status and exemptions
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
   
   
   select @rcode = 0, @procname = 'bspPRUTT022'
   
   -- #26244 set default status and/or exemptions if passed in values are invalid
   if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
   if @exempts is null select @exempts = 0
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize taxable income  */
   select @annualized_wage = (@subjamt * @ppds) - (@exempts * 1800)
   
   
   /* select calculation elements for single folk */
   if @status = 'S'
   begin
   	if @annualized_wage < 2300 goto bspexit
   	if @annualized_wage >= 2300 select @tax_addition = 0, @rate = .023, @wage_bracket = 2300
   	if @annualized_wage >= 3163 select @tax_addition = 20, @rate = .031, @wage_bracket = 3163
   	if @annualized_wage >= 4026 select @tax_addition = 47,  @rate = .04, @wage_bracket = 4026
   	if @annualized_wage >= 4888 select @tax_addition = 81, @rate = .049, @wage_bracket = 4888
   	if @annualized_wage >= 5750 select @tax_addition = 123, @rate = .057, @wage_bracket = 5750
   	if @annualized_wage >= 6613 select @tax_addition = 172, @rate = .065, @wage_bracket = 6613
   end
   
   /* select calculation elements for married folk */
   if @status = 'M'
   begin
   	if @annualized_wage < 2300 goto bspexit
   	if @annualized_wage >= 2300 select @tax_addition = 0, @rate = .023, @wage_bracket = 2300
   	if @annualized_wage >= 4026 select @tax_addition = 40, @rate = .031, @wage_bracket = 4026
   	if @annualized_wage >= 5750 select @tax_addition = 93,  @rate = .04, @wage_bracket = 5750
   	if @annualized_wage >= 7476 select @tax_addition = 162, @rate = .049, @wage_bracket = 7476
   	if @annualized_wage >= 9200 select @tax_addition = 246, @rate = .057, @wage_bracket = 9200
   	if @annualized_wage >= 10926 select @tax_addition = 344, @rate = .065, @wage_bracket = 10926
   end
   
   bspcalc: /* calculate Utah Tax */
   
   
   select @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * @rate) / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUTT022] TO [public]
GO
