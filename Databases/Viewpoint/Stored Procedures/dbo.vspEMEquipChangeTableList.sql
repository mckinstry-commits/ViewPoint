SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMEquipChangeTableList]
/************************************************************
* Created by: TRL 08//08 Issue 126196.
* Modified by:	GF 01/14/2010 - issue #137295 execute as 'viewpointcs'
*
*	  Form:  EM Equipment Change
*     Usage: Used to fill Molule/Table list that shows what 
*	  what table and record count for the Equpment to be Changed
*
*	  Input Parameters
*     EMCo, VPUserName, OldEquipmentCode, NewEquipmentCode
*
*************************************************************/
(@emco bCompany = null,
@vpusername bVPUserName = '',
@oldequipmentcode bEquip = '',
@newequipmentcode bEquip = '',
@viewpointdatabase varchar(128),
@errmsg varchar(256) output)

with execute as 'viewpointcs'  -- needed for bypassing datatype security so that all tables that need changing are in the list.

as 
set nocount on

declare @rcode int, @opencursor int, 
@tablename varchar(128),@columnname varchar(128),@vpemco varchar(128),@vpcoltype varchar(20),
@rowcount int,@sqlstring as NVARCHAR(1000),@paramdef as NVARCHAR(500)

select @rcode = 0, @opencursor = 0 , @rowcount = 0


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
If not exists(select top 1 1 from dbo.DDUP with (nolock) where VPUserName=@vpusername )
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

--Check for missing viewpointdatabase name
if IsNull(@viewpointdatabase,'') = ''
Begin
	select @errmsg = 'Viewpoint database cannot be null!', @rcode = 1
	goto vspexit
End
--Check for valid equipment code
If not exists(select top 1 1 from dbo.EMEM with(nolock) Where EMCo=@emco and Equipment=@oldequipmentcode)
Begin
	If not exists(select top 1 1 from dbo.EMEM with(nolock) Where EMCo=@emco and LastUsedEquipmentCode=@oldequipmentcode and IsNull(ChangeInProgress,'N') = 'Y')
	begin
		select @errmsg = 'Invalid Equipment code!', @rcode = 1
		goto vspexit
	end
End

--Work Table that holds the equipment record count for each table
create table #ChangeTableList (EMCo tinyint,OldEquipment varchar(10),NewEquipment varchar(12),VPUserName varchar(128),
VPMod varchar(2),VPTableName varchar(128),VPColumnName varchar(128),VPColType varchar(20),VPEMCo varchar(128),
RecordCount int)

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

BEGIN TRY
IF IsNull(@vpemco,'')<> ''
	--This gets the count for table that have bEquip and bEMCo columns
	Begin
		set @sqlstring = N'Select @reccount = Count(*)' +
					' From dbo.'+@tablename+' with(nolock) '+
					' Where '+@vpemco+'=@emco and '+@columnname+'= @oldequipmentcode '

		set @paramdef = N'@emco tinyint, @oldequipmentcode varchar(20),@reccount int output'		
				
		exec sp_executesql @sqlstring,@paramdef,@emco,@oldequipmentcode,@reccount = @rowcount output
	
	End
ELSE
	--This section is for UD tables where the bEquip column has no bEMCo table column
	Begin
		set @sqlstring = N'Select @reccount = Count(*)' +
						' From dbo.'+@tablename+' with(nolock) '+
						' Where '+@columnname+'= @oldequipmentcode'
		set @paramdef = N'@oldequipmentcode varchar(20),@reccount int output'
		
		exec sp_executesql @sqlstring,@paramdef,@oldequipmentcode,@reccount = @rowcount output
	End

--insert into temp table for table list for records exist
If @rowcount > 0
BEGIN
	Insert into #ChangeTableList(EMCo,OldEquipment,NewEquipment,VPUserName,
	VPMod,VPTableName,VPColumnName,VPColType,VPEMCo,RecordCount)
	select @emco,@oldequipmentcode,@newequipmentcode,@vpusername,
	vpmod=Upper(Left(@tablename,2)),@tablename,@columnname,@vpcoltype,@vpemco,@rowcount
	
	If exists (select top 1 1 from dbo.EMED with(nolock)
			where EMCo=@emco and OldEquipmentCode=@oldequipmentcode and NewEquipmentCode=@newequipmentcode 
			and VPUserName=@vpusername)
	Begin
		--If detail record exists and TotalRowCount has changed, update EM Equipment Change Detail
		If exists (select top 1 1 from dbo.EMED with(nolock)
			where EMCo=@emco and OldEquipmentCode=@oldequipmentcode and NewEquipmentCode=@newequipmentcode 
			and VPUserName=@vpusername and VPTableName=@tablename and VPColumnName=@columnname 
			and VPColType=@vpcoltype and VPEMCo=@vpemco and (IsNull(RecordCount,0) =0 or IsNull(RecordCount,0)<=@rowcount))
			Begin
				Update dbo.EMED
				Set RecordCount = @rowcount
				Where EMCo=@emco and OldEquipmentCode=@oldequipmentcode and NewEquipmentCode=@newequipmentcode 
				and VPUserName=@vpusername and VPTableName=@tablename and VPColumnName=@columnname 
				and VPColType=@vpcoltype and VPEMCo=@vpemco
			End
		else
			Begin
				Insert Into dbo.EMED (EMCo,OldEquipmentCode,NewEquipmentCode,VPUserName,
				VPMod,VPTableName,VPColumnName,VPColType,VPEMCo,RecordCount,RecordsChanged,ChangeStatus)
				select @emco,@oldequipmentcode,@newequipmentcode,@vpusername,
				vpmod=Upper(Left(@tablename,2)),@tablename,@columnname,@vpcoltype,@vpemco, @rowcount,
				RecordsChanged=0,ChangeStatus=null
			End
	 End

	goto NextTable		
