CREATE TABLE [dbo].[bPMCO]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[APInUse] [dbo].[bYN] NOT NULL,
[SLInUse] [dbo].[bYN] NOT NULL,
[POInUse] [dbo].[bYN] NOT NULL,
[APCo] [dbo].[bCompany] NULL,
[INInUse] [dbo].[bYN] NOT NULL,
[INCo] [dbo].[bCompany] NULL,
[MSInUse] [dbo].[bYN] NOT NULL,
[MSCo] [dbo].[bCompany] NULL,
[PRInUse] [dbo].[bYN] NOT NULL,
[PRCo] [dbo].[bCompany] NULL,
[EMInUse] [dbo].[bYN] NOT NULL,
[EMCo] [dbo].[bCompany] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[SLCostType] [dbo].[bJCCType] NULL,
[MtlCostType] [dbo].[bJCCType] NULL,
[SigPartJob] [dbo].[bYN] NOT NULL,
[SigCharsPO] [smallint] NULL,
[SigCharsMO] [smallint] NULL,
[SigCharsSL] [smallint] NULL,
[SLNo] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SLCharsProject] [tinyint] NULL,
[SLCharsVendor] [tinyint] NULL,
[PONo] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[POCharsProject] [tinyint] NULL,
[POCharsVendor] [tinyint] NULL,
[MONo] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MOCharsProject] [tinyint] NULL,
[PhaseDescYN] [dbo].[bYN] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[OurFirm] [dbo].[bFirm] NULL,
[SLSeqLen] [tinyint] NULL,
[POSeqLen] [tinyint] NULL,
[MOSeqLen] [tinyint] NULL,
[SLCT1Option] [tinyint] NOT NULL CONSTRAINT [DF_bPMCO_SLCT1Option] DEFAULT ((2)),
[SLCostType2] [dbo].[bJCCType] NULL,
[MTCT1Option] [tinyint] NOT NULL CONSTRAINT [DF_bPMCO_MTCT1Option] DEFAULT ((2)),
[POSigPartJob] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_POSigPartJob] DEFAULT ('N'),
[MOGroupByLoc] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_MOGroupByLoc] DEFAULT ('N'),
[BeginStatus] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[FinalStatus] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[APVendUpdYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_APVendUpdYN] DEFAULT ('N'),
[DocTrackView] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[RQInUse] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_RQInUse] DEFAULT ('N'),
[POCreate] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_POCreate] DEFAULT ('Y'),
[MOCreate] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_MOCreate] DEFAULT ('Y'),
[SLStartSeq] [smallint] NULL,
[POStartSeq] [smallint] NULL,
[MOStartSeq] [smallint] NULL,
[ShowCostType1] [dbo].[bJCCType] NULL,
[ShowCostType2] [dbo].[bJCCType] NULL,
[ShowCostType3] [dbo].[bJCCType] NULL,
[ShowCostType4] [dbo].[bJCCType] NULL,
[ShowCostType5] [dbo].[bJCCType] NULL,
[ShowCostType6] [dbo].[bJCCType] NULL,
[ShowCostType7] [dbo].[bJCCType] NULL,
[ShowCostType8] [dbo].[bJCCType] NULL,
[ShowCostType9] [dbo].[bJCCType] NULL,
[ShowCostType10] [dbo].[bJCCType] NULL,
[FaxServerName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[DocHistACO] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_DocHistACO] DEFAULT ('Y'),
[DocHistDrawing] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_DocHistDrawing] DEFAULT ('Y'),
[DocHistInspect] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_DocHistInspect] DEFAULT ('Y'),
[DocHistOtherDoc] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_DocHistOtherDoc] DEFAULT ('Y'),
[DocHistPCO] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_DocHistPCO] DEFAULT ('Y'),
[DocHistPunchList] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_DocHistPunchList] DEFAULT ('Y'),
[DocHistRFI] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_DocHistRFI] DEFAULT ('Y'),
[DocHistRFQ] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_DocHistRFQ] DEFAULT ('Y'),
[DocHistSubmittal] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_DocHistSubmittal] DEFAULT ('Y'),
[DocHistTestLog] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_DocHistTestLog] DEFAULT ('Y'),
[DocHistTransmittal] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_DocHistTransmittal] DEFAULT ('Y'),
[AuditCoParams] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditCoParams] DEFAULT ('Y'),
[AuditDailyLogs] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditDailyLogs] DEFAULT ('N'),
[AuditPMCA] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMCA] DEFAULT ('N'),
[AuditPMEC] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMEC] DEFAULT ('N'),
[AuditPMEH] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMEH] DEFAULT ('N'),
[AuditPMFM] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMFM] DEFAULT ('N'),
[AuditPMIM] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMIM] DEFAULT ('N'),
[AuditPMMF] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMMF] DEFAULT ('N'),
[AuditPMMM] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMMM] DEFAULT ('N'),
[AuditPMNR] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMNR] DEFAULT ('N'),
[AuditPMPA] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMPA] DEFAULT ('N'),
[AuditPMPC] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMPC] DEFAULT ('N'),
[AuditPMPF] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMPF] DEFAULT ('N'),
[AuditPMPL] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMPL] DEFAULT ('N'),
[AuditPMPM] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMPM] DEFAULT ('N'),
[AuditPMPN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMPN] DEFAULT ('N'),
[AuditPMSL] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMSL] DEFAULT ('N'),
[AuditPMTH] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AuditPMTH] DEFAULT ('N'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_AttachBatchReportsYN] DEFAULT ('N'),
[UseApprSubCo] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_UseApprSubCo] DEFAULT ('N'),
[MatlPhaseDesc] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCO_MatlPhaseDesc] DEFAULT ('N'),
[POAddOrigOpen] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCO_POAddOrigOpen] DEFAULT ('N'),
[POAddChgOpen] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCO_POAddChgOpen] DEFAULT ('N'),
[MatlCostType2] [dbo].[bJCCType] NULL,
[SLItemCOAutoAdd] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCO_SLItemCOAutoAdd] DEFAULT ('N'),
[SLItemCOManual] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCO_SLItemCOManual] DEFAULT ('N'),
[AllowPCOToSLSync] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCO_AllowPCOToSLSync] DEFAULT ('N'),
[DocHistSubCO] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCO_DocHistSubCO] DEFAULT ('N'),
[RFIStatus] [dbo].[bStatus] NULL CONSTRAINT [DF_bPMCO_RFIStatus] DEFAULT (NULL),
[DocHistPOCONum] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCO_DocHistPOCONum] DEFAULT ('N'),
[LockDownACOItems] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_LockDownACOItems] DEFAULT ('N'),
[SubmittalReviewDaysResponsibleFirm] [int] NULL,
[SubmittalReviewDaysApprovingFirm] [int] NULL,
[SubmittalReviewDaysRequestingFirm] [int] NULL,
[DocHistSubmittalRegister] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCO_DocHistSubmittalRegister] DEFAULT ('Y')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMCOd    Script Date: 8/28/99 9:37:52 AM ******/
CREATE trigger [dbo].[btPMCOd] on [dbo].[bPMCO] for DELETE as



