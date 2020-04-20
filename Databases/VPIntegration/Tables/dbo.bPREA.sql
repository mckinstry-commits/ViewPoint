CREATE TABLE [dbo].[bPREA]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[SubjectAmt] [dbo].[bDollar] NOT NULL,
[EligibleAmt] [dbo].[bDollar] NOT NULL,
[AuditYN] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPREAd    Script Date: 8/28/99 9:38:11 AM ******/
   CREATE  trigger [dbo].[btPREAd] on [dbo].[bPREA] for DELETE as
    

/*-----------------------------------------------------------------
     *	Created by: kb 11/1/98
     *	Modified by: kb 12/31/98
     *              EN 4/5/00 - was not checking PREA AuditYN flag before inserting into HQMA
     *				EN 02/12/03 - issue 23061  added isnull check, with (nolock), and dbo
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    INSERT INTO dbo.bHQMA
        (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
            SELECT 'bPREA', 'Empl:' + convert(varchar(10),d.Employee) + ' Month:' + convert(varchar(8),d.Mth)
    	       + ' EDLType:' + d.EDLType + ' EDLCode:' + convert(varchar(10),d.EDLCode),
              d.PRCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
             FROM deleted d
    	      JOIN dbo.bPRCO a with (nolock) ON d.PRCo=a.PRCo
             where a.AuditAccums = 'Y' and d.AuditYN = 'Y'
   
   
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Employee Accumulations!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPREAi    Script Date: 8/28/99 9:38:11 AM ******/
   CREATE  trigger [dbo].[btPREAi] on [dbo].[bPREA] for INSERT as
    

/*-----------------------------------------------------------------
     *   	Created by: kb 10/30/98
     * 	Modified by: kb 12/31/98
     *                  EN 4/5/00 - was not checking PREA AuditYN flag before inserting into HQMA
     *					EN 02/12/03 - issue 23061  added isnull check, with (nolock), and dbo
     *
     *	This trigger rejects insertion in bPREH (PR Employee Accumulations)
     *	if the following error condition exists:
     *
     *	Adds HQ Master Audit entry.
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    /* validate PR Company */
    select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Company# '
    	goto error
    	end
    /* validate Employee */
    select @validcnt = count(*) from dbo.bPREH c with (nolock) join inserted i on c.PRCo = i.PRCo
    	and c.Employee=i.Employee
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Employee # '
    	goto error
    	end
    /* validate EDLType */
    select @validcnt = count(*) from inserted i where i.EDLType='E' or i.EDLType='D' or i.EDLType='L'
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'EDLType must be ''E'', ''D'' or ''L'' '
    	goto error
    	end
    /* validate EDLCode */
    select @validcnt2 = count(*) from inserted i where i.EDLType='E'
    select @validcnt = count(*) from inserted i join PREC a on a.PRCo=i.PRCo
    	and i.EDLCode=a.EarnCode where i.EDLType='E'
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid Earnings Code '
    	goto error
    	end
    select @validcnt2 = count(*) from inserted i where i.EDLType='D' or i.EDLType='L'
    select @validcnt = count(*) from inserted i join PRDL a on i.EDLType=a.DLType
    	 and a.PRCo=i.PRCo and i.EDLCode=a.DLCode
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid Deduction/Liability Code '
    	goto error
    	end
   
    /* add HQ Master Audit entry */
    insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	 select 'bPREA', 'Empl:' + convert(varchar(10), Employee) +
    	 ' Month:' +  convert(varchar(8),i.Mth,1) + ' EDLType:' + EDLType +
    	 ' EDLCode:' + convert(varchar(10),EDLCode), i.PRCo, 'A',
    	 null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.PRCO a with (nolock)
    	 on i.PRCo = a.PRCo where a.AuditAccums = 'Y' and i.AuditYN = 'Y'
   
   
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Employee Accumulations!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
/****** Object:  Trigger [dbo].[btPREAu]    Script Date: 11/21/2007 09:46:50 ******/
   CREATE trigger [dbo].[btPREAu] on [dbo].[bPREA] for UPDATE as
    
