CREATE TABLE [dbo].[vPMRFIResponse]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Seq] [bigint] NOT NULL,
[DisplayOrder] [bigint] NOT NULL,
[Send] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPMRFIResponse_Send] DEFAULT ('Y'),
[DateRequired] [dbo].[bDate] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[RespondFirm] [dbo].[bFirm] NULL,
[RespondContact] [dbo].[bEmployee] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[LastDate] [smalldatetime] NOT NULL CONSTRAINT [DF_vPMRFIResponse_LastDate] DEFAULT (getdate()),
[LastBy] [dbo].[bVPUserName] NOT NULL CONSTRAINT [DF_vPMRFIResponse_LastBy] DEFAULT (suser_sname()),
[RFIID] [bigint] NOT NULL,
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[RFIType] [dbo].[bDocType] NOT NULL,
[RFI] [dbo].[bDocument] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Status] [dbo].[bStatus] NULL,
[DateSent] [dbo].[bDate] NULL,
[ToFirm] [dbo].[bFirm] NULL,
[ToContact] [dbo].[bEmployee] NULL,
[DateReceived] [dbo].[bDate] NULL,
[Type] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPMRFIResponse_Type] DEFAULT ('Reply')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMRFIResponsed    Script Date: 8/28/99 9:38:00 AM ******/
CREATE trigger [dbo].[btPMRFIResponsed] on [dbo].[vPMRFIResponse] for DELETE as
/*--------------------------------------------------------------
 * Created By:	GF 07/25/2009
 * Modified By:  JayR 03/20/2012 TK-00000 Move checks to use FK constraints.
 *
 *
 *
 *--------------------------------------------------------------*/
if @@rowcount = 0 return
set nocount on


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType ASC),
		'RFI', i.RFIType, i.RFI, null, getdate(), 'D', 'RFI', i.RFI, null, SUSER_SNAME(),
		'RFI: ' + isnull(i.RFI,'') + ' Response Seq: ' + convert(varchar(8),isnull(i.Seq,0)) + ' has been deleted.', null
from deleted i
left join dbo.bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
join dbo.bPMCO c with (nolock) on i.PMCo=c.PMCo
left join dbo.bJCJM j with (nolock) on j.JCCo=i.PMCo and j.Job=i.Project
where j.ClosePurgeFlag <> 'Y' and  isnull(c.DocHistRFI,'N') = 'Y'
group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Seq


return



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMRFIResponsei    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMRFIResponsei] on [dbo].[vPMRFIResponse] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMRFIResponse
* Created By:	GF 07/25/2009
* Modified By:  JayR 03/20/2012 TK-00000 Move checks to use FK constraints.
*
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

-- document history (PMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType ASC),
		'RFI', i.RFIType, i.RFI, null, getdate(), 'A', 'RFI', null, i.RFI, SUSER_SNAME(),
		'RFI: ' + isnull(i.RFI,'') + ' Response Seq: ' + convert(varchar(8),isnull(i.Seq,0)) + ' has been added.'
from inserted i
left join dbo.bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
join dbo.bPMCO c with (nolock) on i.PMCo=c.PMCo
where isnull(c.DocHistRFI,'N') = 'Y'
group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Seq

RETURN

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMRFIResponseu    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMRFIResponseu] on [dbo].[vPMRFIResponse] for UPDATE as
/*--------------------------------------------------------------
* Update trigger for PMRFIResponse
* Created By:	GF 07/25/2009
* Modified By:  JayR 03/20/2012 TK-00000 Move checks to use FK constraints.
*
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- document history updates (bPMDH)
if update(DateRequired)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'DateRequired',
			convert(char(8),d.DateRequired,1), convert(char(8),i.DateRequired,1), SUSER_SNAME(),
			'RFI Response Seq: ' + convert(varchar(8),isnull(i.Seq,0)) + ' Date Required has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join dbo.bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join dbo.bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateRequired,'') <> isnull(i.DateRequired,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Seq, i.DateRequired, d.DateRequired
	end

if update(RespondFirm)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'RespondFirm',
			convert(varchar(10),d.RespondFirm), convert(varchar(10),i.RespondFirm), SUSER_SNAME(),
			'RFI Response Seq: ' + convert(varchar(8),isnull(i.Seq,0)) + ' Responding Firm has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join dbo.bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join dbo.bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.RespondFirm,0) <> isnull(i.RespondFirm,0) and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Seq, i.RespondFirm, d.RespondFirm
	end
	
if update(RespondContact)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'RespondContact',
			convert(varchar(10),d.RespondContact), convert(varchar(10),i.RespondContact), SUSER_SNAME(),
			'RFI Response Seq: ' + convert(varchar(8),isnull(i.Seq,0)) + ' Responding Contact has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join dbo.bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join dbo.bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.RespondContact,0) <> isnull(i.RespondContact,0) and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Seq, i.RespondContact, d.RespondContact
	end

if update(Notes)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'Notes',
			null, null, SUSER_SNAME(),
			'RFI Response Seq: ' + convert(varchar(8),isnull(i.Seq,0)) + ' Notes has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join dbo.bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join dbo.bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Notes,'') <> isnull(i.Notes,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Seq, i.Notes, d.Notes
	end

if update(DisplayOrder)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'DisplayOrder',
			convert(varchar(8),d.DisplayOrder), convert(varchar(8),i.DisplayOrder), SUSER_SNAME(),
			'RFI Response Seq: ' + convert(varchar(8),isnull(i.Seq,0)) + ' Display Order has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join dbo.bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join dbo.bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DisplayOrder,'') <> isnull(i.DisplayOrder,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Seq, i.DisplayOrder, d.DisplayOrder
	end

if update(Send)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'Send',
			d.Send, i.Send, SUSER_SNAME(),
			'RFI Response Seq: ' + convert(varchar(8),isnull(i.Seq,0)) + ' Send Flag has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join dbo.bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join dbo.bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Send,'') <> isnull(i.Send,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Seq, i.Send, d.Send
	end


RETURN 
GO
ALTER TABLE [dbo].[vPMRFIResponse] WITH NOCHECK ADD CONSTRAINT [CK_vPMRFIResponse_RespondContact] CHECK (([RespondContact] IS NULL OR [RespondFirm] IS NOT NULL AND [VendorGroup] IS NOT NULL))
GO
ALTER TABLE [dbo].[vPMRFIResponse] ADD CONSTRAINT [CK_vPMRFIResponse_Send] CHECK (([Send]='Y' OR [Send]='N'))
GO
ALTER TABLE [dbo].[vPMRFIResponse] ADD CONSTRAINT [PK_vPMRFIResponse] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMRFIResponse_Seq] ON [dbo].[vPMRFIResponse] ([PMCo], [Project], [RFIType], [RFI], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMRFIResponse] WITH NOCHECK ADD CONSTRAINT [FK_vPMRFIResponse_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[vPMRFIResponse] WITH NOCHECK ADD CONSTRAINT [FK_vPMRFIResponse_bPMRI] FOREIGN KEY ([RFIID]) REFERENCES [dbo].[bPMRI] ([KeyID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPMRFIResponse] WITH NOCHECK ADD CONSTRAINT [FK_vPMRFIResponse_bPMFM] FOREIGN KEY ([VendorGroup], [RespondFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[vPMRFIResponse] WITH NOCHECK ADD CONSTRAINT [FK_vPMRFIResponse_bPMPM] FOREIGN KEY ([VendorGroup], [RespondFirm], [RespondContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
