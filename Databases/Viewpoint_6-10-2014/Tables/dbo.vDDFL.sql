CREATE TABLE [dbo].[vDDFL]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[Lookup] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[LookupParams] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[LoadSeq] [tinyint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE trigger [dbo].[vtDDFLd] on [dbo].[vDDFL] for DELETE
/************************************
* Created: GG 03/10/06
* Modified: 
*
* Delete trigger on vDDFL (DD Form Lookups)
*
* Rejects deletion if any of the following conditions exist:
*	Lookup overrides exist in vDDFLc
*
* Adds DD Audit entry
*
************************************/
as



declare @errmsg varchar(255)
  
if @@rowcount = 0 return
set nocount on

-- check DD Custom Form Lookups 
if exists (select top 1 1 from deleted d join dbo.vDDFLc i with (nolock)
					on i.Form = d.Form and i.Seq = d.Seq and i.Lookup = d.Lookup)
	begin
 	select @errmsg = 'Custom Form Lookup entries exist in vDDFLc'
 	goto error
 	end
  	
-- DD Audit 
insert dbo.vDDDA (TableName, Action, KeyString, FieldName,
	OldValue, NewValue, RevDate, UserName, HostName)
select 'vDDFL', 'D', 'Form: ' + rtrim(Form) + ' Seq: ' + convert(varchar,Seq) + ' Lookup: ' + Lookup,
	null, null, null, getdate(), SUSER_SNAME(), host_name()
from deleted
  
return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Form Lookup!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDFLd_Audit] ON [dbo].[vDDFL]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDFL' , '<KeyString Lookup = "' + REPLACE(CAST(deleted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(deleted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(deleted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM vDDFL WHERE Lookup = ''' + CAST(deleted.Lookup AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(deleted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(deleted.Seq AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDFLi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDFLd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE trigger [dbo].[vtDDFLi] on [dbo].[vDDFL] for INSERT
/*****************************
* Created: GG 03/10/06
* Modified: 
*
* Insert trigger on vDDFL (DD Form Lookups)
*
* Rejects insert if the following conditions exist:
*	Invalid Form/Seq 
*	Invalid Lookup
*
* Adds DD Audit entry
*
*************************************/

as


declare @errmsg varchar(255), @numrows int, @validcnt int
  
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate Form/Seq
select @validcnt = count(*)
from inserted i
join dbo.vDDFI f with (nolock) on i.Form = f.Form and i.Seq = f.Seq
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Form and Seq# - must exist in vDDFI'
  	goto error
  	end
-- validate Lookup
select @validcnt = count(*)
from inserted i
join dbo.vDDLH h with (nolock) on i.Lookup = h.Lookup
if @validcnt <> @numrows
	begin
  	select @errmsg = 'Invalid Lookup - must exist in vDDLH'
  	goto error
  	end
--check for Datatype Lookup
if exists(select top 1 1 from inserted i
			join dbo.vDDFI f (nolock) on f.Form = i.Form and f.Seq = i.Seq
			join dbo.vDDDT d (nolock) on f.Datatype = d.Datatype
			where i.Lookup = d.Lookup)
	begin
	select @errmsg = 'Invalid Lookup - already assigned as a Datatype Lookup'
	goto error
	end 

  
-- DD Audit  
insert vDDDA (TableName, Action, KeyString, FieldName, OldValue, 
  	NewValue, RevDate, UserName, HostName)
select 'vDDFL', 'I', 'Form: ' + rtrim(Form) + ' Seq: ' + convert(varchar,Seq) + ' Lookup: ' + Lookup,
	null, null,	null, getdate(), SUSER_SNAME(), host_name()
