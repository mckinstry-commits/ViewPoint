CREATE TABLE [dbo].[bPMSM]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Submittal] [dbo].[bDocument] NOT NULL,
[SubmittalType] [dbo].[bDocType] NOT NULL,
[Rev] [tinyint] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[Issue] [dbo].[bIssue] NULL,
[Status] [dbo].[bStatus] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[ResponsiblePerson] [dbo].[bEmployee] NULL,
[SubFirm] [dbo].[bFirm] NULL,
[SubContact] [dbo].[bEmployee] NULL,
[ArchEngFirm] [dbo].[bFirm] NULL,
[ArchEngContact] [dbo].[bEmployee] NULL,
[DateReqd] [dbo].[bDate] NULL,
[DateRecd] [dbo].[bDate] NULL,
[ToArchEng] [dbo].[bDate] NULL,
[DueBackArch] [dbo].[bDate] NULL,
[RecdBackArch] [dbo].[bDate] NULL,
[DateRetd] [dbo].[bDate] NULL,
[ActivityDate] [dbo].[bDate] NULL,
[CopiesRecd] [tinyint] NULL,
[CopiesSent] [tinyint] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[CopiesReqd] [tinyint] NULL,
[CopiesRecdArch] [tinyint] NULL,
[CopiesSentArch] [tinyint] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[SpecNumber] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Seq] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPMSM] ON [dbo].[bPMSM] ([PMCo], [Project], [Submittal], [SubmittalType], [Rev]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMSM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMSM] WITH NOCHECK ADD
CONSTRAINT [FK_bPMSM_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
ALTER TABLE [dbo].[bPMSM] WITH NOCHECK ADD
CONSTRAINT [FK_bPMSM_bPMDT] FOREIGN KEY ([SubmittalType]) REFERENCES [dbo].[bPMDT] ([DocType])
ALTER TABLE [dbo].[bPMSM] WITH NOCHECK ADD
CONSTRAINT [FK_bPMSM_bPMFM_ArchEngFirm] FOREIGN KEY ([VendorGroup], [ArchEngFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
ALTER TABLE [dbo].[bPMSM] WITH NOCHECK ADD
CONSTRAINT [FK_bPMSM_bPMFM_SubFirm] FOREIGN KEY ([VendorGroup], [SubFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
ALTER TABLE [dbo].[bPMSM] WITH NOCHECK ADD
CONSTRAINT [FK_bPMSM_bPMPM_ArchEngContact] FOREIGN KEY ([VendorGroup], [ArchEngFirm], [ArchEngContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
ALTER TABLE [dbo].[bPMSM] WITH NOCHECK ADD
CONSTRAINT [FK_bPMSM_bPMPM_ResponsiblePerson] FOREIGN KEY ([VendorGroup], [ResponsibleFirm], [ResponsiblePerson]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
ALTER TABLE [dbo].[bPMSM] WITH NOCHECK ADD
CONSTRAINT [FK_bPMSM_bPMPM_SubContact] FOREIGN KEY ([VendorGroup], [SubFirm], [SubContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
ALTER TABLE [dbo].[bPMSM] WITH NOCHECK ADD
CONSTRAINT [FK_bPMSM_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/********************************************************/
CREATE   trigger [dbo].[btPMSMd] on [dbo].[bPMSM] for DELETE as
/*--------------------------------------------------------------
 * Created By:	GF 03/16/2002
 * Modified By:	GF 10/12/2006 - changes for 6.x PMDH document history.
 *				GF 02/01/2007 - issue #123699 issue history
 *				GF 04/24/2008 - issue #125958 delete PM distribution audit
 *				GF 09/02/2008 - issue #129637
 *				GF 10/22/2009 - issue #134090 delete PM Distribution rows
 *				GF 12/21/2010 - issue #141957 record association
 *				GF 01/26/2011 - TFS #398
 *
 *
 * Removes submittal items from PMSI also. Cascade delete.
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- delete submittal items in PMSI
--select @validcnt = count(*) from deleted d JOIN bPMSI a ON a.PMCo=d.PMCo and a.Project=d.Project
--   		and a.SubmittalType=d.SubmittalType and a.Submittal=d.Submittal and a.Rev=d.Rev
--if @validcnt <> 0
--   	begin
--   	delete bPMSI from bPMSI a JOIN deleted d ON a.PMCo=d.PMCo and a.Project=d.Project
--   	and a.SubmittalType=d.SubmittalType and a.Submittal=d.Submittal and a.Rev=d.Rev
--   	end

------ Check bPMSI for submittal items
--if exists(select * from deleted d JOIN bPMSI o ON d.PMCo=o.PMCo and d.Project=o.Project
--		and d.SubmittalType=o.SubmittalType and d.Submittal=o.Submittal and d.Rev=o.Rev)
--	begin
--	select @errmsg = 'Entries exist in PMSI'
--	goto error
--	end

---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMSM' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMSM' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMSM' and i.SourceKeyId=d.KeyID

------ #134090
--delete dbo.vPMDistribution
--from dbo.vPMDistribution v JOIN deleted d ON d.KeyID=v.SubmittalID


---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMSM' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMSM', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Submittal Type: ' + ISNULL(d.SubmittalType,'') + ' Submittal: ' + ISNULL(d.Submittal,'') + ' Revision: ' + ISNULL(CONVERT(VARCHAR(5),d.Rev),'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMSM' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMSM', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Submittal Type: ' + ISNULL(d.SubmittalType,'') + ' Submittal: ' + ISNULL(d.Submittal,'') + ' Revision: ' + ISNULL(CONVERT(VARCHAR(5),d.Rev),'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMSM' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMSM' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMSM' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType ASC),
		'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'D', 'Submittal', i.Submittal, null,
		SUSER_SNAME(), 'Submittal: ' + isnull(i.Submittal,'') + ' has been deleted.', null
from deleted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=i.PMCo and j.Job=i.Project
where j.ClosePurgeFlag <> 'Y' and c.DocHistSubmittal = 'Y'
group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev



RETURN 
   
   
  
 










GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMSMi    Script Date: 8/28/99 9:38:02 AM ******/
CREATE trigger [dbo].[btPMSMi] on [dbo].[bPMSM] for INSERT as
/*--------------------------------------------------------------
 *  Created By:		LM 07/08/1999
 *  Modified By:	GF 03/23/2000
 *					GF 03/16/2002 - Initialize items if revision > 0, use previous revision
 *					GF 10/12/2006 - changes for 6.x PMDH document history.
 *					GF 02/01/2007 - issue #123699 issue history
 *					GF 09/02/2008 - issue #129637
 *					GF 10/22/2009 - issue #134090 insert issue and specnumber into PMSI
 *					GF 10/08/2010 - issue #141648
 *					GF 01/26/2011 - tfs #398
 *					JayR 03/27/2012 TK-00000 Switch to using FKs for validation
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @rcode int, @validcnt int, @validcnt2 int,
		@pmco bCompany, @project bJob, @submittaltype bDocType, @submittal bDocument,
		@rev tinyint, @phasegroup bGroup, @phase bPhase, @initrev tinyint,
		@initstatus bStatus, @opencursor int, @archengfirm int, @subfirm int,
		@archengcontact int, @subcontact int, @pmsm_keyid bigint, @datesent bDate,
		@vendorgroup bGroup, @toarcheng bDate

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @rcode = 0, @opencursor = 0, @datesent = dbo.vfDateOnly()

---- cursor to initialize items if needed
if @numrows = 1
	begin
	select @pmco=PMCo, @project=Project, @submittaltype=SubmittalType, @submittal=Submittal,
			@rev=Rev, @phasegroup=PhaseGroup, @phase=Phase, @subfirm=SubFirm, @subcontact=SubContact,
			@archengfirm=ArchEngFirm, @archengcontact=ArchEngContact, @pmsm_keyid=KeyID,
			@vendorgroup=VendorGroup, @toarcheng=ToArchEng
	from inserted
	end
else
	begin
	---- use a cursor to process each inserted row
	declare bPMSM_insert cursor LOCAL FAST_FORWARD
	for select PMCo, Project, SubmittalType, Submittal, Rev, PhaseGroup, Phase, SubFirm, SubContact,
			ArchEngFirm, ArchEngContact, KeyID, VendorGroup, ToArchEng
	from inserted

   	open bPMSM_insert
   	select @opencursor = 1
   	
   	fetch next from bPMSM_insert into @pmco, @project, @submittaltype, @submittal, @rev, @phasegroup,
   			@phase, @subfirm, @subcontact, @archengfirm, @archengcontact, @pmsm_keyid, @vendorgroup,
   			@toarcheng
   	
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end


insert_check:

---- validate phase
if isnull(@phase,'') <> ''
	begin
	---- validate standard phase - if it doesnt exist in JCJP try to add it
	exec @rcode = bspJCADDPHASE @pmco, @project, @phasegroup, @phase,'Y', null, @errmsg output
	if @rcode <> 0
		begin
		select @errmsg = @errmsg + ' - Error adding phase to job phases.'
		goto error
		End
	End

---- create distribution row for sub firm contact if not null
if @subfirm is not null and @subcontact is not null
	begin
	exec @rcode = dbo.vspPMDistSubmittalInit @pmco, @project, @submittaltype, @submittal, @rev,
				@subfirm, @subcontact, @datesent, null, @pmsm_keyid, @errmsg output
	if @rcode <> 0
		begin
		select @errmsg = @errmsg + ' - Error adding subcontract firm contact to distribution table.'
		goto error
		End
	---- initialize project firm record
	exec @rcode = dbo.bspPMPFirmContactDistAdd @pmco, @project, @vendorgroup, @subfirm, @subcontact, @errmsg output
	end

---- create distribution row for architect engineer firm contact if not null
if @archengfirm is not null and @archengcontact is not null
	begin
	if @toarcheng is null set @toarcheng = @datesent
	exec @rcode = dbo.vspPMDistSubmittalInit @pmco, @project, @submittaltype, @submittal, @rev,
				@archengfirm, @archengcontact, @toarcheng, null, @pmsm_keyid, @errmsg output
	if @rcode <> 0
		begin
		select @errmsg = @errmsg + ' - Error adding architect engineer firm contact to distribution table.'
		goto error
		End
	---- initialize project firm record
	exec @rcode = dbo.bspPMPFirmContactDistAdd @pmco, @project, @vendorgroup, @archengfirm, @archengcontact, @errmsg output
	end


---- if revision > 0 insert items from revision - 1 with status not final
---- into PMSI for this submittal - revision
if @rev > 0
	begin
	select @initrev = max(Rev) from bPMSM WITH (NOLOCK)
	where PMCo=@pmco and Project=@project and SubmittalType=@submittaltype
	and Submittal=@submittal and Rev<@rev
	if @@rowcount <> 0 and isnull(@initrev,@rev) <> @rev
		begin
		---- insert submittal items records into PMSI #134090
		insert into bPMSI (PMCo, Project, Submittal, SubmittalType, Rev, Item, Description, Status,
   				Send, DateReqd, DateRecd, ToArchEng, DueBackArch, RecdBackArch, DateRetd,
   				ActivityDate, CopiesRecd, CopiesSent, CopiesReqd, CopiesRecdArch, CopiesSentArch,
   				Notes, Issue, SpecNumber, ChangedFromPMSM)
		select @pmco, @project, @submittal, @submittaltype, @rev, a.Item, a.Description, b.Status,
   				a.Send, b.DateReqd, b.DateRecd, b.ToArchEng, b.DueBackArch, b.RecdBackArch, b.DateRetd,
   				b.ActivityDate, b.CopiesRecd, b.CopiesSent, b.CopiesReqd, b.CopiesRecdArch, b.CopiesSentArch,
   				a.Notes, b.Issue, b.SpecNumber, 'Y'
    	from bPMSI a join bPMSM b ON b.PMCo=a.PMCo and b.Project=a.Project and b.SubmittalType=a.SubmittalType
		and b.Submittal=a.Submittal and b.Rev=@rev
		left join bPMSC c ON c.Status=a.Status
		where a.PMCo=@pmco and a.Project=@project and a.SubmittalType=@submittaltype 
		and a.Submittal=@submittal and a.Rev=@initrev and c.CodeType <> 'F'
		and not exists(select d.PMCo from bPMSI d where d.PMCo=@pmco and d.Project=@project
				and d.SubmittalType=@submittaltype and d.Submittal=@submittal and d.Rev=@rev)
				
		---- after insert update items and set ChangedFromPMSM back to 'N'
		update dbo.bPMSI set ChangedFromPMSM = 'N'
		from dbo.bPMSI a where a.PMCo=@pmco and a.Project=@project and a.SubmittalType=@submittaltype 
				and a.Submittal=@submittal and a.Rev=@initrev
		end
	end


if @numrows > 1
   	begin
   	fetch next from bPMSM_insert into @pmco, @project, @submittaltype, @submittal, @rev, @phasegroup,
   			@phase, @subfirm, @subcontact, @archengfirm, @archengcontact, @pmsm_keyid, @vendorgroup,
   			@toarcheng
	if @@fetch_status = 0
		begin
		goto insert_check
		end
	else
		begin
		close bPMSM_insert
		deallocate bPMSM_insert
   		select @opencursor = 0
		end
	end



---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType ASC),
		'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'A', 'Submittal', null, i.Submittal, SUSER_SNAME(),
		'Submittal: ' + isnull(i.Submittal,'') + ' has been added.'
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where c.DocHistSubmittal = 'Y'
group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev



return




error:
	if @opencursor = 1
		begin
		close bPMSM_insert
		deallocate bPMSM_insert
   		select @opencursor = 0
		end
	select @errmsg = @errmsg + ' - cannot insert PMSM'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE trigger [dbo].[btPMSMu] on [dbo].[bPMSM] for UPDATE as
/*--------------------------------------------------------------
 * Created By:	LM 01/20/1998
 * Modified By:	GF 03/23/2000
 *				RT 11/24/2003, Issue #23101, added isnull() for contact or resp. person updates to PMIH/PMDH.
 *				GF 02/06/2007 - issue #123699 issue history
 *				GF 03/21/2008 - issue #127547 changed logic for updating submittal items (PMSI)
 *				GF 09/02/2008 - issue #129637
 *				GF 10/23/2009 - issue #134090 - update issue and spec number to items when old match
  *				GF 10/08/2010 - issue #141648
 *				GF 01/26/2011 - tfs #398
 *				JayR 03/27/2012 TK-00000 Switch to using FKs for validation.
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @rcode int, @validcnt int, @validcnt2 int,
		@opencursor int, @pmco bCompany, @project bJob, @phasegroup bGroup, @phase bPhase,
		@submittaltype bDocType, @submittal bDocument, @rev tinyint, 
		@archengfirm int, @subfirm int, @archengcontact int, @subcontact int,
		@oldarchengfirm int, @oldsubfirm int, @oldarchengcontact int, @oldsubcontact int,
		@pmsm_keyid bigint, @datesent bDate, @vendorgroup bGroup, @toarcheng bDate

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @rcode = 0, @opencursor = 0, @datesent = getdate()

---- check for changes to PMCo
if update(PMCo)
      begin
      select @errmsg = 'Cannot change PMCo'
      goto error
      end

---- check for changes to Project
if update(Project)
      begin
      select @errmsg = 'Cannot change Project'
      goto error
      end

---- check for changes to SubmittalType
if update(SubmittalType)
      begin
      select @errmsg = 'Cannot change SubmittalType'
      goto error
      end

---- check for changes to Submittal
if update(Submittal)
      begin
      select @errmsg = 'Cannot change Submittal'
      goto error
      end

---- check for changes to Rev
if update(Rev)
      begin
      select @errmsg = 'Cannot change Rev'
      goto error
      end

---- cursor to validate/add phase if needed
if @numrows = 1
	begin
   	select @pmco=i.PMCo, @project=i.Project, @submittaltype=i.SubmittalType, @submittal=i.Submittal,
   			@rev=i.Rev, @phasegroup=i.PhaseGroup, @phase=i.Phase, @vendorgroup=i.VendorGroup,
   			@subfirm=i.SubFirm, @subcontact=i.SubContact, @oldsubfirm=d.SubFirm,
   			@oldsubcontact=d.SubContact, @archengfirm=i.ArchEngFirm, @archengcontact=i.ArchEngContact,
   			@oldarchengfirm=d.ArchEngFirm, @oldarchengcontact=d.ArchEngContact, @pmsm_keyid=i.KeyID,
   			@toarcheng=i.ToArchEng
	from inserted i join deleted d on i.KeyID=d.KeyID
	end
else
	begin
	---- use a cursor to process each inserted row
   	declare bPMSM_update cursor LOCAL FAST_FORWARD for select
   			i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.PhaseGroup, i.Phase,
   			i.SubFirm, i.SubContact, i.ArchEngFirm, i.ArchEngContact, i.KeyID, d.SubFirm,
   			d.SubContact, d.ArchEngFirm, d.ArchEngContact, i.VendorGroup, i.ToArchEng
   	from inserted i join deleted d on i.KeyID=d.KeyID

   	open bPMSM_update
   	select @opencursor = 1

	fetch next from bPMSM_update into @pmco, @project, @submittaltype, @submittal, @rev, @phasegroup, @phase,
			@subfirm, @subcontact, @archengfirm, @archengcontact, @pmsm_keyid, @oldsubfirm,
			@oldsubcontact, @oldarchengfirm, @oldarchengcontact, @vendorgroup, @toarcheng
	if @@fetch_status <> 0
		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
	end


update_check:
---- validate phase
if update(Phase)
	begin
	if isnull(@phase,'') <> ''
		begin
		---- validate standard phase - if it doesnt exist in JCJP try to add it
		exec @rcode = bspJCADDPHASE @pmco, @project, @phasegroup, @phase, 'Y', null, @errmsg output
		if @rcode <> 0
			begin
			select @errmsg = @errmsg + ' - Error adding phase to job phases.'
			goto error
			end
		end
	end

---- create distribution row for sub firm contact if not null
if @subfirm is not null and @subcontact is not null
	begin
	if isnull(@oldsubfirm,'') <> @subfirm or isnull(@oldsubcontact,'') <> @subcontact
		begin
		exec @rcode = dbo.vspPMDistSubmittalInit @pmco, @project, @submittaltype, @submittal, @rev,
					@subfirm, @subcontact, @datesent, null, @pmsm_keyid, @errmsg output
		if @rcode <> 0
			begin
			select @errmsg = @errmsg + ' - Error adding subcontract firm contact to distribution table.'
			goto error
			End
		---- initialize project firm record
		exec @rcode = dbo.bspPMPFirmContactDistAdd @pmco, @project, @vendorgroup, @subfirm, @subcontact, @errmsg output
		end
	end

---- create distribution row for architect engineer firm contact if not null
if @archengfirm is not null and @archengcontact is not null
	begin
	if isnull(@oldarchengfirm,'') <> @archengfirm or isnull(@oldarchengcontact,'') <> @archengcontact
		begin
		if @toarcheng is null set @toarcheng = @datesent
		exec @rcode = dbo.vspPMDistSubmittalInit @pmco, @project, @submittaltype, @submittal, @rev,
					@archengfirm, @archengcontact, @toarcheng, null, @pmsm_keyid, @errmsg output
		if @rcode <> 0
			begin
			select @errmsg = @errmsg + ' - Error adding architect engineer firm contact to distribution table.'
			goto error
			End
		---- initialize project firm record
		exec @rcode = dbo.bspPMPFirmContactDistAdd @pmco, @project, @vendorgroup, @archengfirm, @archengcontact, @errmsg output
		end
	end

if @numrows > 1
   	begin
	fetch next from bPMSM_update into @pmco, @project, @submittaltype, @submittal, @rev, @phasegroup, @phase,
			@subfirm, @subcontact, @archengfirm, @archengcontact, @pmsm_keyid, @oldsubfirm,
			@oldsubcontact, @oldarchengfirm, @oldarchengcontact, @vendorgroup, @toarcheng
   	if @@fetch_status = 0
		begin
   		goto update_check
		end
   	else
   		begin
   		close bPMSM_update
   		deallocate bPMSM_update
   		select @opencursor = 0
   		end
   	end




---- selected columns are updated in PMSI table when changed in PMSM and the
---- column in the items table is null or status is changed. First set the
---- PMSI.ChangedFromPMSM flag to 'N' so that auditing will not occur for items.
if update(Status) or update(DateReqd) or update(DateRecd) or update(ToArchEng) or update(DueBackArch)
	or update(RecdBackArch) or update(DateRetd) or update(ActivityDate) or update(CopiesSentArch)
	or update(CopiesRecdArch) or update(CopiesReqd) or update(CopiesSent) or update(CopiesRecd)
	or UPDATE(SpecNumber) /*OR UPDATE(Issue) */
	begin
	update bPMSI set ChangedFromPMSM = 'Y'
	from inserted i
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType
	and s.Submittal=i.Submittal and s.Rev=i.Rev
	end

---- update bPMSI dates and copies if changed in bPMSM and bPMSI value is null
if update(Status)
	begin
	update bPMSI set Status=i.Status
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(d.Status,'') <> isnull(i.Status,'') and isnull(d.Status,'')=isnull(s.Status,'')
	end

if update(DateReqd)
	begin
	update bPMSI set DateReqd=i.DateReqd
	from inserted i
	join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.DateReqd,'') <> isnull(i.DateReqd,'')
	and (s.DateReqd is null or isnull(s.DateReqd,'') = isnull(d.DateReqd,''))
	end

if update(DateRecd)
	begin
	update bPMSI set DateRecd=i.DateRecd
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.DateRecd,'') <> isnull(i.DateRecd,'')
	and (s.DateRecd is null or isnull(s.DateRecd,'') = isnull(d.DateRecd,''))
	end

if update(ToArchEng)
	begin
	update bPMSI set ToArchEng=i.ToArchEng
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.ToArchEng,'') <> isnull(i.ToArchEng,'')
	and (s.ToArchEng is null or isnull(s.ToArchEng,'') = isnull(d.ToArchEng,''))
	end

if update(DueBackArch)
	begin
	update bPMSI set DueBackArch=i.DueBackArch
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.DueBackArch,'') <> isnull(i.DueBackArch,'')
	and (s.DueBackArch is null or isnull(s.DueBackArch,'') = isnull(d.DueBackArch,''))
	end

if update(RecdBackArch)
	begin
	update bPMSI set RecdBackArch=i.RecdBackArch
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.RecdBackArch,'') <> isnull(i.RecdBackArch,'')
	and (s.RecdBackArch is null or isnull(s.RecdBackArch,'') = isnull(d.RecdBackArch,''))
	end

if update(DateRetd)
	begin
	update bPMSI set DateRetd=i.DateRetd
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.DateRetd,'') <> isnull(i.DateRetd,'')
	and (s.DateRetd is null or isnull(s.DateRetd,'') = isnull(d.DateRetd,''))
	end

if update(ActivityDate)
	begin
	update bPMSI set ActivityDate=i.ActivityDate
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.ActivityDate,'') <> isnull(i.ActivityDate,'')
	and (s.ActivityDate is null or isnull(s.ActivityDate,'') = isnull(d.ActivityDate,''))
	end

if update(CopiesRecd)
	begin
	update bPMSI set CopiesRecd=i.CopiesRecd
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.CopiesRecd,0) <> isnull(i.CopiesRecd,0)
	and (s.CopiesRecd is null or isnull(s.CopiesRecd,0) = isnull(d.CopiesRecd,0))
	end

if update(CopiesSent)
	begin
	update bPMSI set CopiesSent=i.CopiesSent
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.CopiesSent,0) <> isnull(i.CopiesSent,0)
	and (s.CopiesSent is null or isnull(s.CopiesSent,0) = isnull(d.CopiesSent,0))
	end

if update(CopiesReqd)
	begin
	update bPMSI set CopiesReqd=i.CopiesReqd
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.CopiesReqd,0) <> isnull(i.CopiesReqd,0)
	and (s.CopiesReqd is null or isnull(s.CopiesReqd,0) = isnull(d.CopiesReqd,0))
	end

if update(CopiesRecdArch)
	begin
	update bPMSI set CopiesRecdArch=i.CopiesRecdArch
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.CopiesRecdArch,0) <> isnull(i.CopiesRecdArch,0)
	and (s.CopiesRecdArch is null or isnull(s.CopiesRecdArch,0) = isnull(d.CopiesRecdArch,0))
	end

