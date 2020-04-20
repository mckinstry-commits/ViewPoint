CREATE TABLE [dbo].[bPMPS]
(
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[SubmittalType] [dbo].[bDocType] NOT NULL,
[Seq] [tinyint] NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bPMPS] ADD
CONSTRAINT [FK_bPMPS_bJCPM] FOREIGN KEY ([PhaseGroup], [Phase]) REFERENCES [dbo].[bJCPM] ([PhaseGroup], [Phase])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPSd    Script Date: 8/28/99 9:37:52 AM ******/
CREATE trigger [dbo].[btPMPSd] on [dbo].[bPMPS] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMPS
 * Created By:	GF 12/08/2006 - 6.x HQMA auditing
 * Modified By:  JayR 03/26/2012 - TK-00000 Remove gotos
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMPS', ' Phase: ' + isnull(d.Phase,'') + ' SubmittalType: ' + isnull(d.SubmittalType,'') + ' Seq: ' + isnull(convert(varchar(3),d.Seq),''),
		null, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d

RETURN 
   
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMPSi    Script Date: 8/28/99 9:37:59 AM ******/
CREATE  trigger [dbo].[btPMPSi] on [dbo].[bPMPS] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMPS
 * Created By:	LM 12/22/97
 * Modified By:	GF 12/13/2006 - 6.x HQMA
 *				JayR 03/26/2012 - TK-00000  Change to using FKs for validation.  Cleanup gotos
 *
 *--------------------------------------------------------------*/
declare @numrows int,  @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- Validate DocType
select @validcnt = count(*) from bPMDT r JOIN inserted i ON r.DocType = i.SubmittalType and r.DocCategory = 'SUBMIT'
if @validcnt <> @numrows
      begin
		  RAISERROR('Document Type is Invalid  - cannot insert into PMPS', 11, -1)
		  ROLLBACK TRANSACTION
		  RETURN
      end

---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMPS', ' Phase: ' + isnull(i.Phase,'') + ' SubmittalType: ' + isnull(i.SubmittalType,'') + ' Seq: ' + isnull(convert(varchar(3),i.Seq),''),
		null, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i

RETURN 
   
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPSu    Script Date: 8/28/99 9:37:59 AM ******/
CREATE trigger [dbo].[btPMPSu] on [dbo].[bPMPS] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMPS
 * Created By:   LM 12/22/97
 * Modified By:	GF 12/13/2006 - 6.x auditing
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on
   
---- check for changes to PhaseGroup
   if update(PhaseGroup)
      begin
      RAISERROR('Cannot change PhaseGroup - cannot update PMPS', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Phase
   if update(Phase)
      begin
      RAISERROR('Cannot change Phase - cannot update PMPS', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to SubmittalType
   if update(SubmittalType)
      begin
      RAISERROR('Cannot change SubmittalType - cannot update PMPS', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Seq
   if update(Seq)
      begin
      RAISERROR('Cannot change Seq - cannot update PMPS', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end


---- HQMA inserts
if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPS', 'Phase: ' + isnull(i.Phase,'') + ' SubmittalType: ' + isnull(i.SubmittalType,'') + ' Seq: ' + isnull(convert(varchar(3),i.Seq),''),
		null, 'C', 'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PhaseGroup=i.PhaseGroup and d.Phase=i.Phase 
	and d.SubmittalType=i.SubmittalType and d.Seq=i.Seq
	where isnull(d.Description,'') <> isnull(i.Description,'')

RETURN 
   
   
  
 




GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMPS] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMPS] ON [dbo].[bPMPS] ([PhaseGroup], [Phase], [SubmittalType], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
