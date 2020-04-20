SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspEMNextWOValForWOCopy]
   
   /***********************************************************
    * CREATED BY: JM 2/28/02
    * MODIFIED By : JM 12-10-02 Ref Issue 19573 - Added exclusion of WO's that contain alphas.
    *               TV 02/27/03 19573 Removed above
    *				TV 02/11/04 - 23061 added isnulls
    *
    * USAGE:
    * 	Validates next WO supplied by user as not in use.
    *
    * INPUT PARAMETERS
    *	EMCo   		EMCo to validate against 
    * 	Next WO	WO to validate 
    *
    * OUTPUT PARAMETERS
    *	@msg      	Error message if error occurs, otherwise 
    *
    * RETURN VALUE
    *	0		success
    *	1		failure
    *****************************************************/ 
   
   (@emco bCompany = null, 
   @nextwo bWO = null,
   @msg varchar(255) output)
   as
   set nocount on
   
   
   declare @rcode int, @statustype char(1)
   select @rcode = 0
   
   if @emco is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   	
   if @nextwo is null
   	begin
   	select @msg = 'Missing Begin WO!', @rcode = 1
   	goto bspexit
   	end
   
   --  TV 02/27/03 19573 Allow User to use Alpha if only creating 1 WO
   /*JM 12-10-02 Ref Issue 19573 - Added exclusion of WO's that contain alphas.
    if dbo.bfIsCompletelyNumeric(ltrim(@nextwo)) = 0
   	begin
    	select @msg = 'Work Order cannot contain alpha characters!', @rcode = 1
    	goto bspexit
    	end*/
   
   if exists (select * from bEMWH where EMCo = @emco and WorkOrder = @nextwo)
   	begin
   	select @msg = 'Beginning work order already exists!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMNextWOValForWOCopy]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMNextWOValForWOCopy] TO [public]
GO
