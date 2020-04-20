CREATE TABLE [dbo].[bARCO]
(
[ARCo] [dbo].[bCompany] NOT NULL,
[GLCo] [dbo].[bCompany] NULL,
[CMCo] [dbo].[bCompany] NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[CMInterface] [tinyint] NOT NULL,
[CMSummaryDesc] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NULL,
[JCInterface] [tinyint] NOT NULL,
[FCLevel] [tinyint] NOT NULL,
[FCCalcOnFC] [dbo].[bYN] NOT NULL,
[FCPct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_bARCO_FCPct] DEFAULT ((0)),
[FCMinChrg] [dbo].[bDollar] NOT NULL,
[FCMinBal] [dbo].[bDollar] NOT NULL,
[FCFinOrServ] [char] (1) COLLATE Latin1_General_BIN NULL,
[FCRecType] [tinyint] NULL,
[GLInvLev] [tinyint] NULL,
[InvoiceJrnl] [dbo].[bJrnl] NULL,
[GLInvSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLInvDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLPayLev] [tinyint] NULL,
[PaymentJrnl] [dbo].[bJrnl] NULL,
[GLPaySummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLPayDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLMiscCashLev] [tinyint] NULL,
[MiscCashJrnl] [dbo].[bJrnl] NULL,
[GLMiscSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLMiscDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[InvAutoNum] [dbo].[bYN] NOT NULL,
[InvLastNum] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[RecType] [tinyint] NULL,
[RecTypeOpt] [dbo].[bYN] NOT NULL,
[InvoiceTax] [dbo].[bYN] NOT NULL,
[ReceiptTax] [dbo].[bYN] NOT NULL,
[RelRetainOpt] [dbo].[bYN] NOT NULL,
[DiscOpt] [char] (1) COLLATE Latin1_General_BIN NULL,
[LastStmtDate] [dbo].[bDate] NULL,
[AuditCompany] [dbo].[bYN] NOT NULL,
[AuditCustomers] [dbo].[bYN] NOT NULL,
[AuditRecType] [dbo].[bYN] NOT NULL,
[AuditTrans] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DiscTax] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bARCO_DiscTax] DEFAULT ('N'),
[EMCo] [dbo].[bCompany] NULL,
[EMInterface] [tinyint] NOT NULL CONSTRAINT [DF_bARCO_EMInterface] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bARCO_AuditYN] DEFAULT ('Y'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bARCO_AttachBatchReportsYN] DEFAULT ('N'),
[TaxRetg] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bARCO_TaxRetg] DEFAULT ('Y'),
[SeparateRetgTax] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bARCO_SeparateRetgTax] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

CREATE  trigger [dbo].[btARCOd] on [dbo].[bARCO] for DELETE as
/*----------------------------------------------------------
* Created: ??
*
*	This trigger rejects delete in bARCO (AR Companies)
*	if a dependent record is found in:
*
*		ARRT - Receivable Types
*		ARTL - Transaction Lines
*		ARMT - Monthly Totals
*		ARTH - Transaction Header
*		ARBH - Batch Header
*		ARMD - Misc Distributions 
*
*	Inserts all transactions in HQ Master Audit
*/---------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

/* check ARRT */
if exists(select 1 from dbo.bARRT a (nolock) join deleted d on a.ARCo = d.ARCo)
	begin
	select @errmsg = 'Entries exist in AR Receivable Types for this AR Company'
	goto error
	end
/* check ARTL */
if exists(select 1 from dbo.bARTL a (nolock) join deleted d on a.ARCo = d.ARCo)
	begin
	select @errmsg = 'Entries exist in AR Transaction Lines for this AR Company'
	goto error
	end
/* check ARMT */
if exists(select 1 from dbo.bARMT a (nolock) join deleted d on a.ARCo = d.ARCo)
	begin
	select @errmsg = 'Entries exist in AR Monthly Totals for this AR Company'
	goto error
	end
/* check ARTH */
if exists(select 1 from dbo.bARTH a (nolock) join deleted d on a.ARCo = d.ARCo)
	begin
	select @errmsg = 'Entries exist in AR Transaction Header for this AR Company'
	goto error
	end
/* check ARBH */
if exists(select 1 from dbo.bARBH a (nolock) join deleted d on a.Co = d.ARCo)
	begin
	select @errmsg = 'Entries exist in AR Batch Header for this AR Company'
	goto error
	end
