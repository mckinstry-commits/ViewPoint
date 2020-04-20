SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspEMWOItemAndPartsDelete]
   
   (@emco bCompany = null, @workorder bWO = null,@msg varchar(255) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: TRL 05/22/07
    * MODIFIED By : 
    *
    * USAGE:
    * 	Returns whether Parts exist in bEMWP for an EMCo 
    *	and WorkOrder
    *
    * Error returned if any of the following occurs
    *
    * 	No EMCo, WorkOrder, or WOItem passed
    *
    * INPUT PARAMETERS
    *	EMCo	   	EM Company
    * 	WorkOrder	EMWP.WorkOrder
    *
    * OUTPUT PARAMETERS
    *	@msg      	Error message if error occurs, otherwise 
    *			'true' or 'false'
    *
    * RETURN VALUE
    *	0		success
    *	1		Failure
    *****************************************************/ 
   
   declare @rcode int, @recs smallint
   select @rcode = 0
   
   if @emco is null
   	begin
   		select @msg = 'Missing EM Company!', @rcode = 1
   		goto vspexit
   	end
   if @workorder is null
   	begin
		select @msg = 'Missing Work Order!', @rcode = 1
   		goto vspexit
   	end
   
   delete dbo.EMWP
   where EMCo = @emco and WorkOrder = @workorder 
   			
   select @recs = count(*)from dbo.EMWP with (nolock)
   where EMCo = @emco and WorkOrder = @workorder
   if @recs > 0
	begin
   		select @msg = 'Not all EM Work Order Parts could be deleted!',	@rcode = 1
   	End

delete dbo.EMWI
   where EMCo = @emco and WorkOrder = @workorder 

   select @recs = count(*)from dbo.EMWI with (nolock)
   where EMCo = @emco and WorkOrder = @workorder
   if @recs > 0
	begin
   		select @msg = 'Not all EM Work Order Items could be deleted!',	@rcode = 1
   	End

   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOItemAndPartsDelete] TO [public]
GO
