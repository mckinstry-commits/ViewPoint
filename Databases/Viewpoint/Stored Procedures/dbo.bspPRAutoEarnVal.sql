SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      PROCEDURE [dbo].[bspPRAutoEarnVal]
   
   /***********************************************************
    * CREATED BY: DC 4/24/03  - #19719
    * Modfied	5/20/04 EN  issue 19719  modified some error message verbage
    *		
    *
    * USAGE:
    * Used by PR Auto Earnings to validate Rate/Amount.
    *
    * INPUT PARAMETERS
    *   @prco   	PR Company
    *   @employee   Key field
    *   @earncode	 Key field
    *   @seq 	 Key field
    *   @rateamt	 Rate/ Amount
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if Rate/Amount not valid
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ******************************************************************/
   	(@prco bCompany = 0,
   	@employee bEmployee,
   	@earncode bEDLCode,
   	@seq int,
   	@rateamt bUnitCost, 
   	@msg varchar(100) output)
   
   as
   set nocount on
   
   declare @rcode int, @stdlmt bEDLCode
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   if @employee is null
   	begin
   	select @msg = 'Missing PR Employee!', @rcode = 1
   	goto bspexit
   	end
   if @earncode is null
   	begin
   	select @msg = 'Missing PR Earnings Code!', @rcode = 1
   	goto bspexit
   	end
   if @seq is null
   	begin
   	select @msg = 'Missing PR Sequence!', @rcode = 1
   	goto bspexit
   	end
   if @rateamt is null
   	begin
   	select @msg = 'Missing PR Rate/Amount!', @rcode = 1
   	goto bspexit
   	end
   
   
   -- Get the Standard Limit from PREC
   select @stdlmt = sign(StandardLimit)
   from PREC
   where PRCo = @prco and EarnCode = @earncode
   
   if @stdlmt <> 0 and sign(@rateamt) <> 0
   	if sign(@rateamt) <> @stdlmt
   		begin
   		select @msg = 'The Rate/Amount and Standard Limit must both be of the same sign.', @rcode = 1
   		goto bspexit
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAutoEarnVal] TO [public]
GO
