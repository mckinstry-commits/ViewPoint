CREATE TABLE [dbo].[vDDDT]
(
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InputType] [tinyint] NOT NULL,
[InputMask] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InputLength] [smallint] NULL,
[Prec] [tinyint] NULL,
[MasterTable] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MasterColumn] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MasterDescColumn] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[QualifierColumn] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Lookup] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SetupForm] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ReportLookup] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SQLDatatype] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ReportOnly] [dbo].[bYN] NOT NULL,
[TextID] [int] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vDDDT] ADD
CONSTRAINT [CK_vDDDT_ReportOnly] CHECK (([ReportOnly]='Y' OR [ReportOnly]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   trigger [dbo].[vtDDDTd] on [dbo].[vDDDT] for DELETE
/************************************
* Created: kb 1/10/5
* Modified: GG 02/05/07 - added validation
*
* Delete trigger on vDDDT (DD Datatype)
*
* Rejects deletion if any of the following conditions exist:
*	Datatype overrides exist 
*	Form inputs exist
*	Group data security entries exist
*	User data security entries exist
*	Lookup detail entries exist
*	Report parameters exist
*
* Adds DD Audit entry
*
************************************/
as

declare @errmsg varchar(255)
  
if @@rowcount = 0 return
set nocount on

--check for custom Datatype override
if exists(select top 1 1 from deleted d join dbo.vDDDTc c with (nolock) on c.Datatype = d.Datatype)
	begin
	select @errmsg = 'Custom Datatype overrides exist'
	goto error
	end

--check DD Form Inputs 
if exists(select top 1 1 from deleted d join dbo.DDFIShared i with (nolock) on i.Datatype = d.Datatype)
	begin
	select @errmsg = 'Form Input entries exist'
	goto error
	end

--check DD Data Security
if exists(select top 1 1 from deleted d join dbo.vDDDS s with (nolock) on s.Datatype = d.Datatype)
	begin
	select @errmsg = 'Group Data Security entries exist'
	goto error
	end
if exists(select top 1 1 from deleted d join dbo.vDDDU s with (nolock) on s.Datatype = d.Datatype)
	begin
	select @errmsg = 'User Data Security entries exist'
	goto error
	end

--check DD Lookup Detail 
if exists (select top 1 1 from deleted d join dbo.DDLDShared l with (nolock) on l.Datatype = d.Datatype)
	begin
	select @errmsg = 'Lookup Detail entries exist'
	goto error
	end
--check RP Parameters 
if exists (select top 1 1 from deleted d join dbo.RPRPShared l with (nolock) on l.Datatype = d.Datatype)
	begin
	select @errmsg = 'Report parameters are using datatype'
	goto error
	end

-- DD Audit 
insert dbo.vDDDA (TableName, Action, KeyString, FieldName,
	OldValue, NewValue, RevDate, UserName, HostName)
select 'vDDDT', 'D', 'Datatype: ' + rtrim(Datatype), null,
	null, null, getdate(), SUSER_SNAME(), host_name()
from deleted
  
return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Datatype!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDDTd_Audit] ON [dbo].[vDDDT]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(deleted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM vDDDT WHERE Datatype = ''' + CAST(deleted.Datatype AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDDTi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDDTd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   trigger [dbo].[vtDDDTi] on [dbo].[vDDDT] for INSERT
/*****************************
* Created: kb 1/10/5
* Modified: GG 10/17/06 - #30096 - validate Input Mask
*			GG 02/05/07 - #123484 - additional mask validation
*
* Insert trigger on vDDDT (DD Datatypes)
*
* Rejects insert if the following conditions exist:
*	Improperly formatted Input Mask
*
* Adds custom Datatype entry to vDDDTc
*
* Adds DD Audit entry
*
*************************************/

as

declare @errmsg varchar(255), @numrows int, @validcnt int
  
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate mask for muti-part datatypes
if exists(select top 1 1 from inserted 
			where InputType = 5 and CHARINDEX('N',InputMask)>0 and PATINDEX('%N[^1-9]%', InputMask)>0) 
	begin
	select @errmsg = 'Invalid Input Mask, ''N'' should not be followed by a nonnumeric character '
	goto error
	end 
-- #123484 - additional mask validation
if exists(select top 1 1 from inserted
			where InputType = 5 and substring(InputMask,len(InputMask),1) <> 'N')
	begin
	select @errmsg = 'Invalid Input Mask, ''N'' should be the last character '
	goto error
	end
if exists(select top 1 1 from inserted 
			where InputType = 5 and ((CHARINDEX('L',InputMask)>0 and PATINDEX('%L[0-9]%', InputMask)>0)
				or (CHARINDEX('R',InputMask)>0 and PATINDEX('%R[0-9]%', InputMask)>0)))
	begin
	select @errmsg = 'Invalid Input Mask, ''L'' or ''R'' must be followed by a nonnumeric character '
	goto error
	end

-- add custom Datatype entry to vDDDTc
insert dbo.vDDDTc(Datatype, InputMask, InputLength, Prec, Secure, DfltSecurityGroup, Label)
select Datatype, InputMask, InputLength, Prec, 'N', null, null
from inserted
where Datatype not in (select Datatype from dbo.vDDDTc)


-- DD Audit  
insert vDDDA (TableName, Action, KeyString, FieldName, OldValue, 
  	NewValue, RevDate, UserName, HostName)
select 'vDDDT', 'I', 'Datatype: ' + rtrim(Datatype), null, null,
	null, getdate(), SUSER_SNAME(), host_name()
from inserted 
  	 	 	 
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Datatype!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
    










GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDDTi_Audit] ON [dbo].[vDDDT]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[vDDDT] ([Datatype], [Description], [InputType], [InputMask], [InputLength], [Prec], [MasterTable], [MasterColumn], [MasterDescColumn], [QualifierColumn], [Lookup], [SetupForm], [ReportLookup], [SQLDatatype], [ReportOnly], [TextID]) VALUES (' + ISNULL('''' + REPLACE(CAST(Datatype AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(Description AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(InputType AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL('''' + REPLACE(CAST(InputMask AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(InputLength AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL(CAST(Prec AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL('''' + REPLACE(CAST(MasterTable AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(MasterColumn AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(MasterDescColumn AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(QualifierColumn AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(Lookup AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(SetupForm AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(ReportLookup AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(SQLDatatype AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(ReportOnly AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(TextID AS NVARCHAR(MAX)), 'NULL') + + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDDTi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDDTi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE   trigger [dbo].[vtDDDTu] on [dbo].[vDDDT] for UPDATE
/************************************
* Created: kb 1/10/5
* Modified: GG 10/17/06 - #30096 - validate Input Mask
*			GG 02/05/07 - #123484 - additional mask validation
*
* Update trigger on vDDDT (DD Datatype)
*
* Adds DD Audit entries for changed values
*
************************************/

as


declare @errmsg varchar(255), @numrows int, @validcnt int 
  
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
  
-- check for key changes 
select @validcnt = count(*) from inserted i join deleted d	on i.Datatype = d.Datatype
if @validcnt <> @numrows
	begin
  	select @errmsg = 'Cannot change Datatype'
  	goto error
  	end

-- validate mask for muti-part datatypes
if update(InputType) or update(InputMask)
	begin
	if exists(select top 1 1 from inserted where InputType = 5 and CHARINDEX('N',InputMask)>0 and PATINDEX('%N[^1-9]%', InputMask)>0) 
		begin
		select @errmsg = 'Invalid Input Mask, ''N'' should not be followed by a nonnumeric character '
		goto error
		end 
	-- #123484 - additional mask validation
	if exists(select top 1 1 from inserted
			where InputType = 5 and substring(InputMask,len(InputMask),1) <> 'N')
		begin
		select @errmsg = 'Invalid Input Mask, ''N'' should be the last character '
		goto error
		end
	if exists(select top 1 1 from inserted 
			where InputType = 5 and ((CHARINDEX('L',InputMask)>0 and PATINDEX('%L[0-9]%', InputMask)>0)
				or (CHARINDEX('R',InputMask)>0 and PATINDEX('%R[0-9]%', InputMask)>0)))
		begin
		select @errmsg = 'Invalid Input Mask, ''L'' or ''R'' must be followed by a nonnumeric character '
		goto error
		end
	end
  	
-- DD Audit
if update(Description)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'Description',
		d.Description, i.Description, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.Description,'') <> isnull(d.Description,'')

if update(InputType)
	insert vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select 'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'InputType',
		d.InputType, i.InputType, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype
  	where isnull(i.InputType,'') <> isnull(d.InputType,'')

if update(InputMask)
	insert vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select 'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'InputMask',
		d.InputMask, i.InputMask, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype
  	where isnull(i.InputMask,'') <> isnull(d.InputMask,'')

if update(InputLength)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'InputLength',
		d.InputLength, i.InputLength, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.InputLength,'') <> isnull(d.InputLength,'')

