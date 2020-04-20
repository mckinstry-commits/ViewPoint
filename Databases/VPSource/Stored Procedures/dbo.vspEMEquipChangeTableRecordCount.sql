SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMEquipChangeTableRecordCount]
(@emco bCompany,@vpusername bVPUserName,@oldequipmentcode bEquip,@newequipmentcode bEquip,@viewpointdatabase varchar(128),
@viewpointtablecount int=0 output,@usermemofieldcount int=0 output,@udtablecount int=0 output,
@tablecount int=0 output, @recordcount int=0 output,@tableschanged int=0 output, @recordschanged int=0 output,
@errmsg varchar(256) output)
/************************************************************
*     Created by: TRL 08/18/08 Issue 126196.
*	  Modified by:	
*
*	  Form:  EM Equipment Change
*     Usage: Used to get table and record count for the Equpment to be Changed
*	  Procedure needs to be run before change process and when errors have encountered on incomplete changes.
*
*	  Input Parameters
*     EMCo, VPUserName, OldEquipmentCode, NewEquipmentCode
*
*************************************************************/
as 

set nocount on

declare @rcode int
--Set counts to zero first, want to always return some value for counts
select @rcode = 0, @tablecount=0, @recordcount=0, @tableschanged=0, @recordschanged=0,
@viewpointtablecount =0,@usermemofieldcount =0,@udtablecount =0

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
If IsNull(@vpusername,'') = '' 
Begin
	select @errmsg = 'Missing VP User Name!',@rcode = 1
	goto vspexit
End

--First Check if incomplete update has occured
If exists (select top 1 1 from dbo.EMED with(nolock) Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode)
	BEGIN
	IF IsNull(@newequipmentcode,'') <> ''
		--Return counts with new equipment.
		Begin
			Select @viewpointtablecount = Count(distinct VPTableName) from dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
			and VPColType='Standard'

			Select @usermemofieldcount=IsNull(Sum(RecordsChanged),0) From dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
			and VPColType='Custom Field'

			Select @udtablecount= Count(distinct VPTableName) From dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
			and VPColType='User Database'

			Select @tableschanged = Count(distinct VPTableName) from dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
			and NewEquipmentCode = @newequipmentcode and IsNull(RecordsChanged,0) <> 0

			Select @recordschanged=IsNull(Sum(RecordsChanged),0) From dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
			and NewEquipmentCode = @newequipmentcode and IsNull(RecordsChanged,0) <> 0

			Select @tablecount= Count(distinct VPTableName) From dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
			and NewEquipmentCode = @newequipmentcode

			Select @recordcount=Sum(IsNull(RecordCount,0)) From dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
			and NewEquipmentCode = @newequipmentcode
		End
	ELSE
		--This is here in case new equipment code doesn't get updated for some reason
		--This code is run after the Old Equipment code is entered.
		Begin
			Select @viewpointtablecount = Count(distinct VPTableName) from dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
			and VPColType='Standard'

			Select @usermemofieldcount=IsNull(Sum(RecordsChanged),0) From dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
			and VPColType='Custom Field'

			Select @udtablecount= Count(distinct VPTableName) From dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
			and VPColType='User Database'

			Select @tableschanged = Count(distinct VPTableName) from dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
			and IsNull(RecordsChanged,0) <> 0

			Select @recordschanged=IsNull(Sum(RecordsChanged),0) From dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
			and IsNull(RecordsChanged,0) <> 0

			Select @tablecount= Count(distinct VPTableName) From dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
		
			Select @recordcount=Sum(IsNull(RecordCount,0)) From dbo.EMED with(nolock)
			Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
		End
	END
ELSE
	/*Change Detail Records aren't inserted into EMED until the user starts the change process
	This table get the table record cound before the update. This numbers could change once 
	any open batch are updated.*/
	BEGIN
		exec @rcode = dbo.vspEMEquipChangeEMEDTableRecordCount @emco,@vpusername,@oldequipmentcode,@viewpointdatabase,@viewpointtablecount output,@usermemofieldcount output,@udtablecount output,@tablecount output,@recordcount output,@errmsg output
	END

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipChangeTableRecordCount] TO [public]
GO
