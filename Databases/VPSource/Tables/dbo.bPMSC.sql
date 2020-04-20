CREATE TABLE [dbo].[bPMSC]
(
[Status] [dbo].[bStatus] NOT NULL,
[Description] [dbo].[bDesc] NOT NULL,
[CodeType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[IncludeInProj] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMSC_IncludeInProj] DEFAULT ('N'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ExcludeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMSC_ExcludeYN] DEFAULT ('N'),
[ActiveAllYN] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMSC_ActiveAllYN] DEFAULT ('Y'),
[DocCat] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMSCd    Script Date: 8/28/99 9:38:01 AM ******/
CREATE  trigger [dbo].[btPMSCd] on [dbo].[bPMSC] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMSC
 * Created By:	LM 12/18/97
 * Modified By: GF 10/25/2002 - issue #19010 allow status code to be deleted. No checks.
 *				GF 12/13/2006 - 6.x HQMA
 *				JayR 03/26/2012 TK-00000 Remove unused variables
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMSC','Status: ' + isnull(d.Status,''), null, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d


RETURN 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMSCi    Script Date: 8/28/99 9:38:01 AM ******/
CREATE trigger [dbo].[btPMSCi] on [dbo].[bPMSC] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMSC
 * Created By:	LM 12/18/97
 * Modified By:	GF 12/13/2006 - 6.x HQMA
 *				JayR 03/26/2012  Switch to use table level constraint for validation. Remove unused variables
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMSC', ' Status: ' + isnull(i.Status,''), null, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i


RETURN 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMSCu    Script Date: 8/28/99 9:38:01 AM ******/
CREATE trigger [dbo].[btPMSCu] on [dbo].[bPMSC] for UPDATE as
    

/***  basic declares for SQL Triggers ****/

/*--------------------------------------------------------------
 * Update trigger for PMSC
 * Created By:	LM 12/18/97
 * Modified By:	GF 12/13/2006 - 6.x HQMA
 *				DAN SO 06/23/2009 - Issue: #134018 - ActiveAllYN HQMA
 *				JayR 03/26/2012 TK-00000 Change to using table constraint for validation.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to Status
if update(Status)
      begin
		  RAISERROR('Cannot change Status - cannot update PMSC', 11, -1)
		  ROLLBACK TRANSACTION
		  RETURN
      end

---- HQMA inserts
if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSC', 'Status: ' + isnull(i.Status,''), null, 'C', 'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.Status=i.Status 
	where isnull(d.Description,'') <> isnull(i.Description,'')
if update(CodeType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSC', 'Status: ' + isnull(i.Status,''), null, 'C', 'CodeType',  d.CodeType, i.CodeType, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.Status=i.Status 
	where isnull(d.CodeType,'') <> isnull(i.CodeType,'')
if update(IncludeInProj)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSC', 'Status: ' + isnull(i.Status,''), null, 'C', 'IncludeInProj',  d.IncludeInProj, i.IncludeInProj, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.Status=i.Status 
	where isnull(d.IncludeInProj,'') <> isnull(i.IncludeInProj,'')
if update(ActiveAllYN) 
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMSC', 'Status: ' + isnull(i.Status,''), null, 'C', 'ActiveAllYN',  d.ActiveAllYN, i.ActiveAllYN, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.Status=i.Status 
	where isnull(d.ActiveAllYN,'') <> isnull(i.ActiveAllYN,'')


RETURN 

GO
ALTER TABLE [dbo].[bPMSC] ADD CONSTRAINT [CK_bPMSC_ActiveAllYN] CHECK (([ActiveAllYN]='N' OR [ActiveAllYN]='Y'))
GO
ALTER TABLE [dbo].[bPMSC] WITH NOCHECK ADD CONSTRAINT [CK_bPMSC_CodeType] CHECK (([CodeType]='F' OR [CodeType]='I' OR [CodeType]='B'))
GO
ALTER TABLE [dbo].[bPMSC] ADD CONSTRAINT [PK_bPMSC] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMSC] ON [dbo].[bPMSC] ([Status]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
