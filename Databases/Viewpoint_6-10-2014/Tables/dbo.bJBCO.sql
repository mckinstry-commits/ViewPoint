CREATE TABLE [dbo].[bJBCO]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[AutoSeqInvYN] [dbo].[bYN] NOT NULL,
[InvoiceOpt] [char] (1) COLLATE Latin1_General_BIN NULL,
[LastInvoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ChgPrevProg] [dbo].[bYN] NOT NULL,
[AuditCo] [dbo].[bYN] NOT NULL,
[AuditBills] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UndefinedAsBilledYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBCO_UndefinedAsBilledYN] DEFAULT ('N'),
[EditProgOnBothYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBCO_EditProgOnBothYN] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[AuditTemplate] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBCO_AuditTemplate] DEFAULT ('N'),
[JBTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PrevUpdateYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBCO_PrevUpdateYN] DEFAULT ('N'),
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBCO_AuditYN] DEFAULT ('Y'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBCO_AttachBatchReportsYN] DEFAULT ('N'),
[UseCertified] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBCO_UseCertified] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btJBCOd] on [dbo].[bJBCO] for DELETE as
/*--------------------------------------------------------------
* Created: EN 12/30/99
* Modified: kb 4/9/2 - issue #16897
*			TJL 03/15/04 - Issue #24031, Add AuditYN flag
*			GG 04/20/07 - #30116 - data security review
*
* Delete trigger for JB Companies, reject deletion if following conditions exist:
*	JB Invoices exist
*
* Insert audit entries into bHQMA.
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255)
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on
   
-- check for existing JB Invoices
if exists(select top 1 1 from dbo.bJBIN n (nolock) join deleted d on d.JBCo = n.JBCo)
	begin
	select @errmsg = 'Bills exist - JB Company cannot be deleted'
	goto error
	end
   
/* Audit CM Company deletions */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJBCO', 'JB Co#: ' + convert(varchar(3),JBCo), JBCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted	-- audit all Company deletions
  
return
   
error:
	select @errmsg = @errmsg + ' - cannot remove JB Company'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE trigger [dbo].[btJBCOi] on [dbo].[bJBCO] for INSERT as
/*--------------------------------------------------------------
* Created: 8/30/00 kb
* Modifed: TJL 03/15/04 - Issue #24031, Add AuditYN flag
*			GG 04/20/07 - #30116 - data security review
*			TRL 02/18/08 --@21452
*
* Insert trigger for JB Companies, reject insert if any of the following conditions exist:
*	Invalid Company #
*	AuditCoParams must be 'Y'.
*
*  Add audit entries in bHQMA.
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   
/* validate HQ Company */
select @validcnt = count(*) from dbo.bHQCO c (nolock) join inserted i on c.HQCo = i.JBCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid JB Company#, must be setup in HQ first '
	goto error
	end
   
/* validate AuditCoParams */
select @validcnt = count(*) from inserted where AuditCo = 'Y'
if @validcnt <> @numrows
	begin
	select @errmsg = 'Option to audit company parameters must be checked.'
	goto error
	end
   
/* add HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJBCO', 'JB Co#: ' + convert(char(3), JBCo), JBCo, 'A', null, null, null, getdate(), SUSER_SNAME() 
from inserted

--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJBCO',  'JB Co#: ' + convert(char(3), JBCo), JBCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup int
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bJBCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bJBCo', i.JBCo, i.JBCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bJBCo' and s.Qualifier = i.JBCo 
						and s.Instance = convert(char(30),i.JBCo) and s.SecurityGroup = @dfltsecgroup)
	end 

return

error:
   select @errmsg = @errmsg + ' - cannot insert JB Company'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
/****** Object:  Trigger dbo.btJBCOu    Script Date: 8/28/99 9:38:18 AM ******/
CREATE trigger [dbo].[btJBCOu] on [dbo].[bJBCO] for UPDATE as
 
/***  basic declares for SQL Triggers ****/
declare @numrows int, @errmsg varchar(255), @validcount int

