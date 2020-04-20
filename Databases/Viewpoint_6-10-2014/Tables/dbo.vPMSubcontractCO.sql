CREATE TABLE [dbo].[vPMSubcontractCO]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[SubCO] [smallint] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Date] [dbo].[bDate] NULL,
[Status] [dbo].[bStatus] NULL,
[Reference] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLCo] [dbo].[bCompany] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Details] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ReadyForAcctg] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPMSubcontractCO_ReadyForAcctg] DEFAULT ('N'),
[ApprovedBy] [dbo].[bVPUserName] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[DateSent] [dbo].[bDate] NULL,
[DateDueBack] [dbo].[bDate] NULL,
[DateReceived] [dbo].[bDate] NULL,
[DateApproved] [dbo].[bDate] NULL,
[DocType] [dbo].[bDocType] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMSubcontractCOd    Script Date: 09/05/2006 ******/
CREATE trigger [dbo].[btPMSubcontractCOd] on [dbo].[vPMSubcontractCO] for DELETE as
/*--------------------------------------------------------------
 * Created By:	GF 01/10/2011 - TFS #1715-TK-01997 record association
 * Modified By:	GF 04/08/2011 - TK-03189
                JayR 03/20/2012 TK-00000 Move checks to use FK constraints.
 *
 *
 * Delete trigger for vPMSubcontractCO
 *
 * bPMDH auditing
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- #134090
delete dbo.bPMSL
from dbo.bPMSL v JOIN deleted d ON d.SLCo=v.SLCo AND d.SL=v.SL AND d.SubCO=v.SubCO

---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMSubcontractCO' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMSubcontractCO' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMSubcontractCO' and i.SourceKeyId=d.KeyID

---- DELETE DISTRIBUTIONS - TK-01997
-- Now taken care of by a foreign key constraint. 

---- delete subconract CO association 
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMSubcontractCO' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT null
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMSubcontractCO' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL
				
				

---- document history (bPMDH) TK-03189
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, SLCo, SL, SubCO)
select d.PMCo, d.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY d.PMCo ASC, d.Project ASC),
		'SUBCO', NULL, ISNULL(CONVERT(VARCHAR(10),d.SubCO),''), null, getdate(), 'D', 'SubCO', ISNULL(CONVERT(VARCHAR(10),d.SubCO),''), null, SUSER_SNAME(),
		'SLCo: ' + CONVERT(VARCHAR(3),d.SLCo) + ' Subcontract: ' + ISNULL(d.SL,'') + ' SubCO: ' + ISNULL(CONVERT(VARCHAR(10),d.SubCO),'') + ' has been deleted.',
		d.SLCo, d.SL, d.SubCO
from deleted d
left join dbo.bPMDH h on h.PMCo=d.PMCo and h.Project=d.Project and h.DocCategory='SUBCO'
join dbo.bPMCO c with (nolock) on d.PMCo=c.PMCo
left join dbo.bJCJM j with (nolock) on j.JCCo=d.PMCo and j.Job=d.Project
where j.ClosePurgeFlag <> 'Y' and c.DocHistSubCO = 'Y'
group by d.PMCo, d.Project, d.SLCo, d.SL, d.SubCO


RETURN

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMSubcontractCOi    ******/
CREATE trigger [dbo].[btPMSubcontractCOi] on [dbo].[vPMSubcontractCO] for INSERT as
/*--------------------------------------------------------------
 * Created By:	GF 04/08/2011 TK-03189 TK-03589 TK-03857
 * Modified By: DAN SO 05/13/2011 - TK-05193 - Prefill PMSubcontractCO Distribution from PMSS
 *              JayR 03/20/2012 TK-00000 Move checks to use FK constraints.
 *				SCOTTP 05/03/2014 TFS-13563 Remove code that uses PMDistribution. Distribution is now managed via the form or C&S Form
 *
 *--------------------------------------------------------------*/


if @@rowcount = 0 return
set nocount on



---- assigned to a subconrract TK-03859
---- insert record association
INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
SELECT 'PMSubcontractCO', i.KeyID, 'SLHD', a.KeyID
FROM inserted i
JOIN dbo.bSLHD a ON a.SLCo=i.SLCo AND a.SL=i.SL
WHERE NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord b WHERE b.RecTableName = 'PMSubcontractCO'
				AND b.RECID=i.KeyID AND b.LinkTableName='SLHD' AND b.LINKID=a.KeyID)
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='SLHD'
				AND c.RECID=a.KeyID AND c.LinkTableName='PMSubcontractCO' AND c.LINKID=i.KeyID)


