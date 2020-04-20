CREATE TABLE [dbo].[bPRWH]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[EIN] [char] (9) COLLATE Latin1_General_BIN NOT NULL,
[Resub] [tinyint] NOT NULL,
[ResubTLCN] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[CoName] [varchar] (57) COLLATE Latin1_General_BIN NULL,
[LocAddress] [varchar] (22) COLLATE Latin1_General_BIN NULL,
[DelAddress] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (22) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[ZipExt] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Contact] [varchar] (27) COLLATE Latin1_General_BIN NULL,
[Phone] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[PhoneExt] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[EMail] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[Fax] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PensionPlan] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Misc1Desc] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Misc1EDLType] [char] (1) COLLATE Latin1_General_BIN NULL,
[Misc1EDLCode] [dbo].[bEDLCode] NULL,
[Misc2Desc] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Misc2EDLType] [char] (1) COLLATE Latin1_General_BIN NULL,
[Misc2EDLCode] [dbo].[bEDLCode] NULL,
[PIN] [varchar] (17) COLLATE Latin1_General_BIN NULL,
[SickPayFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRWH_SickPayFlag] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[Misc3Desc] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Misc3EDLType] [char] (1) COLLATE Latin1_General_BIN NULL,
[Misc3EDLCode] [dbo].[bEDLCode] NULL,
[Misc4Desc] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Misc4EDLType] [char] (1) COLLATE Latin1_General_BIN NULL,
[Misc4EDLCode] [dbo].[bEDLCode] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[RepTitle] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[TaxWithheldAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWH_TaxWithheldAmt] DEFAULT ((0)),
[W2TaxAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWH_W2TaxAmt] DEFAULT ((0)),
[TaxCredits] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWH_TaxCredits] DEFAULT ((0)),
[TotalTaxDue] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWH_TotalTaxDue] DEFAULT ((0)),
[BalanceDue] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWH_BalanceDue] DEFAULT ((0)),
[Overpay] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWH_Overpay] DEFAULT ((0)),
[OverpayCredit] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWH_OverpayCredit] DEFAULT ((0)),
[OverpayRefund] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWH_OverpayRefund] DEFAULT ((0)),
[GrossPayroll] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWH_GrossPayroll] DEFAULT ((0)),
[StatePickup] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWH_StatePickup] DEFAULT ((0))
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRWH] ON [dbo].[bPRWH] ([PRCo], [TaxYear]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRWH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btPRWHd] on [dbo].[bPRWH] for DELETE as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
*
*	Delete trigger for PR W2 Header table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------


set nocount on

/* HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRWH', 
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


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[btPRWHi] on [dbo].[bPRWH] for INSERT as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 
*
*	Insert trigger for PR W2 Header table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

  
set nocount on
 
/* add HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRWH', 
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

CREATE   trigger [dbo].[btPRWHu] on [dbo].[bPRWH] for UPDATE as
/*-----------------------------------------------------------------
* Created:		CHS	09/179/2010	#138193
* Modified: 	EN 10/31/2012 - D-05285/#146601 Removed code that audited Method field which was removed from PRWH   
* 
*	Update trigger for PR W2 Header
* 
*	Adds record to HQ Master Audit.
*/----------------------------------------------------------------
   
set nocount on
   
if update(EIN)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'EIN', 
		d.EIN, 
		i.EIN, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.EIN, '') <> isnull(d.EIN, '') and a.W2AuditYN = 'Y'
	end
	
if update(PIN)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'PIN', 
		d.PIN, 
		i.PIN, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.PIN, '') <> isnull(d.PIN, '') and a.W2AuditYN = 'Y'
	end	
	
if update(CoName)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'CoName', 
		d.CoName, 
		i.CoName, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.CoName, '') <> isnull(d.CoName, '') and a.W2AuditYN = 'Y'
	end

if update(LocAddress)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'LocAddress', 
		d.LocAddress, 
		i.LocAddress, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.LocAddress, '') <> isnull(d.LocAddress, '') and a.W2AuditYN = 'Y'
	end

if update(DelAddress)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'DelAddress', 
		d.DelAddress, 
		i.DelAddress, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.DelAddress, '') <> isnull(d.DelAddress, '') and a.W2AuditYN = 'Y'
	end	

if update(City)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
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
		
if update(State)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'State', 
		d.State, 
		i.State, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.State, '') <> isnull(d.State, '') and a.W2AuditYN = 'Y'
	end		

if update(Zip)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Zip', 
		d.Zip, 
		i.Zip, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Zip, '') <> isnull(d.Zip, '') and a.W2AuditYN = 'Y'
	end	
	
