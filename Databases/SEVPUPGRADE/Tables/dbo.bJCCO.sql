CREATE TABLE [dbo].[bJCCO]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[ValidPhaseChars] [tinyint] NOT NULL,
[PostClosedJobs] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_PostClosedJobs] DEFAULT ('N'),
[UseJobBilling] [dbo].[bYN] NOT NULL,
[DefaultBillType] [dbo].[bBillType] NOT NULL,
[ARCo] [dbo].[bCompany] NOT NULL,
[INCo] [dbo].[bCompany] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLCostLevel] [tinyint] NOT NULL,
[GLCostOveride] [dbo].[bYN] NOT NULL,
[GLCostJournal] [dbo].[bJrnl] NULL,
[GLCostDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLCostSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLRevLevel] [tinyint] NOT NULL,
[GLRevOveride] [dbo].[bYN] NOT NULL,
[GLRevJournal] [dbo].[bJrnl] NULL,
[GLRevDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLRevSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLCloseLevel] [tinyint] NOT NULL,
[GLCloseJournal] [dbo].[bJrnl] NULL,
[GLCloseDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLCloseSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLMaterialLevel] [tinyint] NOT NULL,
[GLMatJournal] [dbo].[bJrnl] NULL,
[GLMatDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLMatSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLMiscMatAcct] [dbo].[bGLAcct] NULL,
[ValidateMaterial] [dbo].[bYN] NOT NULL,
[UseTaxOnMaterial] [dbo].[bYN] NOT NULL,
[PRCo] [dbo].[bCompany] NULL,
[PostCrewProgress] [dbo].[bYN] NOT NULL,
[ProjMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ProjMinPct] [dbo].[bPct] NOT NULL,
[ProjPercent] [dbo].[bYN] NOT NULL,
[ProjOverUnder] [dbo].[bYN] NOT NULL,
[ProjRemain] [dbo].[bYN] NOT NULL,
[AuditCoParams] [dbo].[bYN] NOT NULL,
[AuditDepts] [dbo].[bYN] NOT NULL,
[AuditContracts] [dbo].[bYN] NOT NULL,
[AuditJobs] [dbo].[bYN] NOT NULL,
[AuditChngOrders] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[AddJCSICode] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_AddJCSICode] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[ProjInactivePhases] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_ProjInactivePhases] DEFAULT ('N'),
[AuditPhases] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_AuditPhases] DEFAULT ('N'),
[AuditCostTypes] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_AuditCostTypes] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PostSoftClosedJobs] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_PostSoftClosedJobs] DEFAULT ('N'),
[ProjPostForecast] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_ProjPostForecast] DEFAULT ('N'),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_AttachBatchReportsYN] DEFAULT ('N'),
[AuditPhaseMaster] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_AuditPhaseMaster] DEFAULT ('N'),
[ProjJobInMultiBatch] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_ProjJobInMultiBatch] DEFAULT ('N'),
[ProjResDetOpt] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_ProjResDetOpt] DEFAULT ('N'),
[ProjRemainUCOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCCO_ProjRemainUCOpt] DEFAULT ('E'),
[AuditProjectionOverrides] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_AuditProjectionOverrides] DEFAULT ('N'),
[CFRevMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCCO_CFRevMethod] DEFAULT ('N'),
[CFRevInterval] [tinyint] NULL,
[CFRevParts] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[CFCostMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCCO_CFCostMethod] DEFAULT ('N'),
[CFCostInterval] [tinyint] NULL,
[CFCostParts] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ProjNoteTimeStamp] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCCO_ProjNoteTimeStamp] DEFAULT ('Y'),
[AuditLiabilityTemplate] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCO_AuditLiabilityTemplate] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btJCCOd    Script Date: 8/28/99 9:37:42 AM ******/
   CREATE trigger [dbo].[btJCCOd] on [dbo].[bJCCO] for DELETE as
    

