SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRMET08]    Script Date: 10/26/2007 10:20:46 ******/
   CREATE proc [dbo].[bspPRMET08]
   /********************************************************
   * CREATED BY: 	EN 12/13/00 - tax update effective 1/1/2001
   * MODIFIED BY:  EN 11/13/01 - issue 15015
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 12/09/02 - issue 19593  tax update effective 1/1/2003
   *				EN 10/29/03 - issue 22881 tax update effective 1/1/2004
   *				EN 11/16/04 - issue 26218 tax update effective 1/1/2005
   *				EN 1/4/05 - issue 26244  default status and exemptions
   *				EN 11/02/05 - issue 30243  tax update effective 1/1/2006
   *				EN 11/27/06 - issue 123198  tax update effective 1/1/2007
   *				EN 10/26/07 - issue 125983  tax update effective 1/1/2008
   *
   * USAGE:
   * 	Calculates Maine Income Tax
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
   
   select @rcode = 0, @dedn = 2850, @procname = 'bspPRMET08'
   
   -- #26244 set default status and/or exemptions if passed in values are invalid
   -- #123198  As of 1/1/2007 Maine stopped including a table for 'B' ... if employee is married filing separately
   --   with the intent of withholding at the single rate, filing status 'S' should be used.
   if (@status is null) or (@status is not null and @status not in ('S','M','B')) select @status = 'S'
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
   		if @annualized_wage <= 2600 goto bspcalc
   		if @annualized_wage > 2600 select @wage_bracket = 2600, @rate = .02
   		if @annualized_wage > 7450 select @tax_addition = 97, @wage_bracket = 7450, @rate = .045
   		if @annualized_wage > 12300 select @tax_addition = 315, @wage_bracket = 12300, @rate = .07
   		if @annualized_wage > 22050 select @tax_addition = 998, @wage_bracket = 22050, @rate = .085
   end
   
   /* married wage table and tax */
   if @status <> 'S'
   	begin
   		if @annualized_wage <= 6250 goto bspcalc
   		if @annualized_wage > 6250 select @wage_bracket = 6250, @rate = .02
   		if @annualized_wage > 16000 select @tax_addition = 195, @wage_bracket = 16000, @rate = .045
   		if @annualized_wage > 25700 select @tax_addition = 632, @wage_bracket = 25700, @rate = .07
   		if @annualized_wage > 45150 select @tax_addition = 1993, @wage_bracket = 45150, @rate = .085
   end
   
   
 --  /* married with two incomes, wage table and tax */
 --  if @status = 'B'
 --  	begin
 --  		if @annualized_wage <= 2875 goto bspcalc
 --  		if @annualized_wage > 2875 select @wage_bracket = 2875, @rate = .02
 --  		if @annualized_wage > 7450 select @tax_addition = 92, @wage_bracket = 7450, @rate = .045
 --  		if @annualized_wage > 12000 select @tax_addition = 296, @wage_bracket = 12000, @rate = .07
 --  		if @annualized_wage > 21150 select @tax_addition = 937, @wage_bracket = 21150, @rate = .085
 --  end
   
   
   bspcalc: /* calculate Maine Tax */
   	select @amt = @tax_addition + ((@annualized_wage - @wage_bracket) * @rate)
 	if @amt<=40 select @amt=0 --#30243 apply low income tax credit
   	select @amt = round((@amt / @ppds),0)
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMET08] TO [public]
GO
