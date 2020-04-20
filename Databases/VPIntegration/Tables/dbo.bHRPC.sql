CREATE TABLE [dbo].[bHRPC]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[PositionCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[JobTitle] [dbo].[bDesc] NULL,
[Description] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[BegSalary] [dbo].[bDollar] NULL,
[EndSalary] [dbo].[bDollar] NULL,
[PartTimeYN] [dbo].[bYN] NOT NULL,
[PartimeHrs] [dbo].[bHrs] NULL,
[AdYN] [dbo].[bYN] NOT NULL,
[AdMode] [dbo].[bDesc] NULL,
[ClosingDate] [dbo].[bDate] NULL,
[BonusYN] [dbo].[bYN] NOT NULL,
[BonusPct] [dbo].[bPct] NULL,
[ReportLevel] [int] NULL,
[ReportPosition] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[OpenJobs] [int] NULL,
[Contact] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ContactPhone] [dbo].[bPhone] NULL,
[ContactEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ContactFax] [dbo].[bPhone] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btHRPCd    Script Date: 2/3/2003 9:44:38 AM ******/
   CREATE   trigger [dbo].[btHRPCd] on [dbo].[bHRPC] for Delete
    as
    

	/**************************************************************
    * Created: 04/03/00 ae
    * Last Modified: 3/16/04 23061
	*				mh 10/29/2008 - 127008
    *
    *
    **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
	/* Audit inserts */
	insert into bHQMA select 'bHRPC','HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(d.PositionCode,'')),
	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
	from deleted d join dbo.bHRCO e on e.HRCo = d.HRCo and e.AuditPositionsYN  = 'Y'
   
    Return

    error:

    select @errmsg = (@errmsg + ' - cannot delete HRPC! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   trigger [dbo].[btHRPCi] on [dbo].[bHRPC] for INSERT as
    

	/*-----------------------------------------------------------------
     *   	Created by: ae  3/31/00
     * 	Modified by: 3/16/04 23061
	 *					mh 10/29/2008 - 127008
     *
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* Audit inserts */
   if not exists (select 1 from inserted i join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN = 'Y')
    	return
   
   insert into bHQMA select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
    	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    	from inserted i join dbo.bHRCO e on e.HRCo = i.HRCo and e.AuditPositionsYN = 'Y'
   
   return
   
    error:
    	select @errmsg = @errmsg + ' - cannot insert into HRPC!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    trigger [dbo].[btHRPCu] on [dbo].[bHRPC] for UPDATE as
    

	/*-----------------------------------------------------------------
     *  Created by: ae 04/04/00
	 *				mh 10/29/2008 - 127008
     * 	Modified by:
     */----------------------------------------------------------------
    
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
    
	select @numrows = @@rowcount
    
	if @numrows = 0 return
    
	set nocount on
    
	if update(JobTitle)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','JobTitle',
        convert(varchar(30),d.JobTitle), Convert(varchar(30),i.JobTitle),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.JobTitle <> d.JobTitle
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y'

	if update(BegSalary)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','BegSalary',
        convert(varchar(12),d.BegSalary), Convert(varchar(12),i.BegSalary),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.BegSalary <> d.BegSalary
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y'    

	if update(EndSalary)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','EndSalary',
        convert(varchar(12),d.EndSalary), Convert(varchar(12),i.EndSalary),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.EndSalary <> d.EndSalary
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y'   

	if update(PartTimeYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','PartTimeYN',
        convert(varchar(1),d.PartTimeYN), Convert(varchar(1),i.PartTimeYN),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.PartTimeYN <> d.PartTimeYN
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(PartimeHrs)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','PartimeHrs',
        convert(varchar(10),d.PartimeHrs), Convert(varchar(10),i.PartimeHrs),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.PartimeHrs <> d.PartimeHrs
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(AdYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','AdYN',
        convert(varchar(1),d.AdYN), Convert(varchar(1),i.AdYN),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.AdYN <> d.AdYN
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(AdMode)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','AdMode',
        convert(varchar(30),d.AdMode), Convert(varchar(30),i.AdMode),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.AdMode <> d.AdMode
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(ClosingDate)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','ClosingDate',
        convert(varchar(20),d.ClosingDate), Convert(varchar(20),i.ClosingDate),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.AdMode <> d.AdMode
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(BonusYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','BonusYN',
        convert(varchar(1),d.BonusYN), Convert(varchar(1),i.BonusYN),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.BonusYN <> d.BonusYN
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(BonusPct)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','BonusPct',
        convert(varchar(6),d.BonusPct), Convert(varchar(6),i.BonusPct),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.BonusPct <> d.BonusPct
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(ReportLevel)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','ReportLevel',
        convert(varchar(6),d.ReportLevel), Convert(varchar(6),i.ReportLevel),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.ReportLevel <> d.ReportLevel
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(ReportPosition)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','ReportPosition',
        convert(varchar(10),d.ReportPosition), Convert(varchar(10),i.ReportPosition),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.ReportPosition <> d.ReportPosition
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update([Type])
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','Type',
        convert(varchar(1),d.Type), Convert(varchar(1),i.Type),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.Type <> d.Type
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(OpenJobs)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','OpenJobs',
        convert(varchar(6),d.OpenJobs), Convert(varchar(6),i.OpenJobs),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.OpenJobs <> d.OpenJobs
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(Contact)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','Contact',
        convert(varchar(30),d.Contact), Convert(varchar(30),i.Contact),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.Contact <> d.Contact
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(ContactPhone)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','ContactPhone',
        convert(varchar(20),d.ContactPhone), Convert(varchar(20),i.ContactPhone),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.ContactPhone <> d.ContactPhone
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(ContactEmail)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','ContactEmail',
        convert(varchar(20),d.ContactEmail), Convert(varchar(20),i.ContactEmail),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.ContactEmail <> d.ContactEmail
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 

	if update(ContactFax)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRPC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','ContactFax',
        convert(varchar(20),d.ContactFax), Convert(varchar(20),i.ContactFax),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode
        and i.ContactFax <> d.ContactFax
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y' 
    
     
    return
    
    error:
    	select @errmsg = @errmsg + ' - cannot update HRPC!'
    	RAISERROR(@errmsg, 11, -1);
    
    	rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biHRPC] ON [dbo].[bHRPC] ([HRCo], [PositionCode]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRPC] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRPC].[PartTimeYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRPC].[AdYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRPC].[BonusYN]'
GO