/*----------------------------------------------------------
     *	This trigger rejects delete in bJCCO (Companies) if a
     *	dependent record is found in:
     *
     * Created By:	03/08/2004 - ISSUE #17898 - added delete from bJCUO when JCCo deleted
     *
     *		Contract Master
     *		Job Master
     *		Department Master
     *		JCID entries exist
     *
     *
     *	Adds HQ Master Audit entry.
     */---------------------------------------------------------
    declare @errmsg varchar(255), @errno int, @numrows int
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    /* check Job Master */
    if exists(select * from bJCJM j, deleted d where j.JCCo = d.JCCo)
    	begin
    	select @errmsg = 'Jobs exist'
    	goto error
    	end
    /* check Contract Master */
    if exists (select * from bJCCM c, deleted d where c.JCCo = d.JCCo)
    	begin
    	select @errmsg = 'Contracts exist'
    	goto error
    	end
    /* check Departments */
    if exists (select * from bJCDM m, deleted d where m.JCCo = d.JCCo)
    	begin
    	select @errmsg = 'Departments exist'
    	goto error
    	end
    /* check JCID */
    if exists (select * from bJCID i, deleted d where i.JCCo = d.JCCo and i.ARCo is not null )
    	begin
    	select @errmsg = 'Journals exist'
    	goto error
    	end
   
   
   -- delete rows from bJCUO for company
   delete bJCUO from deleted d join bJCUO on bJCUO.JCCo=d.JCCo
   
   -- auditing
   Insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    			 select 'bJCCO',  'JC Co#: ' + convert(char(3), JCCo), JCCo, 'D',
    			 null, null, null, getdate(), SUSER_SNAME() from deleted
   return
   
   
   error:
    	select @errmsg = @errmsg + ' - cannot delete JC Company!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btJCCOi] on [dbo].[bJCCO] for INSERT as 
/*-----------------------------------------------------------------
* Created:  ?
* Modified: 08/09/02 CMW - changed verbiage on HQCO validation (issue # 17886).
*			GG 09/20/02 - #18522 ANSI nulls
*           TV 03/18/03 - clean up commented code
*			GG 04/20/07 - #30116 - data security review
*			GF 12/07/2007 - issue #25569 PostSoftClosedJobs validation
*		    TRL 02/18/08 --#21452	
*
*
*	This trigger rejects insertion in bJCCO (Companies) if the
*	following error condition exists:
*
*		JCCo Invalid HQ Company number
*		ARCo Invalid AR Company number
*		INCo Invalid IN Company number
*		GLCo Invalid GL Company number
*		Invalid CostJrnl if GLCostLvl = Summary or Detail
*		Invalid RevJrnl if GLRevLvl = Summary or Detail
*		Invalid CloseJrnl if GLCloseLvl = Summary or Detail
*		Invalid MatJrnl if GLMatLvl = Summary or Detail
*		Invalid GLMiscMatAcct
*		ProjMethod not = 1, 2, or 3
*		ProjMinPct not between 0 to 100
*
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
	declare @errmsg varchar(255), @errno int, @numrows int, @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* validate HQ Company number */
select @validcnt = count(*) from dbo.bHQCO h (nolock) join inserted i on h.HQCo = i.JCCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid JC Company - not in HQCO.'
	goto error
	end
/*Validate ProjMethod equals 1, 2, or 3 */
select @validcnt = count(*) from inserted where ProjMethod in ('1','2','3')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Projection Method'
	goto error
	end
/*Validate ProjMinPct is between 0 and 100 */
select @validcnt = count(*) from inserted where ProjMinPct >= 0 and ProjMinPct < 100
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Projection Minimum Percent'
	goto error
	end

---- validate PostClosedJobs vs PostSoftClosedJobs
select @validcnt = count(*) from inserted i where i.PostClosedJobs = 'Y' and i.PostSoftClosedJobs = 'N'
if @validcnt <> 0
	begin
	select @errmsg = 'When allow posting to hard-closed jobs is checked, must also allow posting to soft-closed jobs.'
	goto error
	end

-- Master Audit
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCCO',  'JC Co#: ' + convert(char(3), JCCo), JCCo, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted

--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCCO',  'JC Co#: ' + convert(char(3), JCCo), JCCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bJCCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bJCCo', i.JCCo, i.JCCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bJCCo' and s.Qualifier = i.JCCo 
						and s.Instance = convert(char(30),i.JCCo) and s.SecurityGroup = @dfltsecgroup)
	end 

return