/* check ARMD */
if exists(select 1 from dbo.bARMD a (nolock) join deleted d on a.ARCo = d.ARCo)
	begin
	select @errmsg = 'Entries exist in AR Misc Distributions for this AR Company'
	goto error
	end
/* Audit AR Company deletions */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bARCO', 'AR Co#: ' + isnull(convert(varchar(3),ARCo),''),
	ARCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted

return

error:
	select @errmsg = @errmsg + ' - cannot delete AR Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   trigger [dbo].[btARCOi] on [dbo].[bARCO] for INSERT as
/*-----------------------------------------------------------------
* Created: ??
* Modified: GG 04/18/07 - #30116 - data security
*			TRL 02/18/08 --@21452
*	This trigger rejects insertion in bARCO (AR Companies) if
*	any of the following error conditions exist:
*
*		ARCo Invalid vs HQCO.HQCo
*		removed per QA request 11/11/97: GLCo Invalid vs HQCO.HQCo and GLCo not null
*		removed per QA request 11/11/97: CMCo Invalid vs HQCO.HQCo and CMCo not null
*		removed per QA request 11/11/97: JCCo Invalid vs HQCO.HQCo and JCCo not null
*		removed per QA request 1/25/98: CMAcct Invalid vs CMAC.Acct and  ARCO.ARCo = CMAC.CMCo and CMAcct not null
*		CMInterface <> 0 or 1
*		JCInterface <> 0 or 1
*		FCLevel <> 1, 2 or 3
*		FCFinOrServ <> F or S
*		GLInvLev <> 0, 1 or 2
*		GLPayLev <> 0, 1 or 2
*		GLMiscCashLev <> 0, 1 or 2
*		DiscOpt <> I, P or N
*
*	Adds HQ Master Audit entry
*/----------------------------------------------------------------
declare @errmsg varchar(255), @errno int, @numrows int, @nullcnt int,
   	@validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* validate AR Company number */
select @validcnt = count(*) from dbo.bHQCO h (nolock) join inserted i on h.HQCo = i.ARCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AR Company'
	goto error
	end
/* validate CMInterface = 0 or 1 */
select @validcnt = count(*) from inserted where CMInterface in (0,1)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid CM Interface'
	goto error
	end
/* validate JCInterface = 0 or 1 */
select @validcnt = count(*) from inserted where JCInterface in (0,1)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid JC Interface'
	goto error
	end
/* validate FCLevel = 1, 2 or 3 */
select @validcnt = count(*) from inserted where FCLevel in (1,2,3)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Finance Charge Level'
	goto error
	end
/* validate FCFinOrServ = F or S */
select @validcnt = count(*) from inserted where FCFinOrServ in ('F','S')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Finance or Service Charge'
	goto error
	end
/* validate GLPayLev = 0, 1 or 2 */
select @validcnt = count(*) from inserted where GLPayLev in (0,1,2)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid GL Pay Level'
	goto error
	end
/* validate GLInvLev = 0, 1 or 2 */
select @validcnt = count(*) from inserted where GLInvLev in (0,1,2)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid GL Invoice Level'
	goto error
	end
/* validate GLMiscCashLev equals 0, 1, or 2 */
select @validcnt = count(*) from inserted where GLMiscCashLev in (0,1,2)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid GL Misc Cash Level'
	goto error
	end
/* validate DiscOpt = I, P or N */
select @validcnt = count(*) from inserted where DiscOpt in ('I','P','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Discount Option'
	goto error
	end

--Master Audit
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bARCO',  'AR Co#: ' + isnull(convert(char(3), ARCo),''), ARCo, 'A',
   null, null, null, getdate(), SUSER_SNAME()
from inserted

--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bARCO',  'AR Co#: ' + convert(char(3), ARCo), ARCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup int
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bARCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bARCo', i.ARCo, i.ARCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bARCo' and s.Qualifier = i.ARCo 
						and s.Instance = convert(char(30),i.ARCo) and s.SecurityGroup = @dfltsecgroup)
	end 
   
return