if update(CopiesSentArch)
	begin
	update bPMSI set CopiesSentArch=i.CopiesSentArch
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.CopiesSentArch,0) <> isnull(i.CopiesSentArch,0)
	and (s.CopiesSentArch is null or isnull(s.CopiesSentArch,0) = isnull(d.CopiesSentArch,0))
	end

----#134090
if update(SpecNumber)
	begin
	update bPMSI set SpecNumber=i.SpecNumber
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.SpecNumber,'') <> isnull(i.SpecNumber,'')
	and (s.SpecNumber is null or isnull(s.SpecNumber,'') = isnull(d.SpecNumber,''))
	end
----#134090
--if update(Issue)
--	begin
--	update bPMSI set Issue=i.Issue
--	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
--	join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType and s.Submittal=i.Submittal and s.Rev=i.Rev
--	where isnull(i.Status,'') = isnull(s.Status,'') and isnull(d.Issue,'') <> isnull(i.Issue,'')
--	and (s.Issue is null or isnull(s.Issue,'') = isnull(d.Issue,''))
--	end

---- reset PMSI.ChangedFromPMSM flag
update bPMSI set ChangedFromPMSM = 'N'
from inserted i
join bPMSI s on s.PMCo=i.PMCo and s.Project=i.Project and s.SubmittalType=i.SubmittalType
and s.Submittal=i.Submittal and s.Rev=i.Rev
where s.ChangedFromPMSM = 'Y'



