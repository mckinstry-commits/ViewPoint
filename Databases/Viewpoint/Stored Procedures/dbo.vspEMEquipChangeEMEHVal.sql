SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMEquipChangeEMEHVal]
/*******************************************
*	Created by:  09/17/08 TRL Issue 126196
*	Modified by:
*
*	Form:  EM Equipment
*	Usage: Verify the Equipment entered isnot being used
*	as part of an Equipment code. 
*	
*
*	Input Parameters
*	EMCo, Equipment
*	Return Parameters
*	ErrMsg
*
*******************************************/
(@emco bCompany, @equip bEquip,@errmsg varchar(256)output)

as 
set nocount on

declare @rcode int, @otherequip bEquip, @changeuser bVPUserName

select @rcode = 0 

--Validate EM Co
if @emco is null
Begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto vspexit
End

--Validate Old Equipment
--Check for missing equipment
if IsNull(@equip,'') = ''
Begin
	select @errmsg = 'Missing Equipment code!', @rcode = 1
	goto vspexit
End

--Is Equipment code already being used
If exists (select top 1 1 from EMEH Where EMCo=@emco and NewEquipmentCode=@equip)
begin
	select top 1 @otherequip = OldEquipmentCode,@changeuser = VPUserName 
	From EMEH Where EMCo=@emco and NewEquipmentCode =@equip 
	If @@rowcount >=1
	begin
		select @errmsg = 'Equipment code "'+@equip+'" records are being changed for old Equipment "'+@otherequip+'" by User: '+@changeuser+'.  Equipment code cannot be used at this time!', @rcode = 1	
		goto vspexit
	end
End

--Is Equipment code already being changed
If exists (select top 1 1 from EMEH Where EMCo=@emco and OldEquipmentCode=@equip)
begin
	select top 1 @otherequip = NewEquipmentCode,@changeuser = VPUserName 
	From EMEH Where EMCo=@emco and OldEquipmentCode =@equip
	select @errmsg = 'Equipment code "'+@equip+'" records being changed to new Equipment code "'+@otherequip+'" by User: '+@changeuser+'.  Equipment code cannot be used at this time!', @rcode = 1
	goto vspexit
End

vspexit:
	Return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipChangeEMEHVal] TO [public]
GO