if update(Prec)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'Prec',
		d.Prec, i.Prec, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.Prec,'') <> isnull(d.Prec,'')

if update(MasterTable)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'MasterTable',
		d.MasterTable, i.MasterTable, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.MasterTable,'') <> isnull(d.MasterTable,'')

if update(MasterColumn)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'MasterColumn',
		d.MasterColumn, i.MasterColumn, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.MasterColumn,'') <> isnull(d.MasterColumn,'')

if update(MasterDescColumn)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'MasterDescColumn',
		d.MasterDescColumn, i.MasterDescColumn, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.MasterDescColumn,'') <> isnull(d.MasterDescColumn,'')

if update(QualifierColumn)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'QualifierColumn',
		d.QualifierColumn, i.QualifierColumn, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.QualifierColumn,'') <> isnull(d.QualifierColumn,'')

if update(Lookup)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'Lookup',
		d.Lookup, i.Lookup, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.Lookup,'') <> isnull(d.Lookup,'')

if update(SetupForm)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'SetupForm',
		d.SetupForm, i.SetupForm, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.SetupForm,'') <> isnull(d.SetupForm,'')

if update(ReportLookup)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'ReportLookup',
		d.ReportLookup, i.ReportLookup, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.ReportLookup,'') <> isnull(d.ReportLookup,'')