/*--------------------------------------------------------------
 * Delete trigger for PMCO
 * Created By:	GF 12/08/2006 - 6.x HQMA auditing
 * Modified By:  JayR 03/20/2012 Change to use FK for validation and deletion.  
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMCO','PM Co#: ' + isnull(convert(varchar(3),d.PMCo),''), null, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d

RETURN
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE trigger [dbo].[btPMCOi] on [dbo].[bPMCO] for INSERT as
/*-----------------------------------------------------------------
* Created:	Unknown
* Modified:	GF 01/16/2002 - Added Auditing
*			GF 12/17/2003 - concatenation and changed pseudo cursor to cursor
*			GF 06/10/2004 - issue #24794 error message on SL chars project/vendor not checking count of SL type
*			GG 04/20/07 - #30116 - data security review
*			TRL 02/18/08 --#21452
*			GF 05/26/2009 - issue #24641
*			JayR 03/20/2012 TK-00000  Change code to use FK and table constraints.
*
*	This trigger rejects insertion in bPMCO (Companies) if the
*	following error condition exists:
*
*
*  HQCo Invalid HQ Company number
*  JCCo Invalid JC Company number
*  InUse flags not (Y,N)
*  Invalid JC Phase Group
*  Invalid SL Cost Type if not null and not in JCCT
*  Invalid Matl Cost Type if not null and not in JCCT
*  Invalid SigPartJob, SLNo, PONo, MONo flags
*  Invalid SLCT option flags
*  Invalid POSigPartJob, MOSigPartJob, POMatlType, MOMatlType, MSMatlType flags
*
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

if @@rowcount = 0 return
set nocount on

---- initialize document categories
if not exists(select 1 from bPMCT)
	begin
	declare @sql nvarchar(max)
	set @sql = 'exec dbo.vspPMCTInitialize'
	exec (@sql)
	end

------ audit company
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMCO',  'PM Co#: ' + isnull(convert(char(3), PMCo),''), PMCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
from inserted

--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMCO',  'PM Co#: ' + convert(char(3), PMCo), PMCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bPMCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bPMCo', i.PMCo, i.PMCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bPMCo' and s.Qualifier = i.PMCo 
						and s.Instance = convert(char(30),i.PMCo) and s.SecurityGroup = @dfltsecgroup)
	end 

RETURN 


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************************/
CREATE trigger [dbo].[btPMCOu] on [dbo].[bPMCO] for UPDATE as
/*-----------------------------------------------------------------
 *	Created By: GF 01/16/2002
 *	Modified By: TRL 02/18/08 --#21452	
 *				GF 02/16/2010 - issue #136053 subcontract prebilling
 *				GF 04/06/2012 - TK-00000 HQMA audit
 *
 *
 *	Validates information for update in bPMCO (PM Company)
 *
 *
 *	Adds record to HQ Master Audit.
 */----------------------------------------------------------------

