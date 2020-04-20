CREATE TABLE [dbo].[bAPCO]
(
[APCo] [dbo].[bCompany] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[ExpJrnl] [dbo].[bJrnl] NULL,
[GLExpInterfaceLvl] [tinyint] NOT NULL,
[GLExpSummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLExpTransDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLJobDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLInvDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLEquipDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLExpDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PayJrnl] [dbo].[bJrnl] NULL,
[GLPayInterfaceLvl] [tinyint] NOT NULL,
[GLPayDetailDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GLPaySummaryDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[DiscOffGLAcct] [dbo].[bGLAcct] NULL,
[DiscTakenGLAcct] [dbo].[bGLAcct] NULL,
[ExpPayType] [tinyint] NULL,
[JobPayType] [tinyint] NULL,
[SubPayType] [tinyint] NULL,
[RetPayType] [tinyint] NULL,
[OverridePayType] [dbo].[bYN] NOT NULL,
[RetHoldCode] [dbo].[bHoldCode] NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[CMInterfaceLvl] [tinyint] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[JCInterfaceLvl] [tinyint] NOT NULL,
[NetAmtOpt] [dbo].[bYN] NOT NULL,
[INCo] [dbo].[bCompany] NULL,
[INInterfaceLvl] [tinyint] NOT NULL,
[EMCo] [dbo].[bCompany] NULL,
[EMInterfaceLvl] [tinyint] NOT NULL,
[InvTotYN] [dbo].[bYN] NOT NULL,
[SLTotYN] [dbo].[bYN] NOT NULL,
[SLCompChkYN] [dbo].[bYN] NOT NULL,
[SLAllowPayYN] [dbo].[bYN] NOT NULL,
[POTotYN] [dbo].[bYN] NOT NULL,
[POCompChkYN] [dbo].[bYN] NOT NULL,
[POAllowPayYN] [dbo].[bYN] NOT NULL,
[ChkLines] [tinyint] NOT NULL,
[AuditCoParams] [dbo].[bYN] NOT NULL,
[AuditPayTypes] [dbo].[bYN] NOT NULL,
[AuditVendors] [dbo].[bYN] NOT NULL,
[AuditHold] [dbo].[bYN] NOT NULL,
[AuditComp] [dbo].[bYN] NOT NULL,
[AuditRecur] [dbo].[bYN] NOT NULL,
[AuditTrans] [dbo].[bYN] NOT NULL,
[AuditPay] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[APRefUnqYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_APRefUnqYN] DEFAULT ('N'),
[CheckReportTitle] [char] (60) COLLATE Latin1_General_BIN NULL,
[OverFlowReportTitle] [char] (60) COLLATE Latin1_General_BIN NULL,
[JobLineDescDfltYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_JobLineDescDfltYN] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[APRefUnq] [tinyint] NOT NULL CONSTRAINT [DF_bAPCO_APRefUnq] DEFAULT ((1)),
[AllCompChkYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_AllCompChkYN] DEFAULT ('N'),
[AllAllowPayYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_AllAllowPayYN] DEFAULT ('N'),
[UseTaxDiscountYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_UseTaxDiscountYN] DEFAULT ('N'),
[PMVendUpdYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_PMVendUpdYN] DEFAULT ('N'),
[PMVendAddYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_PMVendAddYN] DEFAULT ('N'),
[ICRptYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_ICRptYN] DEFAULT ('N'),
[ICRptTitle] [char] (60) COLLATE Latin1_General_BIN NULL,
[ICPayAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPCO_ICPayAmt] DEFAULT ((0)),
[PayCategoryYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_PayCategoryYN] DEFAULT ('N'),
[PayCategory] [int] NULL,
[AuditUnappInv] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_AuditUnappInv] DEFAULT ('N'),
[InvExceedRecvdYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_InvExceedRecvdYN] DEFAULT ('N'),
[POItemTotYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_POItemTotYN] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[JobLineJobPhaseUMDfltYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_JobLineJobPhaseUMDfltYN] DEFAULT ('N'),
[EMLineDescDfltYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_EMLineDescDfltYN] DEFAULT ('N'),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_AttachBatchReportsYN] DEFAULT ('N'),
[AttachVendorPayInfoYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_AttachVendorPayInfoYN] DEFAULT ('N'),
[CheckReportTitleByVendor] [char] (60) COLLATE Latin1_General_BIN NULL,
[EFTRemittanceReport] [char] (60) COLLATE Latin1_General_BIN NULL,
[CreditSvcRemittanceReport] [char] (60) COLLATE Latin1_General_BIN NULL,
[EFTRemittanceReportByVendor] [char] (60) COLLATE Latin1_General_BIN NULL,
[CreditSvcRemittanceReportByVendor] [char] (60) COLLATE Latin1_General_BIN NULL,
[VendorPayAttachTypeID] [int] NULL,
[AuditTransHoldCodeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_AuditTransHoldCodeYN] DEFAULT ('N'),
[TaxBasisNetRetgYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_TaxBasisNetRetgYN] DEFAULT ('N'),
[SMPayType] [tinyint] NULL,
[POItemLineTotYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_POItemLineTotYN] DEFAULT ('N'),
[InvExceedRecvdLineYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPCO_InvExceedRecvdLineYN] DEFAULT ('N'),
[APCreditService] [tinyint] NOT NULL CONSTRAINT [DF_bAPCO_APCreditService] DEFAULT ((0)),
[CSCMCo] [dbo].[bCompany] NULL,
[CSCMAcct] [dbo].[bCMAcct] NULL,
[CDAcctCode] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[CDCustID] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CDCodeWord] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[TCCo] [numeric] (6, 0) NULL,
[TCAcct] [numeric] (10, 0) NULL,
[CSDataFilePath] [varchar] (300) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btAPCOd] on [dbo].[bAPCO] for DELETE as
/*-----------------------------------------------------------------
* Created: GG 02/27/98
* Modified: GG 02/27/98
*
* Validates and inserts HQ Master Audit entry.  Will rollback delete
* if entries exist in numerous AP tables
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

/* check AP Payable Types */
if exists(select 1 from dbo.bAPPT a (nolock) join deleted d on a.APCo = d.APCo)
	begin
	select @errmsg = 'Entries exist in AP Payable Types for this AP Company'
	goto error
	end
