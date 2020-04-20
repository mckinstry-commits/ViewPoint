CREATE TABLE [dbo].[bPRCAEmployerCodes]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[T4CodeNumber] [smallint] NOT NULL,
[T4CodeNumberSeq] [smallint] NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NULL,
[EDLCode] [dbo].[bEDLCode] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CHS
-- Create date: 09/30/2010	- #141451 Add auditing
-- Description:	Delete trigger for bPRCAEmployerCodes
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployerCodesd] 
   ON  [dbo].[bPRCAEmployerCodes] 
   for Delete
   
AS 

set nocount on

/* HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRCAEmployerCodes', 
	'PRCo: ' + cast(d.PRCo as varchar(10)) + ',  Tax Year: ' + d.TaxYear + ',  Code Number: ' + cast(d.T4CodeNumber as varchar(10)), 
	d.PRCo, 
	'D', 
	null, 
	null, 
	null, 
	getdate(), 
	SUSER_SNAME() 
from deleted d
join dbo.bPRCO c (nolock) on d.PRCo = c.PRCo
where c.W2AuditYN = 'Y'

return


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 09/17/2009
-- Modified date: 09/30/2010	- #141451 Add auditing
-- Description:	Insert trigger for bPRCAEmployerCodes.  In order
-- to insert a T4CodeNumber, TaxYear must exist in bPRCAEmployer and 
-- T4 Code Number must first exist in bPRCACodes
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployerCodesi] 
   ON  [dbo].[bPRCAEmployerCodes] 
   for Insert
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if not exists(select 1 from bPRCAEmployer p join inserted i on
	p.PRCo = i.PRCo and p.TaxYear = i.TaxYear)
	begin
		select @errmsg = 'T4 Tax Year has not been set up in bPRCAEmployer.'
		goto error
	end

	if not exists(select 1 from bPRCACodes p join inserted i on 
	p.PRCo = i.PRCo and p.TaxYear = i.TaxYear and p.T4CodeNumber = i.T4CodeNumber)
	begin
		select @errmsg = 'T4 Code Number has not been set up in bPRCACodes.'
		goto error
	end


	/* add HQ Master Audit entry */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployerCodes', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Code Number: ' + cast(i.T4CodeNumber as varchar(10)), 
		i.PRCo, 
		'A', 
		null, 
		null, 
		null, 
		getdate(), 
		SUSER_SNAME() 
	from inserted i
	join dbo.bPRCO c (nolock) on i.PRCo = c.PRCo
	where c.W2AuditYN = 'Y'


	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot insert bPRCAEmployerCodes.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 09/17/2009
-- Description:	Update trigger for bPRCAEmployerCodes to prevent key changes.
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployerCodesu] 
   ON  [dbo].[bPRCAEmployerCodes] 
   for Update
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if update(PRCo) or update(TaxYear) or update(T4CodeNumber) or update(T4CodeNumberSeq) 
	begin
		select @errmsg = 'Cannot change primary key values'
		goto error
	end

/* add HQ Master Audit entry */
if update(EDLType)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployerCodes', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Code Number: ' + cast(i.T4CodeNumber as varchar(10)), 
		i.PRCo, 
		'C', 
		'EDLType', 
		d.EDLType, 
		i.EDLType, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.EDLType, '') <> isnull(d.EDLType, '') and a.W2AuditYN = 'Y'
	end		
	
if update(EDLCode)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployerCodes', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Code Number: ' + cast(i.T4CodeNumber as varchar(10)), 
		i.PRCo, 
		'C', 
		'EDLCode', 
		d.EDLCode, 
		i.EDLCode, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.EDLCode, -1) <> isnull(d.EDLCode, -1) and a.W2AuditYN = 'Y'
	end	


	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot update bPRCAEmployerCodes.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

END

GO
CREATE UNIQUE CLUSTERED INDEX [biPRCAEmployerCodes] ON [dbo].[bPRCAEmployerCodes] ([PRCo], [TaxYear], [T4CodeNumber], [T4CodeNumberSeq]) ON [PRIMARY]
GO