if update(ZipExt)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'ZipExt', 
		d.ZipExt, 
		i.ZipExt, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.ZipExt, '') <> isnull(d.ZipExt, '') and a.W2AuditYN = 'Y'
	end			

if update(Contact)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Contact', 
		d.Contact, 
		i.Contact, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Contact, '') <> isnull(d.Contact, '') and a.W2AuditYN = 'Y'
	end		

if update(Phone)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Phone', 
		d.Phone, 
		i.Phone, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Phone, '') <> isnull(d.Phone, '') and a.W2AuditYN = 'Y'
	end	
			
if update(PhoneExt)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'PhoneExt', 
		d.PhoneExt, 
		i.PhoneExt, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.PhoneExt, '') <> isnull(d.PhoneExt, '') and a.W2AuditYN = 'Y'
	end	

if update(Fax)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Fax', 
		d.Fax, 
		i.Fax, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Fax, '') <> isnull(d.Fax, '') and a.W2AuditYN = 'Y'
	end	

if update(EMail)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'EMail', 
		d.EMail, 
		i.EMail, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.EMail, '') <> isnull(d.EMail, '') and a.W2AuditYN = 'Y'
	end	

if update(SickPayFlag)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'SickPayFlag', 
		d.SickPayFlag, 
		i.SickPayFlag, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.SickPayFlag, '') <> isnull(d.SickPayFlag, '') and a.W2AuditYN = 'Y'
	end		

if update(PensionPlan)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'PensionPlan', 
		d.PensionPlan, 
		i.PensionPlan, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.PensionPlan, '') <> isnull(d.PensionPlan, '') and a.W2AuditYN = 'Y'
	end	

if update(ResubTLCN)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'ResubTLCN', 
		d.ResubTLCN, 
		i.ResubTLCN, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.ResubTLCN, '') <> isnull(d.ResubTLCN, '') and a.W2AuditYN = 'Y'
	end
		
if update(RepTitle)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'RepTitle', 
		d.RepTitle, 
		i.RepTitle, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.RepTitle, '') <> isnull(d.RepTitle, '') and a.W2AuditYN = 'Y'
	end	
		
if update(TaxWithheldAmt)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'TaxWithheldAmt', 
		d.TaxWithheldAmt, 
		i.TaxWithheldAmt, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.TaxWithheldAmt, 0) <> isnull(d.TaxWithheldAmt, 0) and a.W2AuditYN = 'Y'
	end			
		
if update(W2TaxAmt)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'W2TaxAmt', 
		d.W2TaxAmt, 
		i.W2TaxAmt, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.W2TaxAmt, 0) <> isnull(d.W2TaxAmt, 0) and a.W2AuditYN = 'Y'
	end		
		
if update(TaxCredits)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'TaxCredits', 
		d.TaxCredits, 
		i.TaxCredits, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.TaxCredits, 0) <> isnull(d.TaxCredits, 0) and a.W2AuditYN = 'Y'
	end				
		
if update(TotalTaxDue)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'TotalTaxDue', 
		d.TotalTaxDue, 
		i.TotalTaxDue, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.TotalTaxDue, 0) <> isnull(d.TotalTaxDue, 0) and a.W2AuditYN = 'Y'
	end		
		
if update(BalanceDue)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'BalanceDue', 
		d.BalanceDue, 
		i.BalanceDue, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.BalanceDue, 0) <> isnull(d.BalanceDue, 0) and a.W2AuditYN = 'Y'
	end	
		
if update(Overpay)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Overpay', 
		d.Overpay, 
		i.Overpay, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Overpay, 0) <> isnull(d.Overpay, 0) and a.W2AuditYN = 'Y'
	end		

if update(OverpayCredit)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'OverpayCredit', 
		d.OverpayCredit, 
		i.OverpayCredit, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.OverpayCredit, 0) <> isnull(d.OverpayCredit, 0) and a.W2AuditYN = 'Y'
	end		

if update(OverpayRefund)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'OverpayRefund', 
		d.OverpayRefund, 
		i.OverpayRefund, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.OverpayRefund, 0) <> isnull(d.OverpayRefund, 0) and a.W2AuditYN = 'Y'
	end		

if update(GrossPayroll)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWH', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'GrossPayroll', 
		d.GrossPayroll, 
		i.GrossPayroll, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.GrossPayroll, 0) <> isnull(d.GrossPayroll, 0) and a.W2AuditYN = 'Y'
	end		
	
	
	
return


GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRWH].[SickPayFlag]'
GO
