CREATE TABLE [dbo].[bPRWS]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[TaxID] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[TaxEntity] [char] (10) COLLATE Latin1_General_BIN NULL,
[Wages] [dbo].[bDollar] NOT NULL,
[Tax] [dbo].[bDollar] NOT NULL,
[OtherStateData] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[TaxType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[StateControl] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[OptionCode1] [varchar] (75) COLLATE Latin1_General_BIN NULL,
[OptionCode2] [varchar] (75) COLLATE Latin1_General_BIN NULL,
[Misc1Amt] [dbo].[bDollar] NOT NULL,
[Misc2Amt] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Misc3Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWS_Misc3Amt] DEFAULT ((0)),
[Misc4Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWS_Misc4Amt] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRWS] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btPRWSd] on [dbo].[bPRWS] for DELETE as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
*
*	Delete trigger for PR W2 Employee State Info table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------


set nocount on

/* HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRWS', 
	'PRCo: ' + cast(d.PRCo as varchar(10)) + ',  Tax Year: ' + d.TaxYear + ',  State: ' + d.State,   
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

CREATE trigger [dbo].[btPRWSi] on [dbo].[bPRWS] for INSERT as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
*
*	Insert trigger for PR W2 Employee State Info table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

  
set nocount on
 
/* add HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRWS', 
	'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State, 
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

CREATE  trigger [dbo].[btPRWSu] on [dbo].[bPRWS] for UPDATE as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
* 
*	Update trigger for PR W2 Employee State Info table
* 
*	Adds record to HQ Master Audit.
*/----------------------------------------------------------------
   
set nocount on
   
if update(TaxID)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWS', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State, 
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
		'bPRWS', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State, 
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
		'bPRWS', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State, 
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
		'bPRWS', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State, 
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
	
if update(OtherStateData)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWS', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State, 
		i.PRCo, 
		'C', 
		'OtherStateData', 
		d.OtherStateData, 
		i.OtherStateData, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.OtherStateData, '') <> isnull(d.OtherStateData, '') and a.W2AuditYN = 'Y'
	end	
		
if update(StateControl)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWS', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State, 
		i.PRCo, 
		'C', 
		'StateControl', 
		d.StateControl, 
		i.StateControl, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.StateControl, '') <> isnull(d.StateControl, '') and a.W2AuditYN = 'Y'
	end	
	
if update(OptionCode1)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWS', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State, 
		i.PRCo, 
		'C', 
		'OptionCode1', 
		d.OptionCode1, 
		i.OptionCode1, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.OptionCode1, '') <> isnull(d.OptionCode1, '') and a.W2AuditYN = 'Y'
	end		

if update(OptionCode2)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWS', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  State: ' + i.State, 
		i.PRCo, 
		'C', 
		'OptionCode2', 
		d.OptionCode2, 
		i.OptionCode2, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.OptionCode2, '') <> isnull(d.OptionCode2, '') and a.W2AuditYN = 'Y'
	end	
				
return


GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRWS].[Misc1Amt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRWS].[Misc2Amt]'
GO
