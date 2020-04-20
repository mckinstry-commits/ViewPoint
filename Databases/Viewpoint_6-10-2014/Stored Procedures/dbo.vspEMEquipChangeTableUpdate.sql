SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspEMEquipChangeTableUpdate]
                
/****************************************************
*Created by 08/28/08 TRL Isseu 126196 EM Equipment Change form
*Modified by: TRL Issue 132294 Updated Begin Try/Catch state and added execute as viepwointcs
*
*
*Usage: Used to change the Equipment code in All Viewpoint and User Database Tables
*also, includes custom fields (user memo fields)
*
*Input Parameters: EM Company, VPUserName, OldEquipmentCode,NewEquipmentCode,Viewpoint Database,
*Viewpoint Table, Column and EMCo col name, total records to bechanged
*
*Output Parameters: Records Changed, Change Status Message and errmsg.
*
****************************************************/
(@emco bCompany, @vpusername bVPUserName, @oldequipmentcode bEquip, @newequipmentcode bEquip,
 @viewpointdatabase varchar(128), @vptablename varchar(128), @vpcolumnname varchar(128),
 @vpemco varchar(128), @totalrecords int, @recordschanged int output,
 @changestatusmsg varchar(256) output, @errmsg varchar(275) output)   

with execute as 'viewpointcs'  -- needed for altering and updating tables directly
AS
set nocount on

declare @rcode int,@oldvptable varchar(128),@newvptable varchar(128),@udtable varchar(128),
		@updatesqlstring NVARCHAR(1000),@updateparamdef NVARCHAR(500),
		@rowcount int,@changesqlstring NVARCHAR(1000),@changeparamdef NVARCHAR(500),
		@vpactualtablename varchar(128),@errornumber as int, @errormessage varchar(256)

Select @rcode = 0, @recordschanged = 0, @changestatusmsg='',
		@oldvptable = 'b'+@vptablename,@newvptable='v'+@vptablename,@udtable=@vptablename

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

--Check for missing viewpointdatabase name
if IsNull(@viewpointdatabase,'') = ''
Begin
	select @errmsg = 'Viewpoint database cannot be null!', @rcode = 1
	goto vspexit
End

--Validate VPTableName
If IsNull(@vptablename,'') = '' 
Begin
	select @errmsg = 'Missing Viewpoint Table Name!',@rcode = 1
	goto vspexit
End

--Validate Column Name
If IsNull(@vpcolumnname,'') = '' 
Begin
	select @errmsg = 'Missing Viewpoint Column Name!',@rcode = 1
	goto vspexit
End

---?May not need this validation line?
--If not exists (Select top 1 1 from dbo.EMED with(nolock) Where EMCo=@emco and VPUserName=@vpusername
--	and OldEquipmentCode=@oldequipmentcode and NewEquipmentCode=@newequipmentcode and 
--	VPTableName=@vptablename and VPColumnName=@vpcolumnname)
--begin
--	select @errmsg = 'Equipment Change Detail record does not exist!',@rcode = 1
--	goto vspexit
--End

---- need to check if a foreign key exists that does a cascade update.
---- if an FK exists, then the equipment has already been changed when EMEM
---- was updated. Jump to the section where we update EMED with record count
IF EXISTS(SELECT f.name AS [ForeignKey] FROM sys.foreign_keys AS f
				WHERE OBJECT_NAME(f.parent_object_id) = '@vptablename'
					AND f.update_referential_action_desc = 'CASCADE')
	BEGIN
	GOTO Records_Changed
	--- Update Change info to EM Equipment Detail
	IF EXISTS(SELECT 1 FROM dbo.bEMED WHERE EMCo = @emco AND VPUserName = @vpusername 
					AND OldEquipmentCode = @oldequipmentcode
					AND NewEquipmentCode = @newequipmentcode
					AND VPTableName = @vptablename 
					AND VPColumnName=@vpcolumnname)
		BEGIN
		UPDATE dbo.bEMED
			SET RecordsChanged = RecordCount,
				ChangeStatus = 'Completed'
		WHERE EMCo = @emco
			AND VPUserName = @vpusername
			AND OldEquipmentCode = @oldequipmentcode
			AND NewEquipmentCode = @newequipmentcode
			AND VPTableName=@vptablename
			AND VPColumnName=@vpcolumnname
		END
	SET @rcode = 0
	GOTO vspexit	
	END  


--Get actual table name
SELECT @vpactualtablename = t.TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES t (NOLOCK)
Inner Join EMChangeEquipCol c with(nolock) on t.TABLE_CATALOG = c.ViewpointDB 
WHERE t.TABLE_TYPE = 'BASE TABLE' AND c.VPTableName Not In ('EMEM','EMEH','EMED') 
AND  c.VPTableType Not In ('Audit','View') and t.TABLE_NAME in (@oldvptable,@newvptable,@udtable)
If IsNull(@vpactualtablename,'')= ''
begin
	select @errmsg = 'Missing the database table for '+  +'!',@rcode = 1
	goto vspexit
end

--Work Table that holds the equipment record count for each table
create table #EquipmentCount (equipmentrecordcount int)

