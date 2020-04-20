CREATE TABLE [dbo].[bUDTH]
(
[TableName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[FormName] [dbo].[bDesc] NULL,
[CompanyBasedYN] [dbo].[bYN] NOT NULL,
[CreatedBy] [dbo].[bVPUserName] NULL,
[DateCreated] [dbo].[bDate] NULL,
[LastRunDate] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Created] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bUDTH_Created] DEFAULT ('N'),
[Dirty] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bUDTH_Dirty] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[UseNotesTab] [int] NOT NULL CONSTRAINT [DF_bUDTH_UseNotesTab] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AuditTable] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bUDTH_AuditTable] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   CREATE TRIGGER [dbo].[btUDTHd] ON [dbo].[bUDTH]
   FOR DELETE
   /*****************************************************
   	Created:	03/08/2001 RM
    
	Modified:	05/08/2001 kb - added code to delete the UDTM module assignments
				12/07/2007 TP - added code to delete the DDFS Form Security
				07/23/2008 AL - added code to delete the DDTS Tab Security
				09/20/2010 AL - added code to delete the DDSL Records
   	Delete Values in DDFH, DDFT,UDTC when they delete their form header.
   
   ******************************************************/
   AS
   declare @tablename varchar(20)
   
   --Have to delete DDFL and then DDUI and then DDFI Entries first
   
   delete vDDFLc
   from vDDFLc l, deleted d
   where  d.FormName = l.Form
   
   delete vDDUI
   from vDDUI i, deleted d
   where  d.FormName = i.Form
   
   delete vDDFIc
   from vDDFIc i, deleted d
   where  d.FormName = i.Form
   
   delete bUDTC
   from bUDTC c, deleted d
   where c.TableName = d.TableName
   
   delete vDDFTc
   from vDDFTc t, deleted d
   where t.Form = d.FormName
   
   delete vDDTS
   from vDDTS t, deleted d
   where t.Form = d.FormName

   delete vDDFS
   from vDDFS t, deleted d
   where t.Form = d.FormName
   
   delete vDDFHc
   from vDDFHc h, deleted d
   where h.Form = d.FormName
   
   delete vDDSLc
   from vDDSLc h, deleted d
   where h.TableName = 'b'+ d.TableName
   
   --delete module assignment
   delete vDDMFc
   from vDDMFc u, deleted d
   where u.Form = d.TableName
   
   declare droptable cursor for
   select TableName from deleted where Created = 'Y'
   
   open droptable
   
   fetch next from droptable into @tablename
   while @@Fetch_status = 0
   begin
   	exec vspUDDropTable @tablename,''
   	fetch next from droptable into @tablename
   end
   
   close droptable
   deallocate droptable
   
   
   
   
  
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Modified:	Jonathan 05/27/2009 - Removed FKeyID column from HQMA insert statement.
-- Create date: 5/22/2009
-- Description:	Trigger to audit changes to the Auditing field
-- =============================================
CREATE TRIGGER [dbo].[vUDTHu] 
   ON  [dbo].[bUDTH] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	IF UPDATE(AuditTable)
		INSERT INTO HQMA ( TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName )
		SELECT    inserted.TableName
				, '<KeyString TableName="' + inserted.TableName + '" />'
				, NULL
				, 'U'
				, 'AuditTable'
				, deleted.AuditTable
				, inserted.AuditTable
				, CURRENT_TIMESTAMP
				, SUSER_SNAME()				
		FROM inserted
		INNER JOIN deleted ON inserted.KeyID = deleted.KeyID
		WHERE ISNULL(inserted.AuditTable, '') <> ISNULL(deleted.AuditTable, '')
END

GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bUDTH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biUDTH] ON [dbo].[bUDTH] ([TableName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bUDTH].[CompanyBasedYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bUDTH].[Created]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bUDTH].[Dirty]'
GO