error:
	select @errmsg = @errmsg + ' - cannot insert JC Company!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJCCOu    Script Date: 8/28/99 9:37:42 AM ******/
CREATE    trigger [dbo].[btJCCOu] on [dbo].[bJCCO] for UPDATE 
/*-----------------------------------------------------------------
* Created:
* Modified: GG	03/08/2002	- #16459 - remove PRUseJCDept
*			GG	09/20/2002	- #18522 ANSI nulls
*           TV	03/18/2003	- clean out commented code (housekeeping)\
*			GF	03/08/2004	- ISSUE #17898 - added update to bJCUO when ProjMethod, Active changed
*			GF	04/01/2005	- issue #27183 - added update to bJCUO when ProjInactivePhases changed
*			GF	12/07/2007	- issue #25569 PostSoftClosedJobs validation
*		    TRL	02/18/2008	- #21452	
*			GF	03/29/2009	- issue #129898
*			CHS	12/28/2009	- issue #137134
*
*
*	This trigger rejects update in bJCCO (JC Companies) if the
*	following error condition exists:
*
*		ARCo Invalid AR Company number
*		INCo Invalid IN Company number
*		GLCo Invalid GL Company number
*		Invalid CostJrnl if GLCostLvl = Summary or Detail
*		Invalid RevJrnl if GLRevLvl = Summary or Detail
*		Invalid CloseJrnl if GLCloseLvl = Summary or Detail
*		Invalid MatJrnl if GLMatLvl = Summary or Detail
*		Invalid GLMiscMatAcct
*		ProjMethod not = 1, 2, or 3
*		ProjMinPct not between 0 to 100
*		Cannot change JC Company
*		Cannot change ARCo if records exist in bJCID
*		Cannot change GLCo if records exist in bJCDM
*		Cannot change GLCo if records exist in bJCAC
*
*	Adds record to HQ Master Audit.
*/----------------------------------------------------------------
   as
   
   

declare @errmsg varchar(255), @numrows int, @validcount int, @validcount2 int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for key changes
   select @validcount = count(*) from deleted d, inserted i where d.JCCo = i.JCCo
   if @validcount <> @numrows
    	begin
    	select @errmsg = 'Cannot change JC Company'
    	goto error
    	end
   
   -- Validate ProjMinPct is between 0 and 100
   if update (ProjMinPct)
    	begin
    	select @validcount = count(*) from inserted
    		where ProjMinPct >= 0 and ProjMinPct < 100
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid Projection Minimum Percent'
    		goto error
    		end
    	end
   
   -- Cannot change ARCo if records exist in bJCID
   select @validcount = count(*) from deleted d, inserted i, bJCID a
    	where d.JCCo = i.JCCo and d.ARCo <> i.ARCo and a.JCCo = d.JCCo and a.ARCo = d.ARCo
   if @validcount <> 0
    	begin
    	select @errmsg = 'Cannot change AR Company, JCID records exist'
    	goto error
    	end
   
   -- Cannot change GLCo if records exist in bJCDM
   select @validcount = count(*) from deleted d, inserted i, bJCDM a
    	where d.JCCo = i.JCCo and d.GLCo <> i.GLCo and a.JCCo = d.JCCo and a.GLCo = d.GLCo
   if @validcount <> 0
    	begin
    	select @errmsg = 'Cannot change GL Company, Department records exist'
    	goto error
    	end
   
   -- Cannot change GLCo if records exist in bJCAC
   select @validcount = count(*) from deleted d, inserted i, bJCAC a
    	where d.JCCo = i.JCCo and d.GLCo <> i.GLCo and a.JCCo = d.JCCo and a.GLCo = d.GLCo
   if @validcount <> 0
    	begin
    	select @errmsg = 'Cannot change GL Company, Allocation records exist'
    	goto error
    	end
   
   -- -- -- Validate ProjMethod equals 1, 2
   if update (ProjMethod)
    	begin
    	select @validcount = count(*) from inserted where ProjMethod in ('1','2')
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid Projection Method'
    		goto error
    		end
   	-- update bJCUO.ProjMethod when changed
   	update bJCUO set ProjMethod=i.ProjMethod
   	from inserted i join bJCUO u on u.JCCo=i.JCCo and u.Form='JCProjection'
   	where i.ProjMethod <> u.ProjMethod
    	end
   
   -- -- -- Validate JCUO.ProjInactivePhases if changed
   if update (ProjInactivePhases)
    	begin
   	-- update bJCUO.ProjInactivePhases when changed
   	update bJCUO set ProjInactivePhases=i.ProjInactivePhases
   	from inserted i join bJCUO u on u.JCCo=i.JCCo and u.Form='JCProjection'
   	where i.ProjInactivePhases <> u.ProjInactivePhases and i.ProjInactivePhases = 'N'
    	end

