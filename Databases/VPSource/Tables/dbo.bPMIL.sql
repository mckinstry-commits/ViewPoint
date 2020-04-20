CREATE TABLE [dbo].[bPMIL]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[InspectionType] [dbo].[bDocType] NOT NULL,
[InspectionCode] [dbo].[bDocument] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Location] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[InspectionDate] [dbo].[bDate] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[InspectionFirm] [dbo].[bVendor] NULL,
[InspectionContact] [dbo].[bEmployee] NULL,
[InspectorName] [dbo].[bDesc] NULL,
[Status] [dbo].[bStatus] NULL,
[Issue] [dbo].[bIssue] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMIL] ADD
CONSTRAINT [FK_bPMIL_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************************/
CREATE trigger [dbo].[btPMILd] on [dbo].[bPMIL] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMIL
 * Created By:	GF 11/11/2006
 * Modified By:	GF 11/26/2006 6.x
 *				GF 02/05/2007 - issue #123699 issue history
 *				GF 12/21/2010 - issue #141957 record association
 *				GF 01/26/2011 - TFS #398
 *				JayR 03/22/2012 - TK-00000 Change to use FK
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMIL' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMIL' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMIL' and i.SourceKeyId=d.KeyID


---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMIL' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMIL', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Inspection Log Type: ' + ISNULL(d.InspectionType,'') + ' Inspectin Log: ' + ISNULL(d.InspectionCode,'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMIL' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMIL', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Inspection Log Type: ' + ISNULL(d.InspectionType,'') + ' Inspection Log: ' + ISNULL(d.InspectionCode,'') + ' : ' + ISNULL(d.Description,'')
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMIL' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMIL' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMIL' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL



---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.InspectionType ASC),
		'INSPECT', i.InspectionType, i.InspectionCode, null, getdate(), 'D', 'InspectionCode', i.InspectionCode, null,
		SUSER_SNAME(), 'Inspection Log: ' + isnull(i.InspectionCode,'') + ' has been deleted.', null
from deleted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='INSPECT'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=i.PMCo and j.Job=i.Project
where j.ClosePurgeFlag <> 'Y' and c.DocHistInspect = 'Y'
group by i.PMCo, i.Project, i.InspectionType, i.InspectionCode


RETURN 
   
   
  
 










GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE trigger [dbo].[btPMILi] on [dbo].[bPMIL] for INSERT as
/*--------------------------------------------------------------
 *  Insert trigger for PMIL
 *  Created By:		GF 04/17/2002
 *  Modified By:	GF 11/25/2006 6.x document history and issue history
 *					GF 10/08/2010 - issue #141648
 *					JayR 03/22/2012 - TK-00000 Change to us FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.InspectionType ASC),
		'INSPECT', i.InspectionType, i.InspectionCode, null, getdate(), 'A', 'InspectionCode', null, i.InspectionCode,
		SUSER_SNAME(), 'Inspection Log: ' + isnull(i.InspectionCode,'') + ' has been added.', null
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='INSPECT'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where c.DocHistInspect = 'Y'
group by i.PMCo, i.Project, i.InspectionType, i.InspectionCode


RETURN 
   
   
   
  
 









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************************/
CREATE trigger [dbo].[btPMILu] on [dbo].[bPMIL] for UPDATE as
/*--------------------------------------------------------------
 *	Update trigger for PMIL
 *  Created By:		GF 04/17/2002
 *  Modified By:	GF 11/26/2006 6.x
 *					GF 02/06/2007 - issue #123699 issue history
  *				GF 10/08/2010 - issue #141648
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
	begin
	RAISERROR('Cannot change PMCo - cannot update PMIL', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

---- check for changes to Project
if update(Project)
	begin
	RAISERROR('Cannot change Project - cannot update PMIL', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

---- check for changes to InspectionType
if update(InspectionType)
	begin
	RAISERROR('Cannot change Inspection Type - cannot update PMIL', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

---- check for changes to Inspection Code
if update(InspectionCode)
	begin
	RAISERROR('Cannot change Inspection Code - cannot update PMIL', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end



---- document history updates (bPMDH)
if update(Description)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.InspectionType),
			'INSPECT', i.InspectionType, i.InspectionCode, null, getdate(), 'C', 'Description',
			d.Description, i.Description, SUSER_SNAME(), 'Description has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.InspectionType=i.InspectionType and d.InspectionCode=i.InspectionCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='INSPECT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.DocHistInspect = 'Y'
	group by i.PMCo, i.Project, i.InspectionType, i.InspectionCode, i.Description, d.Description
	end
if update(Issue)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.InspectionType),
			'INSPECT', i.InspectionType, i.InspectionCode, null, getdate(), 'C', 'Issue',
			convert(varchar(8),d.Issue), convert(varchar(8),i.Issue),  SUSER_SNAME(), 'Issue has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.InspectionType=i.InspectionType and d.InspectionCode=i.InspectionCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='INSPECT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Issue,0) <> isnull(i.Issue,0) and c.DocHistInspect = 'Y'
	group by i.PMCo, i.Project, i.InspectionType, i.InspectionCode, i.Issue, d.Issue
	end
if update(InspectionDate)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.InspectionType),
			'INSPECT', i.InspectionType, i.InspectionCode, null, getdate(), 'C', 'InspectionDate',
			convert(char(8),d.InspectionDate,1), convert(char(8),i.InspectionDate,1), SUSER_SNAME(), 'Inspection Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.InspectionType=i.InspectionType and d.InspectionCode=i.InspectionCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='INSPECT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.InspectionDate,'') <> isnull(i.InspectionDate,'') and c.DocHistInspect = 'Y'
	group by i.PMCo, i.Project, i.InspectionType, i.InspectionCode, i.InspectionDate, d.InspectionDate
	end
if update(Location)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.InspectionType),
			'INSPECT', i.InspectionType, i.InspectionCode, null, getdate(), 'C', 'Location',
			d.Location, i.Location, SUSER_SNAME(), 'Location has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.InspectionType=i.InspectionType and d.InspectionCode=i.InspectionCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='INSPECT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Location,'') <> isnull(i.Location,'') and c.DocHistInspect = 'Y'
	group by i.PMCo, i.Project, i.InspectionType, i.InspectionCode, i.Location, d.Location
	end
if update(InspectorName)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.InspectionType),
			'INSPECT', i.InspectionType, i.InspectionCode, null, getdate(), 'C', 'InspectorName',
			d.InspectorName, i.InspectorName, SUSER_SNAME(), 'Inspector Name has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.InspectionType=i.InspectionType and d.InspectionCode=i.InspectionCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='INSPECT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.InspectorName,'') <> isnull(i.InspectorName,'') and c.DocHistInspect = 'Y'
	group by i.PMCo, i.Project, i.InspectionType, i.InspectionCode, i.InspectorName, d.InspectorName
	end
if update(Status)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.InspectionType),
			'INSPECT', i.InspectionType, i.InspectionCode, null, getdate(), 'C', 'Status',
			d.Status, i.Status, SUSER_SNAME(), 'Status has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.InspectionType=i.InspectionType and d.InspectionCode=i.InspectionCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='INSPECT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and c.DocHistInspect = 'Y'
	group by i.PMCo, i.Project, i.InspectionType, i.InspectionCode, i.Status, d.Status
	end
if update(InspectionFirm)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.InspectionType),
			'INSPECT', i.InspectionType, i.InspectionCode, null, getdate(), 'C', 'InspectionFirm',
			convert(varchar(10),d.InspectionFirm), convert(varchar(10),i.InspectionFirm),  SUSER_SNAME(), 'Inspection Firm has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.InspectionType=i.InspectionType and d.InspectionCode=i.InspectionCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='INSPECT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.InspectionFirm,0) <> isnull(i.InspectionFirm,0) and c.DocHistInspect = 'Y'
	group by i.PMCo, i.Project, i.InspectionType, i.InspectionCode, i.InspectionFirm, d.InspectionFirm
	end
if update(InspectionContact)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.InspectionType),
			'INSPECT', i.InspectionType, i.InspectionCode, null, getdate(), 'C', 'InspectionContact',
			convert(varchar(8),d.InspectionContact), convert(varchar(8),i.InspectionContact),  SUSER_SNAME(), 'Inspection Contact has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.InspectionType=i.InspectionType and d.InspectionCode=i.InspectionCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='INSPECT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.InspectionContact,0) <> isnull(i.InspectionContact,0) and c.DocHistInspect = 'Y'
	group by i.PMCo, i.Project, i.InspectionType, i.InspectionCode, i.InspectionContact, d.InspectionContact
	end



RETURN 
   
   
  
 












GO
ALTER TABLE [dbo].[bPMIL] WITH NOCHECK ADD CONSTRAINT [CK_bPMIL_InspectionContact] CHECK (([InspectionContact] IS NULL OR [InspectionFirm] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMIL] WITH NOCHECK ADD CONSTRAINT [CK_bPMIL_InspectionFirm] CHECK (([InspectionFirm] IS NULL OR [VendorGroup] IS NOT NULL))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMIL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMIL] ON [dbo].[bPMIL] ([PMCo], [Project], [InspectionType], [InspectionCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMIL] WITH NOCHECK ADD CONSTRAINT [FK_bPMIL_bPMDT] FOREIGN KEY ([InspectionType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO

GO
ALTER TABLE [dbo].[bPMIL] WITH NOCHECK ADD CONSTRAINT [FK_bPMIL_bPMPL] FOREIGN KEY ([PMCo], [Project], [Location]) REFERENCES [dbo].[bPMPL] ([PMCo], [Project], [Location])
GO
ALTER TABLE [dbo].[bPMIL] WITH NOCHECK ADD CONSTRAINT [FK_bPMIL_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
ALTER TABLE [dbo].[bPMIL] WITH NOCHECK ADD CONSTRAINT [FK_bPMIL_bPMFM] FOREIGN KEY ([VendorGroup], [InspectionFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[bPMIL] WITH NOCHECK ADD CONSTRAINT [FK_bPMIL_bPMPM] FOREIGN KEY ([VendorGroup], [InspectionFirm], [InspectionContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
