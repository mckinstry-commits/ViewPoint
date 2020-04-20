CREATE TABLE [dbo].[bPRCD]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Class] [dbo].[bClass] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[Factor] [dbo].[bRate] NOT NULL,
[OldRate] [dbo].[bUnitCost] NOT NULL,
[NewRate] [dbo].[bUnitCost] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCDd    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE  trigger [dbo].[btPRCDd] on [dbo].[bPRCD] for DELETE as
   

/*-----------------------------------------------------------------
    *   	Created by: EN 3/30/00
    *        Modified by: EN 7/31/00 - bHQMA modify not working
    *						EN 01/28/03 - issue 23061  added isnull check, with dbo
    *
    *
    *	Adds HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRCD',
   	 'Craft:' + d.Craft + ' Class:' + d.Class + ' DL Code:' + convert(varchar(10),d.DLCode) + ' Factor:'+
   	  convert(varchar(15),d.Factor),
   	 d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME() from deleted d
        join PRCO p on d.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Class Deductions/Liabilites!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRCDi    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE   trigger [dbo].[btPRCDi] on [dbo].[bPRCD] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created by: kb 11/4/98
    * 	Modified by: GG 12/28/00 - fixed Factor validation
    *	             MV 1/28/02 added calc category validation
    *				EN 01/28/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Insert trigger for PR Class Deductions/Liabilities
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
   
   /* validate PR Craft */
   select @validcnt = count(*) from dbo.bPRCM c with (nolock) join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Craft '
   	goto error
   	end
   
   /* validate PR Class */
   select @validcnt = count(*) from dbo.bPRCC c with (nolock) join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft and c.Class = i.Class
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Class '
   	goto error
   	end
   
   /* validate DLCode */
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and c.DLCode = i.DLCode
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Deduction/Liability Code '
   	goto error
   	end
   
   -- validate Factor
   select @validcnt = count(*) from inserted i join dbo.bPRDL d with (nolock) on i.PRCo = d.PRCo and i.DLCode = d.DLCode
       where d.Method = 'V' and i.Factor <= 0
   if @validcnt <> 0
       begin
       select @errmsg = 'Factor must be greater than 0.00 for Variable Rate Deductions and Liabilities '
       goto error
       end
   select @validcnt = count(*) from inserted i join dbo.bPRDL d with (nolock) on i.PRCo = d.PRCo and i.DLCode = d.DLCode
       where d.Method <> 'V' and i.Factor <> 0
   if @validcnt <> 0
       begin
       select @errmsg = 'Factor must be 0.00 for non Variable Rate Deductions and Liabilities '
       goto error
       end
   
   /*validate CalCategory.*/
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.DLCode = c.DLCode
       where i.PRCo = c.PRCo and c.CalcCategory not in ('C', 'A') 
   if @validcnt <> 0
   	begin
   	select @errmsg = 'DLCode calculation category must be C or A. '
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRCD',
   	 'Craft:' + Craft + ' Class:' + Class + ' DL Code:' + convert(varchar(10),DLCode) +
         ' Factor:' + convert(varchar(15),Factor),
   	 i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i join PRCO a
   	 on i.PRCo=a.PRCo where a.AuditCraftClass='Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Class Deductions/Liabilites!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCDu    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE  trigger [dbo].[btPRCDu] on [dbo].[bPRCD] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created: kb 11/4/98
    * Modified: kb 12/3/98
    * 		   EN 4/7/00 - key change validation not checking everything it should
    *           EN 10/09/00 - Checking for key changes incorrectly
    *			EN 01/28/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Validates and inserts HQ Master Audit entry.
    *
    *		Cannot change primary key - PR Company
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check for key changes */
   if update(PRCo)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change PR Company '
        	goto error
        	end
       end
   if update(Craft)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Craft '
        	goto error
        	end
       end
   if update(Class)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Class = i.Class
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Class '
        	goto error
        	end
       end
   if update(DLCode)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Class = i.Class and d.DLCode = i.DLCode
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change DLCode '
        	goto error
        	end
       end
   if update(Factor)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Class = i.Class and d.DLCode = i.DLCode and d.Factor = i.Factor
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Factor '
        	goto error
        	end
       end
   
   /* Insert records into HQMA for changes made to audited fields */
   if exists (select * from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditCraftClass = 'Y')
   	begin
       insert into dbo.bHQMA select 'bPRCD',
       	'Craft:' + i.Craft + ' Class:' + i.Class + ' DL Code:' +
       	+ convert(varchar(10),i.DLCode) + ' Factor:' + convert(varchar(15),i.Factor),
       	i.PRCo, 'C','Old Rate', convert(varchar(15),d.OldRate), Convert(varchar(15),i.OldRate),
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class and
       	i.DLCode = d.DLCode and i.Factor = d.Factor
           join dbo.PRCO p on i.PRCo = p.PRCo
           where i.OldRate <> d.OldRate and p.AuditCraftClass='Y'
       insert into dbo.bHQMA select 'bPRCD',
       	'Craft:' + i.Craft + ' Class:' + i.Class + ' DL Code:' +
       	+ convert(varchar(10),i.DLCode) + ' Factor:' + convert(varchar(15),i.Factor),
       	i.PRCo, 'C','New Rate', convert(varchar(15),d.NewRate), Convert(varchar(15),i.NewRate),
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class and
       	i.DLCode = d.DLCode and i.Factor = d.Factor
           join dbo.PRCO p on i.PRCo = p.PRCo
           where i.NewRate <> d.NewRate and p.AuditCraftClass='Y'
       end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Class Deductions/Liabilities!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRCD] ON [dbo].[bPRCD] ([PRCo], [Craft], [Class], [DLCode], [Factor]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCD].[OldRate]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCD].[NewRate]'
GO
