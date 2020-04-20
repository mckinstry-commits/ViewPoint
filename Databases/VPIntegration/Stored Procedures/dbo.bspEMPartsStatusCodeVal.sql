SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMPartsStatusCodeVal    Script Date: 2/28/2002 11:02:41 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspEMPartsStatusCodeVal    Script Date: 8/28/99 9:34:29 AM ******/
   CREATE   proc [dbo].[bspEMPartsStatusCodeVal]
   /***********************************************************
    * CREATED BY: JM 12/16/98
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    * USAGE:
    * 	Validates EM Parts Status Code vs EMPS and returns 
    *	Description, or error msg if any of the following occurs
    *
    * 	No EMGroup passed
    *	No PartsStatusCode passed
    *	PartsStatusCode not found in EMPS
    *
    * INPUT PARAMETERS
    *	EMGroup	   	EMGroup to validate against 
    * 	PartsStatusCode Status Code to be validated 
    *
    * OUTPUT PARAMETERS
    *	@msg      	Error message if error occurs, otherwise 
    *			Description of StatusCode from EMPS
    *
    * RETURN VALUE
    *	0		success
    *	1		Failure
    *****************************************************/ 
   
   (@emgroup bGroup = null, @partsstatuscode bCostCode = null, 
   @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   if @emgroup is null
   	begin
   	select @msg = 'Missing EM Group!', @rcode = 1
   	goto bspexit
   
   	end
   
   if @partsstatuscode is null
   	begin
   	select @msg = 'Missing Parts Status Code!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   from dbo.EMPS with(nolock)
   where EMGroup = @emgroup and PartsStatusCode = @partsstatuscode 
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Parts Status Code not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMPartsStatusCodeVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMPartsStatusCodeVal] TO [public]
GO
