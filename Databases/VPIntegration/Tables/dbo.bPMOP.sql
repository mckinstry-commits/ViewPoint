CREATE TABLE [dbo].[bPMOP]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[PCOType] [dbo].[bDocType] NOT NULL,
[PCO] [dbo].[bPCO] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Issue] [dbo].[bIssue] NULL,
[Contract] [dbo].[bContract] NULL,
[PendingStatus] [tinyint] NOT NULL,
[Date1] [dbo].[bDate] NULL,
[Date2] [dbo].[bDate] NULL,
[Date3] [dbo].[bDate] NULL,
[ApprovalDate] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[IntExt] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMOP_IntExt] DEFAULT ('E'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ROMAmount] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPMOP_ROMAmount] DEFAULT ((0)),
[Details] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Reference] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InitiatedBy] [char] (1) COLLATE Latin1_General_BIN NULL,
[Priority] [tinyint] NOT NULL CONSTRAINT [DF_bPMOP_Priority] DEFAULT ((3)),
[ReasonCode] [dbo].[bReasonCode] NULL,
[BudgetType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMOP_BudgetType] DEFAULT ('N'),
[SubType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMOP_SubType] DEFAULT ('N'),
[ContractType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMOP_ContractType] DEFAULT ('N'),
[Status] [dbo].[bStatus] NULL,
[POType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMOP_POType] DEFAULT ('N'),
[ResponsiblePerson] [dbo].[bEmployee] NULL,
[DateCreated] [dbo].[bDate] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[PricingMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMOP_PricingMethod] DEFAULT ('U')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMOPd    Script Date: 8/28/99 9:37:57 AM ******/
CREATE trigger [dbo].[btPMOPd] on [dbo].[bPMOP] for DELETE as
/*--------------------------------------------------------------
 *  Delete trigger for PMOP
 *  Created By:  LM 1/13/98
 *  Modified By:	GF 06/20/2002
 *				GF 09/04/2002 - issue #18449 - delete distributions with PCO.
 *				GF 05/18/2004 - issue #24585 - delete RFQ's with PCO
 *				GF 02/05/2007 - issue #123699 issue history
 *				GF 04/24/2008 - issue #125958 delete PM distribution audit
 *				GF 12/21/2010 - issue #141957 record association
 *				GF 01/26/2011 - TFS #398
 *				JayR 03/23/2012 - TK-00000 Switch to using FKs with cascade delete for deletion
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- Check bPMOI for detail
if exists(select * from deleted d JOIN bPMOI o ON d.PMCo=o.PMCo and d.Project=o.Project and d.PCOType=o.PCOType and d.PCO=o.PCO)
   	begin
   	RAISERROR('Entries exist in PMOI - cannot delete from PMOP', 11, -1)
   	ROLLBACK TRANSACTION
   	RETURN	
   	end

---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMOP' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMOP' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMOP' and i.SourceKeyId=d.KeyID


---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMOP' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction, [Login])
SELECT x.KeyID, 'bPMOP', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'PCO Type: ' + ISNULL(d.PCOType,'') + ' PCO: ' + ISNULL(d.PCO,'') + ' : ' + ISNULL(d.Description,''), SUSER_NAME()
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMOP' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction, [Login])
SELECT x.KeyID, 'bPMOP', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'PCO Type: ' + ISNULL(d.PCOType,'') + ' PCO: ' + ISNULL(d.PCO,'') + ' : ' + ISNULL(d.Description,''), SUSER_NAME()
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMOP' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMOP' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select d.PMCo, d.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY d.PMCo ASC, d.Project ASC, d.PCOType ASC),
		'PCO', d.PCOType, d.PCO, null, getdate(), 'D', 'PCO', d.PCO, null,
		SUSER_SNAME(), 'PCO: ' + isnull(d.PCO,'') + ' has been deleted.', null
from deleted d
left join bPMDH h on h.PMCo=d.PMCo and h.Project=d.Project and h.DocCategory='PCO'
join bPMCO c with (nolock) on d.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=d.PMCo and j.Job=d.Project
where j.ClosePurgeFlag <> 'Y' and isnull(c.DocHistPCO,'N') = 'Y'
group by d.PMCo, d.Project, d.PCOType, d.PCO




RETURN
  
 









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMOPi    Script Date: 8/28/99 9:37:57 AM ******/
CREATE trigger [dbo].[btPMOPi] on [dbo].[bPMOP] for INSERT as
/*--------------------------------------------------------------
 *  Insert trigger for PMOP
 *  Created By: LM 1/13/98
 *	Modified By: GF 10/09/2002 - changed dbl quotes to single quotes
 *				 GF 08/15/2003 - issue #22169 - wrap in isnulls for bPMDH updates
 *				 GF 02/05/2007 - issue 123699 issue history
 *				GF 10/08/2010 - issue #141648
 *				GF 01/26/2011 - tfs #398 no more issue history
 *				JayR 03/23/2012 Switch to using FKs for validation
 *
 *--------------------------------------------------------------*/