END

/*This is to check for Equipment Code that have already been changed
when errors have occured.*/
IF @rowcount = 0 and IsNull(@newequipmentcode,'') <> ''
BEGIN
	select @rowcount =  0

	If IsNull(@vpemco,'')<> ''
		--This gets the count for table that have bEquip and bEMCo columns
		Begin
			set @sqlstring = N'Select @reccount = Count(*)' +
						' From dbo.'+@tablename+' with(nolock) '+
						' Where '+@vpemco+'=@emco and '+@columnname+'= @newequipmentcode '

			set @paramdef = N'@emco tinyint, @newequipmentcode varchar(20),@reccount int output'		
				
			exec sp_executesql @sqlstring,@paramdef,@emco,@newequipmentcode,@reccount = @rowcount output
	
		End
	Else
		--This section is for UD tables where the bEquip column has no bEMCo table column
		Begin
			set @sqlstring = N'Select @reccount = Count(*)' +
						' From dbo.'+@tablename+' with(nolock) '+
						' Where '+@columnname+'= @newequipmentcode'
			set @paramdef = N'@newequipmentcode varchar(20),@reccount int output'
		
			exec sp_executesql @sqlstring,@paramdef,@newequipmentcode,@reccount = @rowcount output
		End
	--Add to Change table List
	If @rowcount > 0
	BEGIN
		Insert into #ChangeTableList(EMCo,OldEquipment,NewEquipment,VPUserName,
		VPMod,VPTableName,VPColumnName,VPColType,VPEMCo,RecordCount)
		select @emco,@oldequipmentcode,@newequipmentcode,@vpusername,
		vpmod=Upper(Left(@tablename,2)),@tablename,@columnname,@vpcoltype,@vpemco,@rowcount
	
		If exists (select top 1 1 from dbo.EMED with(nolock)
			where EMCo=@emco and OldEquipmentCode=@oldequipmentcode and NewEquipmentCode=@newequipmentcode 
			and VPUserName=@vpusername)
		Begin
			--If detail record exists and TotalRowCount has changed, update EM Equipment Change Detail
			If exists (select top 1 1 from dbo.EMED with(nolock)
				where EMCo=@emco and OldEquipmentCode=@oldequipmentcode and NewEquipmentCode=@newequipmentcode 
				and VPUserName=@vpusername and VPTableName=@tablename and VPColumnName=@columnname 
				and VPColType=@vpcoltype and VPEMCo=@vpemco and (IsNull(RecordCount,0) =0 or IsNull(RecordCount,0)<=@rowcount))
				Begin
					Update dbo.EMED
					Set RecordCount = @rowcount
					Where EMCo=@emco and OldEquipmentCode=@oldequipmentcode and NewEquipmentCode=@newequipmentcode 
					and VPUserName=@vpusername and VPTableName=@tablename and VPColumnName=@columnname 
					and VPColType=@vpcoltype and VPEMCo=@vpemco
				End
			else
				Begin
					Insert Into dbo.EMED (EMCo,OldEquipmentCode,NewEquipmentCode,VPUserName,
					VPMod,VPTableName,VPColumnName,VPColType,VPEMCo,RecordCount,RecordsChanged,ChangeStatus)
					select @emco,@oldequipmentcode,@newequipmentcode,@vpusername,
					vpmod=Upper(Left(@tablename,2)),@tablename,@columnname,@vpcoltype,@vpemco,@rowcount,
					RecordsChanged=0,ChangeStatus=null
				End
		End
	END
END
END TRY
BEGIN CATCH
				
	goto NextTable		

END CATCH

--cycle to next record
goto NextTable

CloseTableListCursor:
If @opencursor = 1
begin
	close cTableList
	deallocate cTableList	
End

-- Fill List View
Select c.VPMod,c.VPTableName,c.VPColumnName,c.VPColType,
VPChangeYN = 'Y',
c.VPEMCo, c.RecordCount, RecordsChanged = IsNull(e.RecordsChanged,0),ChangeStatus = IsNull(e.ChangeStatus,'')
From #ChangeTableList c
Left Join dbo.EMED e with(nolock)on e.VPMod=c.VPMod and e.VPTableName=c.VPTableName and e.VPColumnName=c.VPColumnName and e.VPColType=c.VPColType
and e.EMCo=c.EMCo and e.OldEquipmentCode=c.OldEquipment and e.NewEquipmentCode=c.NewEquipment and e.VPUserName=c.VPUserName

vspexit:
	Return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipChangeTableList] TO [public]
GO
