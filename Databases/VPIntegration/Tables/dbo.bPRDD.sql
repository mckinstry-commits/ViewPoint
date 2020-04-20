CREATE TABLE [dbo].[bPRDD]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[Seq] [tinyint] NOT NULL,
[RoutingId] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[BankAcct] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Status] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Frequency] [dbo].[bFreq] NULL,
[Method] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Pct] [dbo].[bPct] NULL,
[Amount] [dbo].[bDollar] NULL,
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
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRDDd    Script Date: 8/28/99 9:38:11 AM ******/
   CREATE   trigger [dbo].[btPRDDd] on [dbo].[bPRDD] for DELETE as
   

/*-----------------------------------------------------------------
    *	Created by: EN 3/31/00
    *  Modified by: EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Adds HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   INSERT INTO dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bPRDD','PR Co#: ' + convert(char(3),d.PRCo) +
   	' Empl#: ' + convert(varchar(10),d.Employee) + ' Seq: ' + convert(varchar(10),d.Seq),
             d.PRCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	JOIN dbo.bPRCO with (nolock) ON d.PRCo=bPRCO.PRCo
           where bPRCO.AuditEmployees='Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Deposit Eistributions!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRDDi    Script Date: 8/28/99 9:38:11 AM ******/
    CREATE   trigger [dbo].[btPRDDi] on [dbo].[bPRDD] for INSERT as
    

/*-----------------------------------------------------------------
     *   	Created by: EN 3/31/00
     *  Modified: GG 04/03/01 - fixed Frequency code validation
     *				EN 10/9/02 - issue 18877 change double quotes to single
     *				EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
     *											and corrected old syle joins
     *
     * Validate PR Company, Employee, Type, Status, Frequency and Method.
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
   
   -- Validate Type
   select @validcnt = count(*) from inserted where Type = 'C' or Type = 'S'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Type must be ''C'' or ''S'' '
   	goto error
   	end
   
   -- Validate Status
   select @validcnt = count(*) from inserted where Status = 'A' or Status = 'I' or Status = 'P'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Status must be ''A'', ''I'', or ''P'' '
   	goto error
   	end
   
   -- Validate Frequency
   select @validcnt = count(*) from inserted i where i.Frequency is null
   select @validcnt2 = count(*) from inserted i join dbo.bHQFC f with (nolock) on i.Frequency = f.Frequency
   if @validcnt + @validcnt2 <> @numrows
    	begin
    	select @errmsg = 'Invalid Frequency Code'
    	goto error
    	end
   
   -- Validate Method
   select @validcnt = count(*) from inserted where Method = 'A' or Method = 'P'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Method must be ''A'' or ''P'' '
   	goto error
   	end
   
    /* add HQ Master Audit entry */
    insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	 select 'bPRDD',  'PRCo: ' + convert(varchar(3),i.PRCo) +' Empl: ' + convert(varchar(10), Employee) +
    	 ' Seq: ' + convert(varchar(10),Seq), i.PRCo, 'A',
    	 null, null, null, getdate(), SUSER_SNAME() from inserted i
        join dbo.PRCO a with (nolock) on i.PRCo=a.PRCo where a.AuditEmployees = 'Y'
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Deposit Distributions!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
/****** Object:  Trigger [dbo].[btPRDDu]    Script Date: 12/27/2007 09:06:40 ******/
   CREATE   trigger [dbo].[btPRDDu] on [dbo].[bPRDD] for UPDATE as
   