/* check AP Vendor Activity */
if exists(select 1 from dbo.bAPVA a (nolock) join deleted d on a.APCo = d.APCo)
	begin
	select @errmsg = 'Entries exist in AP Vendor Activity for this AP Company'
	goto error
	end
/* check AP Vendor 1099 Totals */
if exists(select 1 from dbo.bAPFT a (nolock) join deleted d on a.APCo = d.APCo)
	begin
	select @errmsg = 'Entries exist in AP Vendor 1099 Totals for this AP Company'
	goto error
	end
/* check AP Vendor Hode Codes */
if exists(select 1 from dbo.bAPVH a (nolock) join deleted d on a.APCo = d.APCo)
	begin
	select @errmsg = 'Entries exist in AP Vendor Hold Codes for this AP Company'
	goto error
	end
/* check AP Vendor Compliance */
if exists(select 1 from dbo.bAPVC a (nolock) join deleted d on a.APCo = d.APCo)
	begin
	select @errmsg = 'Entries exist in AP Vendor Compliance for this AP Company'
	goto error
	end
/* check AP Recurring Invoices */
if exists(select 1 from dbo.bAPRH a (nolock) join deleted d on a.APCo = d.APCo)
	begin
	select @errmsg = 'Entries exist in AP Recurring Invoices for this AP Company'
	goto error
	end
/* check AP Transactions */
if exists(select 1 from dbo.bAPTH a (nolock) join deleted d on a.APCo = d.APCo)
	begin
	select @errmsg = 'Entries exist in AP Transactions for this AP Company'
	goto error
	end
/* check AP Unapproved Invoices */
if exists(select 1 from dbo.bAPUI a (nolock) join deleted d on a.APCo = d.APCo)
	begin
	select @errmsg = 'Entries exist in AP Unapproved Invoices for this AP Company'
	goto error
	end
/* check AP Payments */
if exists(select 1 from dbo.bAPPH a (nolock) join deleted d on a.APCo = d.APCo)
	begin
	select @errmsg = 'Entries exist in AP Payments for this AP Company'
	goto error
	end

/* Audit AP Company deletions */
insert dbo.bHQMA(TableName, KeyString, Co, RecType,
	FieldName, OldValue, NewValue, DateTime, UserName)
select 'bAPCO', 'AP Co#: ' + convert(varchar(3),APCo), APCo, 'D',
	null, null, null, getdate(), SUSER_SNAME()
from deleted

return

