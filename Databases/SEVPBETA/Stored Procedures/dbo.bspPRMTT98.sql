SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMTT98    Script Date: 8/28/99 9:33:29 AM ******/
   CREATE   proc [dbo].[bspPRMTT98]
   /********************************************************
   * CREATED BY: 	bc 6/3/98
   * MODIFIED BY:	bc 6/3/98
   * MODIFIED BY:  EN 1/17/00 - @tax_addition was dimensioned to int which would throw off tax calculation slightly
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 Montana Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status, tax is currently figured the same for 'S' and 'M'
   *	@exempts	# of regular exemptions
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts bDollar = 0,
   @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   
   declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
   @procname varchar(30), @wage_bracket int, @tax_addition bDollar
   
   select @rcode = 0, @deduction = 1700, @procname = 'bspPRMTT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize earnings then subtract deductions */
   select @annualized_wage = @subjamt * @ppds - @exempts * @deduction
   
   /* not eligable for state tax */
   if @annualized_wage <= 8230 goto bspexit
   
   /* determine tax factors used to calculate the withholding */
   if @annualized_wage > 8230 select @tax_addition = 213.98, @wage_bracket = 8230, @rate = .044
   if @annualized_wage > 18250 select @tax_addition = 654.86, @wage_bracket = 18250, @rate = .061
   if @annualized_wage > 40000 select @tax_addition = 1981.61, @wage_bracket = 40000, @rate = .065
   
   
   bspcalc: /* calculate Montana Tax  */
   
   	select @amt = (@tax_addition + (@rate * (@annualized_wage - @wage_bracket))) / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMTT98] TO [public]
GO
