CREATE TABLE [dbo].[bDDUD]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Identifier] [int] NOT NULL,
[TableName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Seq] [int] NULL,
[ColumnName] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bDesc] NULL,
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ColType] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BidtekDefaultValue] [dbo].[bYN] NULL,
[RequiredValue] [dbo].[bYN] NULL,
[UpdateKeyYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bDDUD_UpdateKeyYN] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE   trigger [dbo].[btDDUDd] ON [dbo].[bDDUD] for DELETE as
    

declare @errmsg varchar(255), @validcnt int
    /*-----------------------------------------------------------------
     *	This trigger deletes all associated records for this importform
     * Created By: DANF 01/11/2007
     *  Modified - 
     *----------------------------------------------------------------*/
    declare  @errno   int, @numrows int
    SELECT @numrows = @@rowcount
    IF @numrows = 0 return
    set nocount on
    begin


     /* check for Template information in IM */
     if exists (
		select top 1 1 from deleted d 
		join bIMTH h on d.Form = h.Form	
		join bIMTD t on h.ImportTemplate = t.ImportTemplate and d.Identifier = t.Identifier)
     	begin
     	select @errmsg = 'This Import Column is currently being used in IM. The column will need to be deleted in IM before it can be deleted from DDUD.'
     	goto error
     	end

select * from bIMTD
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

 
  
   
   
   /****** Object:  Trigger dbo.btDDUDi    ******/
   CREATE   trigger [dbo].[btDDUDi] on [dbo].[bDDUD] for INSERT as
   

declare @errmsg varchar(255), @nullcnt int, @numrows int, @validcnt int, @opencursor tinyint,
           @form varchar(30), @identifier int, @tablename varchar(30), @columnname varchar(30),
           @coltype varchar(30)
   
   /*-----------------------------------------------------------------
    * CREATED BY: DANF 06/01/00
    *  Modified - DANF 12/04/2003 - 23061 Added isnull check, with (nolock) and dbo.
    *			  DANF 03/13/07 - Issue 124038 Correct Data Type query
    *             EricV 08/29/11 - Modified not to use cursor, which was causing an error.
    *		      Andyw 9/17/12 - B-07373 Modified to support v tables as well as b's
    *
    * This trigger rejects insertion in bDDFI (Form Inputs) if any
    * of the following error conditions exist:
    *
    * Updates ColType based on Datatype
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
  
   BEGIN TRY
  
	   /* Updated not to use a cursor */
	   update d
	   set ColType = sys.types.name
	   from dbo.bDDUD d
	   inner join inserted 
		  on inserted.Form = d.Form
		  and inserted.Identifier = d.Identifier
		  and inserted.TableName = d.TableName
		  and inserted.ColumnName = d.ColumnName
	   inner join sys.tables on sys.tables.name in ('b'+inserted.TableName,'v'+inserted.TableName)
	   inner join sys.columns on sys.columns.object_id = sys.tables.object_id
		  and sys.columns.name = inserted.ColumnName
	   inner join sys.types on sys.types.system_type_id = sys.columns.system_type_id 
	   where inserted.Form is not null and inserted.Identifier is not null and inserted.ColumnName is not null
   END TRY
   BEGIN CATCH
       SET @errmsg = ERROR_MESSAGE()
       GOTO error
   END CATCH
   return

   
/*
   declare bDDUD_insert cursor local fast_forward for
   select Form, Identifier, TableName, ColumnName
   from inserted
   where Form is not null and Identifier is not null and ColumnName is not null
   
   open bDDUD_insert
   select @opencursor = 1  -- open cursor flag
   
   fetch next from bDDUD_insert into @form, @identifier, @tablename, @columnname
   if @@fetch_status <> 0
      begin
      select @errmsg = 'Cursor error'
      goto error
      end
   set_columntype:
   
	/* Issue 124038
	select @coltype = name from systypes with (nolock) where xusertype =
			  (select distinct xtype from systypes with (nolock) where xtype =
			  (select xtype from syscolumns with (nolock) where name = @columnname and id =
			  (select object_id(@tablename))))
	*/

	select @coltype = DATA_TYPE
	from INFORMATION_SCHEMA.COLUMNS with (nolock)
	where TABLE_NAME = 'b'+ @tablename and COLUMN_NAME = @columnname
 
   
   update dbo.DDUD
   set ColType = @coltype
   from dbo.DDUD d with (nolock)
   where d.Form=@form and d.Identifier=@identifier and d.TableName=@tablename and d.ColumnName=@columnname
   
   if @opencursor = 1
      begin
        fetch next from bDDUD_insert into @form, @identifier, @tablename, @columnname
        if @@fetch_status = 0
            goto set_columntype
        else
            begin
    	   close bDDUD_insert
    	   deallocate bDDUD_insert
              select @opencursor = 0
    	 end
       end
   
   return
   
    error:
       if @opencursor = 1
           begin
           close bDDUD_insert
           deallocate bDDUD_insert
           end
