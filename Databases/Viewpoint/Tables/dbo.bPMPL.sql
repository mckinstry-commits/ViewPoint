CREATE TABLE [dbo].[bPMPL]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Location] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPMPL] ON [dbo].[bPMPL] ([PMCo], [Project], [Location]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMPL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMPL] WITH NOCHECK ADD
CONSTRAINT [FK_bPMPL_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPLd    Script Date: 8/28/99 9:37:58 AM ******/
CREATE trigger [dbo].[btPMPLd] on [dbo].[bPMPL] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMPL
 * Created By: LM  12/18/97
 * Modified By:	GF 12/08/2006 - 6.x HQMA auditing
 *				JayR 03/26/2012 - TK-00000 Change to use FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMPL','PM Co#: ' + isnull(convert(char(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'') + ' Location: ' + isnull(d.Location,''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMPL = 'Y'


RETURN 
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPLi    Script Date: 8/28/99 9:37:59 AM ******/
CREATE trigger [dbo].[btPMPLi] on [dbo].[bPMPL] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMPL
 * Created By:  LM 1/7/97
 * Modified By:	GF 12/08/2006 - 6.x HQMA auditing
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


-- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMPL', ' Key: ' + convert(char(3), i.PMCo) + '/' + isnull(i.Project,'') + '/' + isnull(i.Location,''),
       i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMPL = 'Y'


RETURN 
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPLu    Script Date: 8/28/99 9:37:59 AM ******/
CREATE trigger [dbo].[btPMPLu] on [dbo].[bPMPL] for UPDATE as
/*--------------------------------------------------------------
 *  Update trigger for PMPL
 *  Created By: LM 12/18/97
 * Modified By:	GF 12/08/2006 - 6.X HQMA auditing
 *				JayR 03/26/2012 Change to use FKs for validation.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
      begin
      RAISERROR('Cannot change PMCo - cannot update PMPL', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end

---- check for changes to Project
if update(Project)
      begin
      RAISERROR('Cannot change Project - cannot update PMPL', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Location
if update(Location)
      begin
      RAISERROR('Cannot change Location - cannot update PMPL', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end


---- HQMA inserts
if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPL', 'PM Co: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' Location: ' + isnull(i.Location,''),
		i.PMCo, 'C', 'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Location=i.Location
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.AuditPMPL='Y'


RETURN 
   
   
  
 





GO
