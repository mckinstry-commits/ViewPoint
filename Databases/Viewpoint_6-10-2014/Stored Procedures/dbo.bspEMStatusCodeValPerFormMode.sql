SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMStatusCodeValNoFinal    Script Date: 8/28/99 9:34:31 AM ******/
   CREATE    proc [dbo].[bspEMStatusCodeValPerFormMode]
    /***********************************************************
     * CREATED BY: JM 11/12/02 - Adapted from bspEMStatusCodeValNoFinal
     * MODIFIED By : TV 02/11/04 - 23061 added isnulls
     *
     * USAGE:
     * 	Validates EM Status Code vs EMWS with fail if StatusType is 'F' for final and form 
     *	in Add or Change mode. Error returned if any of the following occurs
     *
     * 	No EMGroup passed
     *	No StatusCode passed
     *	StatusCode not found in EMWS
     *	StatusType = 'F' and form in Add or Change mode
     *	
     *
     * INPUT PARAMETERS
     *	EMGroup   	EMGroup to validate against 
     * 	StatusCode 	Status Code to validate 
     *	FormMode	Changes message if StatusType = 'F'
     *
     * OUTPUT PARAMETERS
     *	@msg      	Error message if error occurs, otherwise 
     *			Description of StatusCode from EMWS
     *
     * RETURN VALUE
     *	0		success
     *	1		failure
     *****************************************************/ 
   (@emgroup bGroup = null, @statuscode bCostCode = null, @formmode tinyint = null, @msg varchar(255) output)
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
   if @formmode is null
    	begin
    	select @msg = 'Missing Form Mode!', @rcode = 1
    	goto bspexit
    	end
    
   select @msg = Description, @statustype = StatusType from dbo.EMWS where EMGroup = @emgroup and StatusCode = @statuscode 
   if @@rowcount = 0
    	begin
    	select @msg = 'Status Code not on file!', @rcode = 1
    	goto bspexit
    	end
    
   if @statustype = 'F'
   begin
   		/* Form mode = View or Find */
   		if @formmode = 0 or @formmode = 3  
		Begin
			select @msg = 'Final'	
		End
		/* Form mode = Change or Add */
   		if @formmode = 1 or @formmode = 2 
		Begin
			select @msg = 'Cannot enter Final - use WOUpdate form.', @rcode = 1
			goto bspexit
    	end
    End

   bspexit:
    --	if @rcode<>0 select @msg=isnull(@msg,'')	+ char(13) + char(10) + '[bspEMStatusCodeValNoFinal]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMStatusCodeValPerFormMode] TO [public]
GO
