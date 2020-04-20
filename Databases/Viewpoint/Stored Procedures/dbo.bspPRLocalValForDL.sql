SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPRLocalValForDL]
   /***********************************************************
    * CREATED: GG 07/23/02
    * MODIFIED: 
    *
    * USAGE:
    * Called by PR Dedn/Liab setup to validates W2Local.  Must be
    * a unique code NOT setup in bPRLI or in use on another deduction code.
    *
    * INPUTS:
    *  @prco		PR Company
    *	@dlcode		Deduction code
    *  @w2local	W-2 Local 
    *
    * OUTPUTS:
    *   @msg      error message 
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @dlcode bEDLCode = null, @w2local bLocalCode = null, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   if @dlcode is null
   	begin
   	select @msg = 'Missing Deduction code!', @rcode = 1
   	goto bspexit
   	end
   if @w2local is null
   	begin
   	select @msg = 'Missing W-2 Local code!', @rcode = 1
   	goto bspexit
   	end
   -- check if Local code exists
   if exists(select 1 from bPRLI where PRCo = @prco and LocalCode = @w2local)
   	begin
   	select @msg = 'Local code already exists.  Must use a unique value.', @rcode = 1
   	goto bspexit
   	end
   if exists(select 1 from bPRDL where PRCo = @prco and W2Local = @w2local and DLCode <> @dlcode)
   	begin
   	select @msg = 'Local code already used with another deduction.  Use a unique value.', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRLocalValForDL] TO [public]
GO
