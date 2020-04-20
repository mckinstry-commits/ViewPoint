CREATE TABLE [dbo].[bPMRQ]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[PCOType] [dbo].[bDocType] NOT NULL,
[PCO] [dbo].[bPCO] NOT NULL,
[RFQ] [dbo].[bDocument] NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[RFQDate] [dbo].[bDate] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[FirmNumber] [dbo].[bFirm] NULL,
[ResponsiblePerson] [dbo].[bEmployee] NULL,
[Status] [dbo].[bStatus] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[DateDue] [dbo].[bDate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMRQ] ADD 
CONSTRAINT [PK_bPMRQ] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [PCOType], [PCO], [RFQ]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMRQ] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMRQ] WITH NOCHECK ADD
CONSTRAINT [FK_bPMRQ_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
ALTER TABLE [dbo].[bPMRQ] WITH NOCHECK ADD
CONSTRAINT [FK_bPMRQ_bPMDT] FOREIGN KEY ([PCOType]) REFERENCES [dbo].[bPMDT] ([DocType])
ALTER TABLE [dbo].[bPMRQ] WITH NOCHECK ADD
CONSTRAINT [FK_bPMRQ_bPMPM] FOREIGN KEY ([VendorGroup], [FirmNumber], [ResponsiblePerson]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
ALTER TABLE [dbo].[bPMRQ] WITH NOCHECK ADD
CONSTRAINT [FK_bPMRQ_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMRQd    Script Date: 8/28/99 9:38:01 AM ******/
CREATE trigger [dbo].[btPMRQd] on [dbo].[bPMRQ] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMRQ
 * Created By:
 * Modified By:	 GF 04/24/2008 - issue #125958 delete PM distribution audit
 *				 JayR 03/26/2012 TK-00000 Change to using FKs for cascase deletion.
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMRQ' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMRQ' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMRQ' and i.SourceKeyId=d.KeyID



---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, RFQPCO)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
		'RFQ', i.PCOType, i.RFQ, null, getdate(), 'D', 'RFQ', i.RFQ, null,
		SUSER_SNAME(), 'RFQ: ' + isnull(i.RFQ,'') + ' has been deleted from PCO: ' + isnull(i.PCO,'') + '.', i.PCO
from deleted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFQ'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=i.PMCo and j.Job=i.Project
where j.ClosePurgeFlag <> 'Y' and isnull(c.DocHistRFQ,'N') = 'Y'
group by i.PMCo, i.Project, i.PCOType, i.RFQ, i.PCO


RETURN 
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/****** Object:  Trigger dbo.btPMRQi    Script Date: 8/28/99 9:38:01 AM ******/
CREATE  trigger [dbo].[btPMRQi] on [dbo].[bPMRQ] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMRQ
 * Created By:	LM 1/15/98
 * Modified By:	GF 10/09/2002 - changed dbl quotes to single quotes
 *				JayR 03/26/2012 TK-00000 Change to use FKs for validation.
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, RFQPCO)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
		'RFQ', i.PCOType, i.RFQ, null, getdate(), 'A', 'RFQ', null, i.RFQ, SUSER_SNAME(),
		'RFQ: ' + isnull(i.RFQ,'') + ' has been added to PCO: ' + isnull(i.PCO,'') + '.', isnull(i.PCO,'')
from inserted i 
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFQ'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where c.DocHistRFQ = 'Y'
group by i.PMCo, i.Project, i.PCOType, i.RFQ, i.PCO


RETURN 

   
   
  
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/****** Object:  Trigger dbo.btPMRQu    Script Date: 8/28/99 9:38:01 AM ******/
CREATE trigger [dbo].[btPMRQu] on [dbo].[bPMRQ] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMRQ
 * Created By:`	LM 1/15/98
 * Modified By:	GF 10/09/2002 - changed dbl quotes to single quotes
 *				JayR  TK-00000 Switch to using FKs for validation.
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for key changes
if update(PMCo) or update(Project) or update(PCOType) or update(PCO) or update(RFQ)
   	begin
   		RAISERROR('Cannot change key fields  - cannot update PMRQ', 11, -1)
   		ROLLBACK TRANSACTION
   		RETURN
   	end


---- document history updates (bPMDH)
if update(Description)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, RFQPCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'RFQ', i.PCOType, i.RFQ, null, getdate(), 'C', 'Description', d.Description, i.Description,
			SUSER_SNAME(), 'Description has been changed', i.PCO
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.RFQ=i.RFQ
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFQ'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and isnull(c.DocHistRFQ,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.RFQ, i.PCO, i.Description, d.Description
	end
if update(RFQDate)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, RFQPCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'RFQ', i.PCOType, i.RFQ, null, getdate(), 'C', 'RFQDate', convert(char(8),d.RFQDate,1),
			convert(char(8),i.RFQDate,1), SUSER_SNAME(), 'RFQ Date has been changed', i.PCO
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.RFQ=i.RFQ
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFQ'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.RFQDate,'') <> isnull(i.RFQDate,'') and isnull(c.DocHistRFQ,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.RFQ, i.PCO, i.RFQDate, d.RFQDate
	end
if update(FirmNumber)
	begin
	insert into bPMDH(PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, RFQPCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'RFQ', i.PCOType, i.RFQ, null, getdate(), 'C', 'Firm', convert(varchar(10),d.FirmNumber),
			convert(varchar(10),i.FirmNumber), SUSER_SNAME(), 'Firm has been changed', i.PCO
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.RFQ=i.RFQ
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFQ'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.FirmNumber,0) <> isnull(i.FirmNumber,0) and isnull(c.DocHistRFQ,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.RFQ, i.PCO, i.FirmNumber, d.FirmNumber
	end
if update(ResponsiblePerson)
	begin
	insert into bPMDH(PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, RFQPCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'RFQ', i.PCOType, i.RFQ, null, getdate(), 'C', 'ResponsiblePerson', convert(varchar(8),d.ResponsiblePerson),
			convert(varchar(8),i.ResponsiblePerson), SUSER_SNAME(), 'Responsible Person has been changed', i.PCO
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.RFQ=i.RFQ
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFQ'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ResponsiblePerson,0) <> isnull(i.ResponsiblePerson,0) and isnull(c.DocHistRFQ,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.RFQ, i.PCO, i.ResponsiblePerson, d.ResponsiblePerson
	end
if update(Status)
	begin
	insert into bPMDH(PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, RFQPCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'RFQ', i.PCOType, i.RFQ, null, getdate(), 'C', 'Status', d.Status, i.Status,
			SUSER_SNAME(), 'Status has been changed', i.PCO
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.RFQ=i.RFQ
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFQ'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and isnull(c.DocHistRFQ,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.RFQ, i.PCO, i.Status, d.Status
	end


RETURN 
   
  
 






GO
