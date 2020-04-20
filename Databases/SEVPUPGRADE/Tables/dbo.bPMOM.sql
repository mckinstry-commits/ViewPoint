CREATE TABLE [dbo].[bPMOM]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[PCOType] [dbo].[bDocType] NULL,
[PCO] [dbo].[bPCO] NULL,
[PCOItem] [dbo].[bPCOItem] NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[IntMarkUp] [numeric] (12, 6) NULL,
[ConMarkUp] [numeric] (12, 6) NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMOMu    Script Date: 8/28/99 9:37:56 AM ******/
CREATE  trigger [dbo].[btPMOMu] on [dbo].[bPMOM] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMOM
 * Created By:	GF 01/15/2007 - 6.x document history enhancement
 * Modified By:  JayR change to remove gotos
 *
 *
 *
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- PMDH inserts
if not exists(select 1 from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo and isnull(c.DocHistPCO,'N') = 'Y')
	begin
  		return
	end

if update(IntMarkUp)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C',
			'IntMarkUp', convert(varchar(16),d.IntMarkUp), convert(varchar(16),i.IntMarkUp), SUSER_SNAME(),
			'CostType: ' + convert(varchar(3),i.CostType) + ' internal markup have been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType
	and d.PCO=i.PCO and d.PCOItem=i.PCOItem and d.PhaseGroup=i.PhaseGroup and d.CostType=i.CostType
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(c.DocHistPCO,'N') = 'Y' and isnull(convert(varchar(16),d.IntMarkUp),'') <> isnull(convert(varchar(16),i.IntMarkUp),'')
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.CostType, i.IntMarkUp, d.IntMarkUp
	end
if update(ConMarkUp)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C',
			'ConMarkUp', convert(varchar(16),d.ConMarkUp), convert(varchar(16),i.ConMarkUp), SUSER_SNAME(),
			'CostType: ' + convert(varchar(3),i.CostType) + ' contract markup have been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType
	and d.PCO=i.PCO and d.PCOItem=i.PCOItem and d.PhaseGroup=i.PhaseGroup and d.CostType=i.CostType
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(c.DocHistPCO,'N') = 'Y' and isnull(convert(varchar(16),d.ConMarkUp),'') <> isnull(convert(varchar(16),i.ConMarkUp),'')
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.CostType, i.ConMarkUp, d.ConMarkUp
	end


RETURN 









GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMOM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMOM] ON [dbo].[bPMOM] ([PMCo], [Project], [PCOType], [PCO], [PCOItem], [PhaseGroup], [CostType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMOM] WITH NOCHECK ADD CONSTRAINT [FK_bPMOM_bPMDT] FOREIGN KEY ([PCOType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
