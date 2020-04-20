CREATE TABLE [dbo].[bGLCO]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[Consolid] [dbo].[bYN] NOT NULL,
[LastMthSubClsd] [dbo].[bMonth] NOT NULL,
[LastMthGLClsd] [dbo].[bMonth] NOT NULL,
[MaxOpen] [tinyint] NOT NULL,
[CashAccrual] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bGLCO_CashAccrual] DEFAULT ('A'),
[Unbal] [dbo].[bYN] NOT NULL,
[AuditCoParams] [dbo].[bYN] NOT NULL,
[AuditAccts] [dbo].[bYN] NOT NULL,
[AuditAutoJrnl] [dbo].[bYN] NOT NULL,
[AuditBals] [dbo].[bYN] NOT NULL,
[AuditBudgets] [dbo].[bYN] NOT NULL,
[AuditDetail] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[XCompJrnlEntryYN] [dbo].[bYN] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[LastMthAPClsd] [dbo].[bMonth] NOT NULL,
[LastMthARClsd] [dbo].[bMonth] NOT NULL,
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bGLCO_AttachBatchReportsYN] DEFAULT ('N'),
[FMConsolid] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bGLCO_FMConsolid] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btGLCOd] on [dbo].[bGLCO] for DELETE as
/*----------------------------------------------------------
* Created: ??
* Modified: AR 2/4/2011  - #143291 - adding foreign keys and check constraints, removing trigger look ups
*
*	This trigger rejects delete in bGLCO (GL Companies) if a
*	dependent record is found in:
*
*		Budget Codes exist
*		Fiscal Year entries exist
*		GL Accounts exist
*		Journals exist
*		Intercompany Acct entries exist
*
*	Adds HQ Master Audit entry.
*/---------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* check Budget Codes */
--#143291 - removing because of FK
/* check Fiscal Year */
--#143291 - removing because of FK
/* check Accounts */
--#143291 - removing because of FK

/* check Journals */
--#143291 - removing because of FK

/* check Intercompany Accts */
--#143291 - removing because of FK

/* Audit GL Company deletions */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bGLCO', 'GL Co#: ' + convert(varchar(3),GLCo),
	GLCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted

return

error:	
	select @errmsg = @errmsg + ' - cannot delete GL Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************/
CREATE trigger [dbo].[btGLCOi] on [dbo].[bGLCO] for INSERT as
/************************************************************************
* CREATED:	??
* MODIFIED:	GG 04/18/07 - #30116 - data security
*			TRL 02/18/08 --#21452
			AR 2/4/2011  - #142311 - adding foreign keys, removing trigger look ups
			AR 2/19/2011 - #142311 - adding check constraint, removing trigger look ups
*
* Purpose: 	This trigger rejects insertion in bGLCO (GL Companies) if the
*			following error condition exists:
*
*			Invalid HQ Company number
*
*			Adds HQ Master Audit entry.
* returns 1 and error msg if failed
*
*************************************************************************/
declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* validate HQ Company number */
--#142311 - removing because of FK

/* validate Last Month Closed in GL and Sub Ledgers 
--#142311 - replacing with a check constraint
if exists(select 1 from inserted where LastMthGLClsd > LastMthSubClsd)
	begin
	select @errmsg = 'Last month closed in General Ledger cannot exceed Sub Ledgers'
	goto error
	end
*/

/* add HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bGLCO',  'GL Co#: ' + convert(char(3), GLCo), GLCo, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted


--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bGLCO',  'GL Co#: ' + convert(char(3), GLCo), GLCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup int
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bGLCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bGLCo', i.GLCo, i.GLCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bGLCo' and s.Qualifier = i.GLCo 
						and s.Instance = convert(char(30),i.GLCo) and s.SecurityGroup = @dfltsecgroup)
	end 

return

error:
	select @errmsg = @errmsg + ' - cannot insert GL Company!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[btGLCOu] on [dbo].[bGLCO] for UPDATE as

/*-----------------------------------------------------------------
* Created: ??
* Modified: GG 02/10/06 - #120200 - cleanup, add audit for XCompJrnlEntryYN
*			TRL 02/18/08 --#21452
*			GG 02/25/08 - #120107 - add separate AP and AR close months	
*			AR 02/19/11	- #142311 - replacing trigger code with a check constraint
*
*	This trigger rejects update in bGLCO (GL Companies) if the
*	following error condition exists:
*
*	Cannot change GL Company
*	Sub Ledger close month cannot exceed General Ledger
*	AP and AR close months cannot excedd Sub Ledger
*
*	Adds record to HQ Master Audit.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int
select @numrows = @@rowcount
   
if @numrows = 0 return
set nocount on
   
/* check for key changes */
if update(GLCo)
	begin
	select @validcnt = count(*)
	from deleted d
	join inserted i on d.GLCo = i.GLCo
	if @numrows <> @validcnt
		begin
   		select @errmsg = 'Cannot change GL Company'
   		goto error
   		end
	end

