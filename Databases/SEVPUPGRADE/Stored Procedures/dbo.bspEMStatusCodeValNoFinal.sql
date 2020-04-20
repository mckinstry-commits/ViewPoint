SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMStatusCodeValNoFinal    Script Date: 8/28/99 9:34:31 AM ******/
   CREATE   proc [dbo].[bspEMStatusCodeValNoFinal]
    /***********************************************************
     * CREATED BY: JM 11/9/98
     * MODIFIED By : JM 3/23/01 - Modified error message to tell user to use EMWOUpdate form to enter final status.
     *				TV 02/11/04 - 23061 added isnulls
     * USAGE:
     * 	Validates EM Status Code vs EMWS with fail if StatusType
     *	is 'F' for final. Error returned if any of the following 
     *	occurs
     *
     * 	No EMGroup passed
     *	No StatusCode passed
     *	StatusCode not found in EMWS
     *	StatusType = 'F'
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
   (@emgroup bGroup = null, @statuscode bCostCode = null, @msg varchar(255) output)
   as
   set nocount on
   
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
   from dbo.EMWS with(nolock)
   where EMGroup = @emgroup and StatusCode = @statuscode 
   if @@rowcount = 0
    	begin
    	select @msg = 'Status Code not on file!', @rcode = 1
    	goto bspexit
    	end
    
   if @statustype = 'F'
    	begin
    	select @msg = 'Cannot enter Final - use WOUpdate form.', @rcode = 1
    	goto bspexit
    	end
    
   
   
   bspexit:
    	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMStatusCodeValNoFinal]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMStatusCodeValNoFinal] TO [public]
GO
