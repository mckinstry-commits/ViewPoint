CREATE TABLE [dbo].[bPRCAEmployer]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[BusinessNumber] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[TransmitterNumber] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[RPPNumber] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[CompanyName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AddressLine1] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AddressLine2] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (28) COLLATE Latin1_General_BIN NULL,
[Province] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[Country] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[PostalCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ContactName] [varchar] (22) COLLATE Latin1_General_BIN NULL,
[ContactPhone] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[ContactPhoneExt] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[ContactEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ReturnType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[OwnerSIN] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[CoOwnerSIN] [varchar] (9) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 09/17/2009
-- Modified		CHS	09/30/2010	- #141451 Add auditing
-- Description:	Delete trigger for bPRCAEmployer
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployerd] 
   ON  [dbo].[bPRCAEmployer] 
   for Delete
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if exists(select 1 from bPRCAEmployerItems c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear)
	begin
		select @errmsg = 'T4 related records exist in bPRCAEmployerItems.'
		goto error
	end

	if exists(select 1 from bPRCAEmployerCodes c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear)
	begin
		select @errmsg = 'T4 related records exist in bPRCAEmployerCodes.'
		goto error
	end

	if exists(select 1 from bPRCAEmployerProvince c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear)
	begin
		select @errmsg = 'T4 related records exist in bPRCAEmployerProvince.'
		goto error
	end
	
	if exists(select 1 from bPRCAEmployees c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear)
	begin
		select @errmsg = 'T4 related records exist in bPRCAEmployees.'
		goto error
	end

	if exists(select 1 from bPRCAEmployeeItems c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear)
	begin
		select @errmsg = 'T4 related records exist in bPRCAEmployeeItems.'
		goto error
	end
	
	if exists(select 1 from bPRCAEmployeeCodes c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear)
	begin
		select @errmsg = 'T4 related records exist in bPRCAEmployeeCodes.'
		goto error
	end

	if exists(select 1 from bPRCAEmployees c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear)
	begin
		select @errmsg = 'T4 related records exist in bPRCAEmployeeProvince.'
		goto error
	end
	
	
/* HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRCAEmployer', 
	'PRCo: ' + cast(d.PRCo as varchar(10)) + ',  Tax Year: ' + d.TaxYear, 
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

	select @errmsg = isnull(@errmsg,'') + ' - cannot delete bPRCAEmployer.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[btPRCAEmployeri] on [dbo].[bPRCAEmployer] for INSERT as
/*-----------------------------------------------------------------
* Created:		CHS	09/30/2010	#141451
* Modified: 
*
*	Insert trigger for PR Canadian Header table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

  
set nocount on
 
/* add HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRCAEmployer', 
	'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
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


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 09/17/2009
-- Modified		CHS	09/30/2010	- #141451 Add auditing
-- Description:	Update trigger for bPRCAEmployer to prevent key changes.
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployeru] 
   ON  [dbo].[bPRCAEmployer] 
   for Update
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if update(PRCo) or update(TaxYear)  
	begin
		select @errmsg = 'Cannot change primary key values'
		goto error
	end


 /* add HQ Master Audit entry */
if update(BusinessNumber)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'BusinessNumber', 
		d.BusinessNumber, 
		i.BusinessNumber, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.BusinessNumber, '') <> isnull(d.BusinessNumber, '') and a.W2AuditYN = 'Y'
	end	

if update(CompanyName)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'CompanyName', 
		d.CompanyName, 
		i.CompanyName, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.CompanyName, '') <> isnull(d.CompanyName, '') and a.W2AuditYN = 'Y'
	end	

if update(TransmitterNumber)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'TransmitterNumber', 
		d.TransmitterNumber, 
		i.TransmitterNumber, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.TransmitterNumber, '') <> isnull(d.TransmitterNumber, '') and a.W2AuditYN = 'Y'
	end	

if update(OwnerSIN)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'OwnerSIN', 
		d.OwnerSIN, 
		i.OwnerSIN, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.OwnerSIN, '') <> isnull(d.OwnerSIN, '') and a.W2AuditYN = 'Y'
	end	

if update(AddressLine1)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
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
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
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
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
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
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
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
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
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
		
if update(Country)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
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
		
if update(ContactName)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'ContactName', 
		d.ContactName, 
		i.ContactName, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.ContactName, '') <> isnull(d.ContactName, '') and a.W2AuditYN = 'Y'
	end		
		
if update(ContactPhone)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'ContactPhone', 
		d.ContactPhone, 
		i.ContactPhone, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.ContactPhone, '') <> isnull(d.ContactPhone, '') and a.W2AuditYN = 'Y'
	end			
		
if update(ContactPhoneExt)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'ContactPhoneExt', 
		d.ContactPhoneExt, 
		i.ContactPhoneExt, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.ContactPhoneExt, '') <> isnull(d.ContactPhoneExt, '') and a.W2AuditYN = 'Y'
	end		

if update(ContactEmail)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'ContactEmail', 
		d.ContactEmail, 
		i.ContactEmail, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.ContactEmail, '') <> isnull(d.ContactEmail, '') and a.W2AuditYN = 'Y'
	end	
			
if update(ReturnType)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'ReturnType', 
		d.ReturnType, 
		i.ReturnType, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.ReturnType, '') <> isnull(d.ReturnType, '') and a.W2AuditYN = 'Y'
	end		
		
if update(CoOwnerSIN)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'CoOwnerSIN', 
		d.CoOwnerSIN, 
		i.CoOwnerSIN, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.CoOwnerSIN, '') <> isnull(d.CoOwnerSIN, '') and a.W2AuditYN = 'Y'
	end		
		
if update(RPPNumber)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployer', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
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
		
	

	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot update bPRCAEmployer.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

END

GO
CREATE UNIQUE CLUSTERED INDEX [biPRCAEmployer] ON [dbo].[bPRCAEmployer] ([PRCo], [TaxYear]) ON [PRIMARY]
GO