error:
	select @errmsg = @errmsg + ' - cannot delete AP Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btAPCOi] on [dbo].[bAPCO] for INSERT as
/*-----------------------------------------------------------------
*  Created:  GG   02/27/98
*  Modified: GG   02/27/98
*			 RM   02/21/01 - now adds default 1099 types if they do not exist
*			 RM   04/19/01 - Just do MISC until further notice
*			 DANF 12/17/02 - Added INT and DIV to trigger.
*			 GG   04/18/07 - #30116 - data security
*			 TRL  02/18/08 --@21452
*			 KK	  12/21/11 - TK-10793 Credit Services Enhancement
*
* Validates and inserts HQ Master Audit entry.  Company numbers for other
* modules, GL Accounts, and CM Accounts are not required to be valid.
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on
   
/* validate Company # in HQ */
select @validcnt = count(*) from inserted i
join dbo.bHQCO h (nolock) on h.HQCo = i.APCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AP Company'
	goto error
	end
/* validate GL Expense Interface Level */
select @validcnt = count(*) from inserted
where GLExpInterfaceLvl in (0,1,2,3)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid GL Expense Interface Level'
	goto error
	end
/* validate GL Payment Interface Level */
select @validcnt = count(*) from inserted where GLPayInterfaceLvl in (0,1,2)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid GL Payment Interface Level'
	goto error
	end
/* validate CM Interface Level */
select @validcnt = count(*) from inserted where CMInterfaceLvl in (0,1)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid CM Interface Level'
	goto error
	end
/* validate JC Interface Level */
select @validcnt = count(*) from inserted where JCInterfaceLvl in (0,1,2)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid JC Interface Level'
	goto error
	end
/* validate IN  Interface Level */
select @validcnt = count(*) from inserted where INInterfaceLvl in (0,1)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid IN Interface Level'
	goto error
	end
/* validate EM Interface Level */
select @validcnt = count(*) from inserted where EMInterfaceLvl in (0,1,2)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid EM Interface Level'
	goto error
	end
/* validate CreditService */
SELECT @validcnt = count(*) FROM inserted WHERE APCreditService IN (0,1,2)
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid Credit Service'
	GOTO error
END
	 
--Add Master Audit  
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bAPCO',  'AP Co#: ' + convert(char(3), APCo), APCo, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted

--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bAPCO',  'AP Co#: ' + convert(char(3), APCo), APCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted
      
--Add default 1099 types if they don't exist
if not exists(select 1 from dbo.bAPTT (nolock) where V1099Type = 'DIV')
	begin
	insert bAPTT(V1099Type,Description)
	values('DIV','Dividend')
	end
if not exists(select 1 from dbo.bAPTT (nolock) where V1099Type = 'INT')
	begin
   	insert bAPTT(V1099Type,Description)
	values('INT','Interest')
	end
if not exists(select * from dbo.bAPTT where V1099Type = 'MISC')
	begin
   	insert bAPTT(V1099Type,Description)
	values('MISC','Miscellaneous')
	end

--#30116 - initialize Data Security
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bAPCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bAPCo', i.APCo, i.APCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bAPCo' and s.Qualifier = i.APCo 
						and s.Instance = convert(char(30),i.APCo) and s.SecurityGroup = @dfltsecgroup)
	end  
   
return
   
error:
   	select @errmsg = @errmsg + ' - cannot insert AP Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
