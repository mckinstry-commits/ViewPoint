SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRDednRoutineVal    Script Date: 8/28/99 9:33:17 AM ******/
   CREATE  procedure [dbo].[bspPRDednRoutineVal]
   /***********************************************************
    * CREATED BY: GG 10/6/98
    * MODIFIED BY : EN 10/8/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * Called by the Employee Filing Status form to validate a routine
    * based deduction code.
    *
    * INPUT PARAMETERS
    *   @prco   	PR Company
    *   @dlcode   	Deduction code to validate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ******************************************************************/
   	(@prco bCompany = 0, @dlcode bEDLCode, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int, @dltype char(1), @method varchar(10)
   
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
   
   -- validate code
   select @msg = Description, @dltype = DLType, @method = Method
   from PRDL
   where PRCo = @prco and DLCode = @dlcode
   if @@rowcount = 0
       begin
   	select @msg = 'PR Deduction Code not on file!', @rcode = 1
   	goto bspexit
   	end
   -- validate Type
   if @dltype <> 'D'
       begin
   	select @msg = 'Must be a deduction!', @rcode = 1
   	goto bspexit
   	end
   -- validate Method
   if @method <> 'R'
       begin
   	select @msg = 'Must be a routine based deduction code!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDednRoutineVal] TO [public]
GO
