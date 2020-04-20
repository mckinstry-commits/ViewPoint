CREATE TABLE [dbo].[bPRWA]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[Item] [tinyint] NOT NULL,
[ItemID] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Seq] [int] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
   CREATE  trigger [dbo].[btPRWAd] on [dbo].[bPRWA] for DELETE as
/*-----------------------------------------------------------------
* Created:		MCP	09/20/2010	#138193
* Modified: 
*
*	Insert trigger for PR W2 Amounts
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

  
   /* HQ Master Audit entry */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWA', 
		'PRCo: ' + cast(d.PRCo as varchar(10)) + ',  Tax Year: ' + d.TaxYear + ', Employee: ' + cast(d.Employee as varchar(10)), 
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

CREATE  trigger [dbo].[btPRWAi] on [dbo].[bPRWA] for INSERT as
/*-----------------------------------------------------------------
* Created:		MCP	09/20/2010	#138193
* Modified: 
*
*	Insert trigger for PR W2 Employees table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

  
set nocount on
 
/* add HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRWA', 
	'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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

CREATE   trigger [dbo].[btPRWAu] on [dbo].[bPRWA] for UPDATE as
/*-----------------------------------------------------------------
* Created:		MCP	09/20/2010	#138193
* Modified: 
* 
*	Update trigger for PR W2 Amounts
* 
*	Adds record to HQ Master Audit.
*/----------------------------------------------------------------
   
set nocount on
   
if update(Amount)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWA', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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
	
if update(ItemID)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWA', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
		i.PRCo, 
		'C', 
		'ItemID', 
		d.ItemID, 
		i.ItemID, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.ItemID, '') <> isnull(d.ItemID, '') and a.W2AuditYN = 'Y'
	end	

	
return


GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRWA] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRWA] ON [dbo].[bPRWA] ([PRCo], [TaxYear], [Employee], [Item], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