/* validate Last Month Closed in GL and Sub Ledgers 
 --#142311 - replacing with a check constraint
if update(LastMthGLClsd) or update(LastMthSubClsd)
	begin
   	if exists(select top 1 1 from inserted where LastMthGLClsd > LastMthSubClsd)
   		begin
   		select @errmsg = 'Last month closed in General Ledger cannot exceed Sub Ledgers'
   		goto error
   		end
	end	 
*/
-- #120107 - validate close months for separate sub ledgers
if update(LastMthSubClsd) or update(LastMthAPClsd) 
	begin
   	if exists(select top 1 1 from inserted where LastMthSubClsd > LastMthSubClsd)
   		begin
   		select @errmsg = 'Last month closed in Sub Ledgers cannot exceed Accounts Payable'
   		goto error
   		end
	end
if update(LastMthSubClsd) or update(LastMthARClsd) 
	begin
   	if exists(select top 1 1 from inserted where LastMthSubClsd > LastMthSubClsd)
   		begin
   		select @errmsg = 'Last month closed in Sub Ledgers cannot exceed Accounts Receivable'
   		goto error
   		end
	end

/* update HQ Master Audit */
if update(Consolid)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Consolidated Co', d.Consolid, i.Consolid, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.GLCo = i.GLCo
	where i.Consolid <> d.Consolid
	end
if update(LastMthSubClsd)
	begin
 	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Last Mth Closed in Sub Ledgers', convert(varchar(30),d.LastMthSubClsd, 1),
   		convert(varchar(30),i.LastMthSubClsd, 1), getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.LastMthSubClsd <> d.LastMthSubClsd
	end
if update(LastMthGLClsd)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Last Mth Closed in GL', convert(varchar(30),d.LastMthGLClsd, 1),
   		convert(varchar(30),i.LastMthGLClsd, 1), getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.LastMthGLClsd <> d.LastMthGLClsd
	end
if update(MaxOpen)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Max months open', convert(varchar(30),d.MaxOpen),
   		convert(varchar(30),i.MaxOpen), getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.MaxOpen <> d.MaxOpen
	end
if update(CashAccrual)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Cash/Accrual', d.CashAccrual, i.CashAccrual, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.CashAccrual <> d.CashAccrual
	end
if update(Unbal)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Unbalanced Entries', d.Unbal, i.Unbal, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.Unbal <> d.Unbal
	end
if update(AuditCoParams)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Audit Co Parameters', d.AuditCoParams, i.AuditCoParams, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.AuditCoParams <> d.AuditCoParams
	end
if update(AuditAccts)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Audit Accounts', d.AuditAccts, i.AuditAccts, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.AuditAccts <> d.AuditAccts
	end
if update(AuditAutoJrnl)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Audit Auto Jrnl', d.AuditAutoJrnl, i.AuditAutoJrnl, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.AuditAutoJrnl <> d.AuditAutoJrnl
	end
if update(AuditBals)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Audit Acct Balances', d.AuditBals, i.AuditBals, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.AuditBals <> d.AuditBals
	end
if update(AuditBudgets)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Audit Budgets', d.AuditBudgets, i.AuditBudgets, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.AuditBudgets <> d.AuditBudgets
	end
if update(AuditDetail)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Audit Detail', d.AuditDetail, i.AuditDetail, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.AuditDetail <> d.AuditDetail
	end
