CREATE TABLE [dbo].[bPRID]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[InsCode] [dbo].[bInsCode] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   CREATE    trigger [dbo].[btPRIDd] on [dbo].[bPRID] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: ES 03/05/04
    * 	Modified: 
    *
    *	This trigger Adds HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* add HQ Master Audit entry */
   insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRID', 'PR Co#: ' + convert(char(3),d.PRCo) +
   	 ' PR State: ' + convert(char(2), d.State) + ' Code: ' + convert(char(10), d.InsCode) +
   	 ' DLCode: ' + convert(char(5), d.DLCode), d.PRCo, 'D', null, null, null, 
            getdate(), SUSER_SNAME() from deleted d
        join dbo.PRCO a with (nolock) on d.PRCo=a.PRCo where a.AuditStateIns='Y'
   
   
   return
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   
   
   
   CREATE       trigger [dbo].[btPRIDi] on [dbo].[bPRID] for INSERT as
   

/*-----------------------------------------------------------------
    * Created by: MV 1/28/02
    * Modified: EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *										and corrected old syle joins
    *	     ES 03/05/04 - issue 23814 added Audit code
    *
    * Insert trigger on PR Insurance 
    *
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
   
   /* validate DLCode */
   select @validcnt = count(*) from inserted i join dbo.PRDL c with (nolock) on i.PRCo = c.PRCo and i.DLCode = c.DLCode
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Dedn/Liab Code '
   	goto error
   	end
   
   /*validate CalCategory.*/
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.DLCode = c.DLCode
       where c.CalcCategory not in ('I', 'A') 
   if @validcnt <> 0
   	begin
   	select @errmsg = 'DLCode calculation category must be I or A. '
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRID', 'PR Co#: ' + convert(char(3),i.PRCo) +
   	 ' PR State: ' + convert(char(2), i.State) + ' Code: ' + convert(char(10), i.InsCode) +
   	 ' DLCode: ' + convert(char(5), i.DLCode), i.PRCo, 'A', null, null, null, 
   	 getdate(), SUSER_SNAME() from inserted i
        join dbo.PRCO a with (nolock) on i.PRCo=a.PRCo where a.AuditStateIns='Y'
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Insurance item!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE   trigger [dbo].[btPRIDu] on [dbo].[bPRID] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: MV 1/28/02
    *	Modified:	EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *											and corrected old syle joins
    *		  ES 03/05/04 - issue 23814 added audit code
    *                
    * Validate PRCo and DLCode and CalcCategory.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   if update(PRCo)
       begin
       select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
   	if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Company# '
   	goto error
   	end
       end
   
   if update(DLCode)
       begin
       select @validcnt = count(*) from inserted i join dbo.PRDL c with (nolock) on i.PRCo = c.PRCo and i.DLCode = c.DLCode
   	if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Dedn/Liab Code '
   	goto error
   	end
       end
   
   /*validate CalCategory.*/
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.DLCode = c.DLCode
       where i.PRCo = c.PRCo and c.CalcCategory not in ('I', 'A') 
   	if @validcnt <> 0
   	begin
   	select @errmsg = 'DLCode calculation category must be I or A. '
   	goto error
   	end
   
   /* Audit updates */
   if exists (select 1 from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditStateIns = 'Y')
   	begin
   	insert into dbo.bHQMA select 'bPRID', 'PR Co#: ' + convert(char(3),i.PRCo) +
   	 ' PR State: ' + convert(char(2), i.State) + ' Code: ' + convert(char(10), i.InsCode) +
   	 ' DLCode: ' + convert(char(5), i.DLCode), i.PRCo, 'C',
   	 'Rate', Convert(varchar(12),d.Rate), Convert(varchar(12),i.Rate),
   	 	getdate(), SUSER_SNAME()
    	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State and i.InsCode = d.InsCode and i.DLCode = d.DLCode
           where i.Rate <> d.Rate
   	end
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Insurance Items!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRID] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRID] ON [dbo].[bPRID] ([PRCo], [State], [InsCode], [DLCode]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRID].[Rate]'
GO
