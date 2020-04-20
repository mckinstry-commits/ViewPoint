SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMST98    Script Date: 8/28/99 9:33:28 AM ******/
   CREATE   proc [dbo].[bspPRMST98]
   /********************************************************
   * CREATED BY: 	bc 6/3/98
   * MODIFIED BY:	bc 6/3/98
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 Mississippi Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status
   *	@exempt_amount	$ value of mississippi exemptions for this employee
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempt_amount bDollar = 0,
   @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
   @procname varchar(30), @allowances bDollar, @wage_bracket int, @counter tinyint,
   @accumulation bDollar
   
   select @rcode = 0, @procname = 'bspPRMST98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize earnings */
   select @annualized_wage = (@subjamt * @ppds) 
   
   /* determine the deduction based on the employee's status */
   if @status = 'S' select @deduction = 2300	/* single */
   if @status = 'B' select @deduction = 2100	/* married with 2 incomes */
   if @status = 'M' select @deduction = 4200	/* married with 1 income */
   if @status = 'H' select @deduction = 3400	/* head of household */
   
   /* calculate employees taxable income */
   select @allowances = @deduction + @exempt_amount
   select annualized_wage = @annualized_wage - @allowances
   
   /* calculate annualized state withholdings */
   select @counter = 1, @rate = .03 /* % of first $5000 of taxable income */
   
   while @counter <= 2
   	begin
   		if @annualized_wage < 5000
   			begin
   			select @accumulation = @accumulation + (5000 * @rate)
   			goto bspcalc
   			end
   
   		select @annualized_wage = @annualized_wage - 5000
   		select @counter = @counter + 1
   
   
   		if @counter = 2 select @rate = .04    	/* % of second $5000 of taxable income */
   		if @counter = 3 select @rate = .05    	/* % of the remainder of the taxable income */
   end
   		
   
   /* if taxable income is still above 10K then take % of the remainder */
   select @accumulation = @accumulation + (@annualized_wage * @rate)
   
   
   bspcalc: /* calculate Mississippi Tax rounded to the nearest dollar */
   	if @accumulation < .01 goto bspexit
   
   	select @amt = ROUND(@accumulation/@ppds,0)
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMST98] TO [public]
GO
