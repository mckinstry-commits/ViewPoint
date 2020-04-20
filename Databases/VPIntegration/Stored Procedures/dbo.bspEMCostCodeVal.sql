SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCostCodeVal    Script Date: 8/28/99 9:34:26 AM ******/
   CREATE   proc [dbo].[bspEMCostCodeVal]
   /***********************************************************
    * CREATED BY: JM 8/21/98
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    * USAGE:
    * Validates EM Cost Code.
    * Error returned if any of the following occurs
    *
    * 	No EMGroup passed
    *	No CostCode passed
    *	CostCode not found in EMCC
    *
    * INPUT PARAMETERS
    *   EMGroup   EMGroup to validate against 
    *   CostCode  Cost Code to validate 
    *
    * OUTPUT PARAMETERS
    *   @msg      Error message if error occurs, otherwise 
    *		Description of CostCode from EMCC
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
(@emgroup bGroup = null, @costcode bCostCode = null, @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   


   if @emgroup is null
   	begin
   	select @msg = 'Missing EM Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @costcode is null
   	begin
   	select @msg = 'Missing Cost Code!', @rcode = 1
   	goto bspexit
   	end

---- validate cost code
select @msg = Description 
from bEMCC with (nolock)
where EMGroup = @emgroup and CostCode = @costcode 
if @@rowcount = 0
   	begin
   	select @msg = 'Cost Code not on file!', @rcode = 1
   	goto bspexit
   	end



   bspexit:
   	if @rcode <> 0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMCostCodeVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCostCodeVal] TO [public]
GO
