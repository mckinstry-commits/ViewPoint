SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspPRExemptRateOfGross]
   /********************************************************
   * CREATED BY:  EN 7/28/04
   * MODIFIED BY:	
   *
   * USAGE:
   *   Calculates deduction or liability amount as a rate of gross
   *   but only on subject earnings over the specified exemption limit.
   *   This exemption limit was read from PRRM_MiscAmt1 and is
   *   passed into this routine as a parameter.
   *   Returns calculated amount (if any) and exemption amount.
   *   Note that the exemption amount remains 0 until the exemption 
   *   limit has been reached the the dedn amount begins calculating.
   *
   *	Called from bspPRProcess routines
   *
   * INPUT PARAMETERS:
   *	@calcbasis		subject amount, this pay pd/pay seq
   *	@rate			dedn/liab rate
   *	@accumsubj		accumulated ytd subject amount
   *	@accumelig		accumulated ytd eligible amount
   *	@exemptamt		exemption limit amount
   *
   * OUTPUT PARAMETERS:
   *	@calcamt		calculated dedn/liab amount
   *     @eligamt		eligible earnings (will be 0 until exemption limit has been reached)
   *	@errmsg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    success
   *	1 		failure
   **********************************************************/
   (@calcbasis bDollar, @rate bUnitCost, @accumsubj bDollar, @accumelig bDollar, @exemptamt bDollar, @calcamt bDollar output, 
    @eligamt bDollar output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @procname varchar(30)
   
   select @rcode = 0, @procname = 'bspPRExemptRateOfGross'
   
   -- handle amount reversal crossing back over the exemption limit
   if (@accumsubj > @exemptamt and @accumsubj + @calcbasis <= @exemptamt)
   	select @eligamt = @exemptamt - @accumsubj, @calcamt = @rate * @eligamt
   -- exemption limit not yet reached
   else if @exemptamt >= @accumsubj + @calcbasis
   	select @eligamt = 0, @calcamt = 0
   -- exemption limit just reached in this pay pd/pay seq
   else if (@accumsubj <= @exemptamt and @accumsubj + @calcbasis > @exemptamt)
   	select @eligamt = (@accumsubj + @calcbasis) - @exemptamt, @calcamt = @rate * @eligamt
   -- exemption limit reached in previous pay pd/pay seq
   else
   	select @eligamt = @calcbasis, @calcamt = @rate * @eligamt
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRExemptRateOfGross] TO [public]
GO