---- document history (bPMDH) TK-03857
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, SLCo, SL, SubCO)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'SUBCO', NULL, ISNULL(CONVERT(VARCHAR(10),i.SubCO),''), null, getdate(), 'A', 'SubCO', null, ISNULL(CONVERT(VARCHAR(10),i.SubCO),''), SUSER_SNAME(),
		'SLCo: ' + CONVERT(VARCHAR(3),i.SLCo) + ' Subcontract: ' + ISNULL(i.SL,'') + ' SubCO: ' + ISNULL(CONVERT(VARCHAR(10),i.SubCO),'') + ' has been added.',
		i.SLCo, i.SL, i.SubCO
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBCO'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where c.DocHistSubCO = 'Y'
group by i.PMCo, i.Project, i.KeyID, i.SLCo, i.SL, i.SubCO



RETURN







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE trigger [dbo].[btPMSubcontractCOu] on [dbo].[vPMSubcontractCO] for UPDATE as
/*--------------------------------------------------------------
 * Created By:	GF 04/09/2011 TK-03189
 * Modified By:	JayR 03/28/2012 TK-00000 Remove unused variables, switch to FKs for validation
 *
 *				
 * Validates columns and inserts document history records.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- key fields cannot be changed
IF UPDATE(PMCo) OR UPDATE(Project) OR UPDATE(SubCO)
	BEGIN
	RAISERROR('Cannot change key fields - cannot update PMSubcontractCO', 11, -1)
    ROLLBACK TRANSACTION
    RETURN
	END

---- document history updates (bPMDH) TK-03189
if update(Description)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, SLCo, SL, SubCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'SUBCO', NULL, ISNULL(CONVERT(VARCHAR(10),i.SubCO),''), null, getdate(), 'C', 'Description',
			d.Description, i.Description, SUSER_SNAME(), 'Description has been changed', i.SLCo, i.SL, i.SubCO
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.DocHistSubCO = 'Y'
	group by i.PMCo, i.Project, i.SLCo, i.SL, i.SubCO, i.Description, d.Description
	END
if update(Status)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, SLCo, SL, SubCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'SUBCO', NULL, ISNULL(CONVERT(VARCHAR(10),i.SubCO),''), null, getdate(), 'C', 'Status',
			d.Status, i.Status, SUSER_SNAME(), 'Status has been changed', i.SLCo, i.SL, i.SubCO
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and c.DocHistSubCO = 'Y'
	group by i.PMCo, i.Project, i.SLCo, i.SL, i.SubCO, i.Status, d.Status
	END
if update(Reference)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, SLCo, SL, SubCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'SUBCO', NULL, ISNULL(CONVERT(VARCHAR(10),i.SubCO),''), null, getdate(), 'C', 'Reference',
			d.Reference, i.Reference, SUSER_SNAME(), 'Reference has been changed', i.SLCo, i.SL, i.SubCO
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Reference,'') <> isnull(i.Reference,'') and c.DocHistSubCO = 'Y'
	group by i.PMCo, i.Project, i.SLCo, i.SL, i.SubCO, i.Reference, d.Reference
	END
if update(ReadyForAcctg)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, SLCo, SL, SubCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'SUBCO', NULL, ISNULL(CONVERT(VARCHAR(10),i.SubCO),''), null, getdate(), 'C', 'ReadyForAcctg',
			d.ReadyForAcctg, i.ReadyForAcctg, SUSER_SNAME(), 'ReadyForAcctg has been changed', i.SLCo, i.SL, i.SubCO
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ReadyForAcctg,'') <> isnull(i.ReadyForAcctg,'') and c.DocHistSubCO = 'Y'
	group by i.PMCo, i.Project, i.SLCo, i.SL, i.SubCO, i.ReadyForAcctg, d.ReadyForAcctg
	END
if update(Date)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, SLCo, SL, SubCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'SUBCO', NULL, ISNULL(CONVERT(VARCHAR(10),i.SubCO),''), null, getdate(), 'C', 'Date',
			CONVERT(VARCHAR(20),d.Date,112), CONVERT(VARCHAR(20),i.Date,112), SUSER_SNAME(), 'Date has been changed', i.SLCo, i.SL, i.SubCO
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Date,'') <> isnull(i.Date,'') and c.DocHistSubCO = 'Y'
	group by i.PMCo, i.Project, i.SLCo, i.SL, i.SubCO, i.Date, d.Date
	END
if update(DateSent)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, SLCo, SL, SubCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'SUBCO', NULL, ISNULL(CONVERT(VARCHAR(10),i.SubCO),''), null, getdate(), 'C', 'DateSent',
			CONVERT(VARCHAR(20),d.DateSent,112), CONVERT(VARCHAR(20),i.DateSent,112), SUSER_SNAME(), 'DateSent has been changed', i.SLCo, i.SL, i.SubCO
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateSent,'') <> isnull(i.DateSent,'') and c.DocHistSubCO = 'Y'
	group by i.PMCo, i.Project, i.SLCo, i.SL, i.SubCO, i.DateSent, d.DateSent
	END
if update(DateDueBack)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, SLCo, SL, SubCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'SUBCO', NULL, ISNULL(CONVERT(VARCHAR(10),i.SubCO),''), null, getdate(), 'C', 'DateDueBack',
			CONVERT(VARCHAR(20),d.DateDueBack,112), CONVERT(VARCHAR(20),i.DateDueBack,112), SUSER_SNAME(), 'DateDueBack has been changed', i.SLCo, i.SL, i.SubCO
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateDueBack,'') <> isnull(i.DateDueBack,'') and c.DocHistSubCO = 'Y'
	group by i.PMCo, i.Project, i.SLCo, i.SL, i.SubCO, i.DateDueBack, d.DateDueBack
	END
if update(DateReceived)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, SLCo, SL, SubCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'SUBCO', NULL, ISNULL(CONVERT(VARCHAR(10),i.SubCO),''), null, getdate(), 'C', 'DateReceived',
			CONVERT(VARCHAR(20),d.DateReceived,112), CONVERT(VARCHAR(20),i.DateReceived,112), SUSER_SNAME(), 'DateReceived has been changed', i.SLCo, i.SL, i.SubCO
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateReceived,'') <> isnull(i.DateReceived,'') and c.DocHistSubCO = 'Y'
	group by i.PMCo, i.Project, i.SLCo, i.SL, i.SubCO, i.DateReceived, d.DateReceived
	END
if update(DateApproved)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, SLCo, SL, SubCO)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'SUBCO', NULL, ISNULL(CONVERT(VARCHAR(10),i.SubCO),''), null, getdate(), 'C', 'DateApproved',
			CONVERT(VARCHAR(20),d.DateApproved,112), CONVERT(VARCHAR(20),i.DateApproved,112), SUSER_SNAME(), 'DateApproved has been changed', i.SLCo, i.SL, i.SubCO
	from inserted i join deleted d on d.KeyID=i.KeyID
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateApproved,'') <> isnull(i.DateApproved,'') and c.DocHistSubCO = 'Y'
	group by i.PMCo, i.Project, i.SLCo, i.SL, i.SubCO, i.DateApproved, d.DateApproved
	END


RETURN 





















GO
ALTER TABLE [dbo].[vPMSubcontractCO] WITH NOCHECK ADD CONSTRAINT [CK_vPMSubcontractCO_ReadyForAcctg] CHECK (([ReadyForAcctg]='Y' OR [ReadyForAcctg]='N'))
GO
ALTER TABLE [dbo].[vPMSubcontractCO] WITH NOCHECK ADD CONSTRAINT [CK_vPMSubcontractCO_SubCO] CHECK (([SubCO]>=(0)))
GO
ALTER TABLE [dbo].[vPMSubcontractCO] ADD CONSTRAINT [PK_vPMSubcontractCO] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMSubcontractCO_SubCO] ON [dbo].[vPMSubcontractCO] ([SLCo], [SL], [SubCO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMSubcontractCO] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubcontractCO_bPMDT] FOREIGN KEY ([DocType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[vPMSubcontractCO] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubcontractCO_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[vPMSubcontractCO] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubcontractCO_bSLHD] FOREIGN KEY ([SLCo], [SL]) REFERENCES [dbo].[bSLHD] ([SLCo], [SL])
GO
ALTER TABLE [dbo].[vPMSubcontractCO] WITH NOCHECK ADD CONSTRAINT [FK_vPMSubcontractCO_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
ALTER TABLE [dbo].[vPMSubcontractCO] NOCHECK CONSTRAINT [FK_vPMSubcontractCO_bPMDT]
GO
ALTER TABLE [dbo].[vPMSubcontractCO] NOCHECK CONSTRAINT [FK_vPMSubcontractCO_bJCJM]
GO
ALTER TABLE [dbo].[vPMSubcontractCO] NOCHECK CONSTRAINT [FK_vPMSubcontractCO_bSLHD]
GO
ALTER TABLE [dbo].[vPMSubcontractCO] NOCHECK CONSTRAINT [FK_vPMSubcontractCO_bPMSC]
GO