if @@rowcount = 0 return
set nocount on

---- check for key changes
 if update(PMCo)
 BEGIN 
  	RAISERROR('Cannot change PM Company - cannot update PM Company!', 11, -1)
  	rollback TRANSACTION
  	return
 END 

---- Insert records into HQMA for changes made to audited fields
 IF UPDATE(APInUse)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'AP In Use',
 		d.APInUse, i.APInUse, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.APInUse,'') <> isnull(d.APInUse,'')
 
 IF UPDATE(SLInUse)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'SL In Use',
 		d.SLInUse, i.SLInUse, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SLInUse,'') <> isnull(d.SLInUse,'')
 
 IF UPDATE(POInUse)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'PO In Use',
 		d.POInUse, i.POInUse, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.POInUse,'') <> isnull(d.POInUse,'')
 
 IF UPDATE(INInUse)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'IN In Use',
 		d.INInUse, i.INInUse, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.INInUse,'') <> isnull(d.INInUse,'')
 
 IF UPDATE(MSInUse)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'MS In Use',
 		d.MSInUse, i.MSInUse, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.MSInUse,'') <> isnull(d.MSInUse,'')
 
 IF UPDATE(PRInUse)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'PR In Use',
 		d.PRInUse, i.PRInUse, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.PRInUse,'') <> isnull(d.PRInUse,'')
 
 IF UPDATE(EMInUse)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'EM In Use',
 		d.EMInUse, i.EMInUse, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.EMInUse,'') <> isnull(d.EMInUse,'')
 
 IF UPDATE(APCo)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'AP Company',
 		convert(varchar(3),d.APCo), convert(varchar(3),i.APCo), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.APCo,0) <> isnull(d.APCo,0)
 
 IF UPDATE(INCo)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'IN Company',
 		convert(varchar(3),d.INCo), convert(varchar(3),i.INCo), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.INCo,0) <> isnull(d.INCo,0)
 
 IF UPDATE(MSCo)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'MS Company',
 		convert(varchar(3),d.MSCo), convert(varchar(3),i.MSCo), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.MSCo,0) <> isnull(d.MSCo,0)
 
 IF UPDATE(PRCo)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'PR Company',
 		convert(varchar(3),d.PRCo), convert(varchar(3),i.PRCo), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.PRCo,0) <> isnull(d.PRCo,0)
 
 IF UPDATE(EMCo)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'EM Company',
 		convert(varchar(3),d.EMCo), convert(varchar(3),i.EMCo), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.EMCo,0) <> isnull(d.EMCo,0)
 
 IF UPDATE(AuditCoParams)
  	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Audit Company Parameters',
 	d.AuditCoParams, i.AuditCoParams, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditCoParams,'') <> isnull(d.AuditCoParams,'')
 
 IF UPDATE(AuditDailyLogs)
  	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Audit Daily Logs',
 	d.AuditDailyLogs, i.AuditDailyLogs, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditDailyLogs,'') <> isnull(d.AuditDailyLogs,'')
 
 IF UPDATE(SLCostType)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'SL Cost Type',
 	convert(varchar(3),d.SLCostType), convert(varchar(3),i.SLCostType), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SLCostType,0) <> isnull(d.SLCostType,0)
 
 IF UPDATE(SLCostType2)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'SL Cost Type 2',
 	convert(varchar(3),d.SLCostType2), convert(varchar(3),i.SLCostType2), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SLCostType2,0) <> isnull(d.SLCostType2,0)
 
 IF UPDATE(MtlCostType)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Mtl Cost Type',
 	convert(varchar(3),d.MtlCostType), convert(varchar(3),i.MtlCostType), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.MtlCostType,0) <> isnull(d.MtlCostType,0)
 
 IF UPDATE(ShowCostType1)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Show Cost Type 1',
 	convert(varchar(3),d.ShowCostType1), convert(varchar(3),i.ShowCostType1), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.ShowCostType1,0) <> isnull(d.ShowCostType1,0)
 
 IF UPDATE(ShowCostType2)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Show Cost Type 2',
 	convert(varchar(3),d.ShowCostType2), convert(varchar(3),i.ShowCostType2), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.ShowCostType2,0) <> isnull(d.ShowCostType2,0)

 IF UPDATE(ShowCostType3)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Show Cost Type 3',
 	convert(varchar(3),d.ShowCostType3), convert(varchar(3),i.ShowCostType3), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.ShowCostType3,0) <> isnull(d.ShowCostType3,0)
 
 IF UPDATE(ShowCostType4)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Show Cost Type 4',
 	convert(varchar(3),d.ShowCostType4), convert(varchar(3),i.ShowCostType4), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.ShowCostType4,0) <> isnull(d.ShowCostType4,0)

 IF UPDATE(ShowCostType5)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Show Cost Type 5',
 	convert(varchar(3),d.ShowCostType5), convert(varchar(3),i.ShowCostType5), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.ShowCostType5,0) <> isnull(d.ShowCostType5,0)
 
 IF UPDATE(ShowCostType6)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Show Cost Type 6',
 	convert(varchar(3),d.ShowCostType6), convert(varchar(3),i.ShowCostType6), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.ShowCostType6,0) <> isnull(d.ShowCostType6,0)

 IF UPDATE(ShowCostType7)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Show Cost Type 7',
 	convert(varchar(3),d.ShowCostType7), convert(varchar(3),i.ShowCostType7), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.ShowCostType7,0) <> isnull(d.ShowCostType7,0)
 
 IF UPDATE(ShowCostType8)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Show Cost Type 8',
 	convert(varchar(3),d.ShowCostType8), convert(varchar(3),i.ShowCostType8), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.ShowCostType8,0) <> isnull(d.ShowCostType8,0)

 IF UPDATE(ShowCostType9)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Show Cost Type 9',
 	convert(varchar(3),d.ShowCostType9), convert(varchar(3),i.ShowCostType9), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.ShowCostType9,0) <> isnull(d.ShowCostType9,0)
 
 IF UPDATE(ShowCostType10)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Show Cost Type 10',
 	convert(varchar(3),d.ShowCostType10), convert(varchar(3),i.ShowCostType10), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.ShowCostType10,0) <> isnull(d.ShowCostType10,0)

 IF UPDATE(SigPartJob)
  	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'SL Significant Part Job',
 	d.SigPartJob, i.SigPartJob, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SigPartJob,'') <> isnull(d.SigPartJob,'')
 
 IF UPDATE(POSigPartJob)
  	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'PO Significant Part Job',
 	d.POSigPartJob, i.POSigPartJob, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.POSigPartJob,'') <> isnull(d.POSigPartJob,'')
 
 IF UPDATE(PhaseDescYN)
  	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Use Phase Description',
 	d.PhaseDescYN, i.PhaseDescYN, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.PhaseDescYN,'') <> isnull(d.PhaseDescYN,'')
 
 IF UPDATE(SigCharsPO)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Significant Characters PO',
 	convert(varchar(3),d.SigCharsPO), convert(varchar(3),i.SigCharsPO), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SigCharsPO,0) <> isnull(d.SigCharsPO,0)
 
 IF UPDATE(SigCharsMO)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Significant Characters MO',
 	convert(varchar(3),d.SigCharsMO), convert(varchar(3),i.SigCharsMO), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SigCharsMO,0) <> isnull(d.SigCharsMO,0)
 
 IF UPDATE(SigCharsSL)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Significant Characters SL',
 	convert(varchar(3),d.SigCharsSL), convert(varchar(3),i.SigCharsSL), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SigCharsSL,0) <> isnull(d.SigCharsSL,0)
 
 IF UPDATE(SLNo)
  	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'SLNo',
 	d.SLNo, i.SLNo, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SLNo,'') <> isnull(d.SLNo,'')
 
 IF UPDATE(PONo)
  	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'PONo',
 	d.PONo, i.PONo, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.PONo,'') <> isnull(d.PONo,'')
 
 IF UPDATE(MONo)
  	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'MONo',
 	d.MONo, i.MONo, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.MONo,'') <> isnull(d.MONo,'')
 
 IF UPDATE(OurFirm)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Our Firm',
 	convert(varchar(8),d.OurFirm), convert(varchar(8),i.OurFirm), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.OurFirm,0) <> isnull(d.OurFirm,0)
 
 IF UPDATE(SLCharsProject)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'SL Characters Project',
 	convert(varchar(3),d.SLCharsProject), convert(varchar(3),i.SLCharsProject), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SLCharsProject,0) <> isnull(d.SLCharsProject,0)
 
 IF UPDATE(SLCharsVendor)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'SL Characters Vendor',
 	convert(varchar(3),d.SLCharsVendor), convert(varchar(3),i.SLCharsVendor), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SLCharsVendor,0) <> isnull(d.SLCharsVendor,0)
 
 IF UPDATE(POCharsProject)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'PO Characters Project',
 	convert(varchar(3),d.POCharsProject), convert(varchar(3),i.POCharsProject), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.POCharsProject,0) <> isnull(d.POCharsProject,0)
 
 IF UPDATE(POCharsVendor)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'PO Characters Vendor',
 	convert(varchar(3),d.POCharsVendor), convert(varchar(3),i.POCharsVendor), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.POCharsVendor,0) <> isnull(d.POCharsVendor,0)
 
 IF UPDATE(MOCharsProject)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'MO Characters Project',
 	convert(varchar(3),d.MOCharsProject), convert(varchar(3),i.MOCharsProject), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.MOCharsProject,0) <> isnull(d.MOCharsProject,0)
 
 IF UPDATE(SLSeqLen)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'SL Sequence Length',
 	convert(varchar(3),d.SLSeqLen), convert(varchar(3),i.SLSeqLen), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SLSeqLen,0) <> isnull(d.SLSeqLen,0)
 
 IF UPDATE(POSeqLen)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'PO Sequence Length',
 	convert(varchar(3),d.POSeqLen), convert(varchar(3),i.POSeqLen), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.POSeqLen,0) <> isnull(d.POSeqLen,0)
 
 IF UPDATE(MOSeqLen)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'MO Sequence Length',
 	convert(varchar(3),d.MOSeqLen), convert(varchar(3),i.MOSeqLen), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.MOSeqLen,0) <> isnull(d.MOSeqLen,0)
 
