CREATE TABLE [dbo].[bPRCE]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Class] [dbo].[bClass] NOT NULL,
[Shift] [tinyint] NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
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
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCEd    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE  trigger [dbo].[btPRCEd] on [dbo].[bPRCE] for DELETE as
   

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
   
   /* Audit Craft/Class Earings deletions */
   insert into dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCE', 'Craft:' + Craft + ' Class:' + Class + ' Shift:' + convert(varchar(3),Shift) + ' Earn Code:' +
   		convert(varchar(10),EarnCode),
   		d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d join dbo.PRCO p on d.PRCo = p.PRCo where p.AuditCraftClass='Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Class Earnings!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCEi    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE  trigger [dbo].[btPRCEi] on [dbo].[bPRCE] for INSERT as
   

/*-----------------------------------------------------------------
    *   	Created by: kb 11/4/98
    * 	Modified by: EN 01/28/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	This trigger rejects insertion in bPRCE (PR Class Earnings) if the
    *	following error condition exists:
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
   
   /* validate Earnings Code */
   select @validcnt = count(*) from dbo.bPREC c with (nolock) join inserted i on c.PRCo = i.PRCo and c.EarnCode = i.EarnCode
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Earnings Code '
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRCE',
   	 'Craft:'
   	 + Craft + ' Class:' + Class + ' Shift:' + convert(varchar(3),Shift) + ' Earn Code:' + convert(varchar(10),EarnCode),
   	 i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i join
   	 dbo.PRCO p on i.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Class Earnings!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCEu    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE  trigger [dbo].[btPRCEu] on [dbo].[bPRCE] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: kb 11/4/98
    *  Modified: kb 12/3/98
    *            EN 10/23/00 - Checking for key changes incorrectly
    *				EN 01/28/03 - issue 23061  added isnull check, with (nolock), and dbo
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
   if update(Shift)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Class = i.Class and d.Shift = i.Shift
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Shift '
        	goto error
        	end
       end
   if update(EarnCode)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Class = i.Class and d.Shift = i.Shift
               and d.EarnCode = i.EarnCode
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change EarnCode '
        	goto error
        	end
       end
   
   /* Insert records into HQMA for changes made to audited fields */
   if exists (select * from inserted i join dbo.bPRCO a on a.PRCo = i.PRCo where a.AuditCraftClass = 'Y')
   	begin
       insert into dbo.bHQMA select 'bPRCE',
       	'Craft:' + i.Craft + ' Class:' + i.Class + ' Shift:' +
       	convert(varchar(3),i.Shift) + ' Earn Code:' + convert(varchar(10),i.EarnCode),
       	i.PRCo, 'C','Old Rate', convert(varchar(15),d.OldRate), Convert(varchar(15),i.OldRate),
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class and i.Shift = d.Shift
       	and i.EarnCode = d.EarnCode
           join dbo.PRCO p on i.PRCo = p.PRCo
           where i.OldRate <> d.OldRate and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCE',
       	'Craft:' + i.Craft + ' Class:' + i.Class + ' Shift:' +
       	convert(varchar(3),i.Shift) + ' Earn Code:' + convert(varchar(10),i.EarnCode),
       	i.PRCo, 'C','New Rate', convert(varchar(15),d.NewRate), Convert(varchar(15),i.NewRate),
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class and i.Shift = d.Shift
       	and i.EarnCode = d.EarnCode
           join dbo.PRCO p on i.PRCo = p.PRCo
           where i.NewRate <> d.NewRate and p.AuditCraftClass = 'Y'
       end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Class Earnings!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCE] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRCE] ON [dbo].[bPRCE] ([PRCo], [Craft], [Class], [Shift], [EarnCode]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCE].[OldRate]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCE].[NewRate]'
GO
