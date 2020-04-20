CREATE TABLE [dbo].[bPRCF]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Class] [dbo].[bClass] NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
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
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCFd    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE  trigger [dbo].[btPRCFd] on [dbo].[bPRCF] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: kb 11/4/98
    *  Modified: EN 01/28/03 - issue 23061  added isnull check, and dbo
    *
    * Validates and inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   /* Audit Craft/Class Add-ons deletions */
   insert into dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCF', 'Craft:' + Craft + ' Class:' + Class + ' Earn Code:' + convert(varchar(10),EarnCode) + ' Factor:'
   		+ convert(varchar(15),Factor),
   		d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d join dbo.PRCO p on d.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Class Addons!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCFi    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE  trigger [dbo].[btPRCFi] on [dbo].[bPRCF] for INSERT as
   

/*-----------------------------------------------------------------
    * Created by: kb 11/4/98
    * Modified by: GG 12/28/00 - added Factor validation
    *				EN 01/28/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Insert trigger for PR Class Addons
    *
    * Adds HQ Master Audit entry.
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
   
   /* validate Earnings Code */
   select @validcnt = count(*) from dbo.bPREC c with (nolock) join inserted i on c.PRCo = i.PRCo and c.EarnCode = i.EarnCode
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Earnings Code '
   	goto error
   	end
   
   -- validate Factor
   select @validcnt = count(*) from dbo.bPREC c with (nolock) join inserted i on c.PRCo = i.PRCo and c.EarnCode = i.EarnCode
   where c.Method = 'V' and i.Factor <= 0
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Factor must be greater than 0.00 for Variable Rate earnings '
   	goto error
   	end
   select @validcnt = count(*) from dbo.bPREC c with (nolock) join inserted i on c.PRCo = i.PRCo and c.EarnCode = i.EarnCode
   where c.Method <> 'V' and i.Factor <> 0
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Factor must be 0.00 for non Variable Rate earnings '
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bPRCF',
       'Craft:' + Craft + ' Class:' + Class + ' Earn Code:' + convert(varchar(10),EarnCode) + ' Factor:'+ convert(varchar(15),Factor),
   	 i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME()
   from inserted i
   join dbo.PRCO p on i.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Class Addons!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCFu    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE  trigger [dbo].[btPRCFu] on [dbo].[bPRCF] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: kb 11/4/98
    *  Modified: kb 12/3/98
    *            EN 4/7/00 - Earn Code validation not working
    *            EN 10/09/00 - Checking for key changes incorrectly
    *				EN 01/28/03 - issue 23061  added isnull check, and dbo
    *
    * Update trigger for PR Craft Class Addons
    *
    * Cannot change primary key, update HQ Audit
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
   if update(EarnCode)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Class = i.Class and d.EarnCode = i.EarnCode
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change EarnCode '
        	goto error
        	end
       end
   if update(Factor)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Class = i.Class and d.EarnCode = i.EarnCode and d.Factor = i.Factor
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Factor '
        	goto error
        	end
       end
   
   /* Insert records into HQMA for changes made to audited fields */
   insert into dbo.bHQMA select 'bPRCF',
   	'Craft:' + i.Craft + ' Class:' + i.Class + ' Earn Code:' +
   	+ convert(varchar(10),i.EarnCode) + ' Factor:' + convert(varchar(15),i.Factor),
   	i.PRCo, 'C','Old Rate', convert(varchar(15),d.OldRate), Convert(varchar(15),i.OldRate),
   	getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class
   	and i.EarnCode = d.EarnCode and i.Factor = d.Factor
       join dbo.PRCO p on i.PRCo = p.PRCo
       where i.OldRate <> d.OldRate and p.AuditCraftClass = 'Y'
   insert into dbo.bHQMA select 'bPRCF',
   	'Craft:' + i.Craft + ' Class:' + i.Class + ' Earn Code:' +
   	+ convert(varchar(10),i.EarnCode) + ' Factor:' + convert(varchar(15),i.Factor),
   	i.PRCo, 'C','New Rate', convert(varchar(15),d.NewRate), Convert(varchar(15),i.NewRate),
   	getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class
   	and i.EarnCode = d.EarnCode and i.Factor = d.Factor
       join dbo.PRCO p on i.PRCo = p.PRCo
       where i.NewRate <> d.NewRate and p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Class Addons!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCF] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRCF] ON [dbo].[bPRCF] ([PRCo], [Craft], [Class], [EarnCode], [Factor]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCF].[OldRate]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCF].[NewRate]'
GO