BEGIN TRY
	BEGIN TRANSACTION
	If IsNull(@vpemco,'') <> ''
		Begin
			set @updatesqlstring = N' Update dbo.'+ @vptablename + ' with (TABLOCKX, HOLDLOCK) ' +
				  ' Set '+@vpcolumnname+'= @newequipmentcode  From dbo.'+@vptablename + 
				  ' Where '+@vpemco+'= @emco and '+@vpcolumnname+'= @oldequipmentcode  '

			set @updateparamdef = N'@emco tinyint, @oldequipmentcode varchar(20),@newequipmentcode varchar(20)'
	
			exec	('Alter Table '+@vpactualtablename + ' DISABLE TRIGGER ALL   ' )
			
			exec sp_executesql @updatesqlstring,@updateparamdef, @emco,@oldequipmentcode,@newequipmentcode

			exec  (' Alter Table '+@vpactualtablename + ' ENABLE TRIGGER ALL') 
			
			insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select @vpactualtablename, 'EM Company: ' + convert(char(3),@emco)+ 'Equipment: ' + @oldequipmentcode,
			 @emco, 'C', @vpcolumnname , @oldequipmentcode, @newequipmentcode, getdate(), SUSER_SNAME()
		End
	Else
		Begin
			set @updatesqlstring = N'Update dbo.'+ @vptablename + ' with (TABLOCKX, HOLDLOCK) ' +
				  ' Set '+@vpcolumnname+'= @newequipmentcode From dbo.'+@vptablename + 
				  ' Where '+@vpcolumnname+'= @oldequipmentcode  '+
				  ' Alter Table '+@vpactualtablename + ' ENABLE TRIGGER ALL'

			set @updateparamdef =N'@oldequipmentcode varchar(20),@newequipmentcode varchar(20)'
			
			exec	('Alter Table '+@vpactualtablename + ' DISABLE TRIGGER ALL' ) 

			exec sp_executesql @updatesqlstring,@updateparamdef, @oldequipmentcode,@newequipmentcode

			exec  (' Alter Table '+@vpactualtablename + ' ENABLE TRIGGER ALL')  
			
			insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     		select @vpactualtablename, 'EM Company: ' + convert(char(3),@emco)+ 'Equipment: ' + @oldequipmentcode,
			 @emco, 'C', @vpcolumnname , @oldequipmentcode, @newequipmentcode, getdate(), SUSER_SNAME()
		End
	Commit TRANSACTION
	
	exec(' Alter Table '+@vpactualtablename + ' ENABLE TRIGGER ALL') 
END TRY
BEGIN CATCH
	SELECT  @errornumber = ERROR_NUMBER() , @errormessage = Left(ERROR_MESSAGE(),255)
    
	-- Is Transaction committable, committ
	IF XACT_STATE() = 1
	begin
		Commit TRANSACTION
	end;

	-- If transaction is uncommittable, rollback
	IF XACT_STATE() =-1
	begin
		select @errmsg = @errormessage + ' - SQL Error: '+ convert(varchar(8),@errornumber), @rcode = 1
		ROLLBACK TRANSACTION
	end;
	exec  (' Alter Table '+@vpactualtablename + ' ENABLE TRIGGER ALL')  As User = 'viewpointcs'
		
END CATCH

IF IsNull(@vpemco,'') <> ''
	BEGIN
		set @changesqlstring = N' Select @reccount = Count('+@vpcolumnname+')' +
			  ' From dbo.'+@vptablename+' with(nolock) '+
			  ' Where '+@vpemco+'= @emco and '+@vpcolumnname+' = @newequipmentcode'
		set @changeparamdef = N'@emco tinyint, @newequipmentcode varchar(20), @reccount int output'

		exec sp_executesql @changesqlstring,@changeparamdef, @emco,@newequipmentcode,@reccount = @rowcount output
	END
ELSE
	BEGIN
		set @changesqlstring = N'Select @reccount = Count('+@vpcolumnname+')' +
			  ' From dbo.'+@vptablename+' with(nolock) '+
			  ' Where '+@vpcolumnname+'= @newequipmentcode'
		set @changeparamdef = N'@newequipmentcode varchar(20), @reccount int output'

		exec sp_executesql @changesqlstring,@changeparamdef, @newequipmentcode,@reccount = @rowcount output
	END
	


Records_Changed:
select @recordschanged = @rowcount 
--set changes status update message
select @changestatusmsg = case 
	when @totalrecords> 0 and @rowcount=0 then 'Errors, no records changed!'
	when @totalrecords = @rowcount then 'Records changed: ' + convert(varchar,IsNull(@rowcount,0)) + ' out of ' + convert(varchar,IsNull(@totalrecords,0))
	when @totalrecords > @rowcount then 'Records changed: '+ convert(varchar,IsNull(@rowcount,0)) + ' out of ' + convert(varchar,IsNull(@totalrecords,0))+' - Less Records Changed!'
	when @totalrecords < @rowcount then 'Error! Records changed: ' + convert(varchar,IsNull(@rowcount,0)) + ' out of ' + convert(varchar,IsNull(@totalrecords,0))+' - More Records Changed'
	else 'Check for errors, no records changed.' end



--set @rcode 
select @rcode = case when @totalrecords> 0 and @rowcount=0 then 1 /*Error, all records should be updated*/
	when @totalrecords = @rowcount then 0 /*No Errors*/
	when @totalrecords > @rowcount then 7 /*Success Conditional - Error? more records converted? More records could have been added?*/
	when @totalrecords < @rowcount then 9 /*Cannot Continue Errors can't leave records with no parent*/
	else 1 end /*Errors, nothing happend*/ 



--Update Change info to EM Equipment Detail
If exists (select top 1 1 From dbo.EMED with(nolock) Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
		 and NewEquipmentCode=@newequipmentcode and VPTableName=@vptablename and VPColumnName=@vpcolumnname)
	begin
		Update dbo.EMED
		Set RecordsChanged = @rowcount,ChangeStatus=@changestatusmsg
		Where EMCo=@emco and VPUserName=@vpusername and OldEquipmentCode=@oldequipmentcode
		and NewEquipmentCode=@newequipmentcode and VPTableName=@vptablename and VPColumnName=@vpcolumnname
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipChangeTableUpdate] TO [public]
GO