/****** Object:  Trigger dbo.btAPCOu   Script Date: 8/28/99 9:36:52 AM ******/
CREATE trigger [dbo].[btAPCOu] on [dbo].[bAPCO] for UPDATE as
/*-----------------------------------------------------------------
*  Created:  GG  02/27/98
*  Modified: GG  02/27/98
*			 DANF 02/21/2002 Add Audit of CheckReportTitle, OverFlowReportTitle,
*						APRefUnqYN, POAllowPayYN, POCompChkYN, POTotYN
*			 MV	 05/01/2002	- Add Audit of JobLineDescDfltYN
*			 MV	 07/29/2002	- APRefUnq audit
*			 MV	 03/18/2003	- #17124 update HQMA with new APCO fields.
*			 MV	 03/04/2004	- #18769 add Pay Category fields to audit.
*			 MV	 08/11/2004	- #25032 - add new APCO flags to audit.
*			 TJL 01/25/2008	- Issue #123687, Add HQMA audit for new APCO flags JobLineJobPhaseUMDfltYN and EMLineDescDfltYN
*			 TRL 02/18/2008	- #21452	
*			 MV	 02/25/2009	- #129891 add HQMA audit for new Email Pay Report info fields
*			 MV	 07/02/2009	- #134611 shortened field name for HQMA audit update for EFT Rem Rpt by Vendor
*			 CHS 08/03/2011	- #TK-07238 added POItemLineTotYN
*			 CHS 08/25/2011	- #TK-07960 added InvExceedRecvdLineYN
*			 KK  12/21/2011 - #TK-10793 added 9 fields from the Credit Service enhancement
*			 CHS 03/15/2012 - #B-09107 added column APOnCostInvNmbr
*			 MV	 03/22/2012 - #B-09107 removed column APOnCostInvNmbr
*			 KK  04/12/2012 - #B-09140 added 2 fields CreditSvcRemittanceReport and CreditSvcRemittanceReportByVendor
*		     KK 05/01/12 - TK-14337 Changed ComData => Comdata
*
*
* Validates and inserts HQ Master Audit entry.  Company numbers for other
* modules, GL Accounts, and CM Accounts are not required to be valid.
*
*		Cannot change primary key - AP Company
*/----------------------------------------------------------------
   
DECLARE @errmsg varchar(255), 
	    @numrows int, 
	    @validcnt int

SELECT @numrows = @@ROWCOUNT
IF @numrows = 0 
BEGIN
	RETURN
END

SET NOCOUNT ON

/* check for key changes */
SELECT @validcnt = COUNT(*) 
  FROM deleted d JOIN inserted i ON d.APCo = i.APCo
   
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Cannot change AP Company'
	GOTO error
END

/* validate GL Expense Interface Level */
IF UPDATE (GLExpInterfaceLvl)
BEGIN
	SELECT @validcnt = count(*) FROM inserted
	WHERE GLExpInterfaceLvl in (0,1,2,3)
	IF @validcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Invalid GL Expense Interface Level'
		GOTO error
	END
END

/* validate GL Payment Interface Level */
IF UPDATE (GLPayInterfaceLvl)
BEGIN
	SELECT @validcnt = count(*) from inserted
	WHERE GLPayInterfaceLvl in (0,1,2)
	IF @validcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Invalid GL Payment Interface Level'
		GOTO error
	END
END

/* validate CM Interface Level */
IF UPDATE(CMInterfaceLvl)
BEGIN
	SELECT @validcnt = count(*) from inserted
	WHERE CMInterfaceLvl in (0,1)
	IF @validcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Invalid CM Interface Level'
		GOTO error
	END
END

/* validate JC Interface Level */
IF UPDATE(JCInterfaceLvl)
BEGIN
	SELECT @validcnt = count(*) from inserted
	WHERE JCInterfaceLvl in (0,1,2)
	IF @validcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Invalid JC Interface Level'
		GOTO error
	END
END

/* validate IN  Interface Level */
IF UPDATE(INInterfaceLvl)
BEGIN
	SELECT @validcnt = count(*) from inserted
	WHERE INInterfaceLvl in (0,1)
	IF @validcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Invalid IN Interface Level'
		GOTO error
	END
END

/* validate EM Interface Level */
IF UPDATE(EMInterfaceLvl)
BEGIN
	SELECT @validcnt = count(*) from inserted
	WHERE EMInterfaceLvl in (0,1,2)
	IF @validcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Invalid EM Interface Level'
		GOTO error
	END
END
   
