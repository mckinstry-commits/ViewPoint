CREATE TABLE [dbo].[bPRPH]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMRef] [dbo].[bCMRef] NOT NULL,
[CMRefSeq] [tinyint] NOT NULL,
[EFTSeq] [smallint] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[ChkType] [char] (1) COLLATE Latin1_General_BIN NULL,
[PaidDate] [dbo].[bDate] NOT NULL,
[PaidMth] [dbo].[bMonth] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[Earnings] [dbo].[bDollar] NOT NULL,
[Dedns] [dbo].[bDollar] NOT NULL,
[PaidAmt] [dbo].[bDollar] NOT NULL,
[NonTrueAmt] [dbo].[bDollar] NOT NULL,
[Void] [dbo].[bYN] NOT NULL,
[VoidMemo] [dbo].[bDesc] NULL,
[Purge] [dbo].[bYN] NOT NULL,
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
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRPHd    Script Date: 8/28/99 9:38:13 AM ******/
   CREATE  trigger [dbo].[btPRPHd] on [dbo].[bPRPH] for DELETE as
   

/*-----------------------------------------------------------------
    *	Created by: kb 11/4/98
    *	Modified by:	EN 02/18/03 - issue 23061  added isnull check, and dbo
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   INSERT INTO dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bPRPH', 'CMCO:' + convert(varchar(3),d.CMCo)
           + ' CMAcct:' + convert(varchar(10),d.CMAcct)
   	+ ' PayMethod:' + d.PayMethod
   	+ ' CMRef:' + d.CMRef
   	+ ' CMRefSeq:' + convert(varchar(3),d.CMRefSeq)
   	+ ' EFTSeq:' + convert(varchar(10),d.EFTSeq),
             d.PRCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	JOIN dbo.bPRCO a ON d.PRCo=a.PRCo
           where a.AuditPayHistory='Y' and d.Purge='N'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Pay History!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRPHi    Script Date: 8/28/99 9:38:13 AM ******/
   CREATE   trigger [dbo].[btPRPHi] on [dbo].[bPRPH] for INSERT as
    

/*-----------------------------------------------------------------
     *   	Created by: kb 10/30/98
     * 	Modified by: GG 06/22/99
     *                  EN 4/7/00 - was not adding HQMA entry if Purge flag = 'N'; that should only apply to delete trigger
     *					EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
     *
     *	This trigger rejects insertion in bPRPH (PR Pay History) if the
     *	following error condition exists:
     *
     *	Adds HQ Master Audit entry.
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    /* validate PR Company */
    select @validcnt = count(*) from dbo.bPRCO c with (nolock) join inserted i on c.PRCo = i.PRCo
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid PR Company# '
    	goto error
    	end
    /* validate CM Company */
    select @validcnt = count(*) from dbo.bCMCO c with (nolock) join inserted i on c.CMCo = i.CMCo
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid CM Company# '
    	goto error
    	end
    /* validate CM Account */
    select @validcnt = count(*) from dbo.bCMAC c with (nolock) join inserted i on c.CMCo = i.CMCo and c.CMAcct = i.CMAcct
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid CM Account '
    	goto error
    	end
    /* validate Pay Method */
    select @validcnt = count(*) from inserted i where i.PayMethod in ('C', 'E')
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Payment Method must be ''C'' or ''E'' '
    	goto error
    	end
    /* validate PR Group*/
    select @validcnt = count(*) from dbo.bPRGR c with (nolock) join inserted i on c.PRCo = i.PRCo and c.PRGroup = i.PRGroup
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid PR Group '
    	goto error
    	end
    /* validate Employee */
    select @validcnt = count(*) from dbo.bPREH c with (nolock) join inserted i on c.PRCo = i.PRCo and c.Employee = i.Employee
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid PR Employee '
    	goto error
    	end
    /* validate Check Type */
    select @validcnt2 = count(*) from inserted i where i.PayMethod='C'
    select @validcnt = count(*) from inserted i where i.ChkType in ('C', 'M') and i.PayMethod='C'
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Check type must be ''C'' or ''M'' '
    	goto error
    	end
    select @validcnt2 = count(*) from inserted i where i.PayMethod='E'
    select @validcnt = count(*) from inserted i where i.ChkType is null and i.PayMethod='E'
    if @validcnt <> @validcnt2
    	begin
    	select @errmsg = 'Check type on an EFT must be null '
    	goto error
    	end
   
    /* add HQ Master Audit entry */
    insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	 select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)+
    	 ' CMAcct:' + convert(varchar(10),CMAcct) + ' PayMethod:' + PayMethod +
    	 ' CMRef:' + CMRef + ' CMRefSeq:' + convert(varchar(10),CMRefSeq) + ' EFTSeq:' +
    	 convert(varchar(10),EFTSeq), i.PRCo, 'A',
    	 null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.PRCO a
    	 on i.PRCo=a.PRCo where a.AuditPayHistory='Y'
   
   
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Payment Header!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRPHu    Script Date: 8/28/99 9:38:13 AM ******/
   CREATE  trigger [dbo].[btPRPHu] on [dbo].[bPRPH] for UPDATE as
    

declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, @validcnt3 int
    /*-----------------------------------------------------------------
     *   	Created by: kb 11/4/98
     * 	Modified by: EN 4/7/00 - key change validation was not checking everything it should
    *                               EN 10/09/00 - Checking for key changes incorrectly
     *					EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
     *
     *	This trigger rejects update in bPRPH (PR Pay History) if the
     *	following error condition exists:
     *
     *	Adds record to HQ Master Audit.
     */----------------------------------------------------------------
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
     if update(CMCo)
       begin
       select @validcnt = count(*) from deleted d join inserted i
         	on d.PRCo = i.PRCo and d.CMCo = i.CMCo
       if @validcnt <> @numrows
         	begin
         	select @errmsg = 'Cannot change CM Company '
         	goto error
         	end
       end
     if update(CMAcct)
       begin
       select @validcnt = count(*) from deleted d join inserted i
         	on d.PRCo = i.PRCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
       if @validcnt <> @numrows
         	begin
         	select @errmsg = 'Cannot change CM Account '
         	goto error
         	end
       end
     if update(PayMethod)
       begin
       select @validcnt = count(*) from deleted d join inserted i
         	on d.PRCo = i.PRCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct and d.PayMethod = i.PayMethod
       if @validcnt <> @numrows
         	begin
         	select @errmsg = 'Cannot change Pay Method '
         	goto error
         	end
       end
     if update(CMRef)
       begin
       select @validcnt = count(*) from deleted d join inserted i
         	on d.PRCo = i.PRCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef
       if @validcnt <> @numrows
         	begin
         	select @errmsg = 'Cannot change CM Reference '
         	goto error
         	end
       end
     if update(CMRefSeq)
       begin
       select @validcnt = count(*) from deleted d join inserted i
         	on d.PRCo = i.PRCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef
            and d.CMRefSeq = i.CMRefSeq
       if @validcnt <> @numrows
         	begin
         	select @errmsg = 'Cannot change CM Reference Seq '
         	goto error
         	end
       end
     if update(EFTSeq)
       begin
       select @validcnt = count(*) from deleted d join inserted i
         	on d.PRCo = i.PRCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef
            and d.CMRefSeq = i.CMRefSeq and d.EFTSeq= i.EFTSeq
       if @validcnt <> @numrows
         	begin
         	select @errmsg = 'Cannot change EFT Seq '
         	goto error
         	end
       end
   
   /* validate PR Group */
   if update(PRGroup)
   	begin
   	select @validcnt = count(*) from dbo.bPRGR c with (nolock) join inserted i
   		on c.PRCo = i.PRCo and c.PRGroup=i.PRGroup
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid PR Group '
   		goto error
   		end
   	end
   
   /* validate Employee */
   if update(Employee)
   	begin
   	select @validcnt = count(*) from dbo.bPREH c with (nolock) join inserted i
   		on c.PRCo = i.PRCo and c.Employee = i.Employee
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Employee '
   		goto error
   		end
   	end
   
   /* validate Check Type */
   if update(ChkType)
   	begin
   	select @validcnt = count(*) from inserted i where i.PayMethod='C'
   	select @validcnt2 = count(*) from inserted i where i.PayMethod='E'
   	if @validcnt<>0
   		begin
   		select @validcnt3 = count(*) from inserted i where i.PayMethod='C' and (i.ChkType='C' or i.ChkType='M')
   		if @validcnt3 <> @validcnt
   			begin
   			select @errmsg = 'Check Type must be ''C'' or ''M'' when PayMethod=''C'' '
   			goto error
   			end
   		end
   	if @validcnt2<>0
   		begin
   		select @validcnt3 = count(*) from inserted i where i.PayMethod='E' and i.ChkType is null
   		if @validcnt2 <> @validcnt3
   			begin
   			select @errmsg = 'Check Type must be null when PayMethod=''E'' '
   			goto error
   			end
   		end
   	end
   
   /* Audit updates */
   if exists (select * from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditPayHistory = 'Y')
   	begin
   	insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','PR Group', Convert(varchar(30),d.PRGroup), Convert(varchar(30),i.PRGroup),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.PRGroup <> d.PRGroup and a.AuditPayHistory='Y'
   	insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','PR EndDate', Convert(varchar(30),d.PREndDate), Convert(varchar(30),i.PREndDate),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.PREndDate <> d.PREndDate and a.AuditPayHistory='Y'
   	insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Employee', Convert(varchar(30),d.Employee), Convert(varchar(30),i.Employee),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.Employee <> d.Employee and a.AuditPayHistory='Y'
   	insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Pay Sequence', Convert(varchar(30),d.PaySeq), Convert(varchar(30),i.PaySeq),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.PaySeq <> d.PaySeq and a.AuditPayHistory='Y'
    	insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Check Type', Convert(varchar(30),d.ChkType), Convert(varchar(30),i.ChkType),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.ChkType <> d.ChkType and a.AuditPayHistory='Y'
    	insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Paid Date', Convert(varchar(30),d.PaidDate), Convert(varchar(30),i.PaidDate),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.PaidDate <> d.PaidDate and a.AuditPayHistory='Y'
   	 insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Paid Month', Convert(varchar(30),d.PaidMth), Convert(varchar(30),i.PaidMth),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.PaidMth <> d.PaidMth and a.AuditPayHistory='Y'
   	 insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Hours', Convert(varchar(30),d.Hours), Convert(varchar(30),i.Hours),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.Hours <> d.Hours and a.AuditPayHistory='Y'
   	 insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Earnings', Convert(varchar(30),d.Earnings), Convert(varchar(30),i.Earnings),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.Earnings <> d.Earnings and a.AuditPayHistory='Y'
    	insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Deductions', Convert(varchar(30),d.Dedns), Convert(varchar(30),i.Dedns),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.Dedns <> d.Dedns and a.AuditPayHistory='Y'
    	insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Paid Amount', Convert(varchar(30),d.PaidAmt), Convert(varchar(30),i.PaidAmt),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.PaidAmt <> d.PaidAmt and a.AuditPayHistory='Y'
    	insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Non-True Amount', Convert(varchar(30),d.NonTrueAmt), Convert(varchar(30),i.NonTrueAmt),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.NonTrueAmt <> d.NonTrueAmt and a.AuditPayHistory='Y'
    	insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Void', Convert(varchar(30),d.Void), Convert(varchar(30),i.Void),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.Void <> d.Void and a.AuditPayHistory='Y'
    	insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Void Memo', Convert(varchar(30),d.VoidMemo), Convert(varchar(30),i.VoidMemo),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.VoidMemo <> d.VoidMemo and a.AuditPayHistory='Y'
     	insert into dbo.bHQMA select 'bPRPH', 'CMCO:' + convert(varchar(3),i.CMCo)
   		+ ' CMAcct:' + convert(varchar(10),i.CMAcct)
   		+ ' PayMethod:' + i.PayMethod
   		+ ' CMRef:' + i.CMRef
   		+ ' CMRefSeq:' + convert(varchar(3),i.CMRefSeq)
   		+ ' EFTSeq:' + convert(varchar(10),i.EFTSeq),
   		i.PRCo, 'C','Purge Flag', Convert(varchar(30),d.Purge), Convert(varchar(30),i.Purge),
    		getdate(), SUSER_SNAME()
    		from inserted i
           join deleted d on i.PRCo = d.PRCo and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.PayMethod = d.PayMethod
   	 	and i.CMRef = d.CMRef and d.CMRefSeq = i.CMRefSeq and d.EFTSeq = i.EFTSeq
           join dbo.PRCO a on i.PRCo=a.PRCo
   	 	where i.Purge <> d.Purge and a.AuditPayHistory='Y'
    	 end
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Pay History Update!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bPRPH] WITH NOCHECK ADD CONSTRAINT [CK_bPRPH_CMAcct] CHECK (([CMAcct]>(0) AND [CMAcct]<(10000)))
GO
ALTER TABLE [dbo].[bPRPH] WITH NOCHECK ADD CONSTRAINT [CK_bPRPH_Purge] CHECK (([Purge]='Y' OR [Purge]='N'))
GO
ALTER TABLE [dbo].[bPRPH] WITH NOCHECK ADD CONSTRAINT [CK_bPRPH_Void] CHECK (([Void]='Y' OR [Void]='N'))
GO
CREATE NONCLUSTERED INDEX [biPRPHCMRef] ON [dbo].[bPRPH] ([CMRef]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRPH] ON [dbo].[bPRPH] ([PRCo], [CMCo], [CMAcct], [PayMethod], [CMRef], [CMRefSeq], [EFTSeq]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
