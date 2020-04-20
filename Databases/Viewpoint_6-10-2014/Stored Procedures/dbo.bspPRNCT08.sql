SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRNCT08]    Script Date: 12/04/2007 10:24:48 ******/
  CREATE proc [dbo].[bspPRNCT08]
  /********************************************************
  * CREATED BY: 	bc 6/2/98
  * MODIFIED BY:	bc 6/2/98
  * MODIFIED BY:  EN 1/17/00 - @tax_subtraction was dimensioned to int which would throw off tax calculation slightly
  *               EN 9/18/00 - single calculation was not subtracting std dedn and withholding allowance
  *				EN 11/26/01 - issue 15184 - update effective 11/26/01
  *				EN 10/8/02 - issue 18877 change double quotes to single
  *				EN 11/10/03 - issue 23039 - update effective 1/1/04
  *				EN 1/10/05 - issue 26244  default status and exemptions
  *				EN 11/28/06 - issue 123215  update effective 1/1/07
  *				EN 12/04/07 - issue 126396  update effective 1/1/08
  *
  * USAGE:
  * 	Calculates North Carolina Income Tax
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
  
  declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
  @procname varchar(30), @tax_subtraction bDollar, @allowance bDollar
  
  select @rcode = 0, @procname = 'bspPRNCT08'
  
  -- #26244 set default status and/or exemptions if passed in values are invalid
  if (@status is null) or (@status is not null and @status not in ('S','H','M','W')) select @status = 'S'
  if @exempts is null select @exempts = 0
 
  if @ppds = 0
  	begin
  	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  
  	goto bspexit
  	end
  
  
  /* annualize earnings */
  select @annualized_wage = @subjamt * @ppds
  
  /* calculation defaults */
  select @tax_subtraction = 0, @rate = 0
  
  /* swingin' single */
  if @status = 'S'
  	begin
  	select @deduction = 3000
  
  	/* subtract deductions and allowances from taxable income */
  	if @annualized_wage < 60000 select @allowance = 2500
  		else select @allowance = 2000
  
     	select @annualized_wage = @annualized_wage - @deduction - (@exempts * @allowance)
  
  	if @annualized_wage <= 12750 select @rate = .06
  	if @annualized_wage > 12750 select @tax_subtraction = 127.5, @rate = .07
  	if @annualized_wage > 60000 select @tax_subtraction = 577.5, @rate = .0775
  end
  
  /* head of household */
  if @status = 'H'
  	begin
  	select @deduction = 4400
  
  	if @annualized_wage < 80000 select @allowance = 2500
  		else select @allowance = 2000
  
  
  	/* subtract deductions and allowances from taxable income */
  	select @annualized_wage = @annualized_wage - @deduction - (@exempts * @allowance)
  
  	if @annualized_wage <= 17000 select @rate = .06
  	if @annualized_wage > 17000 select @tax_subtraction = 170, @rate = .07
  	if @annualized_wage > 80000 select @tax_subtraction = 770, @rate = .0775
  end
  
  /* married or qualifying widow(er) */
  if @status = 'M' or @status = 'W'
  	begin
  	select @deduction = 3000
  
  	if @annualized_wage < 50000 select @allowance = 2500
  		else select @allowance = 2000
  
  
  	/* subtract deductions and allowances from taxable income */
  	select @annualized_wage = @annualized_wage - @deduction - (@exempts * @allowance)
  
  
  
  	if @annualized_wage <= 10625 select @rate = .06
  	if @annualized_wage > 10625 select @tax_subtraction = 106.25, @rate = .07
  	if @annualized_wage > 50000 select @tax_subtraction = 481.25, @rate = .0775
  end
  
  
  
  bspcalc: /* calculate North Carolina Tax */
  
  
  select @annualized_wage = @annualized_wage * @rate - @tax_subtraction
  if @annualized_wage <= 0 goto bspexit
  select @amt = ROUND(@annualized_wage / @ppds,0)
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNCT08] TO [public]
GO
