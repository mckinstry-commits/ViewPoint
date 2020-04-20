SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMAHVal    Script Date: 8/28/99 9:32:39 AM ******/
   /****** Object:  Stored Procedure dbo.bspEMAHVal    Script Date: 5/10/99 ******/
   CREATE   proc [dbo].[bspEMAHVal]
   
   	(@emco bCompany = 0, @alloccode smallint = null, @msg varchar(60) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: AE   5/10/99
    * MODIFIED By : TV 02/11/04 23061 - Added isnulls
    *
    * USAGE:
    * validates EM allocation codes
    * an error is returned if any of the following occurs
    * no allocation code passed, no allocation code found in EMAH
    *
    * INPUT PARAMETERS
    *   EMCo   EM Co to validate against 
    *   AllocCode Allocation Code to validate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of the allocation code
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   
   	declare @rcode int
   	select @rcode = 0
   
   
   if @emco is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @alloccode is null
   
   	begin
   	select @msg = 'Missing Allocation Code!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg = Description 
   	from bEMAH
   	where EMCo = @emco and AllocCode = @alloccode
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Allocation Code not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMAHVal] TO [public]
GO
