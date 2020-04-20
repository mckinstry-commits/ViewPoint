CREATE TABLE [dbo].[bPRTR]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Template] [smallint] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRTRd    Script Date: 8/28/99 9:38:14 AM ******/
   CREATE  trigger [dbo].[btPRTRd] on [dbo].[bPRTR] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/19/00
    *	Modified:	EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Validates and inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   /* Audit Craft Template Reciprocal Item deletions */
   insert into dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRTR', 'Craft:' + Craft + ' Template:' + convert(varchar(10),Template) + ' DLCode:' +
   	    convert(varchar(10),DLCode),
   		d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d join dbo.PRCO p with (nolock) on d.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Template Reciprocal Item!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRTRi    Script Date: 8/28/99 9:38:14 AM ******/
   CREATE   trigger [dbo].[btPRTRi] on [dbo].[bPRTR] for INSERT as
   

/*-----------------------------------------------------------------
    *   	Created by: EN 4/19/00
    *	Modified by: MV 1/28/02 issue 15711 added CalcCategory validation
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *  Validate PR Company, Craft, Template and DLCode.
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
   
   /* validate Template */
   select @validcnt = count(*) from dbo.bPRCT c with (nolock) join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft
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
   
   /*validate CalCategory.*/
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.DLCode = c.DLCode
       where i.PRCo = c.PRCo and c.CalcCategory not in ('C', 'A') 
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Ded/Liab Code calculation category must be C or A. '
   	goto error
   	end
   
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRTR',
   	 'Craft:' + Craft + ' Template:' + convert(varchar(10),Template) + ' DLCode:' +
   	 convert(varchar(10),DLCode),
   	 i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.PRCO p with (nolock)
   	 on i.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Template Reciprocal Item! '
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btPRTRu] on [dbo].[bPRTR] for UPDATE as
   
   
   

/*--------------------------------------------------------------------------
    *  Created: EN 4/19/00
    *                EN 10/09/00 - Checking for key changes incorrectly
    *			EN 02/19/03 - issue 23061  added isnull check
    *
    * Cannot change primary key - PR Company, Craft, Template, DLCode
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
   if update(Template)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Template = i.Template
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Template '
        	goto error
        	end
       end
   if update(DLCode)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Template = i.Template and d.DLCode = i.DLCode
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Dedn/Liab Code '
        	goto error
        	end
       end
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Template Reciprocal Item!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRTR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRTR] ON [dbo].[bPRTR] ([PRCo], [Craft], [Template], [DLCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
