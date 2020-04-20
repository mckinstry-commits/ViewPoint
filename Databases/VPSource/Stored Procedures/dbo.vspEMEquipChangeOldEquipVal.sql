SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMEquipChangeOldEquipVal]
/*******************************************
*	Created by:  08/09/08 TRL Issue 126196
*	Modified by:
*
*	Form:  EM Equipment Change
*	Usage: Validates Equipment being changed and returns equipment info
*	
*	Input Parameters
*	EMCo, VPUserName, Equip
*	Return Parameters
*	Type,Status,Make,Model,Year,ErrMsg
*
*******************************************/
(@emco bCompany,@vpusername bVPUserName, @equip bEquip,
@type varchar(1) output,@status varchar(1) output,@make varchar(20) output,
@model varchar (20) output,@year varchar(6)output,@errmsg varchar(256)output)

as 

set nocount on

declare @rcode int, @otherchangeuser bVPUserName, @oldequipcode bEquip, @newequipcode bEquip,
@changeinprogressYN bYN

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

--Validate Equipment
--Check for missing equipment
if IsNull(@equip,'') = ''
Begin
	select @errmsg = 'Missing Equipment Code to change!', @rcode = 1
	goto vspexit
End
--Is Equipment code already being changed
If exists (select top 1 1 from EMEH Where EMCo=@emco and OldEquipmentCode=@equip)
begin
	select top 1 @newequipcode = NewEquipmentCode,@otherchangeuser = VPUserName 
	From EMEH Where EMCo=@emco and OldEquipmentCode =@equip and VPUserName <> @vpusername
	If @@rowcount >= 1
	begin
		select @errmsg = 'Equipment code already being changed to "'+@newequipcode+'" by User: '+@otherchangeuser+'!', @rcode = 1
		goto vspexit
	end
End
--Is Equipment code already being used
If exists (select top 1 1 from EMEH Where EMCo=@emco and NewEquipmentCode=@equip)
begin
	select top 1 @oldequipcode = OldEquipmentCode,@otherchangeuser = VPUserName 
	From EMEH Where EMCo=@emco and NewEquipmentCode =@equip and VPUserName <> @vpusername
	If @@rowcount >=1 
	begin
		select @errmsg = 'Equipment code is being changed for Equipment: "'+@oldequipcode+'" by User: '+@otherchangeuser+'!', @rcode = 1
		goto vspexit
	end
End

--Check for valid equipment code
If not exists(select top 1 1 from dbo.EMEM with(nolock) Where EMCo=@emco and Equipment=@equip)
	Begin
		If not exists(select top 1 1 from dbo.EMEM with(nolock) Where EMCo=@emco and LastUsedEquipmentCode=@equip and IsNull(ChangeInProgress,'N') = 'Y')
			Begin
				select @errmsg = 'Invalid Equipment code!', @rcode = 1
				goto vspexit
			end
		else
			Begin
				--get equipment to be changed info
				select @errmsg=Description,@type = EMEM.Type, @status = EMEM.Status, @make=Manufacturer,@model=Model,@year=ModelYr,
				@changeinprogressYN=IsNull(ChangeInProgress,'N')
				From dbo.EMEM with(nolock) 
				Where LastUsedEquipmentCode=@equip
			End
	End
Else
	Begin
		--get equipment to be changed info
		select @errmsg=Description,@type = EMEM.Type, @status = EMEM.Status, @make=Manufacturer,@model=Model,@year=ModelYr,
		@changeinprogressYN=IsNull(ChangeInProgress,'N')
		From dbo.EMEM with(nolock) 
		Where EMCo=@emco and Equipment=@equip 
	End

vspexit:
	Return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipChangeOldEquipVal] TO [public]
GO
