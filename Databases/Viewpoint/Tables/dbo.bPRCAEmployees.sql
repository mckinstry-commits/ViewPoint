CREATE TABLE [dbo].[bPRCAEmployees]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[SIN] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[FirstName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MidName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[LastName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Suffix] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[AddressLine1] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AddressLine2] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (28) COLLATE Latin1_General_BIN NULL,
[Province] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[PostalCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ProvinceEmployed] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[CPPQPPExempt] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCAEmployees_CPPQPPExempt] DEFAULT ('N'),
[EIExempt] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCAEmployees_EIExempt] DEFAULT ('N'),
[PPIPExempt] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCAEmployees_PPIPExempt] DEFAULT ('N'),
[RPPNumber] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ReturnType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPRCAEmployees_ReturnType] DEFAULT ('O')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 09/17/2009
-- Modified date: CHS 09/30/2010	- #141451 Add auditing
--				  Liz S 10/01/2010	- #141209 Check Employee in Delete
-- Description:	Delete trigger for bPRCAEmployees
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployeesd] 
   ON  [dbo].[bPRCAEmployees] 
   for Delete
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	IF EXISTS (select 1 from bPRCAEmployeeItems c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear and c.Employee = d.Employee)
	BEGIN
		SELECT @errmsg = 'T4 related records exist in bPRCAEmployeeItems.'
		goto error
	END

	IF EXISTS(select 1 from bPRCAEmployeeCodes c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear and c.Employee = d.Employee)
	BEGIN
		SELECT @errmsg = 'T4 related records exist in bPRCAEmployeeCodes.'
		goto error
	END

	IF EXISTS (select 1 from bPRCAEmployeeProvince c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear and c.Employee = d.Employee)
	BEGIN
		SELECT @errmsg = 'T4 related records exist in bPRCAEmployeeProvince.'
		goto error
	END


/* HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRCAEmployees', 
	'PRCo: ' + cast(d.PRCo as varchar(10)) + ',  Tax Year: ' + d.TaxYear + ',  Employee: ' + cast(d.Employee as varchar(10)), 
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

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot delete bPRCAEmployees.'
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
-- Description:	Insert trigger for bPRCAEmployee.  In order
-- to insert a Employee, TaxYear must exist in bPRCAEmployer.
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployeesi] 
   ON  [dbo].[bPRCAEmployees] 
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


	/* add HQ Master Audit entry */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployees', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
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

	select @errmsg = isnull(@errmsg,'') + ' - cannot insert bPRCAEmployees.'
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
-- Description:	Update trigger for bPRCAEmployes to prevent key changes.
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployeesu] 
   ON  [dbo].[bPRCAEmployees] 
   for Update
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if update(PRCo) or update(TaxYear) or update(Employee) 
	begin
		select @errmsg = 'Cannot change primary key values'
		goto error
	end
	
	/* add HQ Master Audit entry */
	if update(SIN)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'SIN', 
			d.SIN, 
			i.SIN, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.SIN, '') <> isnull(d.SIN, '') and a.W2AuditYN = 'Y'
		end			

	if update(RPPNumber)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'RPPNumber', 
			d.RPPNumber, 
			i.RPPNumber, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.RPPNumber, '') <> isnull(d.RPPNumber, '') and a.W2AuditYN = 'Y'
		end			

	if update(FirstName)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'FirstName', 
			d.FirstName, 
			i.FirstName, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.FirstName, '') <> isnull(d.FirstName, '') and a.W2AuditYN = 'Y'
		end		

	if update(MidName)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'MidName', 
			d.MidName, 
			i.MidName, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.MidName, '') <> isnull(d.MidName, '') and a.W2AuditYN = 'Y'
		end	
	
	if update(LastName)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'LastName', 
			d.LastName, 
			i.LastName, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.LastName, '') <> isnull(d.LastName, '') and a.W2AuditYN = 'Y'
		end	
	
	if update(Suffix)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'Suffix', 
			d.Suffix, 
			i.Suffix, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.Suffix, '') <> isnull(d.Suffix, '') and a.W2AuditYN = 'Y'
		end		

	if update(AddressLine1)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'AddressLine1', 
			d.AddressLine1, 
			i.AddressLine1, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.AddressLine1, '') <> isnull(d.AddressLine1, '') and a.W2AuditYN = 'Y'
		end			

	if update(AddressLine2)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'AddressLine2', 
			d.AddressLine2, 
			i.AddressLine2, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.AddressLine2, '') <> isnull(d.AddressLine2, '') and a.W2AuditYN = 'Y'
		end		

	if update(City)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'City', 
			d.City, 
			i.City, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.City, '') <> isnull(d.City, '') and a.W2AuditYN = 'Y'
		end	

	if update(Province)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'Province', 
			d.Province, 
			i.Province, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.Province, '') <> isnull(d.Province, '') and a.W2AuditYN = 'Y'
		end	

	if update(PostalCode)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'PostalCode', 
			d.PostalCode, 
			i.PostalCode, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.PostalCode, '') <> isnull(d.PostalCode, '') and a.W2AuditYN = 'Y'
		end			

	if update(ProvinceEmployed)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'ProvinceEmployed', 
			d.ProvinceEmployed, 
			i.ProvinceEmployed, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.ProvinceEmployed, '') <> isnull(d.ProvinceEmployed, '') and a.W2AuditYN = 'Y'
		end			
		
	if update(Country)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'Country', 
			d.Country, 
			i.Country, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.Country, '') <> isnull(d.Country, '') and a.W2AuditYN = 'Y'
		end	

	if update(CPPQPPExempt)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'CPPQPPExempt', 
			d.CPPQPPExempt, 
			i.CPPQPPExempt, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.CPPQPPExempt, '') <> isnull(d.CPPQPPExempt, '') and a.W2AuditYN = 'Y'
		end	

	if update(PPIPExempt)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'PPIPExempt', 
			d.PPIPExempt, 
			i.PPIPExempt, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.PPIPExempt, '') <> isnull(d.PPIPExempt, '') and a.W2AuditYN = 'Y'
		end	
		
	if update(EIExempt)
   		begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 
			'bPRCAEmployees', 
			'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Employee: ' + cast(i.Employee as varchar(10)), 
			i.PRCo, 
			'C', 
			'EIExempt', 
			d.EIExempt, 
			i.EIExempt, 
			getdate(), 
			SUSER_SNAME() 
		from inserted i
			join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
			join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
		where isnull(i.EIExempt, '') <> isnull(d.EIExempt, '') and a.W2AuditYN = 'Y'
		end			

	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot update bPRCAEmployees.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

END

GO
CREATE UNIQUE CLUSTERED INDEX [biPRCAEmployees] ON [dbo].[bPRCAEmployees] ([PRCo], [TaxYear], [Employee]) ON [PRIMARY]
GO