error:
   	select @errmsg = @errmsg + ' - cannot insert AR Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btARCOu    Script Date: 8/28/99 9:37:02 AM ******/
   CREATE  trigger [dbo].[btARCOu] on [dbo].[bARCO] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int
   /*-----------------------------------------------------------------
   * Mod JRE 3/11/98 - Removed invoice batch check for tax flag change
   *		TJL 03/15/04 - Issue #24064, Correct HQMA audit of InvLastNum, use AuditYN
   *		TJL 12/29/04 - Issue #26488, Not auditing some fields going from NULL to Something or Something to NULL
   *		TRL 02/18/08 --#21452
   *		TJL 05/19/08 - Issue #128286, International Sales Tax
   *	
   *
   *	This trigger rejects update in bARCO (AR Companies) if any
   *	of the following error conditions exist:
   *
   *		Cannot change AR Company
   *		Cannot change InvoiceTax if open Invoice Batch (ARBH.ARCo = ARCo and
   *			TransType = I, C, A, W, F or R
   *		Cannot change ReceiptTax if open PaymentBatch (ARBH.ARCo = ARCo and
   *			TransType = P or M
   *		CMInterface = 0 or 1
   *		JCInterface = 0 or 1
   *		FCLevel = 1, 2 or 3
   *		FCFinOrServ = F or S
   *		GLPayLev = 0, 1 or 2
   *		GLMiscCashLev = 0, 1 or 2
   *		DiscOpt = I, P or N
   *
   *	Adds record to HQ Master Audit.
   */----------------------------------------------------------------
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* check for key changes */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.ARCo = i.ARCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change AR Company'
   	goto error
   	end
   /* cannot change InvoiceTax if open Invoice Batch */
   /*  --- now its ok to change flag if batch is open
   if update (InvoiceTax)
   	begin
   	select @validcnt = count(*) from bARBH b, inserted i where b.Co = i.ARCo and TransType in ('I', 'C', 'A', 'W', 'F', 'R')
   	if @validcnt > 0
   		begin
   		select @errmsg = 'Invoice Batch exists'
   		goto error
   		end
   	end
   */
   /* cannot change ReceiptTax if open Payment Batch */
   if update (ReceiptTax)
   	begin
   	select @validcnt = count(*) from bARBH b, inserted i where b.Co = i.ARCo and TransType in ('P', 'M')
   	if @validcnt > 0
   		begin
   		select @errmsg = 'Payment Batch exists'
   		goto error
   		end
   	end
   /* validate CMInterface = 0 or 1 */
   if update (CMInterface)
   	begin
   	select @validcnt = count(*) from inserted
   		where CMInterface = 0 or CMInterface = 1
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid CM Interface'
   		goto error
   		end
   	end
   /* validate JCInterface = 0 or 1 */
   if update (JCInterface)
   	begin
   	select @validcnt = count(*) from inserted
   		where JCInterface = 0 or JCInterface = 1
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid JC Interface'
   		goto error
   		end
   	end
   /* validate FCLevel = 1, 2 or 3 */
   if update (FCLevel)
   	begin
   	select @validcnt = count(*) from inserted
   		where FCLevel = 1 or FCLevel = 2 or FCLevel = 3
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Finance Charge Level'
   		goto error
   		end
   	end
   /* validate FCFinOrServ = F or S */
   if update (FCFinOrServ)
   	begin
   	select @validcnt = count(*) from inserted
   		where FCFinOrServ = 'F' or FCFinOrServ = 'S'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Finance or Service Charge'
   		goto error
   		end
   	end
   /* validate GLPayLev = 0, 1 or 2 */
   if update (GLPayLev)
   	begin
   	select @validcnt = count(*) from inserted
   		where GLPayLev = 0 or GLPayLev = 1 or GLPayLev = 2
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid GL Pay Level'
   		goto error
   		end
   	end
   /* validate GLInvLev = 0, 1 or 2 */
   select @validcnt = count(*) from inserted
   	where GLInvLev = 0 or GLInvLev = 1 or GLInvLev = 2
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid GL Invoice Level'
   		goto error
   	end
   /* validate GLMiscCashLev = 0, 1 or 2 */
   if update (GLMiscCashLev)
   	begin
   	select @validcnt = count(*) from inserted
   		where GLMiscCashLev = 0 or GLMiscCashLev = 1 or GLMiscCashLev = 2
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid GL Misc Cash Level'
   		goto error
   		end
   	end
   /* validate DiscOpt = I, P or N */
   if update (DiscOpt)
   	begin
   	select @validcnt = count(*) from inserted
   		where DiscOpt = 'I' or DiscOpt = 'P' or DiscOpt = 'N'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Discount Option'
   		goto error
   		end
   	end
   
   /* Insert records into HQMA for changes made to audited fields */
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'GL Company', convert(char(3),d.GLCo), Convert(char(3),i.GLCo),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.GLCo, 0) <> isnull(d.GLCo, 0) and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'CM Company', convert(char(3),d.CMCo), Convert(char(3),i.CMCo),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.CMCo, 0) <> isnull(d.CMCo, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'CM Account', convert(char(6),d.CMAcct), Convert(char(6),i.CMAcct),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.CMAcct, '') <> isnull(d.CMAcct, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'CM Interface', convert(char(3),d.CMInterface), Convert(char(3),i.CMInterface),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.CMInterface <> d.CMInterface and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'JC Company', convert(char(3),d.JCCo), Convert(char(3),i.JCCo),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.JCCo, 0) <> isnull(d.JCCo, 0) and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'EM Company', convert(char(3),d.EMCo), Convert(char(3),i.EMCo),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.EMCo, 0) <> isnull(d.EMCo, 0) and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'JC Interface', convert(char(3),d.JCInterface), Convert(char(3),i.JCInterface),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.JCInterface <> d.JCInterface and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'FC Level', convert(char(3),d.FCLevel), Convert(char(3),i.FCLevel),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.FCLevel <> d.FCLevel and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Fin Chg Calc On Fin Chg', d.FCCalcOnFC, i.FCCalcOnFC,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.FCCalcOnFC <> d.FCCalcOnFC and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Fin Chg Percentage', convert(char(8),d.FCPct), Convert(char(8),i.FCPct),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.FCPct <> d.FCPct and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Fin Chg Min Chg', convert(char(16),d.FCMinChrg), Convert(char(16),i.FCMinChrg),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.FCMinChrg <> d.FCMinChrg and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'FC Min Balance', convert(char(16),d.FCMinBal), Convert(char(16),i.FCMinBal),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.FCMinBal <> d.FCMinBal and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Fin or Svc Chg', d.FCFinOrServ, i.FCFinOrServ,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.FCFinOrServ <> d.FCFinOrServ and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Fin Chg Receivable Type', convert(char(3),d.FCRecType), convert(char(3),i.FCRecType),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.FCRecType, 0) <> isnull(d.FCRecType, 0) and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'GL Interface Level', convert(char(3),d.GLInvLev), Convert(char(3),i.GLInvLev),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.GLInvLev <> d.GLInvLev and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Invoice Jrnl', d.InvoiceJrnl, i.InvoiceJrnl,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.InvoiceJrnl, '') <> isnull(d.InvoiceJrnl, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'GL Interface Summary Desc', d.GLInvSummaryDesc, i.GLInvSummaryDesc,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.GLInvSummaryDesc, '') <> isnull(d.GLInvSummaryDesc, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'GL Interface Detail Desc', d.GLInvDetailDesc, i.GLInvDetailDesc,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.GLInvDetailDesc, '') <> isnull(d.GLInvDetailDesc, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'GL Pay Level', convert(char(3),d.GLPayLev), Convert(char(3),i.GLPayLev),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.GLPayLev <> d.GLPayLev and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Payment Jrnl', d.PaymentJrnl, i.PaymentJrnl,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.PaymentJrnl, '') <> isnull(d.PaymentJrnl, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'GL Pay Summary Desc', d.GLPaySummaryDesc, i.GLPaySummaryDesc,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.GLPaySummaryDesc, '') <> isnull(d.GLPaySummaryDesc, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'GL Pay Detail Desc', d.GLPayDetailDesc, i.GLPayDetailDesc,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.GLPayDetailDesc, '')<> isnull(d.GLPayDetailDesc, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'GL Misc Cash Level', convert(char(3),d.GLMiscCashLev), Convert(char(3),i.GLMiscCashLev),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.GLMiscCashLev <> d.GLMiscCashLev and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Misc Cash Jrnl', d.MiscCashJrnl, i.MiscCashJrnl,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.MiscCashJrnl, '') <> isnull(d.MiscCashJrnl, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'GL Misc Summary Desc', d.GLMiscSummaryDesc, i.GLMiscSummaryDesc,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.GLMiscSummaryDesc, '') <> isnull(d.GLMiscSummaryDesc, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'GL Misc Detail Desc', d.GLMiscDetailDesc, i.GLMiscDetailDesc,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.GLMiscDetailDesc, '') <> isnull(d.GLMiscDetailDesc, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Invoice Auto Numbering', d.InvAutoNum, i.InvAutoNum,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.InvAutoNum <> d.InvAutoNum and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Invoice Last Number', convert(char(10),d.InvLastNum), Convert(char(10),i.InvLastNum),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.InvLastNum, '') <> isnull(d.InvLastNum, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Receivable Type', convert(char(3),d.RecType), convert(char(3),i.RecType),
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.RecType, 0) <> isnull(d.RecType, 0) and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Receivable Type Option', d.RecTypeOpt, i.RecTypeOpt,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.RecTypeOpt <> d.RecTypeOpt and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Invoice Tax', d.InvoiceTax, i.InvoiceTax,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where  i.InvoiceTax <> d.InvoiceTax and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Receipt Tax', d.ReceiptTax, i.ReceiptTax,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.ReceiptTax <> d.ReceiptTax and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Release Retainage Option', d.RelRetainOpt, i.RelRetainOpt,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.RelRetainOpt <> d.RelRetainOpt and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Calculate Retainage on Tax', d.TaxRetg, i.TaxRetg,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.TaxRetg <> d.TaxRetg and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Separate Retainage Tax', d.SeparateRetgTax, i.SeparateRetgTax,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.SeparateRetgTax <> d.SeparateRetgTax and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')

   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Discount Option', d.DiscOpt, i.DiscOpt,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.DiscOpt <> d.DiscOpt and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Last Stmt Date', d.LastStmtDate, i.LastStmtDate,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where isnull(i.LastStmtDate, '') <> isnull(d.LastStmtDate, '') and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Audit Customers', d.AuditCustomers, i.AuditCustomers,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.AuditCustomers <> d.AuditCustomers and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Audit Receivable Types', d.AuditRecType, i.AuditRecType,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.AuditRecType <> d.AuditRecType and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Audit Transactions', d.AuditTrans, i.AuditTrans,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.AuditTrans <> d.AuditTrans and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
   insert into bHQMA select 'bARCO', 'AR Co#: ' + isnull(convert(char(3),i.ARCo),''), i.ARCo, 'C',
   	'Tax in Discount Offered', d.DiscTax, i.DiscTax,
   	getdate(), SUSER_SNAME()
   from inserted i
   join deleted d on d.ARCo = i.ARCo
   where i.DiscTax <> d.DiscTax and (i.AuditCompany = 'Y' and i.AuditYN = 'Y')
   
