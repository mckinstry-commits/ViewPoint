CREATE TABLE [dbo].[vPMPOCO]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[POCo] [dbo].[bCompany] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POCONum] [smallint] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Details] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Date] [dbo].[bDate] NULL,
[Status] [dbo].[bStatus] NULL,
[Reference] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DateSent] [dbo].[bDate] NULL,
[DateDueBack] [dbo].[bDate] NULL,
[DateReceived] [dbo].[bDate] NULL,
[DateApproved] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ReadyForAcctg] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPMPOCO_ReadyForAcctg] DEFAULT ('N'),
[ReadyBy] [dbo].[bVPUserName] NULL,
[DocType] [dbo].[bDocType] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMPOCOd    Script Date: 09/05/2006 ******/
CREATE trigger [dbo].[btPMPOCOd] on [dbo].[vPMPOCO] for DELETE as
/*--------------------------------------------------------------
 * Created By:	GF 04/06/2011 - TK-03857
 * Modified By:	
 *      JayR 03/19/2012 - TK-00000 Change some deletes to use FK...cascade deletes
 *
 * Delete trigger for vPMPOCO
 *
 * bPMDH auditing
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

delete dbo.bPMMF
from dbo.bPMMF v JOIN deleted d ON d.POCo=v.POCo AND d.PO=v.PO AND d.POCONum=v.POCONum

---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMPOCO' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMPOCO' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMPOCO' and i.SourceKeyId=d.KeyID


---- delete purchase order change order association 
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMPOCO' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT null
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMPOCO' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL



---- (bPMDH) TK-03857
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, POCo, PO, POCONum)
select d.PMCo, d.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY d.PMCo ASC, d.Project ASC),
		'PURCHASECO', NULL, ISNULL(CONVERT(VARCHAR(10),d.POCONum),''), null, getdate(), 'D', 'POCONum', ISNULL(CONVERT(VARCHAR(10),d.POCONum),''), null, SUSER_SNAME(),
		'POCo: ' + CONVERT(VARCHAR(3),d.POCo) + ' PO: ' + ISNULL(d.PO,'') + ' POCONum: ' + ISNULL(CONVERT(VARCHAR(10),d.POCONum),'') + ' has been deleted.',
		d.POCo, d.PO, d.POCONum
from deleted d
left join dbo.bPMDH h on h.PMCo=d.PMCo and h.Project=d.Project and h.DocCategory='PURCHASECO'
join dbo.bPMCO c with (nolock) on d.PMCo=c.PMCo
left join dbo.bJCJM j with (nolock) on j.JCCo=d.PMCo and j.Job=d.Project
where j.ClosePurgeFlag <> 'Y' and c.DocHistPOCONum = 'Y'
group by d.PMCo, d.Project, d.POCo, d.PO, d.POCONum


RETURN
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPOCOi    ******/
CREATE trigger [dbo].[btPMPOCOi] on [dbo].[vPMPOCO] for INSERT as
/*--------------------------------------------------------------
 * Created By:	GF 04/08/2011 TK-03857 TK-03569
 * Modified By:	DAN SO 05/09/2011 - TK-04902 - Prefill PMPOCO Distribution from PMPOHeader Distribution
 *  JayR  03/19/2012 - TK-00000 Change validation to use FK Constaints.
 *	SCOTTP 05/03/2014 TFS-13563 Remove code that uses PMDistribution. Distribution is now managed via the form or C&S Form
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- assigned to a purchase order TK-03569
---- insert record association
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT 'PMPOCO', i.KeyID, 'POHD', a.KeyID
FROM inserted i
JOIN dbo.bPOHD a ON a.POCo=i.POCo AND a.PO=i.PO
WHERE NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord b WHERE b.RecTableName = 'PMPOCO'
				AND b.RECID=i.KeyID AND b.LinkTableName='POHD' AND b.LINKID=a.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='POHD'
				AND c.RECID=a.KeyID AND c.LinkTableName='PMPOCO' AND c.LINKID=i.KeyID)


---- document history (bPMDH) TK-03857
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, POCo, PO, POCONum)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'PURCHASECO', NULL, CONVERT(VARCHAR(10),i.POCONum), null, getdate(), 'A', 'POCONum', null, CONVERT(VARCHAR(10),i.POCONum), SUSER_SNAME(),
		'POCo: ' + CONVERT(VARCHAR(3),i.POCo) + ' PO: ' + ISNULL(i.PO,'') + ' POCONum: ' + ISNULL(CONVERT(VARCHAR(10),i.POCONum),'') + ' has been added.',
		i.POCo, i.PO, i.POCONum
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PURCHASECO'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where c.DocHistPOCONum = 'Y'
group by i.PMCo, i.Project, i.KeyID, i.POCo, i.PO, i.POCONum


return









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE trigger [dbo].[btPMPOCOu] on [dbo].[vPMPOCO] for UPDATE as
/*--------------------------------------------------------------
 * Created By:	GF 03/23/2011 TK-03189 TK-03857
 * Modified By:	JayR 03/20/2012 TK-00000 Move checks to use FK constraints.
 *
 *				
 * Validates columns and inserts document history records.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- key fields cannot be changed
IF UPDATE(PMCo) OR UPDATE(Project) OR UPDATE(POCONum)
	BEGIN
		RAISERROR('Cannot change key fields - cannot update PMPOCO', 11, -1)
		ROLLBACK TRANSACTION
		RETURN
	END
	
---- document history updates (bPMDH) TK-03857
if update(Description)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, POCo, PO, POCONum)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PURCHASECO', NULL, ISNULL(CONVERT(VARCHAR(10),i.POCONum),''), null, getdate(), 'C', 'Description',
			d.Description, i.Description, SUSER_SNAME(), 'Description has been changed', i.POCo, i.PO, i.POCONum
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PURCHASECO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.DocHistPOCONum = 'Y'
	group by i.PMCo, i.Project, i.POCo, i.PO, i.POCONum, i.Description, d.Description
	END
if update(Status)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, POCo, PO, POCONum)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PURCHASECO', NULL, ISNULL(CONVERT(VARCHAR(10),i.POCONum),''), null, getdate(), 'C', 'Status',
			d.Status, i.Status, SUSER_SNAME(), 'Status has been changed', i.POCo, i.PO, i.POCONum
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PURCHASECO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and c.DocHistPOCONum = 'Y'
	group by i.PMCo, i.Project, i.POCo, i.PO, i.POCONum, i.Status, d.Status
	END
if update(Reference)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, POCo, PO, POCONum)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PURCHASECO', NULL, ISNULL(CONVERT(VARCHAR(10),i.POCONum),''), null, getdate(), 'C', 'Reference',
			d.Reference, i.Reference, SUSER_SNAME(), 'Reference has been changed', i.POCo, i.PO, i.POCONum
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PURCHASECO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Reference,'') <> isnull(i.Reference,'') and c.DocHistPOCONum = 'Y'
	group by i.PMCo, i.Project, i.POCo, i.PO, i.POCONum, i.Reference, d.Reference
	END
if update(ReadyForAcctg)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, POCo, PO, POCONum)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PURCHASECO', NULL, ISNULL(CONVERT(VARCHAR(10),i.POCONum),''), null, getdate(), 'C', 'ReadyForAcctg',
			d.ReadyForAcctg, i.ReadyForAcctg, SUSER_SNAME(), 'ReadyForAcctg has been changed', i.POCo, i.PO, i.POCONum
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PURCHASECO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ReadyForAcctg,'') <> isnull(i.ReadyForAcctg,'') and c.DocHistPOCONum = 'Y'
	group by i.PMCo, i.Project, i.POCo, i.PO, i.POCONum, i.ReadyForAcctg, d.ReadyForAcctg
	END
if update(Date)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, POCo, PO, POCONum)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PURCHASECO', NULL, ISNULL(CONVERT(VARCHAR(10),i.POCONum),''), null, getdate(), 'C', 'Date',
			CONVERT(VARCHAR(20),d.Date,112), CONVERT(VARCHAR(20),i.Date,112), SUSER_SNAME(), 'Date has been changed', i.POCo, i.PO, i.POCONum
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PURCHASECO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Date,'') <> isnull(i.Date,'') and c.DocHistPOCONum = 'Y'
	group by i.PMCo, i.Project, i.POCo, i.PO, i.POCONum, i.Date, d.Date
	END
if update(DateSent)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, POCo, PO, POCONum)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PURCHASECO', NULL, ISNULL(CONVERT(VARCHAR(10),i.POCONum),''), null, getdate(), 'C', 'DateSent',
			CONVERT(VARCHAR(20),d.DateSent,112), CONVERT(VARCHAR(20),i.DateSent,112), SUSER_SNAME(), 'DateSent has been changed', i.POCo, i.PO, i.POCONum
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PURCHASECO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateSent,'') <> isnull(i.DateSent,'') and c.DocHistPOCONum = 'Y'
	group by i.PMCo, i.Project, i.POCo, i.PO, i.POCONum, i.DateSent, d.DateSent
	END
if update(DateDueBack)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, POCo, PO, POCONum)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PURCHASECO', NULL, ISNULL(CONVERT(VARCHAR(10),i.POCONum),''), null, getdate(), 'C', 'DateDueBack',
			CONVERT(VARCHAR(20),d.DateDueBack,112), CONVERT(VARCHAR(20),i.DateDueBack,112), SUSER_SNAME(), 'DateDueBack has been changed', i.POCo, i.PO, i.POCONum
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PURCHASECO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateDueBack,'') <> isnull(i.DateDueBack,'')and c.DocHistPOCONum = 'Y'
	group by i.PMCo, i.Project, i.POCo, i.PO, i.POCONum, i.DateDueBack, d.DateDueBack
	END
if update(DateReceived)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, POCo, PO, POCONum)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PURCHASECO', NULL, ISNULL(CONVERT(VARCHAR(10),i.POCONum),''), null, getdate(), 'C', 'DateReceived',
			CONVERT(VARCHAR(20),d.DateReceived,112), CONVERT(VARCHAR(20),i.DateReceived,112), SUSER_SNAME(), 'DateReceived has been changed', i.POCo, i.PO, i.POCONum
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PURCHASECO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateReceived,'') <> isnull(i.DateReceived,'') and c.DocHistPOCONum = 'Y'
	group by i.PMCo, i.Project, i.POCo, i.PO, i.POCONum, i.DateReceived, d.DateReceived
	END
if update(DateApproved)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, POCo, PO, POCONum)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PURCHASECO', NULL, ISNULL(CONVERT(VARCHAR(10),i.POCONum),''), null, getdate(), 'C', 'DateApproved',
			CONVERT(VARCHAR(20),d.DateApproved,112), CONVERT(VARCHAR(20),i.DateApproved,112), SUSER_SNAME(), 'DateApproved has been changed', i.POCo, i.PO, i.POCONum
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PURCHASECO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateApproved,'') <> isnull(i.DateApproved,'') and c.DocHistPOCONum = 'Y'
	group by i.PMCo, i.Project, i.POCo, i.PO, i.POCONum, i.DateApproved, d.DateApproved
	END


RETURN






















GO
ALTER TABLE [dbo].[vPMPOCO] WITH NOCHECK ADD CONSTRAINT [CK_vPMPOCO_POCONum] CHECK (([POCONum]>=(0)))
GO
ALTER TABLE [dbo].[vPMPOCO] WITH NOCHECK ADD CONSTRAINT [CK_vPMPOCO_ReadyForAcctg] CHECK (([ReadyForAcctg]='Y' OR [ReadyForAcctg]='N'))
GO
ALTER TABLE [dbo].[vPMPOCO] WITH NOCHECK ADD CONSTRAINT [DF_vPMPOCO_PO] CHECK (([PO] IS NOT NULL))
GO
ALTER TABLE [dbo].[vPMPOCO] ADD CONSTRAINT [PK_vPMPOCO] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMPOCO_POCONum] ON [dbo].[vPMPOCO] ([POCo], [PO], [POCONum]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMPOCO] WITH NOCHECK ADD CONSTRAINT [FK_vPMPOCO_bPMDT] FOREIGN KEY ([DocType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[vPMPOCO] WITH NOCHECK ADD CONSTRAINT [FK_vPMPOCO_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[vPMPOCO] WITH NOCHECK ADD CONSTRAINT [FK_vPMPOCO_bPOHD] FOREIGN KEY ([POCo], [PO]) REFERENCES [dbo].[bPOHD] ([POCo], [PO])
GO
ALTER TABLE [dbo].[vPMPOCO] WITH NOCHECK ADD CONSTRAINT [FK_vPMPOCO_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
ALTER TABLE [dbo].[vPMPOCO] NOCHECK CONSTRAINT [FK_vPMPOCO_bPMDT]
GO
ALTER TABLE [dbo].[vPMPOCO] NOCHECK CONSTRAINT [FK_vPMPOCO_bJCJM]
GO
ALTER TABLE [dbo].[vPMPOCO] NOCHECK CONSTRAINT [FK_vPMPOCO_bPOHD]
GO
ALTER TABLE [dbo].[vPMPOCO] NOCHECK CONSTRAINT [FK_vPMPOCO_bPMSC]
GO