---- validate PostClosedJobs vs PostSoftClosedJobs
if update(PostClosedJobs) or update(PostSoftClosedJobs)
	begin
	select @validcount = count(*) from inserted i where i.PostClosedJobs = 'Y' and i.PostSoftClosedJobs = 'N'
	if @validcount <> 0
		begin
		select @errmsg = 'When allow posting to hard-closed jobs is checked, must also allow posting to soft-closed jobs.'
		goto error
		end
	end





---- Insert records into HQMA for changes made to audited fields
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'No. Valid Phase Chars', Convert(char(30),d.ValidPhaseChars), Convert(char(30),i.ValidPhaseChars),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.ValidPhaseChars <> d.ValidPhaseChars
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Post to Closed Jobs', d.PostClosedJobs, i.PostClosedJobs,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.PostClosedJobs <> d.PostClosedJobs
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Use Job Billing', d.UseJobBilling, i.UseJobBilling,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.UseJobBilling <> d.UseJobBilling
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Default Billing Type', d.DefaultBillType, i.DefaultBillType,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.DefaultBillType <> d.DefaultBillType
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'AR Company', Convert(char(3),d.ARCo), Convert(char(3),i.ARCo),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.ARCo <> d.ARCo
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'IN Company', Convert(char(3),d.INCo), Convert(char(3),i.INCo),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.INCo <> d.INCo
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Company', Convert(char(3),d.GLCo), Convert(char(3),i.GLCo),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.GLCo <> d.GLCo
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Cost Interface Level', Convert(char(3),d.GLCostLevel), Convert(char(3),i.GLCostLevel),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.GLCostLevel <> d.GLCostLevel
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Allow GL Cost Override', d.GLCostOveride, i.GLCostOveride,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.GLCostOveride <> d.GLCostOveride
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Cost Journal', d.GLCostJournal, i.GLCostJournal,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and isnull(i.GLCostJournal,'') <> isnull(d.GLCostJournal,'')
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Cost Transaction Desc', d.GLCostDetailDesc, i.GLCostDetailDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and isnull(i.GLCostDetailDesc,'') <> isnull(d.GLCostDetailDesc,'')
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Cost Summary Desc', d.GLCostSummaryDesc, i.GLCostSummaryDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and isnull(i.GLCostSummaryDesc,'') <> isnull(d.GLCostSummaryDesc,'')
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Revenue Interface Level', Convert(char(3),d.GLRevLevel), Convert(char(3),i.GLRevLevel),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.GLRevLevel <> d.GLRevLevel
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Allow GL Revenue Override', d.GLRevOveride, i.GLRevOveride,
   
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.GLRevOveride <> d.GLRevOveride
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Revenue Journal', d.GLRevJournal, i.GLRevJournal,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and isnull(i.GLRevJournal,'') <> isnull(d.GLRevJournal,'')
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
   
    	'GL Revenue Transaction Desc', d.GLRevDetailDesc, i.GLRevDetailDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and isnull(i.GLRevDetailDesc,'') <> isnull(d.GLRevDetailDesc,'')
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Revenue Summary Desc', d.GLRevSummaryDesc, i.GLRevSummaryDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and isnull(i.GLRevSummaryDesc,'') <> isnull(d.GLRevSummaryDesc,'')
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Close Interface Level', Convert(char(3),d.GLCloseLevel), Convert(char(3),i.GLCloseLevel),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.GLCloseLevel <> d.GLCloseLevel
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Close Journal', d.GLCloseJournal, i.GLCloseJournal,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and isnull(i.GLCloseJournal,'') <> isnull(d.GLCloseJournal,'')
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Close Transaction Desc', d.GLCloseDetailDesc, i.GLCloseDetailDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and isnull(i.GLCloseDetailDesc,'') <> isnull(d.GLCloseDetailDesc,'')
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Close Summary Desc', d.GLCloseSummaryDesc, i.GLCloseSummaryDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and isnull(i.GLCloseSummaryDesc,'') <> isnull(d.GLCloseSummaryDesc,'')
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Material Interface Level', Convert(char(3),d.GLMaterialLevel), Convert(char(3),i.GLMaterialLevel),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.GLMaterialLevel <> d.GLMaterialLevel
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Material Journal', d.GLMatJournal, i.GLMatJournal,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and isnull(i.GLMatJournal,'') <> isnull(d.GLMatJournal,'')
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Material Transaction Desc', d.GLMatDetailDesc, i.GLMatDetailDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and isnull(i.GLMatDetailDesc,'') <> isnull(d.GLMatDetailDesc,'')
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Material Summary Desc', d.GLMatSummaryDesc, i.GLMatSummaryDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and isnull(i.GLMatSummaryDesc,'') <> isnull(d.GLMatSummaryDesc,'')
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'GL Misc Material Account', d.GLMiscMatAcct, i.GLMiscMatAcct,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.GLMiscMatAcct <> d.GLMiscMatAcct
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Validate Material', d.ValidateMaterial, i.ValidateMaterial,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.ValidateMaterial <> d.ValidateMaterial
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Use Tax on Material', d.UseTaxOnMaterial, i.UseTaxOnMaterial,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.UseTaxOnMaterial <> d.UseTaxOnMaterial
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Post Crew Progress', d.PostCrewProgress, i.PostCrewProgress,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.PostCrewProgress <> d.PostCrewProgress
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Projection Method', d.ProjMethod, i.ProjMethod,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.ProjMethod <> d.ProjMethod
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Projection Minimum Percent', Convert(char(30),d.ProjMinPct), Convert(char(30),i.ProjMinPct),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.ProjMinPct <> d.ProjMinPct
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Audit Company Parameters', d.AuditCoParams, i.AuditCoParams,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.AuditCoParams <> d.AuditCoParams
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Audit Departments', d.AuditDepts, i.AuditDepts,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.AuditDepts <> d.AuditDepts
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Audit Contracts', d.AuditContracts, i.AuditContracts,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.AuditContracts <> d.AuditContracts
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Audit Jobs', d.AuditJobs, i.AuditJobs,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.AuditJobs <> d.AuditJobs
    insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
    	'Audit Change Orders', d.AuditChngOrders, i.AuditChngOrders,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.JCCo = d.JCCo and i.AuditChngOrders <> d.AuditChngOrders

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'AddJCSICode', d.AddJCSICode, i.AddJCSICode, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.AddJCSICode,'') <> isnull(d.AddJCSICode,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'ProjInactivePhases', d.ProjInactivePhases, i.ProjInactivePhases, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.ProjInactivePhases,'') <> isnull(d.ProjInactivePhases,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'AuditPhases', d.AuditPhases, i.AuditPhases, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.AuditPhases,'') <> isnull(d.AuditPhases,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'AuditCostTypes', d.AuditCostTypes, i.AuditCostTypes, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.AuditCostTypes,'') <> isnull(d.AuditCostTypes,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'Post Soft Closed Jobs', d.PostSoftClosedJobs, i.PostSoftClosedJobs, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.PostSoftClosedJobs,'') <> isnull(d.PostSoftClosedJobs,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'ProjPostForecast', d.ProjPostForecast, i.ProjPostForecast, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.ProjPostForecast,'') <> isnull(d.ProjPostForecast,'')

