CREATE TABLE [dbo].[bPMTS]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Transmittal] [dbo].[bDocument] NOT NULL,
[Seq] [int] NOT NULL,
[DocType] [dbo].[bDocType] NULL,
[Document] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DocumentDesc] [dbo].[bItemDesc] NULL,
[CopiesSent] [tinyint] NULL,
[Status] [dbo].[bStatus] NULL,
[Remarks] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Rev] [tinyint] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[DrawingRev] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SubmittalRev] [varchar] (5) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPMTS] ON [dbo].[bPMTS] ([PMCo], [Project], [Transmittal], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMTS] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMTS] WITH NOCHECK ADD
CONSTRAINT [CK_bPMTS_DocType_Document] CHECK (([DocType] IS NULL AND [Document] IS NULL OR [DocType] IS NOT NULL AND [Document] IS NOT NULL))
ALTER TABLE [dbo].[bPMTS] WITH NOCHECK ADD
CONSTRAINT [FK_bPMTS_bPMTM] FOREIGN KEY ([PMCo], [Project], [Transmittal]) REFERENCES [dbo].[bPMTM] ([PMCo], [Project], [Transmittal]) ON DELETE CASCADE
ALTER TABLE [dbo].[bPMTS] WITH NOCHECK ADD
CONSTRAINT [FK_bPMTS_bPMDT] FOREIGN KEY ([DocType]) REFERENCES [dbo].[bPMDT] ([DocType])
ALTER TABLE [dbo].[bPMTS] WITH NOCHECK ADD
CONSTRAINT [FK_bPMTS_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
ALTER TABLE [dbo].[bPMTS] ADD
CONSTRAINT [FK_bPMTS_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btPMTSd] on [dbo].[bPMTS] for DELETE as 
/*-------------------------------------------------------------- 
 *  Delete trigger for PMTS
 *  Created By:		GF 03/13/2002
 *  Modified By:	
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @opencursor int,
		@description varchar(100), @rev tinyint, @pmco bCompany, @project bJob,
		@doctype bDocType, @document bDocument, @transmittal bDocument,
		@action varchar(250), @doccategory varchar(10), @seq int,
		@documentdesc bItemDesc, @catdesc bDesc, @closepurgeflag bYN

select @numrows = @@rowcount 
if @numrows = 0 return
set nocount on

select @opencursor = 0

---- generate document history
if @numrows = 1
	begin
   	select @pmco=PMCo, @project=Project, @transmittal=Transmittal, @doctype=DocType,
			@document=Document, @documentdesc=DocumentDesc, @rev=Rev
	from deleted
	end
else
	begin
   	---- use a cursor to process each inserted row
   	declare bPMTS cursor LOCAL FAST_FORWARD
   	for select PMCo, Project, Transmittal, DocType, Document, DocumentDesc, Rev
   	from deleted

   	open bPMTS
   	set @opencursor = 1

	fetch next from bPMTS into @pmco, @project, @transmittal, @doctype, @document, @documentdesc, @rev
	if @@fetch_status <> 0
		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
	end



record_check:
---- check purge flag
select @closepurgeflag=ClosePurgeFlag
from bJCJM with (nolock) where JCCo=@pmco and Job=@project
if isnull(@closepurgeflag,'N') = 'Y' goto next_record

---- if no document or document type then insert history and goto next record
if isnull(@doctype,'') = '' and isnull(@document,'') = ''
	begin
	---- document history (bPMDH)
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select @pmco, @project, isnull(max(h.Seq),0)+1, 'TRANSMIT', null, @transmittal, null, getdate(), 'C', null, null, null, SUSER_SNAME(),
			'Document: empty - ' + isnull(ltrim(rtrim(@documentdesc)),'') + ' has been removed from transmittal: ' + isnull(@transmittal,'') + '.', null
	from inserted i join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TRANSMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where c.DocHistTransmittal = 'Y'
	group by i.PMCo, i.Project, i.Transmittal
	goto next_record
	end


---- get document category
select @doccategory=DocCategory
from bPMDT with (nolock) where DocType=@doctype
if @@rowcount = 0 goto next_record
---- skip if document category is 'MTG' - meeting minutes
if isnull(@doccategory,'MTG') = 'MTG' goto next_record

---- get document description dependent of document category
select @description = case @doccategory
	when 'SUBMIT' then (select Description from bPMSM with (nolock) where PMCo=@pmco and Project=@project
				and SubmittalType=@doctype and Submittal=@document and Rev=isnull(@rev,Rev))
	when 'RFI' then (select Subject from bPMRI with (nolock) where PMCo=@pmco and Project=@project
				and RFIType=@doctype and RFI=@document)  
	when 'PCO' then (select Description from bPMOP with (nolock) where PMCo=@pmco and Project=@project
				and PCOType=@doctype and convert(varchar(10),PCO)=convert(varchar(10),@document))
	when 'OTHER' then (select Description from bPMOD with (nolock) where PMCo=@pmco and Project=@project
				and DocType=@doctype and Document=@document) 
	when 'DRAWING' then (select Description from bPMDG with (nolock) where PMCo=@pmco and Project=@project
				and DrawingType=@doctype and Drawing=@document)
	when 'INSPECT' then (select Description from bPMIL with (nolock) where PMCo=@pmco and Project=@project
				and InspectionType=@doctype and InspectionCode=@document)
 	when 'TEST' then (select Description from bPMTL with (nolock) where PMCo=@pmco and Project=@project
				and TestType=@doctype and TestCode=@document)
	else ' ' end

---- build action statement
select @catdesc = case @doccategory
	when 'SUBMIT' then 'Submittal: '
	when 'RFI' then 'RFI: '
	when 'PCO' then 'PCO: '
	when 'OTHER' then 'Other Document: '
	when 'DRAWING' then 'Drawing Log: '
	when 'INSPECT' then 'Inspection Log: '
	when 'TEST' then 'Test Log: '
	else ' ' end

select @action = isnull(ltrim(rtrim(@catdesc)),'') + isnull(@document,'') + ', has been removed from transmittal: ' + isnull(@transmittal,'') + '.' ----' - ' + isnull(ltrim(rtrim(@description)),'') + ', has been removed from transmittal: ' + isnull(@transmittal,'') + '.'
---- insert document history record for the assigned document first
if @doccategory not in ('SUBMIT','DRAWING')
	begin
	---- document history (bPMDH)
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select @pmco, @project, isnull(max(h.Seq),0)+1, @doccategory, @doctype, @document, null, getdate(),
			'C', null, null, null, SUSER_SNAME(), @action, @transmittal
	from bPMDH h join bPMCO c with (nolock) on c.PMCo=@pmco
	where h.PMCo=@pmco and h.Project=@project and h.DocCategory=@doccategory
	and c.DocHistTransmittal = 'Y'
	end
else
	begin
	---- document history (bPMDH)
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select @pmco, @project, isnull(max(h.Seq),0)+1, @doccategory, @doctype, @document, @rev, getdate(),
			'C', null, null, null, SUSER_SNAME(), @action, @transmittal
	from bPMDH h join bPMCO c with (nolock) on c.PMCo=@pmco
	where h.PMCo=@pmco and h.Project=@project and h.DocCategory=@doccategory
	and c.DocHistTransmittal = 'Y'
	end


---- insert document history record for transmittal to record that document was added.
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select @pmco, @project, isnull(max(h.Seq),0)+1, 'TRANSMIT', null, @transmittal, null, getdate(),
			'C', null, null, null, SUSER_SNAME(), @action, null
from bPMDH h join bPMCO c with (nolock) on c.PMCo=@pmco
where h.PMCo=@pmco and h.Project=@project and h.DocCategory='TRANSMIT'
and c.DocHistTransmittal = 'Y'



next_record:
if @numrows > 1
	begin
	fetch next from bPMTS into @pmco, @project, @transmittal, @doctype, @document, @documentdesc, @rev
   	if @@fetch_status = 0
   		goto record_check
   	else
   		begin
   		close bPMTS
   		deallocate bPMTS
   		set @opencursor = 0
   		end
   	end





return




error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot remove PMTS'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction











GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMTSi    Script Date: 8/28/99 9:38:02 AM ******/
CREATE trigger [dbo].[btPMTSi] on [dbo].[bPMTS] for INSERT as
/*--------------------------------------------------------------
 *  Insert trigger for PMTS
 *  Created By: LM 1/20/98
 *	Modified By:	GF 01/16/2002
 *					GF 03/12/2002 - Changed bPMDH to insert for transmittal assignment
 *					GF 04/08/2002 - Added DRAW Category to document category checks.
 *					GF 07/23/2002 - Added Revision to PMTS for Submittals and Drawings
 *					GF 03/10/2005 - issue #27351 added check that a document exists for each document type
 *					GF 10/12/2006 - changes for 6.x PMDH document history.
 *					JayR 03/28/2012 TK-00000 Change to using FKs for validation
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @opencursor int,
		@description varchar(100), @rev tinyint, @pmco bCompany, @project bJob, @doctype bDocType,
   		@document bDocument, @transmittal bDocument, @action varchar(250), @doccategory varchar(10),
   		@seq int, @documentdesc bItemDesc, @catdesc bDesc

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @opencursor = 0

---- Validate Document
select @validcnt2 = count(*) from inserted i where i.DocType is null
select @validcnt = case t.DocCategory
   	when 'SUBMIT' then (select count(*) from inserted i JOIN bPMSM d 
   	ON d.PMCo= i.PMCo and d.Project = i.Project and d.SubmittalType=i.DocType and d.Submittal = i.Document and i.Document is not null)  
   	when 'RFI' then (select count(*) from inserted i JOIN bPMRI r 
   	ON r.PMCo=i.PMCo and r.Project=i.Project and r.RFIType=i.DocType and r.RFI = i.Document and i.Document is not null)  
   	when 'PCO' then (select count(*) from inserted i JOIN bPMOP p 
   	ON p.PMCo=i.PMCo and p.Project=i.Project and p.PCOType=i.DocType and convert(varchar(10),p.PCO) = convert(varchar(10),i.Document) and i.Document is not null)  
   	when 'OTHER' then (select count(*) from inserted i JOIN bPMOD o 
   	ON o.PMCo=i.PMCo and o.Project=i.Project and o.DocType=i.DocType and o.Document = i.Document and i.Document is not null)  
   	end
   	from inserted i JOIN bPMDT t on i.DocType=t.DocType
if @validcnt = 0 and @validcnt2 = 0
	begin
	select @errmsg = 'Document is Invalid '
	goto error
	end


---- generate document history
if @numrows = 1
	begin
   	select @pmco=PMCo, @project=Project, @transmittal=Transmittal, @doctype=DocType,
			@document=Document, @documentdesc=DocumentDesc, @rev=Rev
	from inserted
	end
else
	begin
   	---- use a cursor to process each inserted row
   	declare bPMTS cursor LOCAL FAST_FORWARD
   	for select PMCo, Project, Transmittal, DocType, Document, DocumentDesc, Rev
   	from inserted

   	open bPMTS
   	set @opencursor = 1

	fetch next from bPMTS into @pmco, @project, @transmittal, @doctype, @document, @documentdesc, @rev
	if @@fetch_status <> 0
		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
	end



record_check:
---- if no document or document type then insert history and goto next record
if isnull(@doctype,'') = '' and isnull(@document,'') = ''
	begin
	---- document history (bPMDH)
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select @pmco, @project, isnull(max(h.Seq),0)+1, 'TRANSMIT', null, @transmittal, null, getdate(), 'C', null, null, null, SUSER_SNAME(),
			'Document: empty - ' + isnull(ltrim(rtrim(@documentdesc)),'') + ' assigned to transmittal: ' + isnull(@transmittal,'') + '.', null
	from bPMDH h join bPMCO c with (nolock) on c.PMCo=@pmco
	where h.PMCo=@pmco and h.Project=@project and h.DocCategory='TRANSMIT'
	and c.DocHistTransmittal = 'Y'
	goto next_record
	end

----from inserted i
----	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TRANSMIT'
----	join bPMCO c with (nolock) on i.PMCo=c.PMCo
----	where c.DocHistTransmittal = 'Y'
----	group by i.PMCo, i.Project, i.Transmittal
----	goto next_record
----	end


---- get document category
select @doccategory=DocCategory
from bPMDT with (nolock) where DocType=@doctype
if @@rowcount = 0 goto next_record
---- skip if document category is 'MTG' - meeting minutes
if isnull(@doccategory,'MTG') = 'MTG' goto next_record

---- get document description dependent of document category
select @description = case @doccategory
	when 'SUBMIT' then (select Description from bPMSM with (nolock) where PMCo=@pmco and Project=@project
				and SubmittalType=@doctype and Submittal=@document and Rev=isnull(@rev,Rev))
	when 'RFI' then (select Subject from bPMRI with (nolock) where PMCo=@pmco and Project=@project
				and RFIType=@doctype and RFI=@document)  
	when 'PCO' then (select Description from bPMOP with (nolock) where PMCo=@pmco and Project=@project
				and PCOType=@doctype and convert(varchar(10),PCO)=convert(varchar(10),@document))
	when 'OTHER' then (select Description from bPMOD with (nolock) where PMCo=@pmco and Project=@project
				and DocType=@doctype and Document=@document) 
	when 'DRAWING' then (select Description from bPMDG with (nolock) where PMCo=@pmco and Project=@project
				and DrawingType=@doctype and Drawing=@document)
	when 'INSPECT' then (select Description from bPMIL with (nolock) where PMCo=@pmco and Project=@project
				and InspectionType=@doctype and InspectionCode=@document)
 	when 'TEST' then (select Description from bPMTL with (nolock) where PMCo=@pmco and Project=@project
				and TestType=@doctype and TestCode=@document)
	else ' ' end

---- build action statement
select @catdesc = case @doccategory
	when 'SUBMIT' then 'Submittal: '
	when 'RFI' then 'RFI: '
	when 'PCO' then 'PCO: '
	when 'OTHER' then 'Other Document: '
	when 'DRAWING' then 'Drawing Log: '
	when 'INSPECT' then 'Inspection Log: '
	when 'TEST' then 'Test Log: '
	else ' ' end

select @action = isnull(ltrim(rtrim(@catdesc)),'') + isnull(@document,'') + ', has been assigned to transmittal: ' + + isnull(@transmittal,'') + '.' ---- + ' - ' + isnull(ltrim(rtrim(@description)),'') + ', has been assigned to transmittal: ' + isnull(@transmittal,'') + '.'
---- insert document history record for the assigned document first
if @doccategory not in ('SUBMIT','DRAWING')
	begin
	---- document history (bPMDH)
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select @pmco, @project, isnull(max(h.Seq),0)+2, @doccategory, @doctype, @document, null, getdate(),
			'C', null, null, null, SUSER_SNAME(), @action, @transmittal
	from bPMDH h join bPMCO c with (nolock) on c.PMCo=@pmco
	where h.PMCo=@pmco and h.Project=@project and h.DocCategory=@doccategory
	and c.DocHistTransmittal = 'Y'
	end
else
	begin
	---- document history (bPMDH)
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select @pmco, @project, isnull(max(h.Seq),0)+2, @doccategory, @doctype, @document, @rev, getdate(),
			'C', null, null, null, SUSER_SNAME(), @action, @transmittal
	from bPMDH h join bPMCO c with (nolock) on c.PMCo=@pmco
	where h.PMCo=@pmco and h.Project=@project and h.DocCategory=@doccategory
	and c.DocHistTransmittal = 'Y'
	end


---- insert document history record for transmittal to record that document was added.
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select @pmco, @project, isnull(max(h.Seq),0)+1, 'TRANSMIT', null, @transmittal, null, getdate(),
			'C', null, null, null, SUSER_SNAME(), @action, null
from bPMDH h join bPMCO c with (nolock) on c.PMCo=@pmco
where h.PMCo=@pmco and h.Project=@project and h.DocCategory='TRANSMIT'
and c.DocHistTransmittal = 'Y'


next_record:
if @numrows > 1
	begin
	fetch next from bPMTS into @pmco, @project, @transmittal, @doctype, @document, @documentdesc, @rev
   	if @@fetch_status = 0
   		goto record_check
   	else
   		begin
   		close bPMTS
   		deallocate bPMTS
   		set @opencursor = 0
   		end
   	end



return



error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMTS'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction













GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMTSu    Script Date: 8/28/99 9:38:03 AM ******/
CREATE trigger [dbo].[btPMTSu] on [dbo].[bPMTS] for UPDATE as
/*--------------------------------------------------------------
* Update trigger for PMTS
* Created By:	LM 1/20/98
* Modified By:	GF 01/16/2002
*				GF 06/05/2008 - issue #128577 remmed out check for duplicate document.
*
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- check for changes to PMCo
if update(PMCo)
	begin
	RAISERROR('Cannot change PMCo - cannot update PMTS', 11, -1)
	ROLLBACK TRANSACTION
	RETURN
	end

-- check for changes to Project
if update(Project)
	begin
	RAISERROR('Cannot change Project - cannot update PMTS', 11, -1)
	ROLLBACK TRANSACTION
	RETURN
	end

---- check for changes to Transmittal
if update(Transmittal)
	begin
	RAISERROR('Cannot change Transmittal - cannot update PMTS', 11, -1)
	ROLLBACK TRANSACTION
	RETURN
	end



-- Validate Document
if update(Document)
	BEGIN
	select @validcnt2 = count(*) from inserted i where i.DocType is null
	select @validcnt = case t.DocCategory
		when 'SUBMIT' then (select count(*) from inserted i JOIN bPMSM d 
		ON d.PMCo= i.PMCo and d.Project = i.Project and d.SubmittalType=i.DocType and d.Submittal = i.Document and i.Document is not null)  
		when 'RFI' then (select count(*) from inserted i JOIN bPMRI r 
		ON r.PMCo=i.PMCo and r.Project=i.Project and r.RFIType=i.DocType and r.RFI = i.Document and i.Document is not null)  
		when 'PCO' then (select count(*) from inserted i JOIN bPMOP p 
		ON p.PMCo=i.PMCo and p.Project=i.Project and p.PCOType=i.DocType and convert(varchar(10),p.PCO) = convert(varchar(10),i.Document) and i.Document is not null)  
		when 'OTHER' then (select count(*) from inserted i JOIN bPMOD o 
		ON o.PMCo=i.PMCo and o.Project=i.Project and o.DocType=i.DocType and o.Document = i.Document and i.Document is not null)  
		end
	from inserted i JOIN bPMDT t on i.DocType=t.DocType
	if @validcnt = 0 and @validcnt2 = 0
		begin
			RAISERROR('Document is Invalid  - cannot update PMTS', 11, -1)
			ROLLBACK TRANSACTION
			RETURN
		end
	END

return
   
   
   
   
  
 



GO
