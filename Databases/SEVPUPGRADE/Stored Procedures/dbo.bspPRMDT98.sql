SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMDT98    Script Date: 8/28/99 9:33:26 AM ******/
   CREATE  proc [dbo].[bspPRMDT98]
   /********************************************************
   * CREATED BY: 	bc 6/2/98
   * MODIFIED BY:	bc 6/2/98
   * MODIFIED BY:  EN 12/29/99 - fixed calculation which was including rate from miscfactor incorrectly
   * MODIFIED BY:  EN 1/3/00 - fixed datatype of @miscfactor, amount of withholding exemption, and loop method which were all causing invalid results
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Maryland Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@exempts	# of exemptions
   *	@miscfactor	factor used for speacial tax routines
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = null, @exempts tinyint = 0,
   @miscfactor bRate = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @annualized_wage bDollar, @rate bRate,
   @procname varchar(30), @counter int, @deductions bDollar,
   @tax_addition tinyint, @wage_bracket int
   
   select @rcode = 0, @rate = 0, @procname = 'bspPRMDT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   
   /* annualize earnings */
   select @annualized_wage = (@subjamt * @ppds)
   
   select @deductions = @annualized_wage * .15
   
   if @deductions < 1500 select @deductions = 1500
   if @deductions > 2000 select @deductions = 2000
   
   
   select @annualized_wage = @annualized_wage - @deductions - (1850 * @exempts)
   
   if @annualized_wage < 0 select @annualized_wage = 0
   
   
   /* Initialize loop variables to determine the return amt */
   select @counter = 1000, @tax_addition = 0, @wage_bracket = 0, @rate = .02
   
   /* Determine which bracket this person falls into then assign the correct values to the tax factors */
   while @counter < 4000
   begin
   	if @annualized_wage < @counter goto bspcalc
   
   	if @counter = 1000 select @tax_addition = 20, @wage_bracket = 1000, @rate = .03
   	if @counter = 2000 select @tax_addition = 50, @wage_bracket = 2000, @rate = .04
   	if @counter = 3000 select @tax_addition = 90, @wage_bracket = 3000, @rate = .0485
   
       select @counter = @counter + 1000
   end
   
   bspcalc: /* calculate Maryland Tax */
   	select @amt = (@tax_addition + (@annualized_wage - @wage_bracket) * (@rate + @miscfactor)) / @ppds
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMDT98] TO [public]
GO