from inserted 
  	 	 	 
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Form Lookup!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
    




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDFLi_Audit] ON [dbo].[vDDFL]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDFL' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[vDDFL] ([Form], [Seq], [Lookup], [LookupParams], [LoadSeq]) VALUES (' + ISNULL('''' + REPLACE(CAST(Form AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(Seq AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL('''' + REPLACE(CAST(Lookup AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(LookupParams AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(LoadSeq AS NVARCHAR(MAX)), 'NULL') + + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDFLi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDFLi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[vtDDFLu] on [dbo].[vDDFL] for UPDATE
/************************************
* Created: GG 03/10/06
* Modified: 
*
* Update trigger on vDDFL (DD Form Lookups)
*
* Rejects update if any of the following conditions exist:
*	Change primary key - Form/Seq/Lookup
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
if update(Form) or update(Seq) or update(Lookup)
	begin
	select @validcnt = count(*)
	from inserted i
	join deleted d	on i.Form = d.Form and i.Seq = d.Seq and i.Lookup = d.Lookup
	if @validcnt <> @numrows
		begin
  		select @errmsg = 'Cannot change Form, Sequence #, or Lookup'
  		goto error
  		end
	end
  
-- DD Audit
if update(LookupParams)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDFL', 'U', 'Form: ' + rtrim(i.Form) + ' Seq: ' + convert(varchar,i.Seq) + ' Lookup: ' + i.Lookup,
		'LookupParams', d.LookupParams, i.LookupParams, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form and i.Seq = d.Seq and i.Lookup = d.Lookup
  	where isnull(i.LookupParams,'') <> isnull(d.LookupParams,'')
if update(LoadSeq)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDFL', 'U', 'Form: ' + rtrim(i.Form) + ' Seq: ' + convert(varchar,i.Seq) + ' Lookup: ' + i.Lookup,
		'LoadSeq', d.LoadSeq, i.LoadSeq, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Form = d.Form and i.Seq = d.Seq and i.Lookup = d.Lookup
  	where isnull(i.LoadSeq,255) <> isnull(d.LoadSeq,255)

return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update Form Lookups!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  

  
 











GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDFLu_Audit] ON [dbo].[vDDFL]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([Form])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDFL' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Form' ,  CONVERT(VARCHAR(MAX), deleted.[Form]) ,  Convert(VARCHAR(MAX), inserted.[Form]) , GETDATE() , HOST_NAME() , 'UPDATE vDDFL SET Form = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Form]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup]  AND  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[Form],'') <> ISNULL(deleted.[Form],'')

 IF UPDATE([Seq])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDFL' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Seq' ,  CONVERT(VARCHAR(MAX), deleted.[Seq]) ,  Convert(VARCHAR(MAX), inserted.[Seq]) , GETDATE() , HOST_NAME() , 'UPDATE vDDFL SET Seq = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Seq]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup]  AND  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[Seq],'') <> ISNULL(deleted.[Seq],'')

 IF UPDATE([Lookup])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDFL' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Lookup' ,  CONVERT(VARCHAR(MAX), deleted.[Lookup]) ,  Convert(VARCHAR(MAX), inserted.[Lookup]) , GETDATE() , HOST_NAME() , 'UPDATE vDDFL SET Lookup = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Lookup]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup]  AND  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[Lookup],'') <> ISNULL(deleted.[Lookup],'')

 IF UPDATE([LookupParams])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDFL' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'LookupParams' ,  CONVERT(VARCHAR(MAX), deleted.[LookupParams]) ,  Convert(VARCHAR(MAX), inserted.[LookupParams]) , GETDATE() , HOST_NAME() , 'UPDATE vDDFL SET LookupParams = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[LookupParams]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup]  AND  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[LookupParams],'') <> ISNULL(deleted.[LookupParams],'')

 IF UPDATE([LoadSeq])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'vDDFL' , '<KeyString Lookup = "' + REPLACE(CAST(inserted.Lookup AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" Seq = "' + REPLACE(CAST(inserted.Seq AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'LoadSeq' ,  CONVERT(VARCHAR(MAX), deleted.[LoadSeq]) ,  Convert(VARCHAR(MAX), inserted.[LoadSeq]) , GETDATE() , HOST_NAME() , 'UPDATE vDDFL SET LoadSeq = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[LoadSeq]), '''' , ''''''), 'NULL') + ''' WHERE Lookup = ''' + CAST(inserted.Lookup AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + '''' + ' AND Seq = ''' + CAST(inserted.Seq AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Lookup] = deleted.[Lookup]  AND  inserted.[Form] = deleted.[Form]  AND  inserted.[Seq] = deleted.[Seq] 
         AND ISNULL(inserted.[LoadSeq],'') <> ISNULL(deleted.[LoadSeq],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDFLi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDFLu_Audit]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [viDDFL] ON [dbo].[vDDFL] ([Form], [Seq], [Lookup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
