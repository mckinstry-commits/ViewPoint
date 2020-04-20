SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspPRKentonKYC06]
   /********************************************************
   * CREATED BY:  EN 9/05/06  issue 122062
   * MODIFIED BY:	
   *
   * USAGE:
   *   Calculates tax deduction for Kenton County Kentucky.
   *   Uses rate1 up to @limitamt1 in annual taxable earnings.
   *   After that uses rate2 on earnings up to @limitamt2 (the FICA cap).
   *   
   *   The FICA deduction code is passing in using the routine's 
   *   Misc Amt #1 field.
   *
   *	Called from bspPRProcessLocal routine.
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
   (@calcbasis bDollar, @rate1 bUnitCost, @rate2 bUnitCost, @accumsubj bDollar, @limitamt1 bDollar, 
	@limitamt2 bDollar, @calcamt bDollar output, @eligamt bDollar output, 
	@errmsg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @procname varchar(30), @eligrate1 bUnitCost, @eligrate2 bUnitCost
   
   select @rcode = 0, @procname = 'bspPRKentonKYC06'

   -- compute tax on first $0 to @limitamt1 annual wages using rate1
   -- compute tax on @limitamt1 annual wages up to @limitamt2 (FICA cap) using rate2
   if @accumsubj + @calcbasis <= @limitamt1
		begin
		select @eligamt = @calcbasis, @calcamt = @eligamt * (@rate1*.01)
		goto bspexit
		end

   if @accumsubj < @limitamt1
		begin
		select @eligrate1 = (@limitamt1 - @accumsubj), @calcamt = @eligrate1 * (@rate1*.01)
		select @eligrate2 = (@calcbasis - (@limitamt1 - @accumsubj)), @calcamt = @calcamt + (@eligrate2 * (@rate2*.01))
		select @eligamt = @eligrate1 + @eligrate2
		goto bspexit
		end

   if @accumsubj + @calcbasis <= @limitamt2
		begin
		select @eligamt = @calcbasis, @calcamt = @eligamt * (@rate2*.01)
		goto bspexit
		end

   if @accumsubj < @limitamt2
		begin
		select @eligamt = (@limitamt2 - @accumsubj), @calcamt = @eligamt * (@rate2*.01)
		end

   
   bspexit:
	select @calcamt=ROUND(@calcamt,2)

   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRKentonKYC06] TO [public]
GO