*/
error:      
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Form Upload!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtDDUDd_Audit] ON [dbo].[bDDUD]
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(deleted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(deleted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'D' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'DELETE FROM bDDUD WHERE Identifier = ''' + CAST(deleted.Identifier AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(deleted.Form AS VARCHAR(MAX)) + ''''
	FROM deleted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDUDi_Audit] trigger', 16, 1 ) with log
 END CATCH 
 

GO
EXEC sp_settriggerorder N'[dbo].[vtDDUDd_Audit]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtDDUDi_Audit] ON [dbo].[bDDUD]
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(inserted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'A' , NULL , NULL , NULL , GETDATE() , HOST_NAME() , 'INSERT INTO dbo.[bDDUD] ([Form], [Identifier], [TableName], [Seq], [ColumnName], [Description], [Datatype], [ColType], [BidtekDefaultValue], [RequiredValue], [UpdateKeyYN]) VALUES (' + ISNULL('''' + REPLACE(CAST(Form AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(Identifier AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL('''' + REPLACE(CAST(TableName AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL(CAST(Seq AS NVARCHAR(MAX)), 'NULL') +  ',' + ISNULL('''' + REPLACE(CAST(ColumnName AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(Description AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(Datatype AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(ColType AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(BidtekDefaultValue AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(RequiredValue AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL') + ',' + ISNULL('''' + REPLACE(CAST(UpdateKeyYN AS NVARCHAR(MAX)), '''' , '''''') + '''', 'NULL')  + ')'
	FROM inserted
 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDUDi_Audit] trigger', 16, 1 ) with log
 END CATCH 
 

GO
EXEC sp_settriggerorder N'[dbo].[vtDDUDi_Audit]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtDDUDu_Audit] ON [dbo].[bDDUD]
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 14 2009  9:56AM

 BEGIN TRY 
 IF UPDATE([Form])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(inserted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Form' ,  CONVERT(VARCHAR(MAX), deleted.[Form]) ,  Convert(VARCHAR(MAX), inserted.[Form]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUD SET Form = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Form]), '''' , ''''''), 'NULL') + ''' WHERE Identifier = ''' + CAST(inserted.Identifier AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Identifier] = deleted.[Identifier]  AND  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[Form],'') <> ISNULL(deleted.[Form],'')

 IF UPDATE([Identifier])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(inserted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Identifier' ,  CONVERT(VARCHAR(MAX), deleted.[Identifier]) ,  Convert(VARCHAR(MAX), inserted.[Identifier]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUD SET Identifier = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Identifier]), '''' , ''''''), 'NULL') + ''' WHERE Identifier = ''' + CAST(inserted.Identifier AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Identifier] = deleted.[Identifier]  AND  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[Identifier],'') <> ISNULL(deleted.[Identifier],'')

 IF UPDATE([TableName])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(inserted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'TableName' ,  CONVERT(VARCHAR(MAX), deleted.[TableName]) ,  Convert(VARCHAR(MAX), inserted.[TableName]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUD SET TableName = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[TableName]), '''' , ''''''), 'NULL') + ''' WHERE Identifier = ''' + CAST(inserted.Identifier AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Identifier] = deleted.[Identifier]  AND  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[TableName],'') <> ISNULL(deleted.[TableName],'')

 IF UPDATE([Seq])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(inserted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Seq' ,  CONVERT(VARCHAR(MAX), deleted.[Seq]) ,  Convert(VARCHAR(MAX), inserted.[Seq]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUD SET Seq = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Seq]), '''' , ''''''), 'NULL') + ''' WHERE Identifier = ''' + CAST(inserted.Identifier AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Identifier] = deleted.[Identifier]  AND  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[Seq],'') <> ISNULL(deleted.[Seq],'')

 IF UPDATE([ColumnName])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(inserted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'ColumnName' ,  CONVERT(VARCHAR(MAX), deleted.[ColumnName]) ,  Convert(VARCHAR(MAX), inserted.[ColumnName]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUD SET ColumnName = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[ColumnName]), '''' , ''''''), 'NULL') + ''' WHERE Identifier = ''' + CAST(inserted.Identifier AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Identifier] = deleted.[Identifier]  AND  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[ColumnName],'') <> ISNULL(deleted.[ColumnName],'')

 IF UPDATE([Description])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(inserted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Description' ,  CONVERT(VARCHAR(MAX), deleted.[Description]) ,  Convert(VARCHAR(MAX), inserted.[Description]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUD SET Description = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Description]), '''' , ''''''), 'NULL') + ''' WHERE Identifier = ''' + CAST(inserted.Identifier AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Identifier] = deleted.[Identifier]  AND  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[Description],'') <> ISNULL(deleted.[Description],'')

 IF UPDATE([Datatype])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(inserted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'Datatype' ,  CONVERT(VARCHAR(MAX), deleted.[Datatype]) ,  Convert(VARCHAR(MAX), inserted.[Datatype]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUD SET Datatype = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[Datatype]), '''' , ''''''), 'NULL') + ''' WHERE Identifier = ''' + CAST(inserted.Identifier AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Identifier] = deleted.[Identifier]  AND  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[Datatype],'') <> ISNULL(deleted.[Datatype],'')

 IF UPDATE([ColType])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(inserted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'ColType' ,  CONVERT(VARCHAR(MAX), deleted.[ColType]) ,  Convert(VARCHAR(MAX), inserted.[ColType]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUD SET ColType = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[ColType]), '''' , ''''''), 'NULL') + ''' WHERE Identifier = ''' + CAST(inserted.Identifier AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Identifier] = deleted.[Identifier]  AND  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[ColType],'') <> ISNULL(deleted.[ColType],'')

 IF UPDATE([BidtekDefaultValue])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(inserted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'BidtekDefaultValue' ,  CONVERT(VARCHAR(MAX), deleted.[BidtekDefaultValue]) ,  Convert(VARCHAR(MAX), inserted.[BidtekDefaultValue]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUD SET BidtekDefaultValue = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[BidtekDefaultValue]), '''' , ''''''), 'NULL') + ''' WHERE Identifier = ''' + CAST(inserted.Identifier AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Identifier] = deleted.[Identifier]  AND  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[BidtekDefaultValue],'') <> ISNULL(deleted.[BidtekDefaultValue],'')

 IF UPDATE([RequiredValue])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(inserted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'RequiredValue' ,  CONVERT(VARCHAR(MAX), deleted.[RequiredValue]) ,  Convert(VARCHAR(MAX), inserted.[RequiredValue]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUD SET RequiredValue = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[RequiredValue]), '''' , ''''''), 'NULL') + ''' WHERE Identifier = ''' + CAST(inserted.Identifier AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Identifier] = deleted.[Identifier]  AND  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[RequiredValue],'') <> ISNULL(deleted.[RequiredValue],'')

 IF UPDATE([UpdateKeyYN])
   INSERT dbo.vDDChangeLog (TableName, KeyString, Action, FieldName, OldValue, NewValue, DateTime, MachineName, CommandText)
   SELECT 'bDDUD' , '<KeyString Identifier = "' + REPLACE(CAST(inserted.Identifier AS VARCHAR(MAX)),'"', '&quot;') + '" Form = "' + REPLACE(CAST(inserted.Form AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 'U' , 'UpdateKeyYN' ,  CONVERT(VARCHAR(MAX), deleted.[UpdateKeyYN]) ,  Convert(VARCHAR(MAX), inserted.[UpdateKeyYN]) , GETDATE() , HOST_NAME() , 'UPDATE bDDUD SET UpdateKeyYN = ''' + ISNULL(REPLACE(Convert(VARCHAR(MAX), inserted.[UpdateKeyYN]), '''' , ''''''), 'NULL') + ''' WHERE Identifier = ''' + CAST(inserted.Identifier AS VARCHAR(MAX)) + '''' + ' AND Form = ''' + CAST(inserted.Form AS VARCHAR(MAX)) + ''''
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[Identifier] = deleted.[Identifier]  AND  inserted.[Form] = deleted.[Form] 
         AND ISNULL(inserted.[UpdateKeyYN],'') <> ISNULL(deleted.[UpdateKeyYN],'')

 END TRY 
 BEGIN CATCH 
   RAISERROR('Error in [dbo].[dbo.vtDDUDi_Audit] trigger', 16, 1 ) with log
 END CATCH 

GO
EXEC sp_settriggerorder N'[dbo].[vtDDUDu_Audit]', 'last', 'update', null
GO
ALTER TABLE [dbo].[bDDUD] WITH NOCHECK ADD CONSTRAINT [CK_bDDUD_BidtekDefaultValue] CHECK (([BidtekDefaultValue]='Y' OR [BidtekDefaultValue]='N' OR [BidtekDefaultValue] IS NULL))
GO
ALTER TABLE [dbo].[bDDUD] WITH NOCHECK ADD CONSTRAINT [CK_bDDUD_RequiredValue] CHECK (([RequiredValue]='Y' OR [RequiredValue]='N' OR [RequiredValue] IS NULL))
GO
ALTER TABLE [dbo].[bDDUD] WITH NOCHECK ADD CONSTRAINT [CK_bDDUD_UpdateKeyYN] CHECK (([UpdateKeyYN]='Y' OR [UpdateKeyYN]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biDDUD] ON [dbo].[bDDUD] ([Form], [Identifier]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
