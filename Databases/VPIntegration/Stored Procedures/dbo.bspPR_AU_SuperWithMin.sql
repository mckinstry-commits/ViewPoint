SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspPR_AU_SuperWithMin]
   /********************************************************
   * CREATED BY:  EN 8/10/09
   * MODIFIED BY:	
   *
   * USAGE:
   *   Calculates Superannuation Guarantee (liability) amount as a rate of gross
   *   with a minimum contributio amount dependant on the employee's work state.
   *
   *	Called from bspPRProcessEmpl routine
   *
   * INPUT PARAMETERS:
   *	@calcbasis		subject amount, this pay pd/pay seq
   *	@rate			dedn/liab rate
   *	@workstate		employee's work (unemployment) state
   *
   * OUTPUT PARAMETERS:
   *	@calcamt		calculated dedn/liab amount
   *	@errmsg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    success
   *	1 		failure
   **********************************************************/
   (@calcbasis bDollar, @rate bUnitCost, @workstate varchar(4), @ppds tinyint, @calcamt bDollar output, 
    @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @procname varchar(30), @ratebasedtax bDollar, @mincontrib bDollar
   
   select @rcode = 0, @procname = 'bspPR_AU_SuperWithMin'

   -- compute tax at the given rate
   select @ratebasedtax = @calcbasis * @rate

   -- determine minimum contribution factor depending on the pay period length

   -- determine minimum contribution based on work state and factored for pay period length
   if @workstate = 'NSW' select @mincontrib = 110.00 * (52 / @ppds)
   if @workstate = 'QLD' select @mincontrib = 125.00 * (52 / @ppds)
   if @workstate = 'VIC' select @mincontrib = 124.90 * (52 / @ppds)
   if @workstate = 'WA' select @mincontrib = 124.00 * (52 / @ppds)
  
   -- determine tax
   select @calcamt = @ratebasedtax
   if @mincontrib > @ratebasedtax select @calcamt = @mincontrib

   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_SuperWithMin] TO [public]
GO
