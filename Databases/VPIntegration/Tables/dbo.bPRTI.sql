CREATE TABLE [dbo].[bPRTI]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Template] [smallint] NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
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
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRTId    Script Date: 8/28/99 9:38:15 AM ******/
   CREATE  trigger [dbo].[btPRTId] on [dbo].[bPRTI] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created by: EN 4/10/00
    *	Modified:	EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Adds HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRTI',
   	 'Craft:' + Craft + ' Template:' + convert(varchar(10),Template)
   	 + ' EDLType:' + EDLType + ' EDLCode:' + convert(varchar(10),EDLCode) + ' Factor:' +
   	 convert(varchar(10),Factor),
   	 d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME() from deleted d join dbo.PRCO p with (nolock) on
   	 d.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Template Items!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRTIi    Script Date: 8/28/99 9:38:15 AM ******/
   CREATE   trigger [dbo].[btPRTIi] on [dbo].[bPRTI] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created by: kb 11/4/98
    * 	Modified by: kb 1/11/00 - was validating the factor wrong for dedns/liabs
    *              GG 12/28/00 - fixed Factor validation
    *		MV 1/28/02 - issue 15711 calccategory validation
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Insert trigger for PR Template Items
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
   
   /* validate Template */
   select @validcnt = count(*) from dbo.bPRCT c with (nolock) join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft
   	and c.Template = i.Template
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Template '
   	goto error
   	end
   
   /* validate EDLType*/
   select @validcnt = count(*) from inserted i where i.EDLType = 'E' or i.EDLType = 'D' or i.EDLType = 'L'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Earnings Type must be ''E'', ''D'' or ''L'' '
   	goto error
   	end
   
   /* validate EDLCode*/
   select @validcnt = count(*) from inserted i where i.EDLType = 'E'
   select @validcnt2 = count(*) from inserted i join dbo.PREC c with (nolock) on i.PRCo = c.PRCo and i.EDLCode = c.EarnCode
   	where i.EDLType = 'E'
   if @validcnt<>@validcnt2
   	begin
   	select @errmsg = 'Invalid Earnings Code '
   	goto error
   	end
   select @validcnt = count(*) from inserted i where i.EDLType = 'D' or i.EDLType = 'L'
   select @validcnt2 = count(*) from inserted i join dbo.PRDL c with (nolock) on i.PRCo = c.PRCo and i.EDLCode = c.DLCode
   	and i.EDLType = c.DLType and (i.EDLType = 'D' or i.EDLType = 'L')
   if @validcnt<>@validcnt2
   	begin
   	select @errmsg = 'Invalid Deduction/Liability Code '
   	goto error
   	end
   
   /* validate Factor */
   select @validcnt = count(*) from dbo.bPREC c with (nolock) join inserted i on c.PRCo = i.PRCo and c.EarnCode = i.EDLCode
   	where i.EDLType = 'E' and i.Factor <> 0 and Method <> 'V'
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Factor must be 0.00 for non Variable Rate Earnings '
   	goto error
   	end
   select @validcnt = count(*) from dbo.bPREC c with (nolock) join inserted i on c.PRCo = i.PRCo and c.EarnCode = i.EDLCode
   	where i.EDLType = 'E' and i.Factor <= 0 and Method = 'V'
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Factor must be greater than 0.00 for Variable Rate Earnings '
   	goto error
   	end
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.EDLType = c.DLType and i.EDLCode = c.DLCode
       where i.EDLType <> 'E' and i.Factor <> 0 and Method <> 'V'
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Factor must be 0.00 for non Variable Rate Deductions and Liabilities '
   	goto error
   	end
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.EDLType = c.DLType and i.EDLCode = c.DLCode
       where i.EDLType <> 'E' and i.Factor <= 0 and Method = 'V'
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Factor must be greater than 0.00 for Variable Rate Deductions and Liabilities '
   	goto error
   	end
   
   /*validate CalCategory.*/
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.EDLType = c.DLType and i.EDLCode = c.DLCode
       where i.EDLType in ('L', 'D') and c.CalcCategory not in ('C', 'A') 
   if @validcnt <> 0
   	begin
   	select @errmsg = 'DLCode calculation category must be C or A. '
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRTI',
   	 'Craft:' + Craft + ' Template:' + convert(varchar(10),Template)
   	 + ' EDLType:' + EDLType + ' EDLCode:' + convert(varchar(10),EDLCode) + ' Factor:' +
   	 convert(varchar(10),Factor),
   	 i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.PRCO p with (nolock) on
   	 i.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Template Items!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRTIu    Script Date: 8/28/99 9:38:15 AM ******/
   CREATE  trigger [dbo].[btPRTIu] on [dbo].[bPRTI] for UPDATE as
   

/*--------------------------------------------------------------------------
    *  Created: kb 11/4/98
    *  Modified: kb 12/3/98
    *            EN 10/24/00 - Checking for key changes incorrectly
    *			EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Validates and inserts HQ Master Audit entry.
    *
    * Cannot change primary key - PR Company, Craft, Template, EDLType, EDLCode, Factor
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
   if update(EDLType)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Template = i.Template and d.EDLType = i.EDLType
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change EDL Type '
        	goto error
        	end
       end
   if update(EDLCode)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Template = i.Template and d.EDLType = i.EDLType
            and d.EDLCode = i.EDLCode
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change EDL Code '
        	goto error
        	end
       end
   if update(Factor)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Template = i.Template and d.EDLType = i.EDLType
            and d.EDLCode = i.EDLCode and d.Factor = i.Factor
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Factor '
        	goto error
        	end
       end
   
   /* Insert records into HQMA for changes made to audited fields */
   insert into dbo.bHQMA select 'bPRTI',
   	'Craft:' + i.Craft + ' Template:' + convert(varchar(10),i.Template)
   	 + ' EDLType:' + i.EDLType + ' EDLCode:' + convert(varchar(10),i.EDLCode) + ' Factor:' +
   	 convert(varchar(10),i.Factor),
   	i.PRCo, 'C','Old Rate', convert(varchar(15),d.OldRate), Convert(varchar(15),i.OldRate),
   	getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Template = d.Template and i.EDLType = d.EDLType
   	and i.EDLCode = d.EDLCode and i.Factor = d.Factor
       join dbo.PRCO p with (nolock) on p.PRCo = i.PRCo
   	where i.OldRate <> d.OldRate and p.AuditCraftClass = 'Y'
   insert into dbo.bHQMA select 'bPRTI',
   	'Craft:' + i.Craft + ' Template:' + convert(varchar(10),i.Template)
   	 + ' EDLType:' + i.EDLType + ' EDLCode:' + convert(varchar(10),i.EDLCode) + ' Factor:' +
   	 convert(varchar(10),i.Factor),
   	i.PRCo, 'C','New Rate', convert(varchar(15),d.NewRate), Convert(varchar(15),i.NewRate),
   	getdate(), SUSER_SNAME()
   	from inserted i join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Template = d.Template and i.EDLType = d.EDLType
   	and i.EDLCode = d.EDLCode and i.Factor = d.Factor
       join dbo.PRCO p with (nolock) on p.PRCo = i.PRCo
       where i.NewRate <> d.NewRate and p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Template Items!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRTI] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRTI] ON [dbo].[bPRTI] ([PRCo], [Craft], [Template], [EDLType], [EDLCode], [Factor]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRTI].[OldRate]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRTI].[NewRate]'
GO
