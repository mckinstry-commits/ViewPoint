CREATE TABLE [dbo].[bPMTL]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[TestType] [dbo].[bDocType] NOT NULL,
[TestCode] [dbo].[bDocument] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Location] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[TestDate] [dbo].[bDate] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[TestFirm] [dbo].[bVendor] NULL,
[TestContact] [dbo].[bEmployee] NULL,
[TesterName] [dbo].[bDesc] NULL,
[Status] [dbo].[bStatus] NULL,
[Issue] [dbo].[bIssue] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMOPd    Script Date: 11/07/2006 ******/
CREATE trigger [dbo].[btPMTLd] on [dbo].[bPMTL] for DELETE as
/*--------------------------------------------------------------
 *  Delete trigger for PMTL
 *  Created By:		GF 11/07/2006
 *  Modified By:	GF 02/01/2007 - issue #123699 issue history
 *					GF 12/21/2010 - issue #141957 record association
 *					GF 01/26/2011 - TFS #398
 *					JayR 03/28/2012 Tk-00000 Change to use FK with delete cascade for part of this
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMTL' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMTL' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMTL' and i.SourceKeyId=d.KeyID

---- #134090
-- Now taken care of with a FK with delete cascade

---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMTL' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMTL', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Test Log Type: ' + ISNULL(d.TestType,'') + ' Test Log: ' + ISNULL(d.TestCode,'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMTL' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMTL', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Test Log Type: ' + ISNULL(d.TestType,'') + ' Test Log: ' + ISNULL(d.TestCode,'') + ' : ' + ISNULL(d.Description,'')
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMTL' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMTL' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMTL' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.TestType ASC),
		'TEST', i.TestType, i.TestCode, null, getdate(), 'D', 'TestCode', i.TestCode, null,
		SUSER_SNAME(), 'Test Log: ' + isnull(i.TestCode,'') + ' has been deleted.', null
from deleted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TEST'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=i.PMCo and j.Job=i.Project
where j.ClosePurgeFlag <> 'Y' and isnull(c.DocHistTestLog,'N') = 'Y'
group by i.PMCo, i.Project, i.TestType, i.TestCode




RETURN 
   
   
  
 









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************************/
CREATE trigger [dbo].[btPMTLi] on [dbo].[bPMTL] for INSERT as
/*--------------------------------------------------------------
 *  Insert trigger for PMTL
 *  Created By:		GF 11/07/2006
 *  Modified By:	GF 02/01/2007 - issue #123699 issue history
 *					GF 10/08/2010 - issue #141648
 *					GF 01/26/2011 - tfs #398
 *					JayR 03/28/2012 TK-00000 Switch to using FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.TestType ASC),
		'TEST', i.TestType, i.TestCode, null, getdate(), 'A', 'TestCode', null, i.TestCode,
		SUSER_SNAME(), 'Test Log: ' + isnull(i.TestCode,'') + ' has been added.', null
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TEST'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where isnull(c.DocHistTestLog,'N') = 'Y'
group by i.PMCo, i.Project, i.TestType, i.TestCode


RETURN 
   
  
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************************/
CREATE trigger [dbo].[btPMTLu] on [dbo].[bPMTL] for UPDATE as
/*--------------------------------------------------------------
 *	Update trigger for PMIL
 *  Created By:		GF 11/07/2006
 *  Modified By:	GF 02/06/2007 - issue #123699 issue history
 *				GF 10/08/2010 - issue #141648
 *				JayR 03/28/2012 TK-00000 Change to use FKs for validation.  				
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
      begin
      RAISERROR('Cannot change PMCo - cannot update PMTL', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Project
if update(Project)
      begin
      RAISERROR('Cannot change Project - cannot update PMTL', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to TestType
if update(TestType)
      begin
      RAISERROR('Cannot change Test Type - cannot update PMTL', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Test Code
if update(TestCode)
      begin
      RAISERROR('Cannot change Test Code - cannot update PMTL', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- document history updates (bPMDH)
if update(Description)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.TestType),
			'TEST', i.TestType, i.TestCode, null, getdate(), 'C', 'Description',
			d.Description, i.Description, SUSER_SNAME(), 'Description has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.TestType=i.TestType and d.TestCode=i.TestCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TEST'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and isnull(c.DocHistTestLog,'N') = 'Y'
	group by i.PMCo, i.Project, i.TestType, i.TestCode, i.Description, d.Description
	end
if update(Issue)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.TestType),
			'TEST', i.TestType, i.TestCode, null, getdate(), 'C', 'Issue',
			convert(varchar(8),d.Issue), convert(varchar(8),i.Issue),  SUSER_SNAME(), 'Issue has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.TestType=i.TestType and d.TestCode=i.TestCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TEST'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Issue,0) <> isnull(i.Issue,0) and isnull(c.DocHistTestLog,'N') = 'Y'
	group by i.PMCo, i.Project, i.TestType, i.TestCode, i.Issue, d.Issue
	end
if update(TestDate)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.TestType),
			'TEST', i.TestType, i.TestCode, null, getdate(), 'C', 'TestDate',
			convert(char(8),d.TestDate,1), convert(char(8),i.TestDate,1), SUSER_SNAME(), 'Test Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.TestType=i.TestType and d.TestCode=i.TestCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TEST'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.TestDate,'') <> isnull(i.TestDate,'') and isnull(c.DocHistTestLog,'N') = 'Y'
	group by i.PMCo, i.Project, i.TestType, i.TestCode, i.TestDate, d.TestDate
	end
if update(Location)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.TestType),
			'TEST', i.TestType, i.TestCode, null, getdate(), 'C', 'Location',
			d.Location, i.Location, SUSER_SNAME(), 'Location has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.TestType=i.TestType and d.TestCode=i.TestCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TEST'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Location,'') <> isnull(i.Location,'') and isnull(c.DocHistTestLog,'N') = 'Y'
	group by i.PMCo, i.Project, i.TestType, i.TestCode, i.Location, d.Location
	end
if update(TesterName)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.TestType),
			'TEST', i.TestType, i.TestCode, null, getdate(), 'C', 'TesterName',
			d.TesterName, i.TesterName, SUSER_SNAME(), 'Tester Name has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.TestType=i.TestType and d.TestCode=i.TestCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TEST'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.TesterName,'') <> isnull(i.TesterName,'') and isnull(c.DocHistTestLog,'N') = 'Y'
	group by i.PMCo, i.Project, i.TestType, i.TestCode, i.TesterName, d.TesterName
	end
if update(Status)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.TestType),
			'TEST', i.TestType, i.TestCode, null, getdate(), 'C', 'Status',
			d.Status, i.Status, SUSER_SNAME(), 'Status has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.TestType=i.TestType and d.TestCode=i.TestCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TEST'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and isnull(c.DocHistTestLog,'N') = 'Y'
	group by i.PMCo, i.Project, i.TestType, i.TestCode, i.Status, d.Status
	end
if update(TestFirm)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.TestType),
			'TEST', i.TestType, i.TestCode, null, getdate(), 'C', 'TestFirm',
			convert(varchar(10),d.TestFirm), convert(varchar(10),i.TestFirm),  SUSER_SNAME(), 'Test Firm has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.TestType=i.TestType and d.TestCode=i.TestCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TEST'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.TestFirm,0) <> isnull(i.TestFirm,0) and isnull(c.DocHistTestLog,'N') = 'Y'
	group by i.PMCo, i.Project, i.TestType, i.TestCode, i.TestFirm, d.TestFirm
	end
if update(TestContact)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.TestType),
			'TEST', i.TestType, i.TestCode, null, getdate(), 'C', 'TestContact',
			convert(varchar(8),d.TestContact), convert(varchar(8),i.TestContact),  SUSER_SNAME(), 'Test Contact has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.TestType=i.TestType and d.TestCode=i.TestCode
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TEST'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.TestContact,0) <> isnull(i.TestContact,0) and isnull(c.DocHistTestLog,'N') = 'Y'
	group by i.PMCo, i.Project, i.TestType, i.TestCode, i.TestContact, d.TestContact
	end




RETURN 
   
   
  
 












GO
ALTER TABLE [dbo].[bPMTL] WITH NOCHECK ADD CONSTRAINT [CK_bPMTL_TestContact] CHECK (([TestContact] IS NULL OR [TestFirm] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMTL] WITH NOCHECK ADD CONSTRAINT [CK_bPMTL_TestFirm] CHECK (([TestFirm] IS NULL OR [VendorGroup] IS NOT NULL))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMTL] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMTL] ON [dbo].[bPMTL] ([PMCo], [Project], [TestType], [TestCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMTL] WITH NOCHECK ADD CONSTRAINT [FK_bPMTL_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[bPMTL] WITH NOCHECK ADD CONSTRAINT [FK_bPMTL_bPMPL] FOREIGN KEY ([PMCo], [Project], [Location]) REFERENCES [dbo].[bPMPL] ([PMCo], [Project], [Location])
GO
ALTER TABLE [dbo].[bPMTL] WITH NOCHECK ADD CONSTRAINT [FK_bPMTL_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
ALTER TABLE [dbo].[bPMTL] WITH NOCHECK ADD CONSTRAINT [FK_bPMTL_bPMDT] FOREIGN KEY ([TestType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[bPMTL] WITH NOCHECK ADD CONSTRAINT [FK_bPMTL_bPMFM] FOREIGN KEY ([VendorGroup], [TestFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[bPMTL] WITH NOCHECK ADD CONSTRAINT [FK_bPMTL_bPMPM] FOREIGN KEY ([VendorGroup], [TestFirm], [TestContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
