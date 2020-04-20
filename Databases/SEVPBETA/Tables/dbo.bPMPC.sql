CREATE TABLE [dbo].[bPMPC]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[Markup] [numeric] (12, 6) NULL,
[RoundAmount] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMPC_RoundAmount] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger [dbo].[btPMPCd]    Script Date: 12/13/2006 12:22:59 ******/
CREATE trigger [dbo].[btPMPCd] on [dbo].[bPMPC] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMPC
 * Created By:	GF 12/13/2006 - 6.x HQMA
 * Modified By: JayR 03/23/2012 Remove unused variables. 
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMPC','PMCo: ' + isnull(convert(varchar(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'') + ' CostType: ' + isnull(convert(varchar(3),d.CostType),''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMPC = 'Y'


RETURN 
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPCi    Script Date: 8/28/99 9:37:58 AM ******/
CREATE  trigger [dbo].[btPMPCi] on [dbo].[bPMPC] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMPC
 * Created By:	LM 12/18/97
 * Modified By:	GF 12/13/2006 - 6.x HQMA
 *				JayR 03/23/2012 - TK-00000 Change to using FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMPC', 'PMCo: ' + isnull(convert(varchar(3),i.PMCo),'') + ' Project: ' + isnull(i.Project,'') + ' CostType: ' + isnull(convert(varchar(3),i.CostType),''),
	i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMPC = 'Y'


RETURN 
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPCu    Script Date: 8/28/99 9:37:58 AM ******/
CREATE   trigger [dbo].[btPMPCu] on [dbo].[bPMPC] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMPC
 * Created By:	LM 12/18/97
 * Modified By:	GF 12/13/2006 - 6.x HQMA
 *				GF 05/18/2009 - issue #133627
 *				GF 08/10/2010 - issue #134354
 *				JayR 03/23/2012  Remove unused variables
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- HQMA inserts
if update(Markup)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPC', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' CostType: ' + isnull(convert(varchar(3),i.CostType),''),
		i.PMCo, 'C', 'Markup', isnull(convert(varchar(16),d.Markup),''), isnull(convert(varchar(16),i.Markup),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.CostType=i.CostType
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Markup,'') <> isnull(i.Markup,'') and c.AuditPMPC = 'Y'
	
if update(RoundAmount)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPC', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' CostType: ' + isnull(convert(varchar(3),i.CostType),''),
		i.PMCo, 'C', 'RoundAmount', d.RoundAmount, i.RoundAmount, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.CostType=i.CostType
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.RoundAmount,'') <> isnull(i.RoundAmount,'') and c.AuditPMPC = 'Y'

RETURN 
   
   
   
  
 





GO
ALTER TABLE [dbo].[bPMPC] ADD CONSTRAINT [CK_bPMPC_RoundAmount] CHECK (([RoundAmount]='Y' OR [RoundAmount]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biPMPC] ON [dbo].[bPMPC] ([PMCo], [Project], [PhaseGroup], [CostType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMPC] WITH NOCHECK ADD CONSTRAINT [FK_bPMPC_bJCCT] FOREIGN KEY ([PhaseGroup], [CostType]) REFERENCES [dbo].[bJCCT] ([PhaseGroup], [CostType])
GO
ALTER TABLE [dbo].[bPMPC] WITH NOCHECK ADD CONSTRAINT [FK_bPMPC_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job]) ON DELETE CASCADE ON UPDATE CASCADE
GO