IF UPDATE(SLCT1Option)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Subcontract Cost Type Option',
 	convert(varchar(3),d.SLCT1Option), convert(varchar(3),i.SLCT1Option), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SLCT1Option,0) <> isnull(d.SLCT1Option,0)
 
IF UPDATE(MTCT1Option)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Material Cost Type Option',
 	convert(varchar(3),d.MTCT1Option), convert(varchar(3),i.MTCT1Option), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.MTCT1Option,0) <> isnull(d.MTCT1Option,0)
IF UPDATE(MOGroupByLoc)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'MO Group Locations Flag',
 	d.MOGroupByLoc, i.MOGroupByLoc, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.MOGroupByLoc,'') <> isnull(d.MOGroupByLoc,'')
IF UPDATE(BeginStatus)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Begin Status',
 	d.BeginStatus, i.BeginStatus, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.BeginStatus,'') <> isnull(d.BeginStatus,'')
IF UPDATE(FinalStatus)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Final Status',
 	d.FinalStatus, i.FinalStatus, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.FinalStatus,'') <> isnull(d.FinalStatus,'')
IF UPDATE(APVendUpdYN)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'AP Vendor Update Flag',
 	d.APVendUpdYN, i.APVendUpdYN, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.APVendUpdYN,'') <> isnull(d.APVendUpdYN,'')