/*-----------------------------------------------------------------
    *   	Created by: EN 3/31/00
    *           Modified by: EN 10/09/00 - Checking for key changes incorrectly
    *						EN 10/9/02 - issue 18877 change double quotes to single
    *						EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *													and corrected old syle joins
	*						EN 12/27/08 - #126315  allow for 20 character Amount when logging to HQMA
    *
    *  Reject key changes.
    *  Validate Type, Status, Frequency and Method.
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
   if update(Seq)
       begin
       select @validcnt = count(*) from deleted d join inserted i
         	on d.PRCo = i.PRCo and d.Employee = i.Employee and d.Seq = i.Seq
       if @validcnt <> @numrows
         	begin
         	select @errmsg = 'Cannot change Sequence # '
         	goto error
         	end
       end
   
   -- Validate Type
   select @validcnt = count(*) from inserted where Type = 'C' or Type = 'S'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Type must be ''C'' or ''S'' '
   	goto error
   	end
   
   -- Validate Status
   select @validcnt = count(*) from inserted where Status = 'A' or Status = 'I' or Status = 'P'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Status must be ''A'', ''I'', or ''P'' '
   	goto error
   	end
   
   -- Validate Frequency
   select @validcnt = count(*) from inserted i where i.Frequency is not null
   select @validcnt2 = count(*) from inserted i join dbo.HQFC f with (nolock) on i.Frequency = f.Frequency where i.Frequency is not null
   if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Invalid Frequency Code'
    	goto error
    	end
   
   -- Validate Method
   select @validcnt = count(*) from inserted where Method = 'A' or Method = 'P'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Method must be ''A'' or ''P'' '
   	goto error
   	end
   
   
   /* add HQ Master Audit entry */
   if exists (select * from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditEmployees = 'Y')
   	begin
        insert into dbo.bHQMA select 'bPRDD', 'PR Co#: ' + convert(char(3),i.PRCo) +
        	' Empl#: ' + convert(varchar(10),i.Employee) + ' Seq: ' + convert(varchar(10),i.Seq),
        	i.PRCo, 'C','Routing Id', d.RoutingId, i.RoutingId,	getdate(), SUSER_SNAME()
         	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.Seq = d.Seq
           join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
           where d.RoutingId <> i.RoutingId and a.AuditEmployees = 'Y'
        insert into dbo.bHQMA select 'bPRDD', 'PR Co#: ' + convert(char(3),i.PRCo) +
        	' Empl#: ' + convert(varchar(10),i.Employee) + ' Seq: ' + convert(varchar(10),i.Seq),
        	i.PRCo, 'C','Bank Acct', d.BankAcct, i.BankAcct, getdate(), SUSER_SNAME()
         	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.Seq = d.Seq
           join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
           where d.BankAcct <> i.BankAcct and a.AuditEmployees = 'Y'
        insert into dbo.bHQMA select 'bPRDD', 'PR Co#: ' + convert(char(3),i.PRCo) +
        	' Empl#: ' + convert(varchar(10),i.Employee) + ' Seq: ' + convert(varchar(10),i.Seq),
        	i.PRCo, 'C','Type', d.Type, i.Type, getdate(), SUSER_SNAME()
         	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.Seq = d.Seq
           join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
           where d.Type <> i.Type and a.AuditEmployees = 'Y'
        insert into dbo.bHQMA select 'bPRDD', 'PR Co#: ' + convert(char(3),i.PRCo) +
        	' Empl#: ' + convert(varchar(10),i.Employee) + ' Seq: ' + convert(varchar(10),i.Seq),
        	i.PRCo, 'C','Status', d.Status, i.Status, getdate(), SUSER_SNAME()
         	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.Seq = d.Seq
           join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
           where d.Status <> i.Status and a.AuditEmployees = 'Y'
        insert into dbo.bHQMA select 'bPRDD', 'PR Co#: ' + convert(char(3),i.PRCo) +
        	' Empl#: ' + convert(varchar(10),i.Employee) + ' Seq: ' + convert(varchar(10),i.Seq),
        	i.PRCo, 'C','Frequency', d.Frequency, i.Frequency, getdate(), SUSER_SNAME()
         	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.Seq = d.Seq
           join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
           where isnull(d.Frequency,'') <> isnull(i.Frequency,'') and a.AuditEmployees = 'Y'
        insert into dbo.bHQMA select 'bPRDD', 'PR Co#: ' + convert(char(3),i.PRCo) +
        	' Empl#: ' + convert(varchar(10),i.Employee) + ' Seq: ' + convert(varchar(10),i.Seq),
        	i.PRCo, 'C','Method', d.Method, i.Method, getdate(), SUSER_SNAME()
         	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.Seq = d.Seq
           join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
           where d.Method <> i.Method and a.AuditEmployees = 'Y'
        insert into dbo.bHQMA select 'bPRDD', 'PR Co#: ' + convert(char(3),i.PRCo) +
        	' Empl#: ' + convert(varchar(10),i.Employee) + ' Seq: ' + convert(varchar(10),i.Seq),
        	i.PRCo, 'C','Percent', convert(varchar(8),d.Pct), convert(varchar(8),i.Pct), getdate(), SUSER_SNAME()
         	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.Seq = d.Seq
           join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
           where isnull(d.Pct,0) <> isnull(i.Pct,0) and a.AuditEmployees = 'Y'
        insert into dbo.bHQMA select 'bPRDD', 'PR Co#: ' + convert(char(3),i.PRCo) +
        	' Empl#: ' + convert(varchar(10),i.Employee) + ' Seq: ' + convert(varchar(10),i.Seq),
        	i.PRCo, 'C','Amount', convert(varchar(20),d.Amount), convert(varchar(20),i.Amount), getdate(), SUSER_SNAME()
         	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Employee = d.Employee and i.Seq = d.Seq
           join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo
           where isnull(d.Amount,0) <> isnull(i.Amount,0) and a.AuditEmployees = 'Y'
       end
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Deposit Distributions!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRDD] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRDD] ON [dbo].[bPRDD] ([PRCo], [Employee], [Seq]) ON [PRIMARY]
GO