if update(SQLDatatype)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'SQLDatatype',
		d.SQLDatatype, i.SQLDatatype, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.SQLDatatype,'') <> isnull(d.SQLDatatype,'')

if update(ReportOnly)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDT', 'U', 'Datatype: ' + rtrim(i.Datatype), 'ReportOnly',
		d.ReportOnly, i.ReportOnly, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.ReportOnly,'') <> isnull(d.ReportOnly,'')



return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update Datatype!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
 









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDDTu_Audit] ON [dbo].[vDDDT]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([Datatype])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Datatype' ,  CONVERT(VARCHAR(MAX), deleted.[Datatype]) ,  Convert(VARCHAR(MAX), inserted.[Datatype]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET Datatype = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Datatype]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[Datatype],'') <> ISNULL(deleted.[Datatype],'')

 IF UPDATE([Description])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Description' ,  CONVERT(VARCHAR(MAX), deleted.[Description]) ,  Convert(VARCHAR(MAX), inserted.[Description]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET Description = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Description]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[Description],'') <> ISNULL(deleted.[Description],'')

 IF UPDATE([InputType])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'InputType' ,  CONVERT(VARCHAR(MAX), deleted.[InputType]) ,  Convert(VARCHAR(MAX), inserted.[InputType]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET InputType = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[InputType]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[InputType],'') <> ISNULL(deleted.[InputType],'')

 IF UPDATE([InputMask])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'InputMask' ,  CONVERT(VARCHAR(MAX), deleted.[InputMask]) ,  Convert(VARCHAR(MAX), inserted.[InputMask]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET InputMask = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[InputMask]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[InputMask],'') <> ISNULL(deleted.[InputMask],'')

 IF UPDATE([InputLength])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'InputLength' ,  CONVERT(VARCHAR(MAX), deleted.[InputLength]) ,  Convert(VARCHAR(MAX), inserted.[InputLength]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET InputLength = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[InputLength]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[InputLength],'') <> ISNULL(deleted.[InputLength],'')

 IF UPDATE([Prec])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Prec' ,  CONVERT(VARCHAR(MAX), deleted.[Prec]) ,  Convert(VARCHAR(MAX), inserted.[Prec]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET Prec = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Prec]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[Prec],'') <> ISNULL(deleted.[Prec],'')

 IF UPDATE([MasterTable])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'MasterTable' ,  CONVERT(VARCHAR(MAX), deleted.[MasterTable]) ,  Convert(VARCHAR(MAX), inserted.[MasterTable]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET MasterTable = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[MasterTable]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[MasterTable],'') <> ISNULL(deleted.[MasterTable],'')

 IF UPDATE([MasterColumn])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'MasterColumn' ,  CONVERT(VARCHAR(MAX), deleted.[MasterColumn]) ,  Convert(VARCHAR(MAX), inserted.[MasterColumn]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET MasterColumn = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[MasterColumn]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[MasterColumn],'') <> ISNULL(deleted.[MasterColumn],'')

 IF UPDATE([MasterDescColumn])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'MasterDescColumn' ,  CONVERT(VARCHAR(MAX), deleted.[MasterDescColumn]) ,  Convert(VARCHAR(MAX), inserted.[MasterDescColumn]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET MasterDescColumn = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[MasterDescColumn]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[MasterDescColumn],'') <> ISNULL(deleted.[MasterDescColumn],'')

 IF UPDATE([QualifierColumn])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'QualifierColumn' ,  CONVERT(VARCHAR(MAX), deleted.[QualifierColumn]) ,  Convert(VARCHAR(MAX), inserted.[QualifierColumn]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET QualifierColumn = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[QualifierColumn]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[QualifierColumn],'') <> ISNULL(deleted.[QualifierColumn],'')

 IF UPDATE([Lookup])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Lookup' ,  CONVERT(VARCHAR(MAX), deleted.[Lookup]) ,  Convert(VARCHAR(MAX), inserted.[Lookup]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET Lookup = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Lookup]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[Lookup],'') <> ISNULL(deleted.[Lookup],'')

 IF UPDATE([SetupForm])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'SetupForm' ,  CONVERT(VARCHAR(MAX), deleted.[SetupForm]) ,  Convert(VARCHAR(MAX), inserted.[SetupForm]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET SetupForm = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[SetupForm]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[SetupForm],'') <> ISNULL(deleted.[SetupForm],'')

 IF UPDATE([ReportLookup])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'ReportLookup' ,  CONVERT(VARCHAR(MAX), deleted.[ReportLookup]) ,  Convert(VARCHAR(MAX), inserted.[ReportLookup]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET ReportLookup = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[ReportLookup]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[ReportLookup],'') <> ISNULL(deleted.[ReportLookup],'')

 IF UPDATE([SQLDatatype])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'SQLDatatype' ,  CONVERT(VARCHAR(MAX), deleted.[SQLDatatype]) ,  Convert(VARCHAR(MAX), inserted.[SQLDatatype]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET SQLDatatype = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[SQLDatatype]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[SQLDatatype],'') <> ISNULL(deleted.[SQLDatatype],'')

 IF UPDATE([ReportOnly])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'ReportOnly' ,  CONVERT(VARCHAR(MAX), deleted.[ReportOnly]) ,  Convert(VARCHAR(MAX), inserted.[ReportOnly]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET ReportOnly = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[ReportOnly]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[ReportOnly],'') <> ISNULL(deleted.[ReportOnly],'')

 IF UPDATE([TextID])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDDT' , '<KeyString Datatype = "' + REPLACE(CAST(inserted.Datatype AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'TextID' ,  CONVERT(VARCHAR(MAX), deleted.[TextID]) ,  Convert(VARCHAR(MAX), inserted.[TextID]) , GETDATE() , HOST_NAME() , 'UPDATE vDDDT SET TextID = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[TextID]), '''' , ''''''), 'NULL') + ''' WHERE Datatype = ''' + CAST(inserted.Datatype AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Datatype] = deleted.[Datatype] 
         AND ISNULL(inserted.[TextID],'') <> ISNULL(deleted.[TextID],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDDTi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDDTu_Audit]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [viDDDT] ON [dbo].[vDDDT] ([Datatype]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [viDDDTLookup] ON [dbo].[vDDDT] ([Datatype], [Lookup]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDDT].[ReportOnly]'
GO