IF UPDATE(DocTrackView)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Document Tracking View',
 	d.DocTrackView, i.DocTrackView, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.DocTrackView,'') <> isnull(d.DocTrackView,'')
IF UPDATE(RQInUse)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'RQ In Use',
	d.RQInUse, i.RQInUse, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.RQInUse,'') <> isnull(d.RQInUse,'')
IF UPDATE(POCreate)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'PO Create',
	d.POCreate, i.POCreate, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.POCreate,'') <> isnull(d.POCreate,'')
IF UPDATE(MOCreate)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'MO Create',
	d.MOCreate, i.MOCreate, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.MOCreate,'') <> isnull(d.MOCreate,'')
IF UPDATE(SLStartSeq)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'SL Starting Sequence',
 	convert(varchar(3),d.SLStartSeq), convert(varchar(3),i.SLStartSeq), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SLStartSeq,0) <> isnull(d.SLStartSeq,0)
IF UPDATE(POStartSeq)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'PO Starting Sequence',
 	convert(varchar(3),d.POStartSeq), convert(varchar(3),i.POStartSeq), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.POStartSeq,0) <> isnull(d.POStartSeq,0)
IF UPDATE(MOStartSeq)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'MO Starting Sequence',
 	convert(varchar(3),d.MOStartSeq), convert(varchar(3),i.MOStartSeq), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.MOStartSeq,0) <> isnull(d.MOStartSeq,0)