--#21452
If update(AttachBatchReportsYN)
begin
	insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.JCCo = d.JCCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
end

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'AuditPhaseMaster', d.AuditPhaseMaster, i.AuditPhaseMaster, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.AuditPhaseMaster,'') <> isnull(d.AuditPhaseMaster,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'ProjJobInMultiBatch', d.ProjJobInMultiBatch, i.ProjJobInMultiBatch, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.ProjJobInMultiBatch,'') <> isnull(d.ProjJobInMultiBatch,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'ProjResDetOpt', d.ProjResDetOpt, i.ProjResDetOpt, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.ProjResDetOpt,'') <> isnull(d.ProjResDetOpt,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'AuditProjectionOverrides', d.AuditProjectionOverrides, i.AuditProjectionOverrides, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.AuditProjectionOverrides,'') <> isnull(d.AuditProjectionOverrides,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'ProjRemainUCOpt', d.ProjRemainUCOpt, i.ProjRemainUCOpt, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.ProjRemainUCOpt,'') <> isnull(d.ProjRemainUCOpt,'')

--#137134
insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'CFRevMethod', d.CFRevMethod, i.CFRevMethod, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.CFRevMethod,'') <> isnull(d.CFRevMethod,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'CFRevInterval', d.CFRevInterval, i.CFRevInterval, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.CFRevInterval,'') <> isnull(d.CFRevInterval,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'CFRevParts', d.CFRevParts, i.CFRevParts, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.CFRevParts,'') <> isnull(d.CFRevParts,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'CFCostMethod', d.CFCostMethod, i.CFCostMethod, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.CFCostMethod,'') <> isnull(d.CFCostMethod,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'CFCostInterval', d.CFCostInterval, i.CFCostInterval, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.CFCostInterval,'') <> isnull(d.CFCostInterval,'')

