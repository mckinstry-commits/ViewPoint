SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[vspEMEquipCompValForWOItemInit]
   
/***********************************************************
* CREATED BY: JM 6-20-02 - Adapted from bspEMEquipVal
* MODIFIED By  JM 09/19/02 - Added '@type = 'C' and ' to test of comp vs compofequip
*				TV 02/11/04 - 23061 added isnulls	
*				TRL 04/02/08 - Issues 126132  and 120532
*					re-wrote stored procedure to fit form modifications for initializing components
*				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
*
* USAGE:
*	Validates EMEM.Equipment
*	If a component, verifies that it is componentof CompOfEquip passed in
*	Returns Equip Type and ComponentTypeCode
*
* INPUT PARAMETERS
*	@emco		EM Company
*	@equip		Equipment to be validated
*	@compofequip	Component's parent equip if @equip is a Component
*
* OUTPUT PARAMETERS
*	@type			Equip Type from bEMEM
*	@componenttypecode 	ComponentTypeCode from bEMEM
*	@msg 			error or Description
*
* RETURN VALUE
*	0 success
*	1 error
***********************************************************/
(@emco bCompany = null,
 @component bEquip = null,
 @compofequip bEquip = null,
 @stdmaintgroups int output,
 @stdmaintitems int output,
 @onopenworkorders int output,
 @msg varchar(255) output)
   
as
   
set nocount on
declare @rcode int, @componentstatus char(1), @numrows int,
@equipmenttype char(1),@equipmentstatus char(1),@type char(1)
 
select @rcode = 0, @stdmaintgroups =0, @stdmaintitems =0, @onopenworkorders = 0
   
if @emco is null
begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto vspexit
end
   
if IsNull(@component,'')=''
begin
   	select @msg = 'Missing Component!', @rcode = 1
   	goto vspexit
end

if IsNull(@compofequip,'')=''
begin
   	select @msg = 'Missing Component of Equipment!', @rcode = 1
   	goto vspexit
end
 

--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @component, @msg output
If @rcode = 1
begin
	  goto vspexit
end

/*Validate Attached Component*/  
select  @msg=Description, @componentstatus = EMEM.Status, @type = EMEM.Type
from dbo.EMEM with(nolock)
where EMCo = @emco and Equipment = @component
select @numrows = @@rowcount
if @numrows = 0
begin
   	select @msg = 'Component is invalid!', @rcode = 1
   	goto vspexit
end
	/* Reject if Status inactive. */
if @componentstatus = 'I'
begin
	select @msg = 'Component Status is Inactive!', @rcode = 1
   	goto vspexit
end	


/*Validate WO Header Equipment*/  
If IsNull(@compofequip,'') <> ''
begin
	/*If a component, make sure @compofequip passed matches component's CompOfEquip */
	select @equipmenttype = EMEM.Type, @equipmentstatus=EMEM.Status 
	from dbo.EMEM 
	where EMCo = @emco and Equipment = @compofequip 
	select @numrows = @@rowcount
	if @numrows = 0
	begin
		select @msg = 'Work Order Header Equipment is not valid!', @rcode = 1
   		goto vspexit
	end

	/* If a component, make sure @compofequip passed in */
	if @equipmenttype = 'C'
	begin
		select @msg = 'Component of Equipment cannot be a Component!', @rcode = 1
   		goto vspexit
	end

	/* Reject if Status inactive. */
	if @equipmentstatus = 'I'
	begin
		select @msg = 'Component of Equipment Status is Inactive!', @rcode = 1
   		goto vspexit
	end

	
end

/*Issue 120532*/
select @stdmaintgroups = Count(Distinct i.StdMaintGroup)From dbo.EMSI i
Left Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Component=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
Left Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
Where i.EMCo=@emco and i.Equipment=@component and  IsNull(w.Equipment,@compofequip)=@compofequip 
and  IsNull(s.StatusType,'') <> 'F' and IsNull(w.WorkOrder,'') = ''

select @stdmaintitems = Count(*)from dbo.EMSI i with(nolock)
Left Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Component=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
Left Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
where i.EMCo=@emco and i.Equipment=@component and IsNull(w.Equipment,@compofequip)=@compofequip
and IsNull(s.StatusType,'') <> 'F' and IsNull(w.WorkOrder,'')= ''

select @onopenworkorders = Count(*)from dbo.EMSI i with(nolock)
Inner Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Component=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
Left Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
where i.EMCo=@emco and i.Equipment=@component and IsNull(w.Equipment,@compofequip)=@compofequip
and IsNull(s.StatusType,'') <> 'F' and IsNull(w.WorkOrder,'') <> ''

vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipCompValForWOItemInit] TO [public]
GO