declare @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
---- Validate PCO Type
select @validcnt = count(*) from bPMDT r with (nolock) JOIN inserted i ON i.PCOType = r.DocType and r.DocCategory = 'PCO'
if @validcnt <> @numrows
      begin
      RAISERROR('PCO Type is Invalid - cannot insert into PMOP', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end

---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
		'PCO', i.PCOType, i.PCO, null, getdate(), 'A', 'PCO', null, i.PCO, SUSER_SNAME(),
		'PCO: ' + isnull(i.PCO,'') + ' has been added.'
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where isnull(c.DocHistPCO,'N') = 'Y'
group by i.PMCo, i.Project, i.PCOType, i.PCO


RETURN







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMOPu    Script Date: 8/28/99 9:37:57 AM ******/
CREATE  trigger [dbo].[btPMOPu] on [dbo].[bPMOP] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMOP
 * Created By: LM 1/13/98
 * Modified By: GF 10/09/2002 - changed dbl quotes to single quotes
 *				GF 08/15/2003 - issue #22169 - wrap values in isnull for PMIH - PMDH inserts
 *				GF 01/12/2004 - issue #16548 - PCO items must be fixed = 'Y' and fixed amount = zero
 *								 for internal flag to be valid.
 *				GF 12/08/2006 - 6.x changes for document history
 *				GF 02/07/2007 - issue #123699 issue history
 *				GF 10/08/2010 - issue #141648
 *				GF 02/09/2011 - VONE - ID B-02365
 *				GP 03/12/2011 - V1# B03061 removed validation for fixed amount PCO Items, now done at form level
 *				JayR 03/23/2012 TK-00000 Switch to using FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on
   
---- check for changes to PMCo
if update(PMCo)
	begin
	RAISERROR('Cannot change PMCo - cannot update PMOP', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

---- check for changes to Project
if update(Project)
	begin
	RAISERROR('Cannot change Project - cannot update PMOP', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

---- check for changes to PCOType
if update(PCOType)
	begin
	RAISERROR('Cannot change PCO Type - cannot update PMOP', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

---- check for changes to PCO
if update(PCO)
	begin
	RAISERROR('Cannot change PCO - cannot update PMOP', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

---- document history updates (bPMDH)
if update(Description)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Description',
			d.Description, i.Description, SUSER_SNAME(), 'Description has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.Description, d.Description
	end

if update(Date1)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Date1',
			convert(char(8),d.Date1,1), convert(char(8),i.Date1,1), SUSER_SNAME(), 'Date1 has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Date1,'') <> isnull(i.Date1,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.Date1, d.Date1
	end
if update(Date2)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Date2',
			convert(char(8),d.Date2,1), convert(char(8),i.Date2,1), SUSER_SNAME(), 'Date2 has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Date2,'') <> isnull(i.Date2,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.Date2, d.Date2
	end
if update(Date3)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Date3',
			convert(char(8),d.Date3,1), convert(char(8),i.Date3,1), SUSER_SNAME(), 'Date3 has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Date3,'') <> isnull(i.Date3,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.Date3, d.Date3
	end
if update(IntExt)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'IntExt',
			d.IntExt, i.IntExt, SUSER_SNAME(), 'IntExt Flag has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.IntExt,'') <> isnull(i.IntExt,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.IntExt, d.IntExt
	end
----B-02365
if update(Reference)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Reference',
			d.Reference, i.Reference, SUSER_SNAME(), 'Reference has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Reference,'') <> isnull(i.Reference,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.Reference, d.Reference
	end
if update(InitiatedBy)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'InitiatedBy',
			d.InitiatedBy, i.InitiatedBy, SUSER_SNAME(), 'InitiatedBy has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.InitiatedBy,'') <> isnull(i.InitiatedBy,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.InitiatedBy, d.InitiatedBy
	end
if update(Priority)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Priority',
			CONVERT(VARCHAR(6),d.Priority), CONVERT(VARCHAR(6),i.Priority), SUSER_SNAME(), 'Priority has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Priority,'') <> isnull(i.Priority,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.Priority, d.Priority
	end
if update(ReasonCode)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'ReasonCode',
			d.ReasonCode, i.ReasonCode, SUSER_SNAME(), 'ReasonCode has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ReasonCode,'') <> isnull(i.ReasonCode,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.ReasonCode, d.ReasonCode
	end
if update(BudgetType)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'BudgetType',
			d.BudgetType, i.BudgetType, SUSER_SNAME(), 'BudgetType has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.BudgetType,'') <> isnull(i.BudgetType,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.BudgetType, d.BudgetType
	end
if update(SubType)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'SubType',
			d.SubType, i.SubType, SUSER_SNAME(), 'SubType has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.SubType,'') <> isnull(i.SubType,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.SubType, d.SubType
	end
if update(ContractType)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'ContractType',
			d.ContractType, i.ContractType, SUSER_SNAME(), 'ContractType has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ContractType,'') <> isnull(i.ContractType,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.ContractType, d.ContractType
	end
if update(POType)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'POType',
			d.POType, i.POType, SUSER_SNAME(), 'POType has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.POType,'') <> isnull(i.POType,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.POType, d.POType
	END
if update(Status)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Status',
			d.Status, i.Status, SUSER_SNAME(), 'Status has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.Status, d.Status
	END
	


RETURN 
   
   
  
 














GO
ALTER TABLE [dbo].[bPMOP] ADD CONSTRAINT [CK_bPMOP_BudgetType] CHECK (([BudgetType]='N' OR [BudgetType]='Y'))
GO
ALTER TABLE [dbo].[bPMOP] WITH NOCHECK ADD CONSTRAINT [CK_bPMOP_Contract] CHECK (([Contract] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMOP] ADD CONSTRAINT [CK_bPMOP_ContractType] CHECK (([ContractType]='N' OR [ContractType]='Y'))
GO
ALTER TABLE [dbo].[bPMOP] ADD CONSTRAINT [CK_bPMOP_POType] CHECK (([POType]='N' OR [POType]='Y'))
GO
ALTER TABLE [dbo].[bPMOP] ADD CONSTRAINT [CK_bPMOP_PricingMethod] CHECK (([PricingMethod]='L' OR [PricingMethod]='U'))
GO
ALTER TABLE [dbo].[bPMOP] ADD CONSTRAINT [CK_bPMOP_Priority] CHECK (([Priority]=(4) OR [Priority]=(3) OR [Priority]=(2) OR [Priority]=(1)))
GO
ALTER TABLE [dbo].[bPMOP] ADD CONSTRAINT [CK_bPMOP_SubType] CHECK (([SubType]='N' OR [SubType]='Y'))
GO
ALTER TABLE [dbo].[bPMOP] ADD CONSTRAINT [PK_bPMOP] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMOP] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMOP] ON [dbo].[bPMOP] ([PMCo], [Project], [PCOType], [PCO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMOP] WITH NOCHECK ADD CONSTRAINT [FK_bPMOP_bPMDT] FOREIGN KEY ([PCOType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[bPMOP] WITH NOCHECK ADD CONSTRAINT [FK_bPMOP_bJCCM] FOREIGN KEY ([PMCo], [Contract]) REFERENCES [dbo].[bJCCM] ([JCCo], [Contract])
GO
ALTER TABLE [dbo].[bPMOP] WITH NOCHECK ADD CONSTRAINT [FK_bPMOP_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[bPMOP] WITH NOCHECK ADD CONSTRAINT [FK_bPMOP_bHQRC] FOREIGN KEY ([ReasonCode]) REFERENCES [dbo].[bHQRC] ([ReasonCode])
GO
ALTER TABLE [dbo].[bPMOP] WITH NOCHECK ADD CONSTRAINT [FK_bPMOP_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