/*-----------------------------------------------------------------
     *   	Created by: kb 10/30/98
     * 	Modified by: kb 12/31/98
     *                  EN 4/5/00 - removed EDLType and EDLCode validation because it is unnecessary since they are key fields and cannot be changed
     *                  EN 4/5/00 - was not checking PREA AuditYN flag before inserting into HQMA
     *                  EN 10/09/00 - Checking for key changes incorrectly
	 *					EN 11/21/07 - #126312  allow for sufficient size strings for logging hrs and amount changes to HQMA
     *
     *	This trigger rejects updates in bPREA (PR Employee Accumulations)
     *	if the following error condition exists:
     *
     *	Adds HQ Master Audit entry.
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* check for key changes */
    if update(PRCo)
       begin
       select @validcnt = count(*) from deleted d join inserted i
          	on d.PRCo = i.PRCo
       if @validcnt <> @numrows
          	begin
          	select @errmsg = 'Cannot change PR Company '
          	goto error
          	end
       end
    if update(Employee)
       begin
       select @validcnt = count(*) from deleted d join inserted i
          	on d.PRCo = i.PRCo and d.Employee = i.Employee
       if @validcnt <> @numrows
          	begin
          	select @errmsg = 'Cannot change Employee '
          	goto error
          	end
       end
    if update(Mth)
       begin
       select @validcnt = count(*) from deleted d join inserted i
          	on d.PRCo = i.PRCo and d.Employee=i.Employee and d.Mth=i.Mth
       if @validcnt <> @numrows
          	begin
          	select @errmsg = 'Cannot change Month '
          	goto error
          	end
       end
    if update(EDLType)
       begin
       select @validcnt = count(*) from deleted d join inserted i
          	on d.PRCo = i.PRCo and d.Employee = i.Employee and d.Mth=i.Mth and d.EDLType=i.EDLType
       if @validcnt <> @numrows
          	begin
          	select @errmsg = 'Cannot change EDL Type '
          	goto error
          	end
       end
    if update(EDLCode)
       begin
       select @validcnt = count(*) from deleted d join inserted i
          	on d.PRCo = i.PRCo and d.Employee = i.Employee and d.Mth=i.Mth and d.EDLType=i.EDLType and d.EDLCode=i.EDLCode
          	and d.EDLCode=d.EDLCode
       if @validcnt <> @numrows
          	begin
          	select @errmsg = 'Cannot change EDL Code '
          	goto error
          	end
       end
   
    /* add HQ Master Audit entry */
   if exists(select * from inserted i join bPRCO a on i.PRCo = a.PRCo and a.AuditAccums = 'Y' and i.AuditYN = 'Y')
       begin
        insert into bHQMA select 'bPREA', 'Empl:' + convert(varchar(10),i.Employee) + ' Month:' + convert(varchar(8),i.Mth)
        	+ ' EDLType:' + i.EDLType + ' EDLCode:' + convert(varchar(10),i.EDLCode),
        	i.PRCo, 'C','Hours', Convert(varchar(20),d.Hours), Convert(varchar(20),i.Hours),
         	getdate(), SUSER_SNAME()
         	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.Mth = d.Mth and i.EDLType = d.EDLType and
        	i.EDLCode = d.EDLCode
           join bPRCO a on i.PRCo = a.PRCo
           where i.Hours <> d.Hours and a.AuditAccums = 'Y' and i.AuditYN = 'Y'
        insert into bHQMA select 'bPREA', 'Empl:' + convert(varchar(10),i.Employee) + ' Month:' + convert(varchar(8),i.Mth)
        	+ ' EDLType:' + i.EDLType + ' EDLCode:' + convert(varchar(10),i.EDLCode),
        	i.PRCo, 'C','Amount', Convert(varchar(20),d.Amount), Convert(varchar(20),i.Amount),
         	getdate(), SUSER_SNAME()
         	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.Mth = d.Mth and i.EDLType = d.EDLType and
        	i.EDLCode = d.EDLCode
           join bPRCO a on i.PRCo = a.PRCo
           where i.Amount <> d.Amount and a.AuditAccums = 'Y' and i.AuditYN = 'Y'
        insert into bHQMA select 'bPREA', 'Empl:' + convert(varchar(10),i.Employee) + ' Month:' + convert(varchar(8),i.Mth)
        	+ ' EDLType:' + i.EDLType + ' EDLCode:' + convert(varchar(10),i.EDLCode),
        	i.PRCo, 'C','Subject Amount', Convert(varchar(20),d.SubjectAmt),
        	Convert(varchar(20),i.SubjectAmt), getdate(), SUSER_SNAME()
         	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.Mth = d.Mth and i.EDLType = d.EDLType and
        	i.EDLCode = d.EDLCode
           join bPRCO a on i.PRCo = a.PRCo
         where i.SubjectAmt <> d.SubjectAmt and a.AuditAccums = 'Y' and i.AuditYN = 'Y'
        insert into bHQMA select 'bPREA', 'Empl:' + convert(varchar(10),i.Employee) + ' Month:' + convert(varchar(8),i.Mth)
        	+ ' EDLType:' + i.EDLType + ' EDLCode:' + convert(varchar(10),i.EDLCode),
        	i.PRCo, 'C','Eligible Amount', Convert(varchar(20),d.EligibleAmt), Convert(varchar(20),i.EligibleAmt),
         	getdate(), SUSER_SNAME()
         	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.Mth = d.Mth and i.EDLType = d.EDLType and
        	i.EDLCode = d.EDLCode
           join bPRCO a on i.PRCo = a.PRCo
           where i.EligibleAmt <> d.EligibleAmt and a.AuditAccums = 'Y' and i.AuditYN = 'Y'
       end
   
   
    return
    error:
    	select @errmsg = @errmsg + ' - cannot update PR Employee Accumulations!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPREA] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPREA] ON [dbo].[bPREA] ([PRCo], [Employee], [Mth], [EDLType], [EDLCode]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPREA].[Hours]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPREA].[Amount]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPREA].[SubjectAmt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPREA].[EligibleAmt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPREA].[AuditYN]'
GO
