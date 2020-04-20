SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMEquipChangeEMEMUpdate]
(@emco int,@oldequipmentcode bEquip,@newequipmentcode bEquip,
@vpusername bVPUserName,@changedate bDate,@changecomplete bDate ,@changestatus varchar(20),
@viewpointdatabase varchar(128),@errmsg varchar(256)output)

as

set nocount on

declare @rcode int,@procerrmsg varchar(256)
select @rcode = 0, @procerrmsg =''

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
if IsNull(@oldequipmentcode,'') = ''
Begin
	select @errmsg = 'Missing Equipment code to change!', @rcode = 1
	goto vspexit
End

--Valid ChangeStatus
--Check for missing Change Status
If IsNull(@changestatus,'') = '' 
begin
	select @errmsg = 'Missing Equipment Change Status!', @rcode = 1
	goto vspexit
end
--Check for invalid change status, value not accessible by customer
If @changestatus not in ('Started','Complete')
begin
	select @errmsg = 'Invalid Equipment Change Status!', @rcode = 1
	goto vspexit
end

--Validate New Equipment
--Check for missing equipment
if IsNull(@newequipmentcode,'') = ''
Begin
	select @errmsg = 'Missing New Equipment code to change!', @rcode = 1
	goto vspexit
End
--Check for valid New Equipment code
If exists(select top 1 1 from dbo.EMEM with(nolock) Where EMCo=@emco and Equipment=@newequipmentcode and IsNull(ChangeInProgress,'N') = 'N')
Begin
	select @errmsg = 'New Equipment code already exists!', @rcode = 1
	goto vspexit
End

--Check for missing viewpointdatabase name
if IsNull(@viewpointdatabase,'') = ''
Begin
	select @errmsg = 'Viewpoint database cannot be null!', @rcode = 1
	goto vspexit
End

If IsNull(@changestatus,'') = 'Started'
Begin
	Begin
		Update dbo.EMEM
		Set ChangeInProgress = 'Y', LastUsedEquipmentCode=@oldequipmentcode,LastEquipmentChangeUser=@vpusername
		Where  EMCo=@emco and Equipment = @oldequipmentcode and IsNull(ChangeInProgress,'N') = 'N'
	 end

	Begin
		Update dbo.EMEM
		Set Equipment= @newequipmentcode
		Where  EMCo=@emco and Equipment = @oldequipmentcode and IsNull(ChangeInProgress,'N') = 'Y'
	 end
	 --FillListTables first 
	If not exists (select top 1 1 from dbo.EMEH Where EMCo=@emco and OldEquipmentCode = @oldequipmentcode and NewEquipmentCode=@newequipmentcode)
	begin
		 Insert into dbo.EMEH(EMCo,OldEquipmentCode,NewEquipmentCode,VPUserName,ChangeStartDate)
		Select @emco,@oldequipmentcode,@newequipmentcode,@vpusername,@changedate
	end	

	 exec @rcode = dbo.vspEMEquipChangeEMEDUpdate @emco,@vpusername,@oldequipmentcode,@newequipmentcode,@viewpointdatabase, @procerrmsg output
	 If @rcode = 1
	 begin
		select @procerrmsg=@errmsg
		goto vspexit
	end	
End

If IsNull(@changestatus,'') = 'Complete'
Begin
	Begin
		Update dbo.EMEM
		Set ChangeInProgress = 'N',LastEquipmentChangeUser=@vpusername, LastEquipmentChangeDate=@changecomplete,
		EquipmentCodeChanges = IsNull(EquipmentCodeChanges,0) + 1
		Where  EMCo=@emco and Equipment = @newequipmentcode	and IsNull(ChangeInProgress,'N') = 'Y'
	End

    Delete from EMED Where EMCo=@emco and OldEquipmentCode = @oldequipmentcode and NewEquipmentCode =@newequipmentcode
	and VPUserName= @vpusername 
	
	Delete from EMEH Where EMCo=@emco and OldEquipmentCode = @oldequipmentcode and NewEquipmentCode =@newequipmentcode 
	and VPUserName= @vpusername 
	
End

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipChangeEMEMUpdate] TO [public]
GO