IF UPDATE(DocHistACO)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'DocHistACO', d.DocHistACO, i.DocHistACO, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.DocHistACO,'') <> isnull(d.DocHistACO,'')
IF UPDATE(DocHistDrawing)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'DocHistDrawing', d.DocHistDrawing, i.DocHistDrawing, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.DocHistDrawing,'') <> isnull(d.DocHistDrawing,'')
IF UPDATE(DocHistInspect)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'DocHistInspect', d.DocHistInspect, i.DocHistInspect, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.DocHistInspect,'') <> isnull(d.DocHistInspect,'')
IF UPDATE(DocHistOtherDoc)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'DocHistOtherDoc', d.DocHistOtherDoc, i.DocHistOtherDoc, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.DocHistOtherDoc,'') <> isnull(d.DocHistOtherDoc,'')
IF UPDATE(DocHistPCO)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'DocHistPCO', d.DocHistPCO, i.DocHistPCO, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.DocHistPCO,'') <> isnull(d.DocHistPCO,'')
IF UPDATE(DocHistPunchList)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'DocHistPunchList', d.DocHistPunchList, i.DocHistPunchList, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.DocHistPunchList,'') <> isnull(d.DocHistPunchList,'')
IF UPDATE(DocHistRFI)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'DocHistRFI', d.DocHistRFI, i.DocHistRFI, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.DocHistRFI,'') <> isnull(d.DocHistRFI,'')
IF UPDATE(DocHistRFQ)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'DocHistRFQ', d.DocHistRFQ, i.DocHistRFQ, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.DocHistRFQ,'') <> isnull(d.DocHistRFQ,'')
IF UPDATE(DocHistSubmittal)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'DocHistSubmittal', d.DocHistSubmittal, i.DocHistSubmittal, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.DocHistSubmittal,'') <> isnull(d.DocHistSubmittal,'')
IF UPDATE(DocHistTestLog)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'DocHistTestLog', d.DocHistTestLog, i.DocHistTestLog, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.DocHistTestLog,'') <> isnull(d.DocHistTestLog,'')
IF UPDATE(DocHistTransmittal)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'DocHistTransmittal', d.DocHistTransmittal, i.DocHistTransmittal, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.DocHistTransmittal,'') <> isnull(d.DocHistTransmittal,'')
IF UPDATE(AuditPMCA)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMCA', d.AuditPMCA, i.AuditPMCA, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMCA,'') <> isnull(d.AuditPMCA,'')
IF UPDATE(AuditPMEC)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMEC', d.AuditPMEC, i.AuditPMEC, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMEC,'') <> isnull(d.AuditPMEC,'')
IF UPDATE(AuditPMEH)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMEH', d.AuditPMEH, i.AuditPMEH, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMEH,'') <> isnull(d.AuditPMEH,'')
IF UPDATE(AuditPMFM)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMFM', d.AuditPMFM, i.AuditPMFM, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMFM,'') <> isnull(d.AuditPMFM,'')
IF UPDATE(AuditPMIM)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMIM', d.AuditPMIM, i.AuditPMIM, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMIM,'') <> isnull(d.AuditPMIM,'')
IF UPDATE(AuditPMMF)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMMF', d.AuditPMMF, i.AuditPMMF, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMMF,'') <> isnull(d.AuditPMMF,'')
IF UPDATE(AuditPMMM)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMMM', d.AuditPMMM, i.AuditPMMM, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMMM,'') <> isnull(d.AuditPMMM,'')
IF UPDATE(AuditPMNR)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMNR', d.AuditPMNR, i.AuditPMNR, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMNR,'') <> isnull(d.AuditPMNR,'')
IF UPDATE(AuditPMPA)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMPA', d.AuditPMPA, i.AuditPMPA, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMPA,'') <> isnull(d.AuditPMPA,'')
IF UPDATE(AuditPMPC)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMPC', d.AuditPMPC, i.AuditPMPC, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMPC,'') <> isnull(d.AuditPMPC,'')
IF UPDATE(AuditPMPF)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMPF', d.AuditPMPF, i.AuditPMPF, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMPF,'') <> isnull(d.AuditPMPF,'')
IF UPDATE(AuditPMPL)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMPL', d.AuditPMPL, i.AuditPMPL, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMPL,'') <> isnull(d.AuditPMPL,'')
IF UPDATE(AuditPMPM)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMPM', d.AuditPMPM, i.AuditPMPM, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMPM,'') <> isnull(d.AuditPMPM,'')
IF UPDATE(AuditPMPN)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMPN', d.AuditPMPN, i.AuditPMPN, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMPN,'') <> isnull(d.AuditPMPN,'')
IF UPDATE(AuditPMSL)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMSL', d.AuditPMSL, i.AuditPMSL, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMSL,'') <> isnull(d.AuditPMSL,'')
IF UPDATE(AuditPMTH)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'AuditPMTH', d.AuditPMTH, i.AuditPMTH, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.AuditPMTH,'') <> isnull(d.AuditPMTH,'')
IF UPDATE(FaxServerName)
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'FaxServerName', d.FaxServerName, i.FaxServerName, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.FaxServerName,'') <> isnull(d.FaxServerName,'')
--#21452
If update(AttachBatchReportsYN)
	begin
	insert into bHQMA select 'bPMCO', 'PM Co#: ' + convert(char(3),i.PMCo), i.PMCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.PMCo = d.PMCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
	end
