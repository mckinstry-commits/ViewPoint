SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRWIT09    Script Date: 8/28/99 9:33:37 AM ******/
   CREATE proc [dbo].[bspPRWIT09]
   /********************************************************
   * CREATED BY: 	bc 6/8/98
   * MODIFIED BY:	bc 6/8/98
   *               EN 5/24/00 - update effective 7/1/00
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *				EN 1/11/05 - issue 26244  default status and exemptions
   *				EN 9/03/2009  #135408 tax update effective 10/01/2009
   *
   * USAGE:
   * 	Calculates Wisconsin Income Tax
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
   @procname varchar(30), @tax_addition bDollar, @deduction int, @dedn  int
   
   
   select @rcode = 0, @procname = 'bspPRWIT09'
   
   -- #26244 set default status and/or exemptions if passed in values are invalid
   if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
   if @exempts is null select @exempts = 0
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   /* method 'A' */
   /* annualize taxable income  */
   select @annualized_wage = (@subjamt * @ppds)
   
   /* determine the deduction based on status and annualized wages */
   if @status = 'S'
   begin
   	if @annualized_wage < 10620 select @deduction = 4000
   	if @annualized_wage >= 43953 select @deduction = 0
   	if @annualized_wage >= 10620 and @annualized_wage < 43953
   		select @deduction = 4000 - (.12 * (@annualized_wage - 10620))
   end
   
   if @status = 'M'
   begin
   	if @annualized_wage < 14950 select @deduction = 5500
   	if @annualized_wage >= 42450 select @deduction = 0
   	if @annualized_wage >= 14950 and @annualized_wage < 42450
   		select @deduction = 5500 - (.20 * (@annualized_wage - 14950))
   end
   
   select @annualized_wage = @annualized_wage - @deduction
   
   /* subtract exemption */
   select @annualized_wage = @annualized_wage - (400 * @exempts)
   
   /* select calculation elements */
   
   	if @annualized_wage <= 9960 select @tax_addition = 0, @rate = .046, @wage_bracket = 0
   	if @annualized_wage > 9960 select @tax_addition = 458.16, @rate = .0615, @wage_bracket = 9960
   	if @annualized_wage > 19910 select @tax_addition = 1070.09, @rate = .065, @wage_bracket = 19910
   	if @annualized_wage > 149330 select @tax_addition = 9482.39, @rate = .0675, @wage_bracket = 149330
    if @annualized_wage > 219200 select @tax_addition = 14198.61, @rate = .0775, @wage_bracket = 219200
  
   
   
   bspcalc: /* calculate Wisconsin Tax */
   
   
   select @amt = @tax_addition + (@annualized_wage - @wage_bracket) * @rate
   select @amt = @amt / @ppds
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRWIT09] TO [public]
GO