/* Insert records into HQMA for changes made to audited fields */
insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'GL Company', convert(char(3),d.GLCo), Convert(char(3),i.GLCo),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.GLCo <> d.GLCo

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Expense Jrnl', d.ExpJrnl, i.ExpJrnl, getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.ExpJrnl <> d.ExpJrnl

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'GL Exp Interface', convert(char(1),d.GLExpInterfaceLvl), Convert(char(1),i.GLExpInterfaceLvl),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.GLExpInterfaceLvl <> d.GLExpInterfaceLvl

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'GL Exp Summary Desc', d.GLExpSummaryDesc, i.GLExpSummaryDesc,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.GLExpSummaryDesc <> d.GLExpSummaryDesc

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'GL Exp Trans Desc', d.GLExpTransDesc, i.GLExpTransDesc,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.GLExpTransDesc <> d.GLExpTransDesc

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'GL Job Detail Desc', d.GLJobDetailDesc, i.GLJobDetailDesc,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.GLJobDetailDesc <> d.GLJobDetailDesc

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'GL Inv Detail Desc', d.GLInvDetailDesc, i.GLInvDetailDesc,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.GLInvDetailDesc <> d.GLInvDetailDesc

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'GL Equip Detail Desc', d.GLEquipDetailDesc, i.GLEquipDetailDesc,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.GLEquipDetailDesc <> d.GLEquipDetailDesc

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'GL Exp Detail Desc', d.GLExpDetailDesc, i.GLExpDetailDesc,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.GLExpDetailDesc <> d.GLExpDetailDesc

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Pay Jrnl', d.PayJrnl, i.PayJrnl, getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.PayJrnl <> d.PayJrnl

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'GL Pay Interface Lvl', convert(char(1),d.GLPayInterfaceLvl), Convert(char(1),i.GLPayInterfaceLvl),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.GLPayInterfaceLvl <> d.GLPayInterfaceLvl

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'GL Pay Detail Desc', d.GLPayDetailDesc, i.GLPayDetailDesc,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.GLPayDetailDesc <> d.GLPayDetailDesc

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'GL Pay Summary Desc', d.GLPaySummaryDesc, i.GLPaySummaryDesc,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.GLPaySummaryDesc <> d.GLPaySummaryDesc

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Disc Offered GL Account', d.DiscOffGLAcct, i.DiscOffGLAcct,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.DiscOffGLAcct <> d.DiscOffGLAcct

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Disc Taken GL Account', d.DiscTakenGLAcct, i.DiscTakenGLAcct,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.DiscTakenGLAcct <> d.DiscTakenGLAcct

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Exp Pay Type', convert(char(3),d.ExpPayType), convert(char(3),i.ExpPayType),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.ExpPayType <> d.ExpPayType

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Job Pay Type', convert(char(3),d.JobPayType), convert(char(3),i.JobPayType),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.JobPayType <> d.JobPayType

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Sub Pay Type', convert(char(3),d.SubPayType), Convert(char(3),i.SubPayType),

getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.SubPayType <> d.SubPayType

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Retainage Pay Type', convert(char(3),d.RetPayType), Convert(char(3),i.RetPayType),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.RetPayType <> d.RetPayType

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Override Pay Types', d.OverridePayType, i.OverridePayType,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.OverridePayType <> d.OverridePayType

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Retainage Hold Code', d.RetHoldCode, i.RetHoldCode,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.RetHoldCode <> d.RetHoldCode

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'CM Co#', convert(char(3),d.CMCo), Convert(char(3),i.CMCo),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.CMCo <> d.CMCo

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'CM Account', convert(char(6),d.CMAcct), Convert(char(6),i.CMAcct),
getdate(), SUSER_SNAME() 	from inserted i, deleted d
where i.APCo = d.APCo and i.CMAcct <> d.CMAcct

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'CM Interface Lvl', convert(char(1),d.CMInterfaceLvl), Convert(char(1),i.CMInterfaceLvl),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.CMInterfaceLvl <> d.CMInterfaceLvl

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'JC Co#', convert(char(3),d.JCCo), Convert(char(3),i.JCCo),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.JCCo <> d.JCCo

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'JC Interface Lvl', convert(char(1),d.JCInterfaceLvl), Convert(char(1),i.JCInterfaceLvl),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.JCInterfaceLvl <> d.JCInterfaceLvl

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Net Amount Option', d.NetAmtOpt, i.NetAmtOpt,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.NetAmtOpt <> d.NetAmtOpt

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'IN Co#', convert(char(3),d.INCo), Convert(char(3),i.INCo),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.INCo <> d.INCo

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'IN Interface Lvl', convert(char(1),d.INInterfaceLvl), Convert(char(1),i.INInterfaceLvl),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.INInterfaceLvl <> d.INInterfaceLvl

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'EM Co#', convert(char(3),d.EMCo), Convert(char(3),i.EMCo),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.EMCo <> d.EMCo

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'EM Interface Lvl', convert(char(1),d.EMInterfaceLvl), Convert(char(1),i.EMInterfaceLvl),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.EMInterfaceLvl <> d.EMInterfaceLvl

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Invoice Total Option', d.InvTotYN, i.InvTotYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.InvTotYN <> d.InvTotYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'SL Total Option', d.SLTotYN, i.SLTotYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.SLTotYN <> d.SLTotYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'SL Compliance Check', d.SLCompChkYN, i.SLCompChkYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.SLCompChkYN <> d.SLCompChkYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'SL Allow Pay Option', d.SLAllowPayYN, i.SLAllowPayYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.SLAllowPayYN <> d.SLAllowPayYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'PO Total Option', d.POTotYN, i.POTotYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.POTotYN <> d.POTotYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'PO Compliance Check', d.POCompChkYN, i.POCompChkYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.POCompChkYN <> d.POCompChkYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'PO Allow Pay Option', d.POAllowPayYN, i.POAllowPayYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.POAllowPayYN <> d.POAllowPayYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'# of Check Lines', convert(char(2),d.ChkLines), Convert(char(2),i.ChkLines),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.ChkLines <> d.ChkLines

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Audit Pay Types', d.AuditPayTypes, i.AuditPayTypes,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.AuditPayTypes <> d.AuditPayTypes

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Audit Vendors', d.AuditVendors, i.AuditVendors,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.AuditVendors <> d.AuditVendors

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Audit Hold Codes', d.AuditHold, i.AuditHold,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.AuditHold <> d.AuditHold

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Audit Compliance', d.AuditComp, i.AuditComp,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.AuditComp <> d.AuditComp

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Audit Recurring Invoices', d.AuditRecur, i.AuditRecur,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.AuditRecur <> d.AuditRecur

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Audit Transactions', d.AuditTrans, i.AuditTrans,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.AuditTrans <> d.AuditTrans

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Audit Payment History', d.AuditPay, i.AuditPay,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.AuditPay <> d.AuditPay

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'AP Ref Uniqueness', d.APRefUnq, i.APRefUnq,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.APRefUnq <> d.APRefUnq

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Check Report Title', d.CheckReportTitle, i.CheckReportTitle,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.CheckReportTitle <> d.CheckReportTitle

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'OverFlow Report Title', d.OverFlowReportTitle, i.OverFlowReportTitle,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.OverFlowReportTitle <> d.OverFlowReportTitle

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Job Line Desc Default', d.JobLineDescDfltYN, i.JobLineDescDfltYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.JobLineDescDfltYN <> d.JobLineDescDfltYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Equip Line Desc Default', d.EMLineDescDfltYN, i.EMLineDescDfltYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.EMLineDescDfltYN <> d.EMLineDescDfltYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Job Line Job Phase UM Default', d.JobLineJobPhaseUMDfltYN, i.JobLineJobPhaseUMDfltYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.JobLineJobPhaseUMDfltYN <> d.JobLineJobPhaseUMDfltYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Prevent Duplicate AP Ref', d.APRefUnqYN, i.APRefUnqYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.APRefUnqYN <> d.APRefUnqYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'All Invoice Compliance Check', d.AllCompChkYN, i.AllCompChkYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.AllCompChkYN <> d.AllCompChkYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'All Invoice Allow Pay Option', d.AllAllowPayYN, i.AllAllowPayYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.AllAllowPayYN <> d.AllAllowPayYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Using Tax Discount', d.UseTaxDiscountYN, i.UseTaxDiscountYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.UseTaxDiscountYN <> d.UseTaxDiscountYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Using Payable Category', d.PayCategoryYN, i.PayCategoryYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.PayCategoryYN <> d.PayCategoryYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Payable Category', d.PayCategory, i.PayCategory,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.PayCategory <> d.PayCategory

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'PO Item Total Option', d.POItemTotYN, i.POItemTotYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.POItemTotYN <> d.POItemTotYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Inv Exceed Item Received', d.InvExceedRecvdYN, i.InvExceedRecvdYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.InvExceedRecvdYN <> d.InvExceedRecvdYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Attach Vendor Payment Info YN', d.AttachVendorPayInfoYN, i.AttachVendorPayInfoYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.AttachVendorPayInfoYN <> d.AttachVendorPayInfoYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Check Report Title by Vendor', d.CheckReportTitleByVendor, i.CheckReportTitleByVendor,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.CheckReportTitleByVendor <> d.CheckReportTitleByVendor

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'EFT Remittance Report Title', d.EFTRemittanceReport, i.EFTRemittanceReport,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.EFTRemittanceReport <> d.EFTRemittanceReport

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Crdt Svc Remittance Rpt Title', d.CreditSvcRemittanceReport, i.CreditSvcRemittanceReport,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.CreditSvcRemittanceReport <> d.CreditSvcRemittanceReport

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'EFT Rem Report Title by Vendor', d.EFTRemittanceReportByVendor, i.EFTRemittanceReportByVendor,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.EFTRemittanceReportByVendor <> d.EFTRemittanceReportByVendor

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Crdt Svc Rem Rpt Title by Vend', d.CreditSvcRemittanceReportByVendor, i.CreditSvcRemittanceReportByVendor,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.CreditSvcRemittanceReportByVendor <> d.CreditSvcRemittanceReportByVendor

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Vendor Pyament Attach Type ID', d.VendorPayAttachTypeID, i.VendorPayAttachTypeID,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.VendorPayAttachTypeID <> d.VendorPayAttachTypeID

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Tax Basis Net Retg YN', d.TaxBasisNetRetgYN, i.TaxBasisNetRetgYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.TaxBasisNetRetgYN <> d.TaxBasisNetRetgYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'PO Item Line Total YN', d.POItemLineTotYN, i.POItemLineTotYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.POItemLineTotYN <> d.POItemLineTotYN

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Inv Exceed Item Line Received', d.InvExceedRecvdLineYN, i.InvExceedRecvdLineYN,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.InvExceedRecvdLineYN <> d.InvExceedRecvdLineYN

