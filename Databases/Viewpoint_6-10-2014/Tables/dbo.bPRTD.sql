CREATE TABLE [dbo].[bPRTD]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Class] [dbo].[bClass] NOT NULL,
[Template] [smallint] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[Factor] [dbo].[bRate] NOT NULL,
[OldRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPRTD_OldRate] DEFAULT ((0)),
[NewRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPRTD_NewRate] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRTDd    Script Date: 8/28/99 9:38:14 AM ******/
   CREATE  trigger [dbo].[btPRTDd] on [dbo].[bPRTD] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: kb 11/4/98
    *  Modified:	EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Validates and inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   /* Audit Craft/Class Template D/L deletions */
   insert into dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRTD', 'Craft:' + Craft + ' Class:' + Class + ' Template:' + convert(varchar(10),Template) + ' DLCode:' +
   	    convert(varchar(10),DLCode) + ' Factor:' + convert(varchar(10),Factor),
   		d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d join dbo.PRCO p with (nolock) on d.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Template Deductions/Liabilites!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRTDi    Script Date: 8/28/99 9:38:14 AM ******/
   CREATE   trigger [dbo].[btPRTDi] on [dbo].[bPRTD] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created by: kb 11/4/98
    * 	Modified by: EN 4/10/00 - validate factor
    *              GG 12/28/00 - fixed Factor validation
    *		MV 1/28/02 - issue 15711 - validate dlcode's CalcCategory
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Insert trigger on PR Template Class Deductions/Liabilities
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
   
   /* validate Template */
   select @validcnt = count(*) from dbo.bPRTC c with (nolock) join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft and c.Class = i.Class
   	and c.Template = i.Template
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Template '
   	goto error
   	end
   
   /* validate DL Code */
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and c.DLCode = i.DLCode
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Deductions/Liabilities Code '
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
       where c.CalcCategory not in ('C', 'A') 
   if @validcnt <> 0
   	begin
   	select @errmsg = 'DLCode calculation category must be C or A. '
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRTD',
   	 'Craft:' + Craft + ' Class:' + Class + ' Template:' + convert(varchar(10),Template) + ' DLCode:' +
   	 convert(varchar(10),DLCode) + ' Factor:' + convert(varchar(10),Factor),
   	 i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.PRCO p with (nolock)
   	 on i.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Template Deductions/Liabilities! '
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btPRTDu] on [dbo].[bPRTD] for UPDATE as
   
   
   

/*--------------------------------------------------------------------------
    *  Created: kb 11/4/98
    *  Modified: kb 12/3/98
    *            EN 10/24/00 - Checking for key changes incorrectly
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Validates and inserts HQ Master Audit entry.
    *
    * Cannot change primary key - PR Company, Craft, Class, Template, Shift, EarnCode
    */-------------------------------------------------------------------------
   
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
   if update(Template)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Class = i.Class
               and d.Template = i.Template
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Template '
        	goto error
        	end
       end
   if update(DLCode)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Class = i.Class
               and d.Template = i.Template and d.DLCode = i.DLCode
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Dedn/Liab Code '
        	goto error
        	end
       end
   if update(Factor)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Class = i.Class
               and d.Template = i.Template and d.DLCode = i.DLCode and d.Factor = i.Factor
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Factor '
        	goto error
        	end
       end
   
   /* Insert records into HQMA for changes made to audited fields */
   if exists(select * from inserted i join PRCO a on i.PRCo = a.PRCo and a.AuditCraftClass = 'Y')
       begin
       insert into dbo.bHQMA select 'bPRTD',
       	'Craft:' + i.Craft + ' Class:' + i.Class + ' Template:' + convert(varchar(10),i.Template) + ' DLCode:' +
   	    convert(varchar(10),i.DLCode) + ' Factor:' + convert(varchar(10),i.Factor),
       	i.PRCo, 'C','Old Rate', convert(varchar(15),d.OldRate), Convert(varchar(15),i.OldRate),
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class
           and i.Template = d.Template and i.DLCode = d.DLCode and i.Factor = d.Factor
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
       	where i.OldRate <> d.OldRate and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRTD',
       	'Craft:' + i.Craft + ' Class:' + i.Class + ' Template:' + convert(varchar(10),i.Template) + ' DLCode:' +
   	    convert(varchar(10),i.DLCode) + ' Factor:' + convert(varchar(10),i.Factor),
       	i.PRCo, 'C','New Rate', convert(varchar(15),d.NewRate), Convert(varchar(15),i.NewRate),
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class
           and i.Template = d.Template and i.DLCode = d.DLCode and i.Factor = d.Factor
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
       	where i.NewRate <> d.NewRate and p.AuditCraftClass='Y'
       end
   
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Template Deductions/Liabilites!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRTD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRTD] ON [dbo].[bPRTD] ([PRCo], [Craft], [Class], [Template], [DLCode], [Factor]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
