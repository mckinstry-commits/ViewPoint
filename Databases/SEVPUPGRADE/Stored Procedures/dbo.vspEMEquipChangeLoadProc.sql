SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMEquipChangeLoadProc]
/*******************************************
*	Created by:  08/09/08 TRL Issue 126196
*	Modified by:
*
*
*	Form:  EM Equipment Change
*	Usage: Load proc for form, looks to see if the 
*	VP User opening the form already has or is changing 
*	an Equipment code. If Equipment change improperly downs
*	validation returns Change info from EMEH (Equipment Change Header)
*	and EMED (Equipment Change Detail
*	Looks for valid EM Company and Returns valid VP User
*
*	Input Parameters
*	EMCo, VPUser
*	Return Parameters
*	OldEquipmentCode, NewEquipmentCode, ChangeStartDate, ChangeCompleteDate
*
*******************************************/
(@emco bCompany,@vpusername bVPUserName output,
@oldequipmentcode bEquip output,@newequipmentcode bEquip output,
@changestartdate bDate output,@changecompletedate bDate output,
@errmsg varchar(256) output)

as

set nocount on

declare @rcode int
select @rcode = 0, @changestartdate = null, @changecompletedate = null

--Validate EM Co
if @emco is null
Begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto vspexit
End
If not exists(select top 1 1 	from dbo.EMCO with (nolock)	where EMCo = @emco)
Begin
	select @errmsg = 'Company# ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
	goto vspexit
End

--Validate User Name
select @vpusername= System_User

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

--Return incomplete Equipment code change inforamation incase equipment change needs to be restarted.
--User can only change one Equipment code at a time per EM Company
If exists (select top 1 1 from dbo.EMEH with(nolock)Where EMCo=@emco and VPUserName=@vpusername)
Begin
	Select @oldequipmentcode = OldEquipmentCode, @newequipmentcode = NewEquipmentCode,
	@changestartdate=ChangeStartDate, @changecompletedate = ChangeCompleteDate
	From dbo.EMEH with(nolock)
	Where EMCo=@emco and VPUserName=@vpusername
End

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipChangeLoadProc] TO [public]
GO
