CREATE TABLE [dbo].[bPRWT]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[LocalCode] [dbo].[bLocalCode] NOT NULL,
[DednCode] [dbo].[bEDLCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Initialize] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btPRWTd] on [dbo].[bPRWT] for DELETE as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
*
*	Delete trigger for PR W2 State Info table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------


set nocount on

/* HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRWT', 
	'PRCo: ' + cast(d.PRCo as varchar(10)) + ',  Tax Year: ' + d.TaxYear + ',  State: ' + d.State + ',  LocalCode: ' + d.LocalCode, 
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

CREATE trigger [dbo].[btPRWTi] on [dbo].[bPRWT] for INSERT as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
*
*	Insert trigger for PR W2 State Info table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

  
set nocount on
 
/* add HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRWT', 
	'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State + ',  LocalCode: ' + i.LocalCode, 
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

CREATE  trigger [dbo].[btPRWTu] on [dbo].[bPRWT] for UPDATE as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
* 
*	Update trigger for PR State Info table
* 
*	Adds record to HQ Master Audit.
*/----------------------------------------------------------------
   
set nocount on
   
if update(Initialize)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWT', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State + ',  LocalCode: ' + i.LocalCode, 
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


GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRWT] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRWT].[Initialize]'
GO
