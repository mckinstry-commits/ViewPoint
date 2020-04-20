CREATE TABLE [dbo].[bPRCAEmployerProvince]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Province] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[DednCode] [dbo].[bEDLCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Initialize] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
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
-- Description:	Delete trigger for bPRCAEmployerProvince
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployerProvinced] 
   ON  [dbo].[bPRCAEmployerProvince] 
   for Delete
   
AS 

set nocount on

/* HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRCAEmployerProvince', 
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


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 09/17/2009
-- Modified date: CHS 09/30/2010	- #141451 Add auditing
-- Description:	Insert trigger for bPRCAEmployerProv.  In order
-- to insert a T4Province, TaxYear must exist in bPRCAEmployer
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployerProvincei] 
   ON  [dbo].[bPRCAEmployerProvince] 
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
		'bPRCAEmployerProvince', 
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

	select @errmsg = isnull(@errmsg,'') + ' - cannot insert bPRCAEmployerProvince.'
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
-- Description:	Update trigger for bPRCAEmployerProvince to prevent key changes.
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployerProvinceu] 
   ON  [dbo].[bPRCAEmployerProvince] 
   for Update
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if update(PRCo) or update(TaxYear) or update(Province) 
	begin
		select @errmsg = 'Cannot change primary key values'
		goto error
	end
	
	
	/* add HQ Master Audit entry */
if update(Initialize)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployerProvince', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Province: ' + i.Province, 
		i.PRCo, 
		'C', 
		'Initialize', 
		d.Initialize, 
		i.Initialize, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.Initialize <> d.Initialize and a.W2AuditYN = 'Y'
	end			
	
	

	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot update bPRCAEmployerProvince.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

END

GO
CREATE UNIQUE CLUSTERED INDEX [biPRCAEmployerProvince] ON [dbo].[bPRCAEmployerProvince] ([PRCo], [TaxYear], [Province]) ON [PRIMARY]
GO
