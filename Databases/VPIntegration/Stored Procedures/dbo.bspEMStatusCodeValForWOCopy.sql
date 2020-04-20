SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspEMStatusCodeValForWOCopy]
   
   (@emgroup bGroup = null, @statuscode bCostCode = null, 
   @msg varchar(255) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: JM 2/28/02
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    * USAGE:
    * 	Validates EM Status Code vs EMWS with fail if StatusType <> 'N'.
    *	Error returned if any of the following occurs
    *
    * 	No EMGroup passed
    *	No StatusCode passed
    *	StatusCode not found in EMWS
    *	StatusType <> 'N'
    *	
    *
    * INPUT PARAMETERS
    *	EMGroup   	EMGroup to validate against 
    * 	StatusCode 	Status Code to validate 
    *
    * OUTPUT PARAMETERS
    *	@msg      	Error message if error occurs, otherwise 
    *			Description of StatusCode from EMWS
    *
    * RETURN VALUE
    *	0		success
    *	1		failure
    *****************************************************/ 
   
   declare @rcode int, @statustype char(1)
   select @rcode = 0
   
   if @emgroup is null
   	begin
   	select @msg = 'Missing EM Group!', @rcode = 1
   	goto bspexit
   	end
   	
   if @statuscode is null
   	begin
   	select @msg = 'Missing Status Code!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @statustype = StatusType
   from bEMWS
   where EMGroup = @emgroup and StatusCode = @statuscode 
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Status Code not on file!', @rcode = 1
   	goto bspexit
   	end
   
   if @statustype <> 'N'
   	begin
   	select @msg = 'Must be StatusType N in EMWS!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMStatusCodeValForWOCopy]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMStatusCodeValForWOCopy] TO [public]
GO
