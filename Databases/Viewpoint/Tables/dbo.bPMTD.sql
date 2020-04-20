CREATE TABLE [dbo].[bPMTD]
(
[CostType] [dbo].[bJCCType] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[PMCo] [dbo].[bCompany] NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [bibPMTD] ON [dbo].[bPMTD] ([CostType], [PMCo], [Template], [PhaseGroup], [Phase]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMTD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMTD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMTD_bPMTH] FOREIGN KEY ([PMCo], [Template]) REFERENCES [dbo].[bPMTH] ([PMCo], [Template]) ON DELETE CASCADE
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE  trigger [dbo].[btPMTDd] on [dbo].[bPMTD] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMTD
 * Created By: GR 10/04/99
 * Modified By: GF 04/08/2002 - Issue 16907 - deleting phase along with cost type
 *				GF 12/13/2006 - 6.x HQMA
 *				JayR 03/28/2012 TK-00000 Remove unused variables, switch to FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMTD', ' Template: ' + isnull(d.Template,'') + ' Phase: ' + isnull(d.Phase,'') + ' CostType: ' + isnull(convert(varchar(3),d.CostType),''),
	d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d join bPMCO c on c.PMCo = d.PMCo
where d.PMCo = c.PMCo and c.AuditPMTH = 'Y'

RETURN 
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[btPMTDi] on [dbo].[bPMTD] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMTD
 * Created By:	GF 12/13/2006 - 6.x HQMA
 * Modified By:  JayR 03/28/2012 TK-00000 Remove unused variables, switch to FKs for validation
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMTD', ' Template: ' + isnull(i.Template,'') + ' Phase: ' + isnull(i.Phase,'') + ' CostType: ' + isnull(convert(varchar(3),i.CostType),''),
	i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMTH = 'Y'


RETURN 
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger [dbo].[btPMTDu]    Script Date: 12/13/2006 09:54:02 ******/
CREATE trigger [dbo].[btPMTDu] on [dbo].[bPMTD] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMTD
 * Created By:	GF 12/13/2006 - 6.x auditing
 * Modified By: JayR 03/28/2012 TK-00000 Remove unused variables, switch to FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- HQMA inserts
if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMTD', 'Template: ' + isnull(i.Template,'') + ' Phase: ' + isnull(i.Phase,'') + ' CostType: ' + isnull(convert(varchar(3),i.CostType),''),
		i.PMCo, 'C', 'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Template=i.Template and d.PhaseGroup=i.PhaseGroup
	and d.Phase=i.Phase and d.CostType=i.CostType
	join bPMCO c on c.PMCo=i.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.AuditPMTH = 'Y'


RETURN 
   
   
  
 





GO
