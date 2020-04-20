CREATE TABLE [dbo].[bPRCAEmployeeCodes]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[T4CodeNumber] [smallint] NOT NULL,
[Amount] [dbo].[bDollar] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CHS
-- Create date: 09/30/2010	- #141451 Add auditing
-- Description:	Delete trigger for bPRCAEmployeeCodes
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployeeCodesd] 
   ON  [dbo].[bPRCAEmployeeCodes] 
   for Delete
AS 
BEGIN


/* HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRCAEmployeeCodes', 
	'PRCo: ' + cast(d.PRCo as varchar(10)) + ',  Tax Year: ' + d.TaxYear + ',  T4 Code No: ' + cast(d.T4CodeNumber as varchar(10)), 
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
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 09/17/2009
-- Modified date: CHS 09/30/2010	- #141451 Add auditing
-- Description:	Insert trigger for bPRCAEmployeeCodes.  In order
-- to insert a T4CodeNumber, TaxYear must exist in bPRCAEmployer,
-- record must exist in bPRCAEmployees and T4 Code Number must 
-- exist in bPRCACodes
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployeeCodesi] 
   ON  [dbo].[bPRCAEmployeeCodes] 
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

	if not exists(select 1 from bPRCAEmployees p join inserted i on
	p.PRCo = i.PRCo and p.TaxYear = i.TaxYear and p.Employee = i.Employee)
	begin
		select @errmsg = 'Employee does not exist in bPRCAEmployee.'
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
		'bPRCAEmployeeCodes', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  T4 Code No: ' + cast(i.T4CodeNumber as varchar(10)), 
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

	select @errmsg = isnull(@errmsg,'') + ' - cannot insert bPRCAEmployeeCodes.'
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
-- Modified date: CHS 09/30/2010	- #141451 Add auditing
-- Description:	Update trigger for bPRCAEmployeeCodes to prevent key changes.
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployeeCodesu] 
   ON  [dbo].[bPRCAEmployeeCodes] 
   for Update
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if update(PRCo) or update(TaxYear) or update(Employee) or update(T4CodeNumber)
	begin
		select @errmsg = 'Cannot change primary key values'
		goto error
	end

	/* add HQ Master Audit entry */
	if update(Amount)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployeeCodes', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  T4 Code No: ' + cast(i.T4CodeNumber as varchar(10)), 
			i.PRCo, 
			'C', 
			'Amount', 
			d.Amount, 
			i.Amount, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.Amount, 0) <> isnull(d.Amount, 0) and a.W2AuditYN = 'Y'
		end		


	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot update bPRCAEmployeeCodes.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

END

GO
CREATE UNIQUE CLUSTERED INDEX [biPRCAEmployeeCodes] ON [dbo].[bPRCAEmployeeCodes] ([PRCo], [TaxYear], [Employee], [T4CodeNumber]) ON [PRIMARY]
GO