--#21452
If update(AttachBatchReportsYN)
begin
	insert into bHQMA select 'bARCO', 'AR Co#: ' + convert(char(3),i.ARCo), i.ARCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.ARCo = d.ARCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
end

   return
   error:
   	select @errmsg = @errmsg + ' - cannot update AR Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_AuditCompany] CHECK (([AuditCompany]='Y' OR [AuditCompany]='N'))
GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_AuditCustomers] CHECK (([AuditCustomers]='Y' OR [AuditCustomers]='N'))
GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_AuditRecType] CHECK (([AuditRecType]='Y' OR [AuditRecType]='N'))
GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_AuditTrans] CHECK (([AuditTrans]='Y' OR [AuditTrans]='N'))
GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_AuditYN] CHECK (([AuditYN]='Y' OR [AuditYN]='N'))
GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_CMAcct] CHECK (([CMAcct]>(0) AND [CMAcct]<(10000) OR [CMAcct] IS NULL))
GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_DiscTax] CHECK (([DiscTax]='Y' OR [DiscTax]='N'))
GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_FCCalcOnFC] CHECK (([FCCalcOnFC]='Y' OR [FCCalcOnFC]='N'))
GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_InvAutoNum] CHECK (([InvAutoNum]='Y' OR [InvAutoNum]='N'))
GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_InvoiceTax] CHECK (([InvoiceTax]='Y' OR [InvoiceTax]='N'))
GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_RecTypeOpt] CHECK (([RecTypeOpt]='Y' OR [RecTypeOpt]='N'))
GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_ReceiptTax] CHECK (([ReceiptTax]='Y' OR [ReceiptTax]='N'))
GO
ALTER TABLE [dbo].[bARCO] WITH NOCHECK ADD CONSTRAINT [CK_bARCO_RelRetainOpt] CHECK (([RelRetainOpt]='Y' OR [RelRetainOpt]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biARCO] ON [dbo].[bARCO] ([ARCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bARCO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