---- Insert records into Issue History
--if update(Issue)
--	begin
--	-- old and new issue exists
--	insert into bPMIH (PMCo, Project, Issue, Seq, DocType, Document, Rev, IssueDateTime, Action)
--	select i.PMCo, i.Project, i.Issue, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Issue ASC),
--			i.SubmittalType, i.Submittal, i.Rev, getdate(),
--			'Issue has changed from ' + isnull(convert(varchar(10),d.Issue),'') + ' to ' + convert(varchar(10),isnull(i.Issue,'')) +
--			' for Submittal: ' + isnull(i.Submittal,'') + ' - ' + isnull(i.Description,'')
--	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project
--	and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
--	left join bPMIH h on h.PMCo=i.PMCo and h.Project=i.Project and h.Issue=i.Issue
--	where isnull(i.Issue,'') <> isnull(d.Issue,'') and isnull(i.Issue,'') <> ''
--	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Issue, d.Issue, h.Issue, i.Description
--	end
--if update(Status)
--	begin
--	insert into bPMIH (PMCo, Project, Issue, Seq, DocType, Document, Rev, IssueDateTime, Action)
--	select i.PMCo, i.Project, i.Issue, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Issue ASC),
--			i.SubmittalType, i.Submittal, i.Rev, getdate(),
--			'Status has changed from ' + isnull(d.Status,'') + ' to ' + isnull(i.Status,'') + 
--			' for Submittal: ' + isnull(i.Submittal,'') + ' - ' + isnull(i.Description,'')
--	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project
--	and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
--	left join bPMIH h on h.PMCo=i.PMCo and h.Project=i.Project and h.Issue=i.Issue
--	where isnull(i.Status,'') <> isnull(d.Status,'') and isnull(i.Issue,'') <> ''
--	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Status, d.Status, i.Issue, d.Issue, h.Issue, i.Description
--	end
--if update(ArchEngContact)
--	begin
--	insert into bPMIH (PMCo, Project, Issue, Seq, DocType, Document, Rev, IssueDateTime, Action)
--	select i.PMCo, i.Project, i.Issue, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Issue ASC),
--			i.SubmittalType, i.Submittal, i.Rev, getdate(),
--			'ArchEng Contact has changed from ' + isnull(convert(varchar(10),d.ArchEngContact),'') + ' to ' + isnull(convert(varchar(10),i.ArchEngContact),'') +
--			' for Submittal: ' + isnull(i.Submittal,'') + ' - ' + isnull(i.Description,'')
--	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project
--	and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
--	left join bPMIH h on h.PMCo=i.PMCo and h.Project=i.Project and h.Issue=i.Issue
--	where isnull(i.ArchEngContact,'') <> isnull(d.ArchEngContact,'') and isnull(i.Issue,'') <> ''
--	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.ArchEngContact, d.ArchEngContact, i.Issue, d.Issue, h.Issue, i.Description
--	end
--if update(SubContact)
--	begin
--	insert into bPMIH (PMCo, Project, Issue, Seq, DocType, Document, Rev, IssueDateTime, Action)
--	select i.PMCo, i.Project, i.Issue, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Issue ASC),
--			i.SubmittalType, i.Submittal, i.Rev, getdate(),
--			'Sub Contact has changed from ' + isnull(convert(varchar(10),d.SubContact),'') + ' to ' + isnull(convert(varchar(10),i.SubContact),'') +
--			' for Submittal: ' + isnull(i.Submittal,'') + ' - ' + isnull(i.Description,'')
--	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project
--	and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
--	left join bPMIH h on h.PMCo=i.PMCo and h.Project=i.Project and h.Issue=i.Issue
--	where isnull(i.SubContact,'') <> isnull(d.SubContact,'') and isnull(i.Issue,'') <> ''
--	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.SubContact, d.SubContact, i.Issue, d.Issue, h.Issue, i.Description
--	end
--if update(ResponsiblePerson)
--	begin
--	insert into bPMIH (PMCo, Project, Issue, Seq, DocType, Document, Rev, IssueDateTime, Action)
--	select i.PMCo, i.Project, i.Issue, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Issue ASC),
--			i.SubmittalType, i.Submittal, i.Rev, getdate(),
--			'Resp. Person has changed from ' + isnull(convert(varchar(10),d.ResponsiblePerson),'') + ' to ' + isnull(convert(varchar(10),i.ResponsiblePerson),'') +
--			' for Submittal: ' + isnull(i.Submittal,'') + ' - ' + isnull(i.Description,'')
--	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project
--	and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
--	left join bPMIH h on h.PMCo=i.PMCo and h.Project=i.Project and h.Issue=i.Issue
--	where isnull(i.ResponsiblePerson,'') <> isnull(d.ResponsiblePerson,'') and isnull(i.Issue,'') <> ''
--	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.ResponsiblePerson, d.ResponsiblePerson, i.Issue, d.Issue, h.Issue, i.Description
--	end


