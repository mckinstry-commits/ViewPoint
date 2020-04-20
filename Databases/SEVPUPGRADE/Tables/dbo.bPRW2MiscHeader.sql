CREATE TABLE [dbo].[bPRW2MiscHeader]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[LineNumber] [int] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NULL,
[EDLCode] [dbo].[bEDLCode] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btPRW2MiscHeaderd] on [dbo].[bPRW2MiscHeader] for DELETE as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
*
*	Delete trigger for PR W2 Misc Info table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------


set nocount on

/* HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRW2MiscHeader', 
	'PRCo: ' + cast(d.PRCo as varchar(10)) + ',  Tax Year: ' + d.TaxYear + ',  Line: ' + cast(d.LineNumber as varchar(10)) + ',  State: ' + d.State,  
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

CREATE trigger [dbo].[btPRW2MiscHeaderi] on [dbo].[bPRW2MiscHeader] for INSERT as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
*
*	Insert trigger for PR W2 Misc Info table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

  
set nocount on
 
/* add HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRW2MiscHeader', 
	'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Line: ' + cast(i.LineNumber as varchar(10)) + ',  State: ' + i.State,  
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

CREATE  trigger [dbo].[btPRW2MiscHeaderu] on [dbo].[bPRW2MiscHeader] for UPDATE as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
* 
*	Update trigger for PR Misc Info table
* 
*	Adds record to HQ Master Audit.
*/----------------------------------------------------------------
   
set nocount on
   
if update(EDLType)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRW2MiscHeader', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Line: ' + cast(i.LineNumber as varchar(10)) + ',  State: ' + i.State, 
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
		'bPRW2MiscHeader', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Line: ' + cast(i.LineNumber as varchar(10)) + ',  State: ' + i.State, 
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
    where isnull(i.EDLCode, 0) <> isnull(d.EDLCode, 0) and a.W2AuditYN = 'Y'
	end
	
if update(Description)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRW2MiscHeader', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Line: ' + cast(i.LineNumber as varchar(10)) + ',  State: ' + i.State, 
		i.PRCo, 
		'C', 
		'Description', 
		d.Description, 
		i.Description, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Description, '') <> isnull(d.Description, '') and a.W2AuditYN = 'Y'
	end
		
return


GO
ALTER TABLE [dbo].[bPRW2MiscHeader] ADD CONSTRAINT [PK_vPRW2MiscHeader] PRIMARY KEY CLUSTERED  ([PRCo], [TaxYear], [State], [LineNumber]) ON [PRIMARY]
GO
