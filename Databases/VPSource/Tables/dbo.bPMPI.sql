CREATE TABLE [dbo].[bPMPI]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[PunchList] [dbo].[bDocument] NOT NULL,
[Item] [smallint] NOT NULL,
[Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[Location] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[DueDate] [dbo].[bDate] NULL,
[FinDate] [dbo].[bDate] NULL,
[BillableYN] [dbo].[bYN] NOT NULL,
[BillableFirm] [dbo].[bFirm] NULL,
[Issue] [dbo].[bIssue] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMPI] ADD
CONSTRAINT [CK_bPMPI_BillableYN] CHECK (([BillableYN]='Y' OR [BillableYN]='N'))
ALTER TABLE [dbo].[bPMPI] ADD
CONSTRAINT [FK_bPMPI_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPId    Script Date: 8/28/99 9:37:58 AM ******/
CREATE trigger [dbo].[btPMPId] on [dbo].[bPMPI] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMPI
 * Created By: LM 1/13/98
 * Modified By:	GF 11/26/2006 - 6.x
 *				GF 02/05/2007 - issue #123699 issue history
 *				GF 01/26/2011 - tfs #398 no more issue history
 *				JayR 03/26/2012 - TK-00000 Change to us FKs for validation.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, Item)
select d.PMCo, d.Project, isnull(max(h.Seq),0)+1 + ROW_NUMBER() OVER(ORDER BY d.PMCo ASC, d.Project ASC),
		'PUNCH', null, d.PunchList, null, getdate(), 'D', 'PunchListItem', d.Item, null,
		SUSER_SNAME(), 'Punch List: ' + isnull(d.PunchList,'') + ' Item: ' + convert(varchar(10),isnull(d.Item,'')) + ' has been deleted.', d.Item
from deleted d
left join bPMDH h on h.PMCo=d.PMCo and h.Project=d.Project and h.DocCategory='PUNCH'
join bPMCO c with (nolock) on d.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=d.PMCo and j.Job=d.Project
where j.ClosePurgeFlag <> 'Y' and isnull(c.DocHistPunchList,'N') = 'Y'
group by d.PMCo, d.Project, d.PunchList, d.Item



RETURN 
   
  
 










GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPIi    Script Date: 8/28/99 9:37:58 AM ******/
CREATE  trigger [dbo].[btPMPIi] on [dbo].[bPMPI] for INSERT as
/*--------------------------------------------------------------
 *  Insert trigger for PMPI
 *  Created By:
 *  Modified By: GF 10/09/2002 - changed dbl quotes to single quotes 
 *				 GF 11/26/2006 - 6.x
 *				 GF 02/05/2007 - issue #123699 - issue history
 *				GF 10/08/2010 - issue #141648
 *				GF 01/26/2011 - tfs #398 no more issue history
 *				JayR 03/26/2012 - TK-00000 Change to use FKs for validation.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, Item)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'PUNCH', null, i.PunchList, null, getdate(), 'A', 'PunchListItem', null, i.Item, SUSER_SNAME(),
		'Punch List: ' + isnull(i.PunchList,'') + ' Item: ' + isnull(convert(varchar(8),i.Item),'') + ' has been added.', i.Item
from inserted i 
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where isnull(c.DocHistPunchList,'N') = 'Y'
group by i.PMCo, i.Project, i.PunchList, i.Item


RETURN 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPIu    Script Date: 8/28/99 9:37:58 AM ******/
CREATE  trigger [dbo].[btPMPIu] on [dbo].[bPMPI] for UPDATE as
/*--------------------------------------------------------------
 *  Update trigger for PMPI
 *  Created By: LM 1/9/98
 *  Modified By: GF 10/09/2002 - changed dbl quotes to single quotes
 *				 GF 11/26/2006 - 6.x
 *				 GF 02/07/2007 - issue #123699 issue history
  *				GF 10/08/2010 - issue #141648
 *				GF 01/26/2011 - tfs #398 no more issue history
 *				JayR 03/26/2012 - Tk-00000 Change to use FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
      begin
      RAISERROR('Cannot change PM Company - cannot update PMPI', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Project
if update(Project)
      begin
      RAISERROR('Cannot change Project - cannot update PMPI', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to PunchList
if update(PunchList)
      begin
      RAISERROR('Cannot change Punch List - cannot update PMPI', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Item
if update(Item)
      begin
      RAISERROR('Cannot change Item - cannot update PMPI', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end


---- inserts for document history
if update(Description)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PUNCH', null, i.PunchList, null, getdate(), 'C', 'Description', d.Description, i.Description,
			SUSER_SNAME(), 'Description has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PunchList=i.PunchList and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.DocHistPunchList = 'Y'
	group by i.PMCo, i.Project, i.PunchList, i.Item, i.Description, d.Description
	end
if update(DueDate)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PUNCH', null, i.PunchList, null, getdate(), 'C', 'DueDate', convert(char(8),d.DueDate,1),
			convert(char(8),i.DueDate,1), SUSER_SNAME(), 'Due Date has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PunchList=i.PunchList and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DueDate,'') <> isnull(i.DueDate,'') and c.DocHistPunchList = 'Y'
	group by i.PMCo, i.Project, i.PunchList, i.Item, i.DueDate, d.DueDate
	end
if update(FinDate)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PUNCH', null, i.PunchList, null, getdate(), 'C', 'FinDate', convert(char(8),d.FinDate,1),
			convert(char(8),i.FinDate,1), SUSER_SNAME(), 'Finish Date has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PunchList=i.PunchList and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.FinDate,'') <> isnull(i.FinDate,'') and c.DocHistTransmittal = 'Y'
	group by i.PMCo, i.Project, i.PunchList, i.Item, i.FinDate, d.FinDate
	end
if update(Location)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PUNCH', null, i.PunchList, null, getdate(), 'C', 'Location', d.Location, i.Location,
			SUSER_SNAME(), 'Location has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PunchList=i.PunchList and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Location,'') <> isnull(i.Location,'') and c.DocHistPunchList = 'Y'
	group by i.PMCo, i.Project, i.PunchList, i.Item, i.Location, d.Location
	end
if update(BillableYN)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PUNCH', null, i.PunchList, null, getdate(), 'C', 'BillableYN', d.BillableYN, i.BillableYN,
			SUSER_SNAME(), 'Billable YN has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PunchList=i.PunchList and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.BillableYN,'') <> isnull(i.BillableYN,'') and c.DocHistPunchList = 'Y'
	group by i.PMCo, i.Project, i.PunchList, i.Item, i.BillableYN, d.BillableYN
	end
if update(ResponsibleFirm)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PUNCH', null, i.PunchList, null, getdate(), 'C', 'ResponsibleFirm', convert(varchar(10),d.ResponsibleFirm),
			convert(varchar(10),i.ResponsibleFirm), SUSER_SNAME(), 'Responsible Firm has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PunchList=i.PunchList and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ResponsibleFirm,'') <> isnull(i.ResponsibleFirm,'') and c.DocHistTransmittal = 'Y'
	group by i.PMCo, i.Project, i.PunchList, i.Item, i.ResponsibleFirm, d.ResponsibleFirm
	end
if update(BillableFirm)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PUNCH', null, i.PunchList, null, getdate(), 'C', 'BillableFirm', convert(varchar(10),d.BillableFirm),
			convert(varchar(10),i.BillableFirm), SUSER_SNAME(), 'Billable Firm has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PunchList=i.PunchList and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.BillableFirm,'') <> isnull(i.BillableFirm,'') and c.DocHistTransmittal = 'Y'
	group by i.PMCo, i.Project, i.PunchList, i.Item, i.BillableFirm, d.BillableFirm
	end
if update(Issue)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PUNCH', null, i.PunchList, null, getdate(), 'C', 'Issue', convert(varchar(10),d.Issue),
			convert(varchar(10),i.Issue), SUSER_SNAME(), 'Issue has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PunchList=i.PunchList and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Issue,'') <> isnull(i.Issue,'') and c.DocHistTransmittal = 'Y'
	group by i.PMCo, i.Project, i.PunchList, i.Item, i.Issue, d.Issue
	end

RETURN 
   
   
  
 









GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMPI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMPI] ON [dbo].[bPMPI] ([PMCo], [Project], [PunchList], [Item]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO

ALTER TABLE [dbo].[bPMPI] WITH NOCHECK ADD CONSTRAINT [FK_bPMPI_bPMPL] FOREIGN KEY ([PMCo], [Project], [Location]) REFERENCES [dbo].[bPMPL] ([PMCo], [Project], [Location])
GO
ALTER TABLE [dbo].[bPMPI] WITH NOCHECK ADD CONSTRAINT [FK_bPMPI_bPMPU] FOREIGN KEY ([PMCo], [Project], [PunchList]) REFERENCES [dbo].[bPMPU] ([PMCo], [Project], [PunchList])
GO
ALTER TABLE [dbo].[bPMPI] WITH NOCHECK ADD CONSTRAINT [FK_bPMPI_bPMFM_BillableFirm] FOREIGN KEY ([VendorGroup], [BillableFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[bPMPI] WITH NOCHECK ADD CONSTRAINT [FK_bPMPI_bPMFM_ResponsibleFirm] FOREIGN KEY ([VendorGroup], [ResponsibleFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMPI].[BillableYN]'
GO
