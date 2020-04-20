CREATE TABLE [dbo].[bPRCT]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Template] [smallint] NOT NULL,
[OverEffectDate] [dbo].[bYN] NOT NULL,
[EffectiveDate] [dbo].[bDate] NULL,
[OverOT] [dbo].[bYN] NOT NULL,
[OTSched] [tinyint] NULL,
[RecipOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[JobCraft] [dbo].[bCraft] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SuperWeeklyMin] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRCT_SuperWeeklyMin] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPRCT] ADD
CONSTRAINT [CK_bPRCT_OverEffectDate] CHECK (([OverEffectDate]='Y' OR [OverEffectDate]='N'))
ALTER TABLE [dbo].[bPRCT] ADD
CONSTRAINT [CK_bPRCT_OverOT] CHECK (([OverOT]='Y' OR [OverOT]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCTd    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE  trigger [dbo].[btPRCTd] on [dbo].[bPRCT] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/10/00
    *  Modified: EN 6/12/00 - delete corresponding entries from bPRTI and bPRTR
    *          GG 3/21/01 - removed cascading deletes - added checks for bPRTC, bPRTI, and bPRTR
    *			EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   -- check for Template Classes
   if exists(select * from dbo.bPRTC w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft and w.Template = d.Template)
    	begin
   	select @errmsg = 'Template classes exist'
   	goto error
   	end
   -- check for Template Items
   if exists(select * from dbo.bPRTI w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft and w.Template = d.Template)
    	begin
   	select @errmsg = 'Add-ons, dedcutions, and/or liabilities exist'
   	goto error
   	end
   -- check for Template Reciprocal Items
   if exists(select * from dbo.bPRTR w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft and w.Template = d.Template)
    	begin
   	select @errmsg = 'Reciprocal deductions and/or liabilties exist'
   	goto error
   	end
   
   /* Audit Craft Template deletions */
   insert into dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCT', 'Craft: ' + d.Craft + ' Template:' + convert(varchar(4),d.Template),
       d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d join dbo.PRCO p with (nolock) on d.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Craft Template!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCTi    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE  trigger [dbo].[btPRCTi] on [dbo].[bPRCT] for INSERT as
   

/*-----------------------------------------------------------------
    *   	Created by: EN 4/10/00
    *		Modified:	EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *  Validates PR Company, Craft, Template, OTSched, RecipOpt and JobCraft.
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
   select @validcnt = count(*) from dbo.bPRTM c with (nolock) join inserted i on c.PRCo = i.PRCo and c.Template = i.Template
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Template '
   	goto error
   	end
   
   /* validate Overtime Schedule */
   select @validcnt = count(*) from inserted where OTSched is not null
   select @validcnt2 = count(*) from dbo.bPROT c with (nolock) join inserted i on c.PRCo = i.PRCo and c.OTSched = i.OTSched
   	where i.OTSched is not null
   if @validcnt <> @validcnt2
   	begin
   	select @errmsg = 'Invalid OT Schedule '
   	goto error
   	end
   
   /* validate RecipOpt */
   select @validcnt = count(*) from inserted where RecipOpt = 'N' or RecipOpt = 'P' or RecipOpt = 'O'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Reciprocal Agrement Option must be ''N'', ''P'' or ''O'' '
   	goto error
   	end
   
   /* validate Job Craft */
   select @validcnt = count(*) from inserted where JobCraft is not null
   select @validcnt2 = count(*) from dbo.bPRCM c with (nolock) join inserted i on c.PRCo = i.PRCo and c.Craft = i.JobCraft
       where i.JobCraft is not null
   if @validcnt <> @validcnt2
   	begin
   	select @errmsg = 'Invalid Job Craft '
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCT', 'Craft:' + i.Craft + ' Template:' + convert(varchar(4),i.Template),
       i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME()
       from inserted i join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Craft Template!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRCTu    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE   trigger [dbo].[btPRCTu] on [dbo].[bPRCT] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/10/00
    *                EN 10/09/00 - Checking for key changes incorrectly
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Cannot change primary key.
    * Validates OTSched, RecipOpt and JobCraft.
    * Inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
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
   
   /* validate Overtime Schedule */
   select @validcnt = count(*) from inserted where OTSched is not null
   select @validcnt2 = count(*) from dbo.bPROT c with (nolock) join inserted i on c.PRCo = i.PRCo and c.OTSched = i.OTSched
   	where i.OTSched is not null
   if @validcnt <> @validcnt2
   	begin
   	select @errmsg = 'Invalid OT Schedule '
   	goto error
   	end
   
   /* validate RecipOpt */
   select @validcnt = count(*) from inserted where RecipOpt = 'N' or RecipOpt = 'P' or RecipOpt = 'O'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Reciprocal Agrement Option must be ''N'', ''P'' or ''O'' '
   	goto error
   	end
   
   /* validate Job Craft */
   select @validcnt = count(*) from inserted where JobCraft is not null
   select @validcnt2 = count(*) from dbo.bPRCM c with (nolock) join inserted i on c.PRCo = i.PRCo and c.Craft = i.JobCraft
       where i.JobCraft is not null
   if @validcnt <> @validcnt2
   	begin
   	select @errmsg = 'Invalid Job Craft '
   	goto error
   	end
   
   /* Insert records into HQMA for changes made to audited fields */
   if exists(select * from inserted i join dbo.PRCO a with (nolock) on i.PRCo = a.PRCo and a.AuditCraftClass = 'Y')
       begin
       insert into dbo.bHQMA select 'bPRCT',
      	    'Craft: ' + i.Craft + ' Template:' + convert(varchar(4),i.Template),
           i.PRCo, 'C', 'Override Effective Date', d.OverEffectDate, i.OverEffectDate,
           getdate(), SUSER_SNAME()
          	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Template = d.Template
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where i.OverEffectDate <> d.OverEffectDate and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCT',
       	'Craft: ' + i.Craft + ' Template:' + convert(varchar(4),i.Template),
       	i.PRCo, 'C', 'Effective Date', convert(varchar(8),d.EffectiveDate), convert(varchar(8),i.EffectiveDate),
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Template = d.Template
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where isnull(i.EffectiveDate,'') <> isnull(d.EffectiveDate,'') and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCT',
      	    'Craft: ' + i.Craft + ' Template:' + convert(varchar(4),i.Template),
           i.PRCo, 'C', 'OverOT', d.OverOT, i.OverOT,
           getdate(), SUSER_SNAME()
          	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Template = d.Template
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where i.OverOT <> d.OverOT and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCT',
       	'Craft: ' + i.Craft + ' Template:' + convert(varchar(4),i.Template),
       	i.PRCo, 'C', 'OT Schedule', d.OTSched, i.OTSched,
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Template = d.Template
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where isnull(i.OTSched,'') <> isnull(d.OTSched,'') and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCT',
      	    'Craft: ' + i.Craft + ' Template:' + convert(varchar(4),i.Template),
           i.PRCo, 'C', 'Reciprocal Agreement Option', d.RecipOpt, i.RecipOpt,
           getdate(), SUSER_SNAME()
          	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Template = d.Template
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where i.RecipOpt <> d.RecipOpt and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCT',
       	'Craft: ' + i.Craft + ' Template:' + convert(varchar(4),i.Template),
       	i.PRCo, 'C', 'Job Craft', d.JobCraft, i.JobCraft,
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Template = d.Template
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where isnull(i.JobCraft,'') <> isnull(d.JobCraft,'') and p.AuditCraftClass = 'Y'

       insert into dbo.bHQMA select 'bPRCT',
       	'Craft: ' + i.Craft + ' Template:' + convert(varchar(4),i.Template),
       	i.PRCo, 'C', 'Superannuation Weekly Minimum', convert(varchar,d.SuperWeeklyMin), convert(varchar,i.SuperWeeklyMin),
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Template = d.Template
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where isnull(i.SuperWeeklyMin,0) <> isnull(d.SuperWeeklyMin,0) and p.AuditCraftClass = 'Y'

       end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Craft Template!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRCT] ON [dbo].[bPRCT] ([PRCo], [Craft], [Template]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCT].[OverEffectDate]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCT].[OverOT]'
GO
