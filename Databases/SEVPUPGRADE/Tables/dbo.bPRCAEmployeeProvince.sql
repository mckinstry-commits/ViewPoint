CREATE TABLE [dbo].[bPRCAEmployeeProvince]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[Province] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[Wages] [dbo].[bDollar] NULL,
[Tax] [dbo].[bDollar] NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CHS
-- Create date: 09/30/2010	- #141451 Add auditing
-- Description:	Delete trigger for PRCAEmployeeProvince
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployeeProvinced] 
   ON  [dbo].[bPRCAEmployeeProvince] 
   for Delete
AS 
BEGIN


/* HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRCAEmployeeProvince', 
	'PRCo: ' + cast(d.PRCo as varchar(10)) + ',  Tax Year: ' + d.TaxYear + ',  Province: ' + d.Province, 
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
-- Description:	Insert trigger for bPRCAEmployeeProv.  In order
-- to insert a T4Province, TaxYear must exist in bPRCAEmployer and 
-- Employee must exist in bPRCAEmployees
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployeeProvincei] 
   ON  [dbo].[bPRCAEmployeeProvince] 
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
		select @errmsg = 'Employee does not exist in bPRCAEmployees.'
		goto error
	end


	/* add HQ Master Audit entry */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployeeProvince', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Province: ' + i.Province, 
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

	select @errmsg = isnull(@errmsg,'') + ' - cannot insert bPRCAEmployeeProvince.'
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
-- Description:	Update trigger for bPRCAEmployeeProvince to prevent key changes.
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployeeProvinceu] 
   ON  [dbo].[bPRCAEmployeeProvince] 
   for Update
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if update(PRCo) or update(TaxYear) or update(Employee) or update(Province)
	begin
		select @errmsg = 'Cannot change primary key values'
		goto error
	end


	/* add HQ Master Audit entry */
	if update(Wages)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployeeProvince', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Province: ' + i.Province, 
			i.PRCo, 
			'C', 
			'Wages', 
			d.Wages, 
			i.Wages, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.Wages, 0) <> isnull(d.Wages, 0) and a.W2AuditYN = 'Y'
		end	

	/* add HQ Master Audit entry */
	if update(Tax)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployeeProvince', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Province: ' + i.Province, 
			i.PRCo, 
			'C', 
			'Tax', 
			d.Tax, 
			i.Tax, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.Tax, 0) <> isnull(d.Tax, 0) and a.W2AuditYN = 'Y'
		end			
		
		

	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot update bPRCAEmployeeProvince.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

END

GO
CREATE CLUSTERED INDEX [biPRCAEmployeeProvince] ON [dbo].[bPRCAEmployeeProvince] ([PRCo], [TaxYear], [Employee], [Province]) ON [PRIMARY]
GO