/*--------------------------------------------------------------
*
*  Update trigger for JBCO
*  Created By: EN  12/30/99
*	TJL 03/15/04 - Issue #24031,  Correct HQMA Audit of Invoice Number, Add AuditYN flag
*	TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*	TJL 08/01/06 - Issue #119928, Add HQMA Auditing for JBCO.PrevUpdateYN, JBCO.JBTemplate, JBCO.AuditTemplate
*	TRL 02/18/08 --@21452
*		TJL 12/22/08 - Issue #129896, Add HQMA Audits for UseCertified field
*
*  Reject key changes.
*  AuditCoParams must be 'Y'.
*  Insert audit entries for changed values into bHQMA.
*--------------------------------------------------------------*/

select @numrows = @@rowcount
if @numrows = 0 return

select @validcount=0

set nocount on

/* check for key changes */
select @validcount = count(*) 
from deleted d, inserted i
where d.JBCo = i.JBCo
if @validcount <> @numrows
	begin
	select @errmsg = 'Cannot change JB Company'
	goto error
	end

/* validate AuditCoParams */
select @validcount = count(*) 
from inserted 
where AuditCo = 'Y'
if @validcount <> @numrows
	begin
	select @errmsg = 'Option to audit company parameters must be checked.'
	goto error
	end

/* HQMA audit posting */
/* Insert records into HQMA for changes made to audited fields */
If update(AutoSeqInvYN)
	begin
	insert into bHQMA select 'bJBCO', 'JB Co#: ' + convert(char(3),i.JBCo), i.JBCo, 'C',
	'AutoSeqInvYN', d.AutoSeqInvYN, i.AutoSeqInvYN,
	getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.JBCo = i.JBCo
	where i.AutoSeqInvYN <> d.AutoSeqInvYN and (i.AuditCo = 'Y' and i.AuditYN = 'Y')
	end

if update(InvoiceOpt)
	begin
	insert into bHQMA select 'bJBCO', 'JB Co#: ' + convert(char(3),i.JBCo), i.JBCo, 'C',
	'InvoiceOpt', d.InvoiceOpt, i.InvoiceOpt,
	getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.JBCo = i.JBCo
	where isnull(i.InvoiceOpt, '') <> isnull(d.InvoiceOpt, '') and (i.AuditCo = 'Y' and i.AuditYN = 'Y')
	end

if update(LastInvoice)
	begin
	insert into bHQMA select 'bJBCO', 'JB Co#: ' + convert(char(3),i.JBCo), i.JBCo, 'C',
	'LastInvoice', d.LastInvoice, i.LastInvoice,
	getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.JBCo = i.JBCo
	where isnull(i.LastInvoice, '') <> isnull(d.LastInvoice, '') and (i.AuditCo = 'Y' and i.AuditYN = 'Y')
	end

if update(ChgPrevProg)
	begin
	insert into bHQMA select 'bJBCO', 'JB Co#: ' + convert(char(3),i.JBCo), i.JBCo, 'C',
	'ChgPrevProg', d.ChgPrevProg, i.ChgPrevProg,
	getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.JBCo = i.JBCo
	where i.ChgPrevProg <> d.ChgPrevProg and (i.AuditCo = 'Y' and i.AuditYN = 'Y')
	end

if update(PrevUpdateYN)
	begin
	insert into bHQMA select 'bJBCO', 'JB Co#: ' + convert(char(3),i.JBCo), i.JBCo, 'C',
	'PrevUpdateYN', d.PrevUpdateYN, i.PrevUpdateYN,
	getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.JBCo = i.JBCo
	where i.PrevUpdateYN <> d.PrevUpdateYN and (i.AuditCo = 'Y' and i.AuditYN = 'Y')
	end

if update(EditProgOnBothYN)
	begin
	insert into bHQMA select 'bJBCO', 'JB Co#: ' + convert(char(3),i.JBCo), i.JBCo, 'C',
	'EditProgOnBothYN', d.EditProgOnBothYN, i.EditProgOnBothYN,
	getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.JBCo = i.JBCo
	where i.EditProgOnBothYN <> d.EditProgOnBothYN and (i.AuditCo = 'Y' and i.AuditYN = 'Y')
	end

if update(UndefinedAsBilledYN)
	begin
	insert into bHQMA select 'bJBCO', 'JB Co#: ' + convert(char(3),i.JBCo), i.JBCo, 'C',
	'UndefinedAsBilledYN', d.UndefinedAsBilledYN, i.UndefinedAsBilledYN,
	getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.JBCo = i.JBCo
	where i.UndefinedAsBilledYN <> d.UndefinedAsBilledYN and (i.AuditCo = 'Y' and i.AuditYN = 'Y')
	end