--TK-10793 Credit Service enhancement fields
insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Credit Service Option', convert(char(2),d.APCreditService), convert(char(2),i.APCreditService),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and i.APCreditService <> d.APCreditService

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Credit Service CMCo', convert(char(3),d.CSCMCo), convert(char(3),i.CSCMCo),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and isnull(i.CSCMCo,'') <> isnull(d.CSCMCo,'')

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Credit Service CMAcct', convert(char(4),d.CSCMAcct), convert(char(4),i.CSCMAcct),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and isnull(i.CSCMAcct,'') <> isnull(d.CSCMAcct,'')

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Comdata Account Code', d.CDAcctCode, i.CDAcctCode,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and isnull(i.CDAcctCode,'') <> isnull(d.CDAcctCode,'')

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Comdata Customer ID', d.CDCustID, i.CDCustID,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and isnull(i.CDCustID,'') <> isnull(d.CDCustID,'')

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Comdata Code Word', d.CDCodeWord, i.CDCodeWord,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and isnull(i.CDCodeWord,'') <> isnull(d.CDCodeWord,'')

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'T-Chek Company', convert(varchar,d.TCCo), convert(varchar,i.TCCo),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and isnull(i.TCCo,0) <> isnull(d.TCCo,0)

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'T-Chek Account', convert(varchar,d.TCAcct), convert(varchar,i.TCAcct),
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and isnull(i.TCAcct,0) <> isnull(d.TCAcct,0)

insert into bHQMA select 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
'Credit Service Data File Path', d.CSDataFilePath, i.CSDataFilePath,
getdate(), SUSER_SNAME()
from inserted i, deleted d
where i.APCo = d.APCo and isnull(i.CSDataFilePath,'') <> isnull(d.CSDataFilePath,'')

    
--#21452
IF UPDATE(AttachBatchReportsYN)
BEGIN
	INSERT INTO bHQMA SELECT 'bAPCO', 'AP Co#: ' + convert(char(3),i.APCo), i.APCo, 'C',
   		'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   		getdate(), SUSER_SNAME()
   	FROM inserted i, deleted d
   	WHERE i.APCo = d.APCo AND i.AttachBatchReportsYN <> d.AttachBatchReportsYN
END

RETURN
   
error:
	SELECT @errmsg = @errmsg + ' - cannot update AP Company!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
GO
CREATE UNIQUE CLUSTERED INDEX [biAPCO] ON [dbo].[bAPCO] ([APCo]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPCO] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[OverridePayType]'
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bAPCO].[CMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[NetAmtOpt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[InvTotYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[SLTotYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[SLCompChkYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[SLAllowPayYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[POTotYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[POCompChkYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[POAllowPayYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[AuditCoParams]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[AuditPayTypes]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[AuditVendors]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[AuditHold]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[AuditComp]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[AuditRecur]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[AuditTrans]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[AuditPay]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[APRefUnqYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[JobLineDescDfltYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[AllCompChkYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[AllAllowPayYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[UseTaxDiscountYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[PMVendUpdYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[PMVendAddYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[ICRptYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[PayCategoryYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[AuditUnappInv]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[InvExceedRecvdYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPCO].[POItemTotYN]'
GO