---- document history updates (bPMDH)
if update(Description)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'Description',
			d.Description, i.Description, SUSER_SNAME(), 'Description has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Description, d.Description
	end
if update(Issue)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'Issue',
			convert(varchar(8),d.Issue), convert(varchar(8),i.Issue),  SUSER_SNAME(), 'Issue has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Issue,0) <> isnull(i.Issue,0) and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Issue, d.Issue
	end
if update(Status)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'Status',
			d.Status, i.Status, SUSER_SNAME(), 'Status has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Status, d.Status
	end
if update(DateReqd)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'DateReqd',
			convert(char(8),d.DateReqd,1), convert(char(8),i.DateReqd,1), SUSER_SNAME(), 'Date Reqd has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateReqd,'') <> isnull(i.DateReqd,'') and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.DateReqd, d.DateReqd
	end
if update(DateRecd)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'DateRecd',
			convert(char(8),d.DateRecd,1), convert(char(8),i.DateRecd,1), SUSER_SNAME(), 'Date Recd has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateRecd,'') <> isnull(i.DateRecd,'') and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.DateRecd, d.DateRecd
	end
if update(ToArchEng)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'ToArchEng',
			convert(char(8),d.ToArchEng,1), convert(char(8),i.ToArchEng,1), SUSER_SNAME(), 'To Arch/Eng Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ToArchEng,'') <> isnull(i.ToArchEng,'') and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.ToArchEng, d.ToArchEng
	end
