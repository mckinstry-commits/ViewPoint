CREATE TABLE [dbo].[bARCN]
(
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [dbo].[bCustomer] NOT NULL,
[Seq] [int] NOT NULL,
[Date] [dbo].[bDate] NOT NULL,
[Contact] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Followup] [dbo].[bDate] NULL,
[Invoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Resolved] [dbo].[bYN] NOT NULL,
[UserID] [dbo].[bVPUserName] NOT NULL,
[Summary] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[CreatedDate] [dbo].[bDate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ARCo] [dbo].[bCompany] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bARCN] ADD
CONSTRAINT [CK_bARCN_Resolved] CHECK (([Resolved]='Y' OR [Resolved]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btARCNd] on [dbo].[bARCN] for DELETE

/*-----------------------------------------------------------------
* Created: TJL  11/26/07 - Issue #29904
* 
*
* Usage:
* 	Audits deletes in bHQMA
*
*/----------------------------------------------------------------
as
declare @errmsg varchar(255), @numrows int, @validcnt int, @user bVPUserName, @nullcnt int

select @numrows = @@rowcount, @validcnt=0
if @numrows = 0 return 
 
set nocount on

-- add HQMA audit
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select distinct('bARCN'), 'CustGroup: ' + isnull(convert(varchar(3),d.CustGroup),'')
	+ ' Customer: ' + isnull(convert(varchar(10),d.Customer),'')
	+ ' Seq: ' + isnull(convert(varchar(10),d.Seq),''), 
  	d.CustGroup, 'D', null, null, null, getdate(), SUSER_SNAME() 
from deleted d
join bHQCO h ON h.CustGroup = d.CustGroup
join bARCO a ON a.ARCo = h.HQCo and a.AuditCustomers = 'Y'

return
 
error:
	select @errmsg = @errmsg + ' - cannot delete Credit Note.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btARCNi] on [dbo].[bARCN] for INSERT 

/*-----------------------------------------------------------------
* Created: TJL  11/26/07 - Issue #29904
* 
*
* Usage:
*	Validate ARCo
* 	Audits insert in bHQMA
*
*/----------------------------------------------------------------
as
declare @errmsg varchar(255), @numrows int, @validcnt int, @user bVPUserName, @nullcnt int

select @numrows = @@rowcount, @validcnt=0
if @numrows = 0 return 
 
set nocount on

-- VALIDATE ARCo 
select @nullcnt = count(*) from inserted i where i.ARCo is null
select @validcnt = count(*) from dbo.bARCO c (NOLOCK) 
  join inserted i on c.ARCo = i.ARCo

if @nullcnt + @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AR Company #.'
	goto error
	end

-- add HQMA audit
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select distinct('bARCN'), 'CustGroup: ' + isnull(convert(varchar(3),i.CustGroup),'')
	+ ' Customer: ' + isnull(convert(varchar(10),i.Customer),'')
	+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),''), 
  	i.CustGroup, 'A', null, null, null, getdate(), SUSER_SNAME() 
from inserted i
join bHQCO h ON h.CustGroup = i.CustGroup
join bARCO a ON a.ARCo = h.HQCo and a.AuditCustomers = 'Y'
 
return
 
error:
	select @errmsg = @errmsg + ' - cannot insert Credit Note.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btARCNu] on [dbo].[bARCN] for UPDATE 

/*-----------------------------------------------------------------
* Created: TJL  11/26/07 - Issue #29904
* 
*
* Usage:
*	Validate ARCo
* 	Audits updates in bHQMA
*
*/----------------------------------------------------------------
as
declare @errmsg varchar(255), @numrows int, @validcnt int, @user bVPUserName, @nullcnt int

select @numrows = @@rowcount, @validcnt=0
if @numrows = 0 return 
 
set nocount on

-- VALIDATE ARCo 
select @nullcnt = count(*) from inserted i where i.ARCo is null
select @validcnt = count(*) from dbo.bARCO c (NOLOCK) 
  join inserted i on c.ARCo = i.ARCo

if @nullcnt + @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AR Company #.'
	goto error
	end

