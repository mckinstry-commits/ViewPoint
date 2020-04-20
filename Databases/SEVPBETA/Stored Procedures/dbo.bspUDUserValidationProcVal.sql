SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspUDUserValidationProcVal    Script Date: 8/28/99 9:33:17 AM ******/
   CREATE  proc [dbo].[bspUDUserValidationProcVal]
   /***********************************************************
    * CREATED BY: kb 12/31/1
    * MODIFIED By :
    *
    * USAGE:
    * validates PR Department PRDP
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Department
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   	(@valproc varchar(60), @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @valproc is null
   	begin
   	select @msg = 'Missing Validation Procedure!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from UDVH
   	where ValProc = @valproc
   
   if @@rowcount = 0
   
   	begin
   	select @msg = 'User Validation Procedure not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspUDUserValidationProcVal] TO [public]
GO
