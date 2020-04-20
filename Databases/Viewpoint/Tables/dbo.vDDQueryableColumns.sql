CREATE TABLE [dbo].[vDDQueryableColumns]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[QueryColumnName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InputType] [tinyint] NULL,
[InputMask] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InputLength] [smallint] NULL,
[Prec] [tinyint] NULL,
[ControlType] [tinyint] NOT NULL,
[ComboType] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ShowInQueryFilter] [dbo].[bYN] NOT NULL,
[ShowInQueryResultSet] [dbo].[bYN] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[vDDQueryableColumns] ADD 
CONSTRAINT [PK_vDDQueryableColumns] PRIMARY KEY CLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [IX_vDDQueryableColumns] ON [dbo].[vDDQueryableColumns] ([Form], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create trigger [dbo].[vtDDQueryableColumnsd] on [dbo].[vDDQueryableColumns] for DELETE
/************************************
* Created: JonathanP 08/14/2008
* Modified: 
*
* Delete trigger on vDDQueryableColumns
*
* Rejects deletion if any of the following conditions exist:
*	Custom Form Inputs exist
*	User Form Inputs exist
*	Form Lookups exist
*
* Adds DD Audit entry
*
************************************/
as

declare @errorMessage varchar(255)
  
if @@rowcount = 0 return
set nocount on

  	
-- DD Audit 
insert dbo.vDDDA (TableName, Action, KeyString, FieldName,
	OldValue, NewValue, RevDate, UserName, HostName)
select 'vDDQueryableColumns', 'D', 'Form: ' + rtrim(Form) + ' Seq: ' + convert(varchar,Seq), null,
	null, null, getdate(), SUSER_SNAME(), host_name()
from deleted
  
return
  
error:
	select @errorMessage = isnull(@errorMessage,'') + ' - cannot delete DD Queryable Column!'
    RAISERROR(@errorMessage, 11, -1)
    rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDQueryableColumnsd_Audit] ON [dbo].[vDDQueryableColumns]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(deleted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(deleted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM vDDQueryableColumns WHERE Form = ''' + CAST(deleted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(deleted.Seq AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDQueryableColumnsi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDQueryableColumnsd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     trigger [dbo].[vtDDQueryableColumnsi] on [dbo].[vDDQueryableColumns] for INSERT
/*****************************
* Created: JonathanP 08/12/2008 - adapted from vtDDFIi
*
*
* Description: Insert trigger on vDDQueryableColumns. Makes sure the entries are valid and 
*              Adds DD Audit entry
*
*************************************/

as
declare @errorMessage varchar(255), @numberOfRows int, @validCount int, @nullCount int
  
select @numberOfRows = @@rowcount
if @numberOfRows = 0 return

set nocount on

-- validate Form
select @validCount = count(*) 
	from inserted i
	join dbo.DDQueryableViewsShared q with (nolock) on i.Form = q.Form

if @validCount <> @numberOfRows
  	begin
  	select @errorMessage = 'Invalid Form - must exist in DDQueryableViewsShared'
  	goto error
  	end
  	
-- Validate Datatype.
select @nullCount = count(*) from inserted where Datatype is null
select @validCount = count(*) 
	from inserted i
	join dbo.vDDDT d with (nolock) on i.Datatype = d.Datatype
	where d.ReportOnly = 'N'

if @validCount + @nullCount <> @numberOfRows
	begin
  		select @errorMessage = 'Invalid Datatype - must exist in vDDDT and not flagged as "Report Only"'
  		goto error
  	end
  	
if exists(select top 1 1 from inserted where Datatype is null and InputType is null)
	begin
		select @errorMessage = 'Must specify either a Datatype or Input Type'
		goto error
	end
	
if exists(select top 1 1 from inserted where Datatype is not null and 
	(InputType is not null or InputMask is not null or InputLength is not null or Prec is not null))	
	begin
  		select @errorMessage = 'Input Type, Mask, Length, and Precision must all be null when Datatype is specified'
  		goto error
  	end
  	
-- validate Input Type
if exists(select top 1 1 from inserted where InputType > 6)
	begin
		select @errorMessage = 'Invalid Input Type - must be 0 through 6'
		goto error
	end
	
-- validate Control Type
if exists(select top 1 1 from inserted where ControlType > 18 and ControlType <> 99)
	begin
		select @errorMessage = 'Invalid Control Type - must be 0 through 18 or 99.'
		goto error
	end	

-- validate Combo Type
select @nullCount = count(*) 
	from inserted 
	where ComboType is null

select @validCount = count(*)
	from inserted i
	join dbo.vDDCB c with (nolock) on i.ComboType = c.ComboType

if @validCount + @nullCount <> @numberOfRows
	begin
  		select @errorMessage = 'Invalid ComboBox Type - must exist in vDDCB'
  		goto error
  	end
  
-- DD Audit  
insert vDDDA (TableName, Action, KeyString, FieldName, OldValue, 
  	NewValue, RevDate, UserName, HostName)
	select 'vDDQueryableColumns', 'I', 'Form: ' + rtrim(Form) + ' Seq: ' + convert(varchar,Seq), null, null,
		null, getdate(), SUSER_SNAME(), host_name()
	from inserted   	 	 	 
return

error:
	select @errorMessage = isnull(@errorMessage,'') + ' - cannot insert DD Queryable Column!'
  	RAISERROR(@errorMessage, 11, -1);
  	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDQueryableColumnsi_Audit] ON [dbo].[vDDQueryableColumns]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[vDDQueryableColumns] ([Form], [Seq], [QueryColumnName], [Datatype], [InputType], [InputMask], [InputLength], [Prec], [ControlType], [ComboType], [ShowInQueryFilter], [ShowInQueryResultSet]) VALUES (' + ISNULL('''' + REPLACE(CAST(Form AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(Seq AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL('''' + REPLACE(CAST(QueryColumnName AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(Datatype AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(InputType AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL('''' + REPLACE(CAST(InputMask AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(InputLength AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL(CAST(Prec AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL(CAST(ControlType AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL('''' + REPLACE(CAST(ComboType AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(ShowInQueryFilter AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(ShowInQueryResultSet AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL')  + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDQueryableColumnsi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDQueryableColumnsi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[vtDDQueryableColumnsu] on [dbo].[vDDQueryableColumns] for UPDATE
/************************************
* Created: JonathanP 08/12/2008 - Adapted from vtDDFIu
* Modified: 
*
* Update trigger on vDDQueryableColumns
*
* Rejects updates based on various conditions and adds DD Audit entries for changed values
*
************************************/

as
declare @errorMessage varchar(255), @numberOfRows int, @validCount int, @nullCount int 
  
select @numberOfRows = @@rowcount
if @numberOfRows = 0 return
set nocount on
  
-- check for key changes 
if update(Form) or update(Seq)
	begin
	select @validCount = count(*)
		from inserted i
		join deleted d	on i.Form = d.Form and i.Seq = d.Seq
		
	if @validCount <> @numberOfRows
		begin
  		select @errorMessage = 'Cannot change Form or Sequence #'
  		goto error
  		end
	end
	
-- validate Datatype
if update(Datatype)
	begin
	
	select @nullCount = count(*) 
		from inserted 
		where Datatype is null
	
	select @validCount = count(*)
		from inserted i
		join dbo.vDDDT d with (nolock) on i.Datatype = d.Datatype
		where d.ReportOnly = 'N'
		
	if @validCount + @nullCount <> @numberOfRows
		begin
  		select @errorMessage = 'Invalid Datatype - must exist in vDDDT and not flagged as "Report Only"'
  		goto error
  		end
	end
	
if update(Datatype) or update(InputType) or update(InputMask) or update(InputLength) or update(Prec)
	begin
	if exists(select top 1 1 from inserted where Datatype is null and InputType is null)
		begin
		select @errorMessage = 'Must specify either a Datatype or Input Type'
		goto error
		end
	if exists(select top 1 1 from inserted where Datatype is not null and 
		(InputType is not null or InputMask is not null or InputLength is not null or Prec is not null))
		begin
  		select @errorMessage = 'Input Type, Mask, Length, and Precision must all be null when Datatype is specified'
  		goto error
  		end
	end
	
-- validate Input Type
if update(InputType)
	begin
	if exists(select top 1 1 from inserted where InputType > 6)
		begin
		select @errorMessage = 'Invalid Input Type - must be "0" through "6"'
		goto error
		end
	end
	
-- validate Input Length
if update(InputLength)
	begin
	if exists(select top 1 1 from inserted where InputLength < 0)
		begin
		select @errorMessage = 'Invalid Input Length - cannot be less than "0"'
		goto error
		end
	end
	
-- validate Precision
if update(Prec)
	begin
	if exists(select top 1 1 from inserted where Prec > 3)
		begin
		select @errorMessage = 'Invalid Precision - must be "0" through "3"'
		goto error
		end
	end
	
if update(InputType) or update(Prec)
	begin
	if exists(select top 1 1 from inserted
			      where((InputType = 1 and Prec is null) or 
					    (InputType <> 1 and Prec is not null)))
		begin
		select @errorMessage = 'Invalid Input Type and Precision - Precision only allowed with numeric inputs'
		goto error
		end
	end
	
-- validate Control Type
if update(ControlType)
	begin
	if exists(select top 1 1 from inserted where ControlType > 18 and ControlType <> 99)
		begin
		select @errorMessage = 'Invalid Control Type - must be 0 through 18, or 99.'
		goto error
		end
	end

-- validate Combo Type
if update(ComboType)
	begin
	
	select @nullCount = count(*) 
		from inserted 
		where ComboType is null
	
	select @validCount = count(*)
		from inserted i
		join dbo.vDDCB c with (nolock) on i.ComboType = c.ComboType
		
	if @validCount + @nullCount <> @numberOfRows
		begin
  		select @errorMessage = 'Invalid ComboBox Type - must exist in vDDCB'
  	 	goto error
  	 	end
	end        
  
-- DD Audit
if update(QueryColumnName)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDQueryableColumns', 'U', 'Form: ' + rtrim(i.Form) + ' Seq: ' + convert(varchar,i.Seq), 'QueryColumnName',
		d.QueryColumnName, i.QueryColumnName, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form and i.Seq = d.Seq
  	where isnull(i.QueryColumnName,'') <> isnull(d.QueryColumnName,'')  	
  	
if update(ShowInQueryFilter)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDQueryableColumns', 'U', 'Form: ' + rtrim(i.Form) + ' Seq: ' + convert(varchar,i.Seq), 'ShowInQueryFilter',
		d.ShowInQueryFilter, i.ShowInQueryFilter, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form and i.Seq = d.Seq
  	where isnull(i.ShowInQueryFilter,'') <> isnull(d.ShowInQueryFilter,'')  	
  	
if update(ShowInQueryResultSet)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDQueryableColumns', 'U', 'Form: ' + rtrim(i.Form) + ' Seq: ' + convert(varchar,i.Seq), 'ShowInQueryResultSet',
		d.ShowInQueryResultSet, i.ShowInQueryResultSet, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form and i.Seq = d.Seq
  	where isnull(i.ShowInQueryResultSet,'') <> isnull(d.ShowInQueryResultSet,'')  	
  	
if update(Datatype)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDQueryableColumns', 'U', 'Form: ' + rtrim(i.Form) + ' Seq: ' + convert(varchar,i.Seq), 'Datatype',
		d.Datatype, i.Datatype, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form and i.Seq = d.Seq
  	where isnull(i.Datatype,'') <> isnull(d.Datatype,'')
  	
if update(InputType)
	 insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDQueryableColumns', 'U', 'Form: ' + rtrim(i.Form) + ' Seq: ' + convert(varchar,i.Seq), 'InputType',
		convert(varchar(3),d.InputType), convert(varchar(3),i.InputType), 
  		getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form and i.Seq = d.Seq
  	where isnull(i.InputType,255) <> isnull(d.InputType,255)
  	
if update(InputMask)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDQueryableColumns', 'U', 'Form: ' + rtrim(i.Form) + ' Seq: ' + convert(varchar,i.Seq), 'InputMask',
		d.Datatype, i.Datatype, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form and i.Seq = d.Seq
  	where isnull(i.InputMask,'') <> isnull(d.InputMask,'')
  	
if update(InputLength)
	 insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDQueryableColumns', 'U', 'Form: ' + rtrim(i.Form) + ' Seq: ' + convert(varchar,i.Seq), 'InputLength',
		convert(varchar(3),d.InputLength), convert(varchar(3),i.InputLength), 
  		getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form and i.Seq = d.Seq
  	where isnull(i.InputLength,-1) <> isnull(d.InputLength,-1)
  	
if update(Prec)
	 insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDQueryableColumns', 'U', 'Form: ' + rtrim(i.Form) + ' Seq: ' + convert(varchar,i.Seq), 'Prec',
		convert(varchar(3),d.Prec), convert(varchar(3),i.Prec), 
  		getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form and i.Seq = d.Seq
  	where isnull(i.Prec,255) <> isnull(d.Prec,255)

if update(ControlType)
	 insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDQueryableColumns', 'U', 'Form: ' + rtrim(i.Form) + ' Seq: ' + convert(varchar,i.Seq), 'ControlType',
		convert(varchar(3),d.ControlType), convert(varchar(3),i.ControlType), 
  		getdate(), SUSER_SNAME(), host_name()
  	from inserted i
 	join deleted d on i.Form = d.Form and i.Seq = d.Seq
  	where isnull(i.ControlType,255) <> isnull(d.ControlType,255)

if update(ComboType)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDQueryableColumns', 'U', 'Form: ' + rtrim(i.Form) + ' Seq: ' + convert(varchar,i.Seq), 'ComboType',
		d.ComboType, i.ComboType, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form and i.Seq = d.Seq
  	where isnull(i.ComboType,'') <> isnull(d.ComboType,'')

return
  
error:
	select @errorMessage = isnull(@errorMessage,'') + ' - cannot update DD Queryable Columns!'
    RAISERROR(@errorMessage, 11, -1);
    rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDQueryableColumnsu_Audit] ON [dbo].[vDDQueryableColumns]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([Form])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Form' ,  CONVERT(VARCHAR(MAX), deleted.[Form]) ,  Convert(VARCHAR(MAX), inserted.[Form]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableColumns SET Form = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Form]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[Form],'') <> ISNULL(deleted.[Form],'')

 IF UPDATE([Seq])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Seq' ,  CONVERT(VARCHAR(MAX), deleted.[Seq]) ,  Convert(VARCHAR(MAX), inserted.[Seq]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableColumns SET Seq = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Seq]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[Seq],'') <> ISNULL(deleted.[Seq],'')

 IF UPDATE([QueryColumnName])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'QueryColumnName' ,  CONVERT(VARCHAR(MAX), deleted.[QueryColumnName]) ,  Convert(VARCHAR(MAX), inserted.[QueryColumnName]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableColumns SET QueryColumnName = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[QueryColumnName]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[QueryColumnName],'') <> ISNULL(deleted.[QueryColumnName],'')

 IF UPDATE([Datatype])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Datatype' ,  CONVERT(VARCHAR(MAX), deleted.[Datatype]) ,  Convert(VARCHAR(MAX), inserted.[Datatype]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableColumns SET Datatype = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Datatype]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[Datatype],'') <> ISNULL(deleted.[Datatype],'')

 IF UPDATE([InputType])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'InputType' ,  CONVERT(VARCHAR(MAX), deleted.[InputType]) ,  Convert(VARCHAR(MAX), inserted.[InputType]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableColumns SET InputType = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[InputType]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[InputType],'') <> ISNULL(deleted.[InputType],'')

 IF UPDATE([InputMask])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'InputMask' ,  CONVERT(VARCHAR(MAX), deleted.[InputMask]) ,  Convert(VARCHAR(MAX), inserted.[InputMask]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableColumns SET InputMask = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[InputMask]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[InputMask],'') <> ISNULL(deleted.[InputMask],'')

 IF UPDATE([InputLength])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'InputLength' ,  CONVERT(VARCHAR(MAX), deleted.[InputLength]) ,  Convert(VARCHAR(MAX), inserted.[InputLength]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableColumns SET InputLength = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[InputLength]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[InputLength],'') <> ISNULL(deleted.[InputLength],'')

 IF UPDATE([Prec])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Prec' ,  CONVERT(VARCHAR(MAX), deleted.[Prec]) ,  Convert(VARCHAR(MAX), inserted.[Prec]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableColumns SET Prec = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Prec]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[Prec],'') <> ISNULL(deleted.[Prec],'')

 IF UPDATE([ControlType])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'ControlType' ,  CONVERT(VARCHAR(MAX), deleted.[ControlType]) ,  Convert(VARCHAR(MAX), inserted.[ControlType]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableColumns SET ControlType = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[ControlType]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[ControlType],'') <> ISNULL(deleted.[ControlType],'')

 IF UPDATE([ComboType])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'ComboType' ,  CONVERT(VARCHAR(MAX), deleted.[ComboType]) ,  Convert(VARCHAR(MAX), inserted.[ComboType]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableColumns SET ComboType = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[ComboType]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[ComboType],'') <> ISNULL(deleted.[ComboType],'')

 IF UPDATE([ShowInQueryFilter])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'ShowInQueryFilter' ,  CONVERT(VARCHAR(MAX), deleted.[ShowInQueryFilter]) ,  Convert(VARCHAR(MAX), inserted.[ShowInQueryFilter]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableColumns SET ShowInQueryFilter = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[ShowInQueryFilter]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[ShowInQueryFilter],'') <> ISNULL(deleted.[ShowInQueryFilter],'')

 IF UPDATE([ShowInQueryResultSet])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDQueryableColumns' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'ShowInQueryResultSet' ,  CONVERT(VARCHAR(MAX), deleted.[ShowInQueryResultSet]) ,  Convert(VARCHAR(MAX), inserted.[ShowInQueryResultSet]) , GETDATE() , HOST_NAME() , 'UPDATE vDDQueryableColumns SET ShowInQueryResultSet = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[ShowInQueryResultSet]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[ShowInQueryResultSet],'') <> ISNULL(deleted.[ShowInQueryResultSet],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDQueryableColumnsi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDQueryableColumnsu_Audit]', 'last', 'update', null
GO
