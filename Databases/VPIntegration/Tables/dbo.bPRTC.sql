CREATE TABLE [dbo].[bPRTC]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Class] [dbo].[bClass] NOT NULL,
[Template] [smallint] NOT NULL,
[OverCapLimit] [dbo].[bYN] NOT NULL,
[OldCapLimit] [dbo].[bDollar] NULL,
[NewCapLimit] [dbo].[bDollar] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRTCd    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE  trigger [dbo].[btPRTCd] on [dbo].[bPRTC] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created by: EN 4/17/00
    *  Modified:   EN 6/12/00 - delete corresponding entries from bPRTP, bPRTE, bPRTF and bPRTD
    *              GG 03/21/01 - removed cascading deletes, add checks on dependant tables
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Adds HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for Template/Class Pay Rates
   if exists(select * from dbo.bPRTP w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft
           and w.Class = d.Class and w.Template = d.Template)
       begin
   	select @errmsg = 'Pay Rates exist'
   	goto error
   	end
   -- check for Template/Class Addons
   if exists(select * from dbo.bPRTF w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft
           and w.Class = d.Class and w.Template = d.Template)
       begin
   	select @errmsg = 'Addons exist'
   	goto error
   	end
   -- check for Template/Class Earnings
   if exists(select * from dbo.bPRTE w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft
           and w.Class = d.Class and w.Template = d.Template)
       begin
   	select @errmsg = 'Earnings exist'
   	goto error
   	end
   -- check for Template/Class D/Ls
   if exists(select * from dbo.bPRTD w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft
           and w.Class = d.Class and w.Template = d.Template)
       begin
   	select @errmsg = 'Deductions/Liabilities exist'
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRTC',
   	 'Craft:' + d.Craft + ' Class:' + d.Class + ' Template:' + convert(varchar(4),d.Template),
   	 d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME() from deleted d
        join dbo.PRCO a with (nolock) on d.PRCo=a.PRCo where a.AuditCraftClass='Y'
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Template Class!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRTCi    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE  trigger [dbo].[btPRTCi] on [dbo].[bPRTC] for INSERT as
   

/*-----------------------------------------------------------------
    *   	Created by: EN 4/17/00
    *					EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Validates Company, Craft, Class, and Template.
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
   select @validcnt = count(*) from dbo.bPRCT c with (nolock) join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft
   	and c.Template = i.Template
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Template '
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRTC',
   	 'Craft:' + Craft + ' Class:' + Class + ' Template:' + convert(varchar(4),Template),
   	 i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.PRCO a with (nolock)
   	 on i.PRCo=a.PRCo where a.AuditCraftClass='Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Template Class!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
/****** Object:  Trigger [dbo].[btPRTCu]    Script Date: 12/27/2007 10:13:05 ******/
   CREATE  trigger [dbo].[btPRTCu] on [dbo].[bPRTC] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/17/00
    *                EN 10/09/00 - Checking for key changes incorrectly
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *				EN 12/27/08 - #126315  allow for 20 character OldCapLimit and NewCapLimit when logging to HQMA
    *
    *	Cannot change primary key - PR Company
    *  Validates and inserts HQ Master Audit entry.
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
   if update(Template)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Class = i.Class and d.Template = i.Template
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Template '
        	goto error
        	end
       end
   
   /* Insert records into HQMA for changes made to audited fields */
   if exists (select * from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditCraftClass = 'Y')
   	begin
       insert into dbo.bHQMA select 'bPRTC',
       	'Craft:' + i.Craft + ' Class:' + i.Class + ' Template:' + convert(varchar(4),i.Template),
       	i.PRCo, 'C','Over Cap Limit', d.OverCapLimit, i.OverCapLimit,
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class and i.Template = d.Template
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where i.OverCapLimit <> d.OverCapLimit and p.AuditCraftClass='Y'
       insert into dbo.bHQMA select 'bPRTC',
       	'Craft:' + i.Craft + ' Class:' + i.Class + ' Template:' + convert(varchar(4),i.Template),
       	i.PRCo, 'C','Old Cap Limit', convert(varchar(20),d.OldCapLimit), Convert(varchar(20),i.OldCapLimit),
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class and i.Template = d.Template
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where isnull(i.OldCapLimit,0) <> isnull(d.OldCapLimit,0) and p.AuditCraftClass='Y'
       insert into dbo.bHQMA select 'bPRTC',
       	'Craft:' + i.Craft + ' Class:' + i.Class + ' Template:' + convert(varchar(4),i.Template),
       	i.PRCo, 'C','New Cap Limit', convert(varchar(20),d.NewCapLimit), Convert(varchar(20),i.NewCapLimit),
       	getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class and i.Template = d.Template
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where isnull(i.NewCapLimit,0) <> isnull(d.NewCapLimit,0) and p.AuditCraftClass='Y'
       end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update Template PR Class!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRTC] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRTC] ON [dbo].[bPRTC] ([PRCo], [Craft], [Class], [Template]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRTC].[OverCapLimit]'
GO
