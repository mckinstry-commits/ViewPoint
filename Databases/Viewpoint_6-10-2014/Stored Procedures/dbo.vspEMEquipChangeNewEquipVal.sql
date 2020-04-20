SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMEquipChangeNewEquipVal]
/*******************************************
*	Created by:  08/09/08 TRL Issue 126196
*	Modified by:
*
*	Form:  EM Equipment Change
*	Usage: Validates New Equipment. 
*	Value cannot exist in EM Equipment Master for EM Company
*	Validates EM Company and VPUser
*
*	Input Parameters
*	EMCo, VPUserName, OldEquipCod, NewEquipCode
*	Return Parameters
*	ErrMsg
*
*******************************************/
(@emco bCompany,@vpusername bVPUserName, @oldequip bEquip,@newequip bEquip,
@errmsg varchar(256)output)

as 
set nocount on

declare @rcode int, @oldequipcode bEquip, @otherchangeuser bVPUserName

select @rcode = 0, @otherchangeuser = ''

--Validate EM Co
if @emco is null
Begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto vspexit
End
--Validate User Name
If IsNull(@vpusername,'') = '' 
Begin
	select @errmsg = 'Missing VP User Name!',@rcode = 1
	goto vspexit
End
If not exists(select top 1 1 from DDUP with (nolock) where VPUserName=@vpusername )
Begin
	select @errmsg = 'User name does not exist in VA User Profile!', @rcode = 1
	goto vspexit
End

--Validate Old Equipment
--Check for missing equipment
if IsNull(@oldequip,'') = ''
Begin
	select @errmsg = 'Missing the Change Equipment code!', @rcode = 1
	goto vspexit
End
--Does Equipment code to be changed exist in EMEM
If not exists(select top 1 1 from dbo.EMEM with(nolock) Where EMCo=@emco and Equipment=@oldequip)
Begin
	If not exists(select top 1 1 from dbo.EMEM with(nolock) Where EMCo=@emco and LastUsedEquipmentCode=@oldequip and IsNull(ChangeInProgress,'N') = 'Y')
	Begin
		select @errmsg = 'Equipmet to be changed is invalid!', @rcode = 1
		goto vspexit
	end
End

--Validate New Equipment
--Check for missing equipment
if IsNull(@newequip,'') = ''
Begin
	select @errmsg = 'Missing New Equipment code!', @rcode = 1
	goto vspexit
End
--New Equipment Code can't already exist in EMEM
If exists(select top 1 1 from dbo.EMEM with(nolock) Where EMCo=@emco and Equipment=@newequip and IsNull(ChangeInProgress,'N') ='N')
Begin
	select @errmsg = 'New Equipment code is already used!', @rcode = 1
	goto vspexit
End

--Is Equipment code already being used
If exists (select top 1 1 from EMEH Where EMCo=@emco and NewEquipmentCode=@newequip)
begin
	select top 1 @oldequipcode = OldEquipmentCode,@otherchangeuser = VPUserName 
	From EMEH Where EMCo=@emco and NewEquipmentCode =@newequip and OldEquipmentCode<>@oldequip
	If @@rowcount >=1
	begin
		select @errmsg = 'New Equipment code "'+@newequip+'" is being changed for Equipment: "'+@oldequipcode+'" by User: '+@otherchangeuser+'!', @rcode = 1	
		goto vspexit
	end
End

--Is Equipment code already being changed
If exists (select top 1 1 from EMEH Where EMCo=@emco and OldEquipmentCode=@newequip)
begin
	select top 1 @oldequipcode = OldEquipmentCode,@otherchangeuser = VPUserName 
	From EMEH Where EMCo=@emco and OldEquipmentCode =@newequip
	select @errmsg = 'New Equipment code "'+@newequip+'" is still being changed by User: '+@otherchangeuser+' for Equipment: "'+@oldequipcode+'".  Please wait to use the New Equipment code!', @rcode = 1
	goto vspexit
End

vspexit:
	Return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipChangeNewEquipVal] TO [public]
GO
