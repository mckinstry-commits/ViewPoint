CREATE TABLE [dbo].[bPRWE]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[SSN] [varchar] (9) COLLATE Latin1_General_BIN NOT NULL,
[FirstName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MidName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[LastName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Suffix] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[LocAddress] [varchar] (22) COLLATE Latin1_General_BIN NULL,
[DelAddress] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (22) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[ZipExt] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[TaxState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Statutory] [tinyint] NOT NULL,
[Deceased] [tinyint] NOT NULL,
[PensionPlan] [tinyint] NOT NULL,
[LegalRep] [tinyint] NOT NULL,
[DeferredComp] [tinyint] NOT NULL,
[CivilStatus] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[SpouseSSN] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[Misc1Amt] [dbo].[bDollar] NOT NULL,
[Misc2Amt] [dbo].[bDollar] NOT NULL,
[SUIWages] [dbo].[bDollar] NULL CONSTRAINT [DF_bPRWE_SUIWages] DEFAULT ((0)),
[SUITaxableWages] [dbo].[bDollar] NULL CONSTRAINT [DF_bPRWE_SUITaxableWages] DEFAULT ((0)),
[WeeksWorked] [int] NULL CONSTRAINT [DF_bPRWE_WeeksWorked] DEFAULT ((0)),
[ThirdPartySickPay] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRWE_ThirdPartySickPay] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[Misc3Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWE_Misc3Amt] DEFAULT ((0)),
[Misc4Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRWE_Misc4Amt] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btPRWEd] on [dbo].[bPRWE] for DELETE as
    

/*-----------------------------------------------------------------
     *	Created by: EN 10/31/99
     *	Modified by: EN 10/31/99 - automatically delete related PRWA and PRWS entries
     *               EN 12/08/00 - modify to also delete related PRWL entries
     *				EN 02/20/03 - issue 23061  added isnull check, and dbo
     *				chs 09/21/2010 138193 added auditing
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int
    declare @prco integer, @taxyear char(4), @employee integer
   
    select @numrows = @@rowcount
   
    if @numrows = 0 return
   
    SELECT @prco = min(PRCo) from deleted
    WHILE @prco is not null
    Begin
      SELECT @taxyear = min(TaxYear) from deleted where PRCo = @prco
      WHILE @taxyear is not null
      Begin
        SELECT @employee = min(Employee) from deleted where PRCo = @prco and TaxYear = @taxyear
   	WHILE @employee is not null
   	Begin
          DELETE FROM dbo.bPRWA where PRCo = @prco and TaxYear = @taxyear and Employee = @employee
          if @@error <> 0
             begin
             select @errmsg = 'Error while purging W2 Employee Amounts'
             goto error
             end
   
          DELETE FROM dbo.bPRWS where PRCo = @prco and TaxYear = @taxyear and Employee = @employee
          if @@error <> 0
             begin
             select @errmsg = 'Error while purging W2 Employee State Amounts'
             goto error
             end
   
          DELETE FROM dbo.bPRWL where PRCo = @prco and TaxYear = @taxyear and Employee = @employee
          if @@error <> 0
             begin
             select @errmsg = 'Error while purging W2 Employee Local Amounts'
             goto error
             end
   
   	  SELECT @employee = min(Employee) from deleted where PRCo = @prco and TaxYear = @taxyear and Employee > @employee
   	End
   	SELECT @taxyear = min(TaxYear) from deleted where PRCo = @prco and TaxYear > @taxyear
      End
      SELECT @prco = min(PRCo) from deleted where PRCo > @prco
    End
    
    set nocount on

   
   /* HQ Master Audit entry */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
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
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Employee W2!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[btPRWEi] on [dbo].[bPRWE] for INSERT as
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
	'bPRWE', 
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

CREATE   trigger [dbo].[btPRWEu] on [dbo].[bPRWE] for UPDATE as
/*-----------------------------------------------------------------
* Created:		MCP	09/20/2010	#138193
* Modified: 
* 
*	Update trigger for PR W2 Employee
* 
*	Adds record to HQ Master Audit.
*/----------------------------------------------------------------
   
set nocount on
   
if update(SSN)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
		i.PRCo, 
		'C', 
		'SSN', 
		d.SSN, 
		i.SSN, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.SSN, '') <> isnull(d.SSN, '') and a.W2AuditYN = 'Y'
	end
	
if update(FirstName)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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
	
if update(LastName)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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

if update(MidName)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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

if update(Suffix)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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

if update(LocAddress)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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
			
if update(TaxState)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
		i.PRCo, 
		'C', 
		'TaxState', 
		d.TaxState, 
		i.TaxState, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.TaxState, '') <> isnull(d.TaxState, '') and a.W2AuditYN = 'Y'
	end	

if update(Statutory)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
		i.PRCo, 
		'C', 
		'Statutory', 
		d.Statutory, 
		i.Statutory, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.Statutory, 0) <> isnull(d.Statutory, 0) and a.W2AuditYN = 'Y'
	end	

if update(PensionPlan)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
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
    where isnull(i.PensionPlan, 0) <> isnull(d.PensionPlan, 0) and a.W2AuditYN = 'Y'
	end						

if update(ThirdPartySickPay)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
		i.PRCo, 
		'C', 
		'ThirdPartySickPay', 
		d.ThirdPartySickPay, 
		i.ThirdPartySickPay, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.ThirdPartySickPay, '') <> isnull(d.ThirdPartySickPay, '') and a.W2AuditYN = 'Y'
	end		

if update(SpouseSSN)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
		i.PRCo, 
		'C', 
		'SpouseSSN', 
		d.SpouseSSN, 
		i.SpouseSSN, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.SpouseSSN, '') <> isnull(d.SpouseSSN, '') and a.W2AuditYN = 'Y'
	end	

if update(CivilStatus)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
		i.PRCo, 
		'C', 
		'CivilStatus', 
		d.CivilStatus, 
		i.CivilStatus, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.CivilStatus, '') <> isnull(d.CivilStatus, '') and a.W2AuditYN = 'Y'
	end
		
if update(SUIWages)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
		i.PRCo, 
		'C', 
		'SUIWages', 
		d.SUIWages, 
		i.SUIWages, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.SUIWages, 0) <> isnull(d.SUIWages, 0) and a.W2AuditYN = 'Y'
	end	
		
if update(SUITaxableWages)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
		i.PRCo, 
		'C', 
		'SUITaxableWages', 
		d.SUITaxableWages, 
		i.SUITaxableWages, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.SUITaxableWages, 0) <> isnull(d.SUITaxableWages, 0) and a.W2AuditYN = 'Y'
	end			
		
if update(WeeksWorked)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRWE', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ', Employee: ' + cast(i.Employee as varchar(10)), 
		i.PRCo, 
		'C', 
		'WeeksWorked', 
		d.WeeksWorked, 
		i.WeeksWorked, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.WeeksWorked, 0) <> isnull(d.WeeksWorked, 0) and a.W2AuditYN = 'Y'
	end		

	
return


GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRWE] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRWE] ON [dbo].[bPRWE] ([PRCo], [TaxYear], [Employee]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRWE].[Misc1Amt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRWE].[Misc2Amt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRWE].[ThirdPartySickPay]'
GO