if update(JBTemplate)
	begin
	insert into bHQMA select 'bJBCO', 'JB Co#: ' + convert(char(3),i.JBCo), i.JBCo, 'C',
	'JB Template', d.JBTemplate, i.JBTemplate,
	getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.JBCo = i.JBCo
	where i.JBTemplate <> d.JBTemplate and (i.AuditCo = 'Y' and i.AuditYN = 'Y')
	end

if update(AuditBills)
	begin
	insert into bHQMA select 'bJBCO', 'JB Co#: ' + convert(char(3),i.JBCo), i.JBCo, 'C',
	'AuditBills', d.AuditBills, i.AuditBills,
	getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.JBCo = i.JBCo
	where i.AuditBills <> d.AuditBills and (i.AuditCo = 'Y' and i.AuditYN = 'Y')
	end

if update(AuditTemplate)
	begin
	insert into bHQMA select 'bJBCO', 'JB Co#: ' + convert(char(3),i.JBCo), i.JBCo, 'C',
	'AuditTemplate', d.AuditTemplate, i.AuditTemplate,
	getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.JBCo = i.JBCo
	where i.AuditTemplate <> d.AuditTemplate and (i.AuditCo = 'Y' and i.AuditYN = 'Y')
	end

--#21452
If update(AttachBatchReportsYN)
	begin
	insert into bHQMA select 'bJBCO', 'JB Co#: ' + convert(char(3),i.JBCo), i.JBCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.JBCo = d.JBCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
	end

if update(UseCertified)
	begin
	insert into bHQMA select 'bJBCO', 'JB Co#: ' + convert(char(3),i.JBCo), i.JBCo, 'C',
	'UseCertified', d.UseCertified, i.UseCertified,
	getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.JBCo = i.JBCo
	where i.UseCertified <> d.UseCertified and (i.AuditCo = 'Y' and i.AuditYN = 'Y')
	end

return

error:
  select @errmsg = @errmsg + ' - cannot update JB Company '
  RAISERROR(@errmsg, 11, -1);
  rollback transaction
   
   
  
 





GO
ALTER TABLE [dbo].[bJBCO] WITH NOCHECK ADD CONSTRAINT [CK_bJBCO_AuditBills] CHECK (([AuditBills]='Y' OR [AuditBills]='N'))
GO
ALTER TABLE [dbo].[bJBCO] WITH NOCHECK ADD CONSTRAINT [CK_bJBCO_AuditCo] CHECK (([AuditCo]='Y' OR [AuditCo]='N'))
GO
ALTER TABLE [dbo].[bJBCO] WITH NOCHECK ADD CONSTRAINT [CK_bJBCO_AuditTemplate] CHECK (([AuditTemplate]='Y' OR [AuditTemplate]='N'))
GO
ALTER TABLE [dbo].[bJBCO] WITH NOCHECK ADD CONSTRAINT [CK_bJBCO_AuditYN] CHECK (([AuditYN]='Y' OR [AuditYN]='N'))
GO
ALTER TABLE [dbo].[bJBCO] WITH NOCHECK ADD CONSTRAINT [CK_bJBCO_AutoSeqInvYN] CHECK (([AutoSeqInvYN]='Y' OR [AutoSeqInvYN]='N'))
GO
ALTER TABLE [dbo].[bJBCO] WITH NOCHECK ADD CONSTRAINT [CK_bJBCO_ChgPrevProg] CHECK (([ChgPrevProg]='Y' OR [ChgPrevProg]='N'))
GO
ALTER TABLE [dbo].[bJBCO] WITH NOCHECK ADD CONSTRAINT [CK_bJBCO_EditProgOnBothYN] CHECK (([EditProgOnBothYN]='Y' OR [EditProgOnBothYN]='N'))
GO
ALTER TABLE [dbo].[bJBCO] WITH NOCHECK ADD CONSTRAINT [CK_bJBCO_PrevUpdateYN] CHECK (([PrevUpdateYN]='Y' OR [PrevUpdateYN]='N'))
GO
ALTER TABLE [dbo].[bJBCO] WITH NOCHECK ADD CONSTRAINT [CK_bJBCO_UndefinedAsBilledYN] CHECK (([UndefinedAsBilledYN]='Y' OR [UndefinedAsBilledYN]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biJBCO] ON [dbo].[bJBCO] ([JBCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBCO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