----#129667
IF UPDATE(POAddOrigOpen)
	begin
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'POAddOrigOpen', d.POAddOrigOpen, i.POAddOrigOpen, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.POAddOrigOpen,'') <> isnull(d.POAddOrigOpen,'')
	end
IF UPDATE(POAddChgOpen)
	begin
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'POAddChgOpen', d.POAddChgOpen, i.POAddChgOpen, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.POAddChgOpen,'') <> isnull(d.POAddChgOpen,'')
	end
----#129666
IF UPDATE(MatlPhaseDesc)
	begin
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'MatlPhaseDesc', d.MatlPhaseDesc, i.MatlPhaseDesc, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.MatlPhaseDesc,'') <> isnull(d.MatlPhaseDesc,'')
	end
IF UPDATE(MatlCostType2)
	begin
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C', 'Material Cost Type 2',
 	convert(varchar(3),d.MatlCostType2), convert(varchar(3),i.MatlCostType2), getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.MatlCostType2, 0) <> isnull(d.MatlCostType2, 0)
 	end
----#136053
IF UPDATE(SLItemCOAutoAdd)
	begin
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'SLItemCOAutoAdd', d.SLItemCOAutoAdd, i.SLItemCOAutoAdd, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SLItemCOAutoAdd,'') <> isnull(d.SLItemCOAutoAdd,'')
	end
----#136053
IF UPDATE(SLItemCOManual)
	begin
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'SLItemCOAutoAdd', d.SLItemCOManual, i.SLItemCOManual, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.SLItemCOManual,'') <> isnull(d.SLItemCOManual,'')
	end