if update(XCompJrnlEntryYN)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Cross Co Jrnl Entry', d.XCompJrnlEntryYN, i.XCompJrnlEntryYN, getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.XCompJrnlEntryYN <> d.XCompJrnlEntryYN
	end

	--#21452
If update(AttachBatchReportsYN)
begin
	insert into bHQMA select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.GLCo = d.GLCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
end
-- #120107 - add separate close months for AP and AR
if update(LastMthAPClsd)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Last Mth Closed in AP', convert(varchar(30),d.LastMthAPClsd, 1),
   		convert(varchar(30),i.LastMthAPClsd, 1), getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.LastMthAPClsd <> d.LastMthAPClsd
	end
if update(LastMthARClsd)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bGLCO', 'GL Co#: ' + convert(char(3),i.GLCo), i.GLCo, 'C',
   		'Last Mth Closed in AR', convert(varchar(30),d.LastMthARClsd, 1),
   		convert(varchar(30),i.LastMthARClsd, 1), getdate(), SUSER_SNAME()
   	from inserted i
	join deleted d on d.GLCo = i.GLCo
   	where i.LastMthARClsd <> d.LastMthARClsd
	end

return

error:
   	select @errmsg = @errmsg + ' - cannot update GL Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 




GO
ALTER TABLE [dbo].[bGLCO] WITH NOCHECK ADD CONSTRAINT [CK_bGLCO_AuditAccts] CHECK (([AuditAccts]='Y' OR [AuditAccts]='N'))
GO
ALTER TABLE [dbo].[bGLCO] WITH NOCHECK ADD CONSTRAINT [CK_bGLCO_AuditAutoJrnl] CHECK (([AuditAutoJrnl]='Y' OR [AuditAutoJrnl]='N'))
GO
ALTER TABLE [dbo].[bGLCO] WITH NOCHECK ADD CONSTRAINT [CK_bGLCO_AuditBals] CHECK (([AuditBals]='Y' OR [AuditBals]='N'))
GO
ALTER TABLE [dbo].[bGLCO] WITH NOCHECK ADD CONSTRAINT [CK_bGLCO_AuditBudgets] CHECK (([AuditBudgets]='Y' OR [AuditBudgets]='N'))
GO
ALTER TABLE [dbo].[bGLCO] WITH NOCHECK ADD CONSTRAINT [CK_bGLCO_AuditCoParams] CHECK (([AuditCoParams]='Y' OR [AuditCoParams]='N'))
GO
ALTER TABLE [dbo].[bGLCO] WITH NOCHECK ADD CONSTRAINT [CK_bGLCO_AuditDetail] CHECK (([AuditDetail]='Y' OR [AuditDetail]='N'))
GO
ALTER TABLE [dbo].[bGLCO] WITH NOCHECK ADD CONSTRAINT [CK_bGLCO_Consolid] CHECK (([Consolid]='Y' OR [Consolid]='N'))
GO
ALTER TABLE [dbo].[bGLCO] WITH NOCHECK ADD CONSTRAINT [CK_bGLCO_SubLedgerMonth] CHECK (([LastMthGLClsd]<=[LastMthSubClsd]))
GO
ALTER TABLE [dbo].[bGLCO] WITH NOCHECK ADD CONSTRAINT [CK_bGLCO_Unbal] CHECK (([Unbal]='Y' OR [Unbal]='N'))
GO
ALTER TABLE [dbo].[bGLCO] WITH NOCHECK ADD CONSTRAINT [CK_bGLCO_XCompJrnlEntryYN] CHECK (([XCompJrnlEntryYN]='Y' OR [XCompJrnlEntryYN]='N'))
GO
ALTER TABLE [dbo].[bGLCO] ADD CONSTRAINT [PK_bGLCO] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=100) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLCO] ON [dbo].[bGLCO] ([GLCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLCO] WITH NOCHECK ADD CONSTRAINT [FK_bGLCO_bHQCO_GLCo] FOREIGN KEY ([GLCo]) REFERENCES [dbo].[bHQCO] ([HQCo])
GO
ALTER TABLE [dbo].[bGLCO] NOCHECK CONSTRAINT [FK_bGLCO_bHQCO_GLCo]
GO
