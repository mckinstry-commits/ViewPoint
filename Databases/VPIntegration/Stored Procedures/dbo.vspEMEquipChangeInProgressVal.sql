SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[vspEMEquipChangeInProgressVal]
  
/***********************************************************
* CREATED BY: TRL 08/13/2008 Issue 126196
* MODIFIED By: 
*				
*				
* USAGE:
*	Validates EMEM.Equipment is Change In progress
*  If the Change in Progress flag is Yes, return error, 
*   We don't want the user to use the Equipment until the change code program is complete
*   From the user's workstation, they can't tell what master file/setup records and detail
*   have been changed so until all records have been updated the Equipment shouldnot be accessed.
*   Why? In correct calcluations or reporting errors could occor
*
* INPUT PARAMETERS
*	@emco		EM Company
*	@equip		Equipment to be validated
*
* OUTPUT PARAMETERS
*	@msg 		error or Description
*
* RETURN VALUE
*	0 success
*	1 error
***********************************************************/
(@emco bCompany = null,@equip bEquip = null,@msg varchar(255) output)
  
as
  
set nocount on
 
declare @rcode int,@changeinprogress bYN, @newequip bEquip, @oldequip bEquip,@changeuser bVPUserName

select @rcode = 0
 
if @emco is null
begin
  	select @msg = 'Missing EM Company!', @rcode = 1
  	goto vspexit
end
  
if IsNull(@equip,'')=''
begin
  	select @msg = 'Missing Equipment!', @rcode = 1
  	goto vspexit
end

--First Check Equipment. In the Equipment Change program the EMEM Equipment record is changed first.
--Validate New Equipment Code, then Old Equipment 
select  @msg=Description,@changeinprogress = IsNull(ChangeInProgress,'N'),
@changeuser = case when IsNull(ChangeInProgress,'N') = 'Y' then  LastEquipmentChangeUser else '' end 
from dbo.EMEM with(nolock)
where EMCo = @emco and Equipment = @equip 
if @@rowcount >= 1 
begin
	--This select checks validates old equipment number entered
	select @newequip =  h.OldEquipmentCode, @changeuser = IsNull(h.VPUserName,m.LastEquipmentChangeUser) from EMEM m with(nolock)
	inner join dbo.EMEH h with(nolock)on h.EMCo=m.EMCo and h.NewEquipmentCode=m.Equipment and h.OldEquipmentCode=m.LastUsedEquipmentCode
	Where m.EMCo=@emco and Equipment=@equip
	If @@rowcount >= 1
	Begin
		select @msg = 'Equipment code "'+@equip+'" records are being changed from "'+ @newequip + '" by User '+@changeuser+'. Equipment code cannot be used at this time!',@rcode = 1
		goto vspexit
	end
end

--Return error if new equipment code is being validated and change in progress is still 'Y'
select  @msg=Description,@changeinprogress = IsNull(ChangeInProgress,'N'),
@changeuser = case when IsNull(ChangeInProgress,'N') = 'Y' then  LastEquipmentChangeUser else '' end 
from dbo.EMEM with(nolock)
where EMCo = @emco and LastUsedEquipmentCode = @equip  and IsNull(ChangeInProgress,'N') = 'Y'
if @@rowcount >= 1 
begin
	--This select checks validates old equipment number entered
	select @newequip =  h.NewEquipmentCode, @changeuser = IsNull(h.VPUserName,m.LastEquipmentChangeUser) from EMEM m with(nolock)
	inner join dbo.EMEH h with(nolock)on h.EMCo=m.EMCo and h.NewEquipmentCode=m.Equipment and h.OldEquipmentCode=m.LastUsedEquipmentCode
	Where m.EMCo=@emco and OldEquipmentCode=@equip
	If @@rowcount >= 1
	Begin
		select @msg = 'Equipment code "'+@equip+'" records are being changed to "'+ @newequip + '" by User '+@changeuser+'. Equipment code cannot be used at this time!',@rcode = 1
		goto vspexit
	end
end
  
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipChangeInProgressVal] TO [public]
GO