----TK-00000
IF UPDATE(UseApprSubCo)
	begin
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bPMCO', 'PM Co#: ' + isnull(convert(varchar(3),i.PMCo),''), i.PMCo, 'C',
		'UseApprSubCo', d.UseApprSubCo, i.UseApprSubCo, getdate(), SUSER_SNAME()
 	from inserted i join deleted d on i.PMCo = d.PMCo
 	where isnull(i.UseApprSubCo,'') <> isnull(d.UseApprSubCo,'')
	end
	
	
RETURN 




GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_AllowMOCharsProject] CHECK (([MONo]<>'P' OR [MOCharsProject] IS NOT NULL AND [MOCharsProject]>=(0) AND [MOCharsProject]<=(10)))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_AllowMONo] CHECK (([MONo]='L' OR [MONo]='P'))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_AllowPCOToSLSync] CHECK (([AllowPCOToSLSync]='Y' OR [AllowPCOToSLSync]='N'))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_AllowPOCharsProject] CHECK (([PONo]<>'P' OR [POCharsProject] IS NOT NULL AND [POCharsProject]>=(0) AND [POCharsProject]<=(10)))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_AllowPOCharsVendor] CHECK (([PONo]<>'V' OR [POCharsVendor] IS NOT NULL AND [POCharsVendor]>=(0) AND [POCharsVendor]<=(10)))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_AllowPONo] CHECK (([PONo]='A' OR [PONo]='V' OR [PONo]='P'))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_AllowSLCharsProject] CHECK (([SLNo]<>'P' OR [SLCharsProject] IS NOT NULL AND [SLCharsProject]>=(0) AND [SLCharsProject]<=(10)))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_AllowSLCharsVendor] CHECK (([SLNo]<>'V' OR [SLCharsVendor] IS NOT NULL AND [SLCharsVendor]>=(0) AND [SLCharsVendor]<=(10)))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_AllowSLNo] CHECK (([SLNo]='S' OR [SLNo]='V' OR [SLNo]='P'))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_DocHistPOCONum] CHECK (([DocHistPOCONum]='Y' OR [DocHistPOCONum]='N'))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_DocHistSubCO] CHECK (([DocHistSubCO]='Y' OR [DocHistSubCO]='N'))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_MTCT1Option] CHECK (([MTCT1Option]=(3) OR [MTCT1Option]=(2) OR [MTCT1Option]=(1)))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_MatlPhaseDesc] CHECK (([MatlPhaseDesc]='Y' OR [MatlPhaseDesc]='N'))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_POAddChgOpen] CHECK (([POAddChgOpen]='Y' OR [POAddChgOpen]='N'))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_POAddOrigOpen] CHECK (([POAddOrigOpen]='Y' OR [POAddOrigOpen]='N'))
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [CK_bPMCO_SLCT1Option] CHECK (([SLCT1Option]=(3) OR [SLCT1Option]=(2) OR [SLCT1Option]=(1)))
GO
ALTER TABLE [dbo].[bPMCO] ADD CONSTRAINT [PK_bPMCO] PRIMARY KEY CLUSTERED  ([PMCo]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bPMCO_KeyID] ON [dbo].[bPMCO] ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [FK_bPMCO_bJCCT_MtlCostType] FOREIGN KEY ([PhaseGroup], [MtlCostType]) REFERENCES [dbo].[bJCCT] ([PhaseGroup], [CostType])
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [FK_bPMCO_bJCCT_SLCostType] FOREIGN KEY ([PhaseGroup], [SLCostType]) REFERENCES [dbo].[bJCCT] ([PhaseGroup], [CostType])
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [FK_bPMCO_bJCCT_SLCostType2] FOREIGN KEY ([PhaseGroup], [SLCostType2]) REFERENCES [dbo].[bJCCT] ([PhaseGroup], [CostType])
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [FK_bPMCO_bHQCO] FOREIGN KEY ([PMCo]) REFERENCES [dbo].[bHQCO] ([HQCo])
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [FK_bPMCO_bJCCO] FOREIGN KEY ([PMCo]) REFERENCES [dbo].[bJCCO] ([JCCo])
GO
ALTER TABLE [dbo].[bPMCO] WITH NOCHECK ADD CONSTRAINT [FK_bPMCO_bPMFM] FOREIGN KEY ([VendorGroup], [OurFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
