SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspJBTemplateEquipVal]
   
   /***********************************************************
    * CREATED BY:      05/23/00 bc
    * MODIFIED By :
	*				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
    *
    ***********************************************************/
   
    @emco bCompany = null,	@catgy bCat, @equip bEquip = null, @msg varchar(255) output
   
   as
   
   set nocount on
   declare @rcode int, @status char(1)
   select @rcode = 0
   
   if @emco is null
     begin
     select @msg = 'Missing EM Company!', @rcode = 1
     goto bspexit
     end
   
   if @equip is null
     begin
     select @msg = 'Missing Equipment!', @rcode = 1
     goto bspexit
     end
   
   if @catgy is null
     begin
     select @msg = 'Missing Category!', @rcode = 1
     goto bspexit
     end
   
	--Return if Equipment Change in progress for New Equipment Code - 126196
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
	If @rcode = 1
	begin
		  goto bspexit
	end

   select  @msg = Description, @status = Status
   from bEMEM
   where EMCo = @emco and Equipment = @equip and (Category is not null and Category = @catgy)
   
   if @@rowcount = 0
     begin
     select @msg = 'Equipment is invalid for category ' + @catgy, @rcode = 1
     goto bspexit
     end
   

   /* Reject if Status is not active */
   if @status <> 'A'
     begin
     select @msg = 'Equipment is not active!', @rcode = 1
     goto bspexit
     end
   
   bspexit:
   	if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[bspJBTemplateEquipVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTemplateEquipVal] TO [public]
GO
