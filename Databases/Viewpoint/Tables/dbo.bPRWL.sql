CREATE TABLE [dbo].[bPRWL]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[LocalCode] [dbo].[bLocalCode] NOT NULL,
[TaxID] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[TaxEntity] [char] (10) COLLATE Latin1_General_BIN NULL,
[Wages] [dbo].[bDollar] NOT NULL,
[Tax] [dbo].[bDollar] NOT NULL,
[TaxType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRWL] ON [dbo].[bPRWL] ([PRCo], [TaxYear], [Employee], [State], [LocalCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRWL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btPRWLd] on [dbo].[bPRWL] for DELETE as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
*
*	Delete trigger for PR W2 Employee Local Info table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------


set nocount on

/* HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRWL', 
	'PRCo: ' + cast(d.PRCo as varchar(10)) + ',  Tax Year: ' + d.TaxYear + ',  State: ' + d.State + ',  Local: ' + d.LocalCode,   
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

CREATE trigger [dbo].[btPRWLi] on [dbo].[bPRWL] for INSERT as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
*
*	Insert trigger for PR W2 Employee Local Info table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

  
set nocount on
 
/* add HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRWL', 
	'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State + ',  Local: ' + i.LocalCode, 
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

CREATE  trigger [dbo].[btPRWLu] on [dbo].[bPRWL] for UPDATE as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
* 
*	Update trigger for PR W2 Employee Local Info table
* 
*	Adds record to HQ Master Audit.
*/----------------------------------------------------------------
   
set nocount on
   
if update(TaxID)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWL', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State + ',  Local: ' + i.LocalCode, 
		i.PRCo, 
		'C', 
		'TaxID', 
		d.TaxID, 
		i.TaxID, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.TaxID, '') <> isnull(d.TaxID, '') and a.W2AuditYN = 'Y'
	end

if update(TaxEntity)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWL', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State + ',  Local: ' + i.LocalCode, 
		i.PRCo, 
		'C', 
		'TaxEntity', 
		d.TaxEntity, 
		i.TaxEntity, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.TaxEntity, '') <> isnull(d.TaxEntity, '') and a.W2AuditYN = 'Y'
	end	

if update(Wages)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWL', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State + ',  Local: ' + i.LocalCode, 
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
    where i.Wages <> d.Wages and a.W2AuditYN = 'Y'
	end	

if update(Tax)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWL', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State + ',  Local: ' + i.LocalCode, 
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
    where i.Tax <> d.Tax and a.W2AuditYN = 'Y'
	end	
	
if update(TaxType)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWL', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State + ',  Local: ' + i.LocalCode, 
		i.PRCo, 
		'C', 
		'TaxType', 
		d.TaxType, 
		i.TaxType, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where i.TaxType <> d.TaxType and a.W2AuditYN = 'Y'
	end	
		
return


GO
