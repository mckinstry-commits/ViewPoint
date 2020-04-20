SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMEquipChangeEMEDTableRecordCount]
/************************************************************
*     Created by: TRL 08/18/08 Issue 126196.
*	  Modified by:	
*
*	  Form:  EM Equipment Change 
*     Usage: Used to fill Molule/Table list that shows what 
*	  what table and record count for the Equpment to be Changed
*	  called from vspEMEquipCahngeTableRecordCount
*	  Input Parameters
*     EMCo, VPUserName, OldEquipmentCode, NewEquipmentCode
*
*************************************************************/
(@emco bCompany = null,
@vpusername bVPUserName = '',
@oldequipmentcode bEquip = '',
@viewpointdatabase varchar(128),
@viewpointtablecount int output,
@usermemofieldcount int output,
@udtablecount int output,
@tablecount int=0 output,
@recordcount int=0 output,
@errmsg varchar(256) output)

as 

set nocount on

declare @rcode int, @opencursor int, 
@tablename varchar(128),@columnname varchar(128),@vpcoltype varchar(20), @vpemco varchar(128),
@rowcount int,@sqlstring as NVARCHAR(1000),@paramdef as NVARCHAR(500)

select @rcode = 0, @opencursor = 0 , @rowcount = 0,@tablecount = 0,@recordcount = 0,
@viewpointtablecount =0,@usermemofieldcount =0,@udtablecount =0

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
--Check for valid equipment code
If not exists(select top 1 1 from dbo.EMEM with(nolock) Where EMCo=@emco and Equipment=@oldequipmentcode)
Begin
	If not exists(select top 1 1 from dbo.EMEM with(nolock) Where EMCo=@emco and LastUsedEquipmentCode=@oldequipmentcode and IsNull(ChangeInProgress,'N') = 'Y')
	Begin
		select @errmsg = 'Invalid Equipment code!', @rcode = 1
		goto vspexit
	end
End

--Check for missing viewpointdatabase name
if IsNull(@viewpointdatabase,'') = ''
Begin
	select @errmsg = 'Viewpoint database cannot be null!', @rcode = 1
	goto vspexit
End

--Work Table that holds the equipment record count for each table
create table #ChangeTableList (VPMod varchar(2),VPTableName varchar(128),VPColumnName varchar(128),
 VPColType varchar(20),VPEMCo varchar(128),RecordCount int)

declare cTableList cursor local fast_forward for

Select VPTableName,VPColumnName,VPColType,VPEMCo 
FROM dbo.EMChangeEquipEMCoCol with (nolock)
Where ViewpointDB=@viewpointdatabase

Open cTableList
select @opencursor = 1

goto NextTable
NextTable:

fetch next from cTableList into @tablename,@columnname,@vpcoltype,@vpemco

If (@@fetch_status <> 0) 
begin
	goto CloseTableListCursor
end

select @rowcount =  0

If IsNull(@vpemco,'') <> ''
	begin
		set @sqlstring = N'Select @reccount = Count(*)' +
						' From dbo.'+@tablename+' with(nolock) '+
						' Where '+@vpemco+'=@emco and '+@columnname+'= @oldequipmentcode '

		set @paramdef = N'@emco tinyint, @oldequipmentcode varchar(20),@reccount int output'		
				
		exec sp_executesql @sqlstring,@paramdef,@emco,@oldequipmentcode,@reccount = @rowcount output
	end
else
	begin
		set @sqlstring = N'Select @reccount = Count(*)' +
								' From dbo.'+@tablename+' with(nolock) '+
								' Where '+@columnname+'= @oldequipmentcode'
		set @paramdef = N'@oldequipmentcode varchar(20),@reccount int output'
			
		exec sp_executesql @sqlstring,@paramdef,@oldequipmentcode,@reccount = @rowcount output
	end

--Update Equipment Detail
If @rowcount > 0
begin
	--insert into temp table for table list.
	Insert into #ChangeTableList(VPMod,VPTableName,VPColumnName,VPColType,VPEMCo,RecordCount)
	select vpmod=Left(@tablename,2),@tablename,@columnname,@vpcoltype,@vpemco,@rowcount
end

--cycle to next record
goto NextTable

CloseTableListCursor:
If @opencursor = 1
begin
	close cTableList
	deallocate cTableList
End

Select @usermemofieldcount = count(*) From #ChangeTableList e Where VPColType = 'Custom Field' 

Select @udtablecount = count(*)  From #ChangeTableList e Where VPColType = 'User Database'

Select @viewpointtablecount = count(*)  From #ChangeTableList e Where VPColType = 'Standard'
 
Select @tablecount = count(Distinct VPTableName) From #ChangeTableList

Select @recordcount=IsNull(Sum(RecordCount),0) From #ChangeTableList 

vspexit:
	Return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipChangeEMEDTableRecordCount] TO [public]
GO
