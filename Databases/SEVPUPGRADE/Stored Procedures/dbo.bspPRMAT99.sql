SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMAT99    Script Date: 8/28/99 9:33:26 AM ******/
   CREATE   proc [dbo].[bspPRMAT99]
   /********************************************************
   * CREATED BY: 	bc 6/1/98
   * MODIFIED BY:  EN 12/17/98
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Massachusettes Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@exempts	# of exemptions (0-99)
   *	@addtl_exempts	# additional exemptions (for disabilities)
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
   @addtl_exempts tinyint = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   
   set nocount on
   
   declare @rcode int, @annualized_wage bDollar, @dedn bDollar, @rate bRate,
   @procname varchar(30), @total_exempts tinyint
   
   select @rcode = 0, @rate = .0595, @procname = 'bspPRMAT99'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize earnings  */
   select @annualized_wage = (@subjamt * @ppds) 
   
   
   /* not eligable for state tax if earnings below 8K */
   
   if @exempts >= 1 and @annualized_wage <= 8000 goto bspexit
   
   if (@annualized_wage * .0765) < 2000
   	select @annualized_wage = @annualized_wage - (@annualized_wage * .0765)
   else
   	select @annualized_wage = @annualized_wage - 2000
   
   
   select @total_exempts = @exempts + @addtl_exempts
   
   
   if @total_exempts = 1
   	select @annualized_wage = @annualized_wage - 4400
   
   if @total_exempts >1
   	select @annualized_wage = @annualized_wage - (@total_exempts * 1000) - 3400
   
   
   bspcalc: /* calculate Massachusettes Tax */
   	select @amt = (@annualized_wage * @rate) / @ppds
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMAT99] TO [public]
GO