insert into bHQMA select 'bJCCO', 'JC Co#: ' + convert(char(3),i.JCCo), i.JCCo, 'C',
	'CFCostParts', d.CFCostParts, i.CFCostParts, getdate(), SUSER_SNAME()
from inserted i join deleted d on d.JCCo=i.JCCo
where i.JCCo=d.JCCo and isnull(i.CFCostParts,'') <> isnull(d.CFCostParts,'')


return


error:
	select @errmsg = @errmsg + ' - cannot update JC Company!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bJCCO] ADD CONSTRAINT [CK_bJCCO_CFCostInterval] CHECK (([CFCostInterval] IS NULL OR [CFCostInterval]>(1) AND [CFCostInterval]<(11)))
GO
ALTER TABLE [dbo].[bJCCO] ADD CONSTRAINT [CK_bJCCO_CFCostMethod] CHECK (([CFCostMethod]='N' OR [CFCostMethod]='L' OR [CFCostMethod]='C'))
GO
ALTER TABLE [dbo].[bJCCO] ADD CONSTRAINT [CK_bJCCO_CFRevInterval] CHECK (([CFRevInterval] IS NULL OR [CFRevInterval]>(1) AND [CFRevInterval]<(11)))
GO
ALTER TABLE [dbo].[bJCCO] ADD CONSTRAINT [CK_bJCCO_CFRevMethod] CHECK (([CFRevMethod]='N' OR [CFRevMethod]='L' OR [CFRevMethod]='C'))
GO
ALTER TABLE [dbo].[bJCCO] ADD CONSTRAINT [CK_bJCCO_ProjRemainUCOpt] CHECK (([ProjRemainUCOpt]='A' OR [ProjRemainUCOpt]='E'))
GO
CREATE UNIQUE CLUSTERED INDEX [biJCCO] ON [dbo].[bJCCO] ([JCCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCCO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[PostClosedJobs]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[UseJobBilling]'
GO
EXEC sp_bindrule N'[dbo].[brBillType]', N'[dbo].[bJCCO].[DefaultBillType]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[GLCostOveride]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[GLRevOveride]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[ValidateMaterial]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[UseTaxOnMaterial]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[PostCrewProgress]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCCO].[ProjMinPct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[ProjPercent]'
GO
EXEC sp_bindefault N'[dbo].[bdYes]', N'[dbo].[bJCCO].[ProjPercent]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[ProjOverUnder]'
GO
EXEC sp_bindefault N'[dbo].[bdYes]', N'[dbo].[bJCCO].[ProjOverUnder]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[ProjRemain]'
GO
EXEC sp_bindefault N'[dbo].[bdYes]', N'[dbo].[bJCCO].[ProjRemain]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[AuditCoParams]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[AuditDepts]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[AuditContracts]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[AuditJobs]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[AuditChngOrders]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[AddJCSICode]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCO].[ProjInactivePhases]'
GO
