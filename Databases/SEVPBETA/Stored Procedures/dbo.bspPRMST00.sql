SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMST00    Script Date: 8/28/99 9:33:28 AM ******/
   CREATE   proc [dbo].[bspPRMST00]
   /********************************************************
   * CREATED BY: 	bc 6/3/98
   * MODIFIED BY:	bc 6/3/98
   * MODIFIED BY:  EN 10/19/99 - update effective 1/1/2000
   * MODIFIED BY:  EN 11/03/99 - fixed several syntax errors which resulted in 0 tax amount being returned
   * MODIFIED BY:  EN 11/17/99 - fixed invalid way of calculating tax for brackets (base tax of $350 or $150 wasn't being added)
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
   @amt bDollar output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
   @procname varchar(30), @allowances bDollar, @annualtax bDollar
   
   select @rcode = 0, @procname = 'bspPRMST00'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
   	goto bspexit
   	end
   
   
   /* annualize earnings */
   select @annualized_wage = (@subjamt * @ppds)
   
   /* determine the deduction based on the employee's status */
   if @status = 'S' select @deduction = 2300	/* single */
   if @status = 'B' select @deduction = 2300	/* married with 2 incomes */
   if @status = 'M' select @deduction = 4600	/* married with 1 income */
   if @status = 'H' select @deduction = 3400	/* head of household */
   
   /* calculate employees taxable income */
   select @allowances = @deduction + @exempt_amount
   select @annualized_wage = @annualized_wage - @allowances
   
   /* calculate annualized state withholdings */
   if @annualized_wage < .01
       begin
       select @amt = 0
       goto bspexit
       end
   
   if @annualized_wage >= 10000
       begin
       select @annualtax = ((@annualized_wage - 10000) * .05) + 350
       goto bspcalc
       end
   
   if @annualized_wage >= 5000
       begin
       select @annualtax = ((@annualized_wage - 5000) * .04) + 150
       goto bspcalc
       end
   
   select @annualtax = @annualized_wage * .03
   
   bspcalc: /* calculate Mississippi Tax rounded to the nearest dollar */
   
   	select @amt = ROUND(@annualtax/@ppds,0)
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMST00] TO [public]
GO