if update(DueBackArch)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'DueBackArch',
			convert(char(8),d.DueBackArch,1), convert(char(8),i.DueBackArch,1), SUSER_SNAME(), 'Due Back Arch/Eng Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DueBackArch,'') <> isnull(i.DueBackArch,'') and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.DueBackArch, d.DueBackArch
	end
if update(RecdBackArch)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'RecdBackArch',
			convert(char(8),d.RecdBackArch,1), convert(char(8),i.RecdBackArch,1), SUSER_SNAME(), 'Recd Back Arch/Eng Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.RecdBackArch,'') <> isnull(i.RecdBackArch,'') and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.RecdBackArch, d.RecdBackArch
	end
if update(DateRetd)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'DateRetd',
			convert(char(8),d.DateRetd,1), convert(char(8),i.DateRetd,1), SUSER_SNAME(), 'Date Retd has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateRetd,'') <> isnull(i.DateRetd,'') and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.DateRetd, d.DateRetd
	end
if update(ActivityDate)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'ActivityDate',
			convert(char(8),d.ActivityDate,1), convert(char(8),i.ActivityDate,1), SUSER_SNAME(), 'Activity Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ActivityDate,'') <> isnull(i.ActivityDate,'') and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.ActivityDate, d.ActivityDate
	end
if update(ResponsiblePerson)
	begin
	insert into bPMDH(PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'ResponsiblePerson',
			convert(varchar(8),d.ResponsiblePerson), convert(varchar(8),i.ResponsiblePerson), SUSER_SNAME(), 'Responsible Person has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ResponsiblePerson,0) <> isnull(i.ResponsiblePerson,0) and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.ResponsiblePerson, d.ResponsiblePerson
	end
if update(SubContact)
	begin
	insert into bPMDH(PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'SubContact',
			convert(varchar(8),d.SubContact), convert(varchar(8),i.SubContact), SUSER_SNAME(), 'Sub Contact has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.SubContact,0) <> isnull(i.SubContact,0) and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.SubContact, d.SubContact
	end
if update(ArchEngContact)
	begin
	insert into bPMDH(PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'ArchEngContact',
			convert(varchar(8),d.ArchEngContact), convert(varchar(8),i.ArchEngContact), SUSER_SNAME(), 'Arch/Eng Contact has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ArchEngContact,0) <> isnull(i.ArchEngContact,0) and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.ArchEngContact, d.ArchEngContact
	end
if update(SubFirm)
	begin
	insert into bPMDH(PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'SubFirm',
			convert(varchar(10),d.SubFirm), convert(varchar(10),i.SubFirm), SUSER_SNAME(), 'Sub Firm has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.SubFirm,0) <> isnull(i.SubFirm,0) and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.SubFirm, d.SubFirm
	end
if update(ArchEngFirm)
	begin
	insert into bPMDH(PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'ArchEngFirm',
			convert(varchar(10),d.ArchEngFirm), convert(varchar(10),i.ArchEngFirm), SUSER_SNAME(), 'Arch/Eng Firm has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ArchEngFirm,0) <> isnull(i.ArchEngFirm,0) and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.ArchEngFirm, d.ArchEngFirm
	end
if update(Phase)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'Phase',
			d.Phase, i.Phase, SUSER_SNAME(), 'Phase has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Phase,'') <> isnull(i.Phase,'') and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Phase, d.Phase
	end
if update(SpecNumber)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'SpecNumber',
			d.SpecNumber, i.SpecNumber, SUSER_SNAME(), 'Spec Number has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.SpecNumber,'') <> isnull(i.SpecNumber,'') and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.SpecNumber, d.SpecNumber
	end
if update(CopiesRecd)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'CopiesRecd',
			convert(varchar(3),d.CopiesRecd), convert(varchar(3),i.CopiesRecd),  SUSER_SNAME(), 'Copies Recd has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.CopiesRecd,0) <> isnull(i.CopiesRecd,0) and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.CopiesRecd, d.CopiesRecd
	end
if update(CopiesSent)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'CopiesSent',
			convert(varchar(3),d.CopiesSent), convert(varchar(3),i.CopiesSent),  SUSER_SNAME(), 'Copies Sent has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.CopiesSent,0) <> isnull(i.CopiesSent,0) and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.CopiesSent, d.CopiesSent
	end
if update(CopiesReqd)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'CopiesReqd',
			convert(varchar(3),d.CopiesReqd), convert(varchar(3),i.CopiesReqd),  SUSER_SNAME(), 'Copies Reqd has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.CopiesReqd,0) <> isnull(i.CopiesReqd,0) and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.CopiesReqd, d.CopiesReqd
	end
if update(CopiesRecdArch)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'CopiesRecdArch',
			convert(varchar(3),d.CopiesRecdArch), convert(varchar(3),i.CopiesRecdArch),  SUSER_SNAME(), 'Copies Recd Arch has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.CopiesRecdArch,0) <> isnull(i.CopiesRecdArch,0) and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.CopiesRecdArch, d.CopiesRecdArch
	end
if update(CopiesSentArch)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'CopiesSentArch',
			convert(varchar(3),d.CopiesSentArch), convert(varchar(3),i.CopiesSentArch),  SUSER_SNAME(), 'Copies Sent Arch has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType and d.Submittal=i.Submittal and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.CopiesSentArch,0) <> isnull(i.CopiesSentArch,0) and c.DocHistSubmittal = 'Y'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.CopiesSentArch, d.CopiesSentArch
	end








return




error:
   	if @opencursor = 1
   		begin
   		close bPMSM_update
   		deallocate bPMSM_update
   		select @opencursor = 0
   		end

	select @errmsg = @errmsg + ' - cannot update PMSM'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction





















GO
