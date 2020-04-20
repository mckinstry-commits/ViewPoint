CREATE TABLE [dbo].[bPMCU]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[DocCat] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Inactive] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCU_Inactive] DEFAULT ('N'),
[UseStdCCList] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCU_UseStdCCList] DEFAULT ('Y'),
[OvrCCList] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[UseStdSubject] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCU_UseStdSubject] DEFAULT ('Y'),
[OvrSubject] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[UseStdFileName] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCU_UseStdFileName] DEFAULT ('Y'),
[OvrFileName] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[AttachToParent] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCU_AttachToParent] DEFAULT ('Y')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMCUu    Script Date: 8/28/99 9:37:49 AM ******/
CREATE trigger [dbo].[btPMCUu] on [dbo].[bPMCU] for UPDATE as
/*--------------------------------------------------------------
* Update trigger for PMCU
* Created By:	GF 08/18/2009 - issue #24641
* Modified By:	
*				
*
*
*--------------------------------------------------------------*/
if @@rowcount = 0 return
set nocount on

---- check for changes to Document Category
if update(DocCat)
BEGIN 
	RAISERROR('Cannot change Add On - cannot update PMCU', 11, -1)
	ROLLBACK TRANSACTION
	RETURN
END 



---- HQMA inserts
if update(Inactive)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCU', 'PM Document Category: ' + isnull(i.DocCat,''), NULL, 'C',
		'Inactive',  d.Inactive, i.Inactive, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocCat=i.DocCat
	where isnull(d.Inactive,'') <> isnull(i.Inactive,'')
if update(UseStdCCList)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCU', 'PM Document Category: ' + isnull(i.DocCat,''), NULL, 'C',
		'UseStdCCList',  d.UseStdCCList, i.UseStdCCList, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocCat=i.DocCat
	where isnull(d.UseStdCCList,'') <> isnull(i.UseStdCCList,'')
if update(UseStdSubject)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCU', 'PM Document Category: ' + isnull(i.DocCat,''), NULL, 'C',
		'UseStdSubject',  d.UseStdSubject, i.UseStdSubject, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocCat=i.DocCat
	where isnull(d.UseStdSubject,'') <> isnull(i.UseStdSubject,'')
if update(UseStdFileName)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCU', 'PM Document Category: ' + isnull(i.DocCat,''), NULL, 'C',
		'UseStdFileName',  d.UseStdFileName, i.UseStdFileName, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocCat=i.DocCat
	where isnull(d.UseStdFileName,'') <> isnull(i.UseStdFileName,'')
if update(OvrCCList)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCU', 'PM Document Category: ' + isnull(i.DocCat,''), NULL, 'C',
		'OvrCCList',  d.OvrCCList, i.OvrCCList, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocCat=i.DocCat
	where isnull(d.OvrCCList,'') <> isnull(i.OvrCCList,'')
if update(OvrSubject)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCU', 'PM Document Category: ' + isnull(i.DocCat,''), NULL, 'C',
		'OvrSubject',  d.OvrSubject, i.OvrSubject, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocCat=i.DocCat
	where isnull(d.OvrSubject,'') <> isnull(i.OvrSubject,'')
if update(OvrFileName)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMCU', 'PM Document Category: ' + isnull(i.DocCat,''), NULL, 'C',
		'OvrFileName',  d.OvrFileName, i.OvrFileName, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocCat=i.DocCat
	where isnull(d.OvrFileName,'') <> isnull(i.OvrFileName,'')

RETURN 



GO
ALTER TABLE [dbo].[bPMCU] ADD CONSTRAINT [CK_bPMCU_AttachToParent] CHECK (([AttachToParent]='Y' OR [AttachToParent]='N'))
GO
ALTER TABLE [dbo].[bPMCU] ADD CONSTRAINT [CK_bPMCU_Inactive] CHECK (([Inactive]='N' OR [Inactive]='Y'))
GO
ALTER TABLE [dbo].[bPMCU] ADD CONSTRAINT [CK_bPMCU_UseStdCCList] CHECK (([UseStdCCList]='N' OR [UseStdCCList]='Y'))
GO
ALTER TABLE [dbo].[bPMCU] ADD CONSTRAINT [CK_bPMCU_UseStdFileName] CHECK (([UseStdFileName]='N' OR [UseStdFileName]='Y'))
GO
ALTER TABLE [dbo].[bPMCU] ADD CONSTRAINT [CK_bPMCU_UseStdSubject] CHECK (([UseStdSubject]='N' OR [UseStdSubject]='Y'))
GO
ALTER TABLE [dbo].[bPMCU] ADD CONSTRAINT [PK_bPMCU] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bPMCU_DocCat] ON [dbo].[bPMCU] ([DocCat]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMCU] WITH NOCHECK ADD CONSTRAINT [FK_bPMCU_bPMCT] FOREIGN KEY ([DocCat]) REFERENCES [dbo].[bPMCT] ([DocCat]) ON DELETE CASCADE
GO