-- Audit updates
if update(ARCo)
	begin
   	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select distinct('bARCN'), 'CustGroup: ' + isnull(convert(varchar(3),i.CustGroup),'')
		+ ' Customer: ' + isnull(convert(varchar(10),i.Customer),'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),''), 
		i.CustGroup, 'C', 'ARCo',
		convert(varchar(3),d.ARCo), convert(varchar(3),i.ARCo), getdate(), SUSER_SNAME() 
   	from inserted i
   	join deleted d on i.CustGroup = d.CustGroup and i.Customer = d.Customer and i.Seq = d.Seq
   	join bHQCO h ON h.CustGroup = i.CustGroup
   	join bARCO a ON a.ARCo = h.HQCo and a.AuditCustomers = 'Y' 
   	where isnull(convert(varchar(3),d.ARCo),'') <> isnull(convert(varchar(3),i.ARCo),'')
	end

if update(Date)
	begin
   	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select distinct('bARCN'), 'CustGroup: ' + isnull(convert(varchar(3),i.CustGroup),'')
		+ ' Customer: ' + isnull(convert(varchar(10),i.Customer),'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),''), 
		i.CustGroup, 'C', 'Date',
		convert(varchar(12),d.Date), convert(varchar(12),i.Date), getdate(), SUSER_SNAME() 
   	from inserted i
   	join deleted d on i.CustGroup = d.CustGroup and i.Customer = d.Customer and i.Seq = d.Seq 
   	join bHQCO h ON h.CustGroup = i.CustGroup
   	join bARCO a ON a.ARCo = h.HQCo and a.AuditCustomers = 'Y' 
   	where isnull(convert(varchar(12),d.Date),'') <> isnull(convert(varchar(12),i.Date),'')
	end

if update(Contact)
	begin
   	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select distinct('bARCN'), 'CustGroup: ' + isnull(convert(varchar(3),i.CustGroup),'')
		+ ' Customer: ' + isnull(convert(varchar(10),i.Customer),'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),''), 
		i.CustGroup, 'C', 'Contact',
		convert(varchar(30),d.Contact), convert(varchar(30),i.Contact), getdate(), SUSER_SNAME() 
   	from inserted i
   	join deleted d on i.CustGroup = d.CustGroup and i.Customer = d.Customer and i.Seq = d.Seq 
   	join bHQCO h ON h.CustGroup = i.CustGroup
   	join bARCO a ON a.ARCo = h.HQCo and a.AuditCustomers = 'Y' 
   	where isnull(convert(varchar(30),d.Contact),'') <> isnull(convert(varchar(30),i.Contact),'')
	end

if update(Followup)
	begin
   	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select distinct('bARCN'), 'CustGroup: ' + isnull(convert(varchar(3),i.CustGroup),'')
		+ ' Customer: ' + isnull(convert(varchar(10),i.Customer),'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),''), 
		i.CustGroup, 'C', 'Followup',
		convert(varchar(12),d.Followup), convert(varchar(12),i.Followup), getdate(), SUSER_SNAME() 
   	from inserted i
   	join deleted d on i.CustGroup = d.CustGroup and i.Customer = d.Customer and i.Seq = d.Seq 
   	join bHQCO h ON h.CustGroup = i.CustGroup
   	join bARCO a ON a.ARCo = h.HQCo and a.AuditCustomers = 'Y' 
   	where isnull(convert(varchar(12),d.Followup),'') <> isnull(convert(varchar(12),i.Followup),'')
	end

if update(Invoice)
	begin
   	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select distinct('bARCN'), 'CustGroup: ' + isnull(convert(varchar(3),i.CustGroup),'')
		+ ' Customer: ' + isnull(convert(varchar(10),i.Customer),'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),''), 
		i.CustGroup, 'C', 'Invoice',
		convert(varchar(10),d.Invoice), convert(varchar(10),i.Invoice), getdate(), SUSER_SNAME() 
   	from inserted i
   	join deleted d on i.CustGroup = d.CustGroup and i.Customer = d.Customer and i.Seq = d.Seq 
   	join bHQCO h ON h.CustGroup = i.CustGroup
   	join bARCO a ON a.ARCo = h.HQCo and a.AuditCustomers = 'Y' 
   	where isnull(convert(varchar(10),d.Invoice),'') <> isnull(convert(varchar(10),i.Invoice),'')
	end

if update(Resolved)
	begin
   	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select distinct('bARCN'), 'CustGroup: ' + isnull(convert(varchar(3),i.CustGroup),'')
		+ ' Customer: ' + isnull(convert(varchar(10),i.Customer),'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),''), 
		i.CustGroup, 'C', 'Resolved',
		convert(varchar(1),d.Resolved), convert(varchar(1),i.Resolved), getdate(), SUSER_SNAME() 
   	from inserted i
   	join deleted d on i.CustGroup = d.CustGroup and i.Customer = d.Customer and i.Seq = d.Seq 
   	join bHQCO h ON h.CustGroup = i.CustGroup
   	join bARCO a ON a.ARCo = h.HQCo and a.AuditCustomers = 'Y' 
   	where isnull(convert(varchar(1),d.Resolved),'') <> isnull(convert(varchar(1),i.Resolved),'')
	end

if update(Summary)
	begin
   	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select distinct('bARCN'), 'CustGroup: ' + isnull(convert(varchar(3),i.CustGroup),'')
		+ ' Customer: ' + isnull(convert(varchar(10),i.Customer),'')
		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),''), 
		i.CustGroup, 'C', 'Summary',
		convert(varchar(30),d.Summary), convert(varchar(30),i.Summary), getdate(), SUSER_SNAME() 
   	from inserted i
   	join deleted d on i.CustGroup = d.CustGroup and i.Customer = d.Customer and i.Seq = d.Seq 
   	join bHQCO h ON h.CustGroup = i.CustGroup
   	join bARCO a ON a.ARCo = h.HQCo and a.AuditCustomers = 'Y' 
   	where isnull(convert(varchar(30),d.Summary),'') <> isnull(convert(varchar(30),i.Summary),'')
	end

/* Cannot use text, ntext, or image columns in the 'inserted' and 'deleted' tables. */
--if update(Notes)
--	begin
--   	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
--   	select distinct('bARCN'), 'CustGroup: ' + isnull(convert(varchar(3),i.CustGroup),'')
--		+ ' Customer: ' + isnull(convert(varchar(10),i.Customer),'')
--		+ ' Seq: ' + isnull(convert(varchar(10),i.Seq),''), 
--		i.CustGroup, 'C', 'Credit Note',
--		'Old credit note has been changed', 'By user ' + convert(varchar(27),SUSER_SNAME()), getdate(), SUSER_SNAME() 
--   	from inserted i
--   	join deleted d on i.CustGroup = d.CustGroup and i.Customer = d.Customer and i.Seq = d.Seq 
--   	join bHQCO h ON h.CustGroup = i.CustGroup
--   	join bARCO a ON a.ARCo = h.HQCo and a.AuditCustomers = 'Y' 
--   	where isnull(convert(varchar(8000),d.Notes),'') <> isnull(convert(varchar(8000),i.Notes),'')
--	end

return
 
error:
	select @errmsg = @errmsg + ' - cannot update Credit Note.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
CREATE UNIQUE CLUSTERED INDEX [biARCN] ON [dbo].[bARCN] ([CustGroup], [Customer], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bARCN] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bARCN].[Resolved]'
GO
