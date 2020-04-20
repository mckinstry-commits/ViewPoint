CREATE TABLE [dbo].[bPRCO]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[Jrnl] [dbo].[bJrnl] NULL,
[GLInterface] [dbo].[bYN] NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[APCo] [dbo].[bCompany] NULL,
[AutoOT] [dbo].[bYN] NOT NULL,
[OTEarnCode] [dbo].[bEDLCode] NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[AllowNoPhase] [dbo].[bYN] NOT NULL,
[JCInterface] [dbo].[bYN] NOT NULL,
[InsByPhase] [dbo].[bYN] NOT NULL,
[JCICraftClass] [dbo].[bYN] NOT NULL,
[JCICrew] [dbo].[bYN] NOT NULL,
[JCIEmployee] [dbo].[bYN] NOT NULL,
[JCIFactor] [dbo].[bYN] NOT NULL,
[JCIEarnType] [dbo].[bYN] NOT NULL,
[JCIShift] [dbo].[bYN] NOT NULL,
[JCIPostingDate] [dbo].[bYN] NOT NULL,
[JCILiabType] [dbo].[bYN] NOT NULL,
[JCIEquip] [dbo].[bYN] NOT NULL,
[JCIRevCode] [dbo].[bYN] NOT NULL,
[EMCo] [dbo].[bCompany] NULL,
[EMUsage] [dbo].[bYN] NOT NULL,
[EMInterface] [dbo].[bYN] NOT NULL,
[EMRevEmployee] [dbo].[bYN] NOT NULL,
[EMRevPhase] [dbo].[bYN] NOT NULL,
[EMRevPostingDate] [dbo].[bYN] NOT NULL,
[EMCostEmployee] [dbo].[bYN] NOT NULL,
[OfficeState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[OfficeLocal] [dbo].[bLocalCode] NULL,
[TaxStateOpt] [dbo].[bYN] NOT NULL,
[UnempStateOpt] [dbo].[bYN] NOT NULL,
[InsStateOpt] [dbo].[bYN] NOT NULL,
[LocalOpt] [dbo].[bYN] NOT NULL,
[AuditCoParams] [dbo].[bYN] NOT NULL,
[AuditEmployees] [dbo].[bYN] NOT NULL,
[AuditAccums] [dbo].[bYN] NOT NULL,
[AuditPayHistory] [dbo].[bYN] NOT NULL,
[AuditDLs] [dbo].[bYN] NOT NULL,
[AuditCraftClass] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[CheckReportTitle] [char] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[EFTReportTitle] [char] (60) COLLATE Latin1_General_BIN NULL,
[NonNegCheckPrint] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_NonNegCheckPrint] DEFAULT ('N'),
[CrewRegEC] [dbo].[bEDLCode] NULL,
[CrewOTEC] [dbo].[bEDLCode] NULL,
[CrewDblEC] [dbo].[bEDLCode] NULL,
[AuditTaxes] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_AuditTaxes] DEFAULT ('N'),
[AuditStateIns] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_AuditStateIns] DEFAULT ('N'),
[ExcludeSSN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_ExcludeSSN] DEFAULT ('N'),
[JCILiabFactor] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_JCILiabFactor] DEFAULT ('N'),
[JCILiabShift] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_JCILiabShift] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_AttachBatchReportsYN] DEFAULT ('N'),
[AttachPayStubYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_AttachPayStubYN] DEFAULT ('N'),
[PayStubAttachTypeID] [int] NULL,
[CheckReportTitleByEmp] [char] (60) COLLATE Latin1_General_BIN NULL,
[EFTReportTitleByEmp] [char] (60) COLLATE Latin1_General_BIN NULL,
[W2AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_W2AutditYN] DEFAULT ('N'),
[MessageFileStatusYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_MessageFileStatusYN] DEFAULT ('Y'),
[SMInterface] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_SMInterface] DEFAULT ('N'),
[SMCo] [dbo].[bCompany] NULL,
[AutoOTUseVariableRatesYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_AutoOTUseVariableRatesYN] DEFAULT ('Y'),
[AutoOTUseHighestRateYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCO_AutoOTUseHighestRateYN] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRCO] ON [dbo].[bPRCO] ([PRCo]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCOd    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE  trigger [dbo].[btPRCOd] on [dbo].[bPRCO] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: kb 10/30/98
    *  Modified:	EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	This trigger rejects delete in bPRCO (Companies) if a dependent record is found in:
    *
    *      bPREC - Earn Codes
    * 		bPRDL - Dedn/Liab Codes
    * 		bPRRM - Routine Master
    *      bPRGR - Groups
    * 		bPRDP - Dept Master
    *      bPRFI - Federal Info
    *      bPRSI - State Info
    * 		bPRLI - Local Info
    *      bPRCM - Craft Master
    *      bPROT - Overtime Schedule
    *      bPRTM - Template Master
    *      bPREH - Employee Header
    * 		bPROP - Occupational Category
    *      bPRGG - Garnishment Groups
    * 		bPRCR - Crew Master
    * 		bPRRC - Race Codes
    * 		bPRLV - Leave Codes
    *
    * Removes entries for the deleted company from bPRUP (User Posting Options)
    * Inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @prco bCompany
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   /* Check bPREC - Earn Codes */
   if exists(select * from dbo.bPREC a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Earnings Code table (bPREC) for this company '
     	goto error
     	end
   
   /* Check bPRDL - Dedn/Liab Codes */
   if exists(select * from dbo.bPRDL a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Dedn/Liab Codes table (bPRDL) for this company '
     	goto error
     	end
   
   /* Check bPRRM - Routine Master */
   if exists(select * from dbo.bPRRM a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Routine Master table (bPRRM) for this company '
     	goto error
     	end
   
   /* Check bPRGR - Groups */
   if exists(select * from dbo.bPRGR a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Groups table (bPRGR) for this company '
     	goto error
     	end
   
   /* Check bPRRM - Routine Master */
   if exists(select * from dbo.bPRRM a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Routine Master table (bPRRM) for this company '
     	goto error
     	end
   
   /* Check bPRDP - Dept Master */
   if exists(select * from dbo.bPRDP a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Dept Master table (bPRDP) for this company '
     	goto error
     	end
   
   /* Check bPRFI - Federal Info */
   if exists(select * from dbo.bPRFI a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Federal Info table (bPRFI) for this company '
     	goto error
     	end
   
   /* Check bPRSI - State Info */
   if exists(select * from dbo.bPRSI a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in State Info table (bPRSI) for this company '
     	goto error
     	end
   
   /* Check bPRLI - Local Info */
   if exists(select * from dbo.bPRLI a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Local Info table (bPRLI) for this company '
     	goto error
     	end
   
   /* Check bPRCM - Craft Master */
   if exists(select * from dbo.bPRCM a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Craft Master table (bPRCM) for this company '
     	goto error
     	end
   
   /* Check bPROT - Overtime Schedule */
   if exists(select * from dbo.bPROT a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Overtime Schedule table (bPROT) for this company '
     	goto error
     	end
   
   /* Check bPRTM - Template Master */
   if exists(select * from dbo.bPRTM a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Template Master table (bPRTM) for this company '
     	goto error
     	end
   
   /* Check bPREH - Employee Header */
   if exists(select * from dbo.bPREH a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Employee Header table (bPREH) for this company '
     	goto error
     	end
   
   /* Check bPROP - Occupational Category */
   if exists(select * from dbo.bPROP a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Occupational Category table (bPROP) for this company '
     	goto error
     	end
   
   /* Check bPRGG - Garnishment Groups */
   if exists(select * from dbo.bPRGG a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Garnishment Groups table (bPRGG) for this company '
     	goto error
     	end
   
   /* Check bPRCR - Crew Master */
   if exists(select * from dbo.bPRCR a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Crew Master table (bPRCR) for this company '
     	goto error
     	end
   
   /* Check bPRRC - Race Codes */
   if exists(select * from dbo.bPRRC a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Race Codes table (bPRRC) for this company '
     	goto error
     	end
   
   /* Check bPRLV - Leave Codes */
   if exists(select * from dbo.bPRLV a with (nolock) join deleted d on a.PRCo = d.PRCo)
     	begin
     	select @errmsg = 'Records exist in Leave Codes table (bPRLV) for this company '
     	goto error
     	end
   
   /* Check bPRUP - User Posting Opts */
   SELECT @prco = min(PRCo) from deleted
   WHILE @prco is not null
       BEGIN
       delete from dbo.bPRUP where PRCo = @prco
   
       SELECT @prco = min(PRCo) from deleted where PRCo > @prco
       END
   
   /* Audit PR Company deletions */
   insert into dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCO', 'PR Co#: ' + convert(varchar(3),PRCo),
   		PRCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted
   if @@rowcount <> @numrows
   	begin
   	select @errmsg = 'Unable to update HQ Master Audit '
   	goto error
   	end
   return
   
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btPRCOi] on [dbo].[bPRCO] for INSERT as
/*-----------------------------------------------------------------
* Created: kb 10/29/98
* Modified: EN 4/6/00 - validate that AuditCoParams is checked.
*			EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
*			GG 04/20/07 - #30116 - data security review
*			  TRL 02/18/08 --#21452	
*			mh 2/26/09 - #125436 - Rejecting insert if AttachPayStubYN = 'Y' and PayStubAttachTypeID
*						is null
*
*	This trigger rejects insertion in bPRCO (PR Employee Master) if the
*	following error condition exists:
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
/* validate PR Company */
select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid PR Company#, must be setup in HQ first'
	goto error
	end

/* validate AuditCoParams */
select @validcnt = count(*) from inserted where AuditCoParams = 'Y'
if @validcnt <> @numrows
	begin
	select @errmsg = 'Option to audit company parameters must be checked.'
	goto error
	end

/* If Attach Pay Stub is checked require PayStubAttachID */
if (select count(1) from inserted where AttachPayStubYN = 'Y' and PayStubAttachTypeID is null) > 0
begin
	select @errmsg = 'Pay Stub Attachment Type ID required when AttachPayStubYN = ''Y'''
	goto error
end
   
/* add HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPRCO',  'PR Co#: ' + convert(char(3), PRCo), PRCo, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted

--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPRCO',  'PR Co#: ' + convert(char(3), PRCo), PRCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bPRCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bPRCo', i.PRCo, i.PRCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bPRCo' and s.Qualifier = i.PRCo 
						and s.Instance = convert(char(30),i.PRCo) and s.SecurityGroup = @dfltsecgroup)
	end    
   
return

error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
 /****** Object:  Trigger dbo.btPRCOu    Script Date: 8/28/99 9:38:10 AM ******/
  CREATE            trigger [dbo].[btPRCOu] on [dbo].[bPRCO] for UPDATE as
 
/*-----------------------------------------------------------------
*  Created: kb 10/29/98
*  Modified: EN 4/6/00 - validate that AuditCoParams is checked.
*            GG 5/18/00 - added JCIShift column - general cleanup
*            EN 10/09/00 - Checking for key changes incorrectly
*            DANF 02/21/02 Added Audit of CheckReportTitle, EFTReportTitle
*			  EN 8/2/02 issue 11029 Added audit of NonNegCheckPrint field
*			  EN 02/11/03 - issue 23061  added isnull check, and dbo
      ES 03/04/04 - issue 23814 Added audit of AuditStateIns field
*			EN 3/23/04 - issue 23996 do not allow GLCo change if it exists in bPRDP
*			EN 9/24/04 - issue 20562 removed audit code for obsolete field LiabDist
*			EN 11/22/04 - issue 22571  relabel "Posting Date" and "Post Date" to "Timecard Date"
*			EN 10/18/05 - issue 30106 shortened Field Name "EM Revenue Detail - Timecard Date" because is was over 30 chars and caused an error
*			  TRL 02/18/08 --#21452	
*			EN 8/6/08 - #127108 fixed typo in audit code for JCIPostingDate field
*			mh 02/14/09 - #125436 Added audit entries 
*			CHS	11/15/2010	- #1338416 - add flag to suppress filing status message.
*			EN 7/11/2012  B-09337/#144937 add auditing for additional rate options and other fields added over the last few years that were missed
*							additional rate option fields: AutoOTUseVariableRatesYN and AutoOTUseHighestRateYN
*
* Validates and inserts HQ Master Audit entry.
*
*		Cannot change primary key - PR Company
*/----------------------------------------------------------------
  declare @errmsg varchar(255), @numrows int, @validcnt int
  select @numrows = @@rowcount
  if @numrows = 0 return
  
  set nocount on
  
  /* check for key changes */
  if update(PRCo)
      begin
      select @validcnt = count(*) from deleted d
           join inserted i on d.PRCo = i.PRCo
      if @validcnt <> @numrows
      	begin
      	select @errmsg = 'Cannot change PR Company '
      	goto error
      	end
      end
  
  -- issue 23996  cannot change GLCo if records exist in bPRDP
  select @validcnt = count(*) from deleted d
  	join inserted i on d.PRCo = i.PRCo and d.GLCo <> i.GLCo
  	join bPRDP a on a.PRCo = d.PRCo and a.GLCo = d.GLCo
  if @validcnt <> 0
   	begin
   	select @errmsg = 'Cannot change GL Company, Department records exist'
   	goto error
   	end
  
  /* validate AuditCoParams */
  select @validcnt = count(*) from inserted where AuditCoParams = 'Y'
  if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Option to audit company parameters must be checked.'
  	goto error
  	end
  
  /* Insert records into HQMA for changes made to audited fields */
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'GL Company', convert(char(3),d.GLCo), Convert(varchar(3),i.GLCo),
  	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.GLCo <> d.GLCo
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'GL Jrnl', convert(varchar(10),d.Jrnl), Convert(varchar(10),i.Jrnl),
  	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where isnull(i.Jrnl,'') <> isnull(d.Jrnl,'')
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'GL Interface', d.GLInterface, i.GLInterface, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.GLInterface <> d.GLInterface
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'CM Company', convert(char(3),d.CMCo), Convert(char(3),i.CMCo),
  	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.CMCo <> d.CMCo
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'AP Company', convert(char(3),d.APCo), Convert(char(3),i.APCo),
  	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where isnull(i.APCo,0) <> isnull(d.APCo,0)
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Auto OT Option', d.AutoOT, i.AutoOT, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.AutoOT <> d.AutoOT
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'OT Earn Code', convert(varchar(10),d.OTEarnCode), Convert(char(10),i.OTEarnCode),
  	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where isnull(i.OTEarnCode,0) <> isnull(d.OTEarnCode,0)
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'JC Company', convert(char(3),d.JCCo), Convert(char(3),i.JCCo),
  	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.JCCo <> d.JCCo
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Allow No Phase', d.AllowNoPhase, i.AllowNoPhase, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.AllowNoPhase <> d.AllowNoPhase
  
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'JC Interface', d.JCInterface, i.JCInterface, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.JCInterface <> d.JCInterface
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Insurance By Phase', d.InsByPhase, i.InsByPhase, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.InsByPhase <> d.InsByPhase
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'JC Detail - Craft/Class', d.JCICraftClass, i.JCICraftClass, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.JCICraftClass <> d.JCICraftClass
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'JC Detail - Crew', d.JCICrew, i.JCICrew, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.JCICrew <> d.JCICrew
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'JC Detail - Employee', d.JCIEmployee, i.JCIEmployee, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.JCIEmployee <> d.JCIEmployee
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'JC Detail - Factor', d.JCIFactor, i.JCIFactor, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.JCIFactor <> d.JCIFactor
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'JC Detail - Earn Type', d.JCIEarnType, i.JCIEarnType, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.JCIEarnType <> d.JCIEarnType
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'JC Detail - Shift', d.JCIShift, i.JCIShift, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.JCIShift <> d.JCIShift
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'JC Detail - Timecard Date', d.JCIPostingDate, i.JCIPostingDate,	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.JCIPostingDate <> d.JCIPostingDate --#127108
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'JC Detail - Liability Type', d.JCILiabType, i.JCILiabType,	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.JCILiabType <> d.JCILiabType
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'JC Detail - Equipment', d.JCIEquip, i.JCIEquip, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.JCIEquip <> d.JCIEquip
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'JC Detail - Revenue Code', d.JCIRevCode, i.JCIRevCode,	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.JCIRevCode <> d.JCIRevCode
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'EM Company', convert(char(3),d.EMCo), Convert(char(3),i.EMCo),
  	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where isnull(i.EMCo,0) <> isnull(d.EMCo,0)
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'EM Usage', d.EMUsage, i.EMUsage, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.EMUsage <> d.EMUsage
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'EM Interface', d.EMInterface, i.EMInterface, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.EMInterface <> d.EMInterface
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'EM Revenue Detail - Employee', d.EMRevEmployee, i.EMRevEmployee, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.EMRevEmployee <> d.EMRevEmployee
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'EM Revenue Detail - Phase', d.EMRevPhase, i.EMRevPhase, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.EMRevPhase <> d.EMRevPhase
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'EM Rev Detail - Timecard Date', d.EMRevPostingDate, i.EMRevPostingDate,
  	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.EMRevPostingDate <> d.EMRevPostingDate
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'EM Cost Detail - Employee', d.EMCostEmployee, i.EMCostEmployee,
  	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.EMCostEmployee <> d.EMCostEmployee
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Office State', d.OfficeState, i.OfficeState, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where isnull(i.OfficeState,'') <> isnull(d.OfficeState,'')
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Office Local', d.OfficeLocal, i.OfficeLocal, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where isnull(i.OfficeLocal,'') <> isnull(d.OfficeLocal,'')
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Tax State Option', d.TaxStateOpt, i.TaxStateOpt, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.TaxStateOpt <> d.TaxStateOpt
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Unemployment State Option', d.UnempStateOpt, i.UnempStateOpt, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.UnempStateOpt <> d.UnempStateOpt
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Insurance State Option', d.InsStateOpt, i.InsStateOpt,	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.InsStateOpt <> d.InsStateOpt
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Local Option', d.LocalOpt, i.LocalOpt,	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.LocalOpt <> d.LocalOpt
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Audit Company', d.AuditCoParams, i.AuditCoParams, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.AuditCoParams <> d.AuditCoParams
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Audit Employees', d.AuditEmployees, i.AuditEmployees, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.AuditEmployees <> d.AuditEmployees
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Audit Accumulations', d.AuditAccums, i.AuditAccums, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.AuditAccums <> d.AuditAccums
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Audit Pay History', d.AuditPayHistory, i.AuditPayHistory, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.AuditPayHistory <> d.AuditPayHistory
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Audit Deductions/Liabilities', d.AuditDLs, i.AuditDLs,	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.AuditDLs <> d.AuditDLs
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Audit Craft/Class', d.AuditCraftClass, i.AuditCraftClass, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.AuditCraftClass <> d.AuditCraftClass
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Audit Check Report Title', d.CheckReportTitle, i.CheckReportTitle,	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.CheckReportTitle <> d.CheckReportTitle
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Audit Taxes', d.AuditTaxes, i.AuditTaxes,	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.AuditTaxes <> d.AuditTaxes
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Audit State Insurance', d.AuditStateIns, i.AuditStateIns,	getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.AuditStateIns <> d.AuditStateIns
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Audit EFT Report Title', d.EFTReportTitle, i.EFTReportTitle, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.EFTReportTitle <> d.EFTReportTitle
  insert into dbo.bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
  	'Non-Negotiable Check Print', d.NonNegCheckPrint, i.NonNegCheckPrint, getdate(), SUSER_SNAME()
  	from inserted i join deleted d
  	on i.PRCo = d.PRCo where i.NonNegCheckPrint <> d.NonNegCheckPrint
  
--#21452
If update(AttachBatchReportsYN)
begin
	insert into bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.PRCo = d.PRCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
end

--#125436
If update(AttachPayStubYN)
begin
	insert into bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
   	'AttachPayStubYN', d.AttachPayStubYN, i.AttachPayStubYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.PRCo = d.PRCo and i.AttachPayStubYN <> d.AttachPayStubYN
end

If update(PayStubAttachTypeID)
begin
	insert into bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
   	'PayStubAttachTypeID', d.PayStubAttachTypeID, i.PayStubAttachTypeID,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.PRCo = d.PRCo and i.PayStubAttachTypeID <> d.PayStubAttachTypeID
end

If update(CheckReportTitleByEmp)
begin
	insert into bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
   	'CheckReportTitleByEmp', d.CheckReportTitleByEmp, i.CheckReportTitleByEmp,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.PRCo = d.PRCo and i.CheckReportTitleByEmp <> d.CheckReportTitleByEmp
end

If update(EFTReportTitleByEmp)
begin
	insert into bHQMA select 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
   	'EFTReportTypeByEmp', d.EFTReportTitleByEmp, i.EFTReportTitleByEmp,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.PRCo = d.PRCo and i.EFTReportTitleByEmp <> d.EFTReportTitleByEmp
end

IF UPDATE(W2AuditYN)
BEGIN
	INSERT INTO bHQMA SELECT 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
   	'W2AuditYN', d.W2AuditYN, i.W2AuditYN,
   	getdate(), SUSER_SNAME()
   	FROM inserted i, deleted d
   	WHERE i.PRCo = d.PRCo and i.W2AuditYN <> d.W2AuditYN
END

IF UPDATE(MessageFileStatusYN)

BEGIN
	INSERT INTO bHQMA SELECT 'bPRCO', 
	'PR Co#: ' + convert(char(3),i.PRCo), 
	i.PRCo, 
	'C',
   	'MessageFileStatusYN', 
   	d.MessageFileStatusYN, 
   	i.MessageFileStatusYN,
   	getdate(), 
   	SUSER_SNAME()
   	FROM inserted i
   	join deleted d on i.PRCo = d.PRCo 
   	WHERE i.MessageFileStatusYN <> d.MessageFileStatusYN
END

--IF UPDATE(CrewRegEC)
--BEGIN
--	INSERT INTO bHQMA SELECT 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
--   	'CrewRegEC', d.CrewRegEC, i.CrewRegEC,
--   	GETDATE(), SUSER_SNAME()
--   	FROM inserted i, deleted d
--   	WHERE i.PRCo = d.PRCo AND i.CrewRegEC <> d.CrewRegEC
--END
--IF UPDATE(CrewOTEC)
--BEGIN
--	INSERT INTO bHQMA SELECT 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
--   	'CrewOTEC', d.CrewOTEC, i.CrewOTEC,
--   	GETDATE(), SUSER_SNAME()
--   	FROM inserted i, deleted d
--   	WHERE i.PRCo = d.PRCo AND i.CrewOTEC <> d.CrewOTEC
--END
--IF UPDATE(CrewDblEC)
--BEGIN
--	INSERT INTO bHQMA SELECT 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
--   	'CrewDblEC', d.CrewDblEC, i.CrewDblEC,
--   	GETDATE(), SUSER_SNAME()
--   	FROM inserted i, deleted d
--   	WHERE i.PRCo = d.PRCo AND i.CrewDblEC <> d.CrewDblEC
--END
--IF UPDATE(ExcludeSSN)
--BEGIN
--	INSERT INTO bHQMA SELECT 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
--   	'ExcludeSSN', d.ExcludeSSN, i.ExcludeSSN,
--   	GETDATE(), SUSER_SNAME()
--   	FROM inserted i, deleted d
--   	WHERE i.PRCo = d.PRCo AND i.ExcludeSSN <> d.ExcludeSSN
--END
--IF UPDATE(JCILiabFactor)
--BEGIN
--	INSERT INTO bHQMA SELECT 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
--   	'JCILiabFactor', d.JCILiabFactor, i.JCILiabFactor,
--   	GETDATE(), SUSER_SNAME()
--   	FROM inserted i, deleted d
--   	WHERE i.PRCo = d.PRCo AND i.JCILiabFactor <> d.JCILiabFactor
--END
--IF UPDATE(JCILiabShift)
--BEGIN
--	INSERT INTO bHQMA SELECT 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
--   	'JCILiabShift', d.JCILiabShift, i.JCILiabShift,
--   	GETDATE(), SUSER_SNAME()
--   	FROM inserted i, deleted d
--   	WHERE i.PRCo = d.PRCo AND i.JCILiabShift <> d.JCILiabShift
--END
--IF UPDATE(SMInterface)
--BEGIN
--	INSERT INTO bHQMA SELECT 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
--   	'SMInterface', d.SMInterface, i.SMInterface,
--   	GETDATE(), SUSER_SNAME()
--   	FROM inserted i, deleted d
--   	WHERE i.PRCo = d.PRCo AND i.SMInterface <> d.SMInterface
--END
--IF UPDATE(SMCo)
--BEGIN
--	INSERT INTO bHQMA SELECT 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
--   	'SMCo', d.SMCo, i.SMCo,
--   	GETDATE(), SUSER_SNAME()
--   	FROM inserted i, deleted d
--   	WHERE i.PRCo = d.PRCo AND ISNULL(i.SMCo,'') <> ISNULL(d.SMCo,'')
--END

IF UPDATE(AutoOTUseVariableRatesYN)
BEGIN
	INSERT INTO bHQMA SELECT 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
   	'AutoOTUseVariableRatesYN', d.AutoOTUseVariableRatesYN, i.AutoOTUseVariableRatesYN,
   	GETDATE(), SUSER_SNAME()
   	FROM inserted i, deleted d
   	WHERE i.PRCo = d.PRCo AND i.AutoOTUseVariableRatesYN <> d.AutoOTUseVariableRatesYN
END
IF UPDATE(AutoOTUseHighestRateYN)
BEGIN
	INSERT INTO bHQMA SELECT 'bPRCO', 'PR Co#: ' + convert(char(3),i.PRCo), i.PRCo, 'C',
   	'AutoOTUseHighestRateYN', d.AutoOTUseHighestRateYN, i.AutoOTUseHighestRateYN,
   	GETDATE(), SUSER_SNAME()
   	FROM inserted i, deleted d
   	WHERE i.PRCo = d.PRCo AND i.AutoOTUseHighestRateYN <> d.AutoOTUseHighestRateYN
END


  return
  error:
  	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Company!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
  
  
  
  
  
  
  
  
  
  
 
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[GLInterface]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[AutoOT]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[AllowNoPhase]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCInterface]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[InsByPhase]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCICraftClass]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCICrew]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCIEmployee]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCIFactor]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCIEarnType]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCIShift]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCIPostingDate]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCILiabType]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCIEquip]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCIRevCode]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[EMUsage]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[EMInterface]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[EMRevEmployee]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[EMRevPhase]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[EMRevPostingDate]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[EMCostEmployee]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[TaxStateOpt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[UnempStateOpt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[InsStateOpt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[LocalOpt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[AuditCoParams]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[AuditEmployees]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[AuditAccums]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[AuditPayHistory]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[AuditDLs]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[AuditCraftClass]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[NonNegCheckPrint]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[AuditTaxes]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[AuditStateIns]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[ExcludeSSN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCILiabFactor]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCO].[JCILiabShift]'
GO
