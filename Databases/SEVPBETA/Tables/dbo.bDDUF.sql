CREATE TABLE [dbo].[bDDUF]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[BatchYN] [dbo].[bYN] NOT NULL,
[DestTable] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BatchSource] [dbo].[bSource] NULL,
[UploadRoutine] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BidtekRoutine] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[ImportRoutine] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE   trigger [dbo].[btDDUFd] ON [dbo].[bDDUF] for DELETE as
    

declare @errmsg varchar(255), @validcnt int
    /*-----------------------------------------------------------------
     *	This trigger deletes all associated records for this importform
     * Created By: GR 9/21/99
     *  Modified - DANF 12/04/2003 - 23061 Added isnull check, with (nolock) and dbo.
     *----------------------------------------------------------------*/
    declare  @errno   int, @numrows int
    SELECT @numrows = @@rowcount
    IF @numrows = 0 return
    set nocount on
    begin


     /* check for Template information in IM */
     if exists (select * from deleted d join bIMTH on bIMTH.Form = d.Form)
     	begin
     	select @errmsg = 'This Import Form is currently being used in IM. The template will need to be delete in IM before it can be deleted in DD.'
     	goto error
     	end

   
    /*---------------------------------------------------------*/
    /* Delete  Form Detail                  */
    /*---------------------------------------------------------*/
    delete dbo.bDDUD from dbo.bDDUD with (nolock) join deleted d on bDDUD.Form = d.Form
   
    return
    error:
        SELECT @errmsg = isnull(@errmsg,'') + ' - cannot delete ImportForm!'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
    end
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDUFd_Audit] ON [dbo].[bDDUF]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUF' , '<KeyString Form = "' + REPLACE(CAST(deleted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM bDDUF WHERE Form = ''' + CAST(deleted.Form AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDUFi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDUFd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDUFi_Audit] ON [dbo].[bDDUF]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUF' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[bDDUF] ([Form], [Description], [BatchYN], [DestTable], [BatchSource], [UploadRoutine], [BidtekRoutine], [ImportRoutine]) VALUES (' + ISNULL('''' + REPLACE(CAST(Form AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(Description AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(BatchYN AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(DestTable AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(BatchSource AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(UploadRoutine AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(BidtekRoutine AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(ImportRoutine AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL')  + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDUFi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDUFi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtDDUFu_Audit] ON [dbo].[bDDUF]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([Form])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUF' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Form' ,  CONVERT(VARCHAR(MAX), deleted.[Form]) ,  Convert(VARCHAR(MAX), inserted.[Form]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUF SET Form = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Form]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[Form],'') <> ISNULL(deleted.[Form],'')

 IF UPDATE([Description])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUF' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Description' ,  CONVERT(VARCHAR(MAX), deleted.[Description]) ,  Convert(VARCHAR(MAX), inserted.[Description]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUF SET Description = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Description]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[Description],'') <> ISNULL(deleted.[Description],'')

 IF UPDATE([BatchYN])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUF' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'BatchYN' ,  CONVERT(VARCHAR(MAX), deleted.[BatchYN]) ,  Convert(VARCHAR(MAX), inserted.[BatchYN]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUF SET BatchYN = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[BatchYN]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[BatchYN],'') <> ISNULL(deleted.[BatchYN],'')

 IF UPDATE([DestTable])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUF' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'DestTable' ,  CONVERT(VARCHAR(MAX), deleted.[DestTable]) ,  Convert(VARCHAR(MAX), inserted.[DestTable]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUF SET DestTable = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[DestTable]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[DestTable],'') <> ISNULL(deleted.[DestTable],'')

 IF UPDATE([BatchSource])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUF' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'BatchSource' ,  CONVERT(VARCHAR(MAX), deleted.[BatchSource]) ,  Convert(VARCHAR(MAX), inserted.[BatchSource]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUF SET BatchSource = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[BatchSource]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[BatchSource],'') <> ISNULL(deleted.[BatchSource],'')

 IF UPDATE([UploadRoutine])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUF' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'UploadRoutine' ,  CONVERT(VARCHAR(MAX), deleted.[UploadRoutine]) ,  Convert(VARCHAR(MAX), inserted.[UploadRoutine]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUF SET UploadRoutine = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[UploadRoutine]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[UploadRoutine],'') <> ISNULL(deleted.[UploadRoutine],'')

 IF UPDATE([BidtekRoutine])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUF' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'BidtekRoutine' ,  CONVERT(VARCHAR(MAX), deleted.[BidtekRoutine]) ,  Convert(VARCHAR(MAX), inserted.[BidtekRoutine]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUF SET BidtekRoutine = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[BidtekRoutine]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[BidtekRoutine],'') <> ISNULL(deleted.[BidtekRoutine],'')

 IF UPDATE([ImportRoutine])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUF' , '<KeyString Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'ImportRoutine' ,  CONVERT(VARCHAR(MAX), deleted.[ImportRoutine]) ,  Convert(VARCHAR(MAX), inserted.[ImportRoutine]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUF SET ImportRoutine = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[ImportRoutine]), '''' , ''''''), 'NULL') + ''' WHERE Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[ImportRoutine],'') <> ISNULL(deleted.[ImportRoutine],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDUFi_Audit] trigger', 16, 1 ) with log
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtDDUFu_Audit]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biDDUF] ON [dbo].[bDDUF] ([Form]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bDDUF].[BatchYN]'
GO
