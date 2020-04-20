SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    PROCEDURE [dbo].[bspPRAutoEarnCodeVal]
   
   /***********************************************************
    * CREATED BY: MV 05/31/01
    * Modfied	MV 07/22/02 - #14690 return LimitType too
    *			EN 10/7/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * Used by PR Auto Earnings setup to validates earnings code
    *
    * INPUT PARAMETERS
    *   @prco   	PR Company
    *   @edlcode   Code to validate
    *
    * OUTPUT PARAMETERS
    *   @limit	The standard annual limit from PREC
    *	@limittype The limit type from bPREC
    *   @msg      Earning code description or error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ******************************************************************/
   	(@prco bCompany = 0, @edlcode bEDLCode = null,@limit bDollar output,
   	 @limittype varchar (10) output, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int, @PRedtype char(1), @PRDLdltype char(1)
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   if @edlcode is null
   	begin
   	select @msg = 'Missing PR Earnings Code!', @rcode = 1
   	goto bspexit
   	end
   -- validate earning code from PREC, return standard annual limit
   select @msg = Description, @limit = StandardLimit, 
	@limittype = case LimitType when 'A' then 'Annual' when 'P' then 'Pay Period' when 'M' then 'Monthly' else 'None' end
   from PREC
   where PRCo = @prco and EarnCode = @edlcode
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Earnings Code not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAutoEarnCodeVal] TO [public]
GO
