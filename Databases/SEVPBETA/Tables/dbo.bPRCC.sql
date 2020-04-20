CREATE TABLE [dbo].[bPRCC]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Class] [dbo].[bClass] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[EEOClass] [char] (1) COLLATE Latin1_General_BIN NULL,
[OldCapLimit] [dbo].[bUnitCost] NOT NULL,
[NewCapLimit] [dbo].[bUnitCost] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[WghtAvgOT] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCC_WghtAvgOT] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRCCd    Script Date: 8/28/99 9:38:09 AM ******/
   CREATE   trigger [dbo].[btPRCCd] on [dbo].[bPRCC] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created by: EN 4/17/00
    *  Modified by: EN 6/7/00
    *               EN 6/7/00 - delete corresponding entries from bPRCP, bPRCE, bPRCF and bPRCD
    *               EN 7/31/00 - bHQMA insert not working
    *               EN 1/2/01 - warn rather than deleting corresponding entries from bPRCP, bPRCE, bPRCF, bPRCD
    *               GG 03/21/01 - removed checks on tables requiring valid Craft Template (will be checked in btPRTCd)
    *                           - added checks for bPRCA, bPRAE, and bPREH
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 12/10/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *
    *	Adds HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
    -- check for Class Pay Rates
    if exists(select * from dbo.bPRCP w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft and w.Class = d.Class)
    	begin
   	select @errmsg = 'Pay Rates exist'
   	goto error
   	end
    -- check for Class Earnings
    if exists(select * from dbo.bPRCE w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft and w.Class = d.Class)
    	begin
   	select @errmsg = 'Earnings exist'
   	goto error
   	end
    -- check for Class Addons
    if exists(select * from dbo.bPRCF w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft and w.Class = d.Class)
    	begin
   	select @errmsg = 'Addons exist'
   	goto error
   	end
    -- check for Class D/Ls
    if exists(select * from dbo.bPRCD w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft and w.Class = d.Class)
    	begin
   	select @errmsg = 'Deductions/Liabilities exist'
   	goto error
   	end
    -- check for Craft Accums
    if exists(select * from dbo.bPRCA w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft and w.Class = d.Class)
    	begin
   	select @errmsg = 'Craft/Class report accumulations exist'
   	goto error
   	end
    -- check for Template Classes
    if exists(select * from dbo.bPRTC w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft and w.Class = d.Class)
    	begin
   	select @errmsg = 'Craft/Class in use on Templates'
   	goto error
   	end
   -- check for Employee Auto Earnings
    if exists(select * from dbo.bPRAE w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft and w.Class = d.Class)
    	begin
   	select @errmsg = 'Craft/Class assigned in Employee Auto Earnings'
   	goto error
   	end
   -- check for Employee Header
    if exists(select * from dbo.bPREH w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Craft = d.Craft and w.Class = d.Class)
    	begin
   	select @errmsg = 'Craft/Class assigned in Employee Header'
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRCC',
   	 'Craft:' + d.Craft + ' Class:' + d.Class,
   	 d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME() from deleted d
        join dbo.PRCO p with (nolock) on d.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Craft/Class!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE  trigger [dbo].[btPRCCi] on [dbo].[bPRCC] for INSERT as
   

/*-----------------------------------------------------------------
    * Created: EN 4/17/00
    * Modified:	01/20/2003 GG - #18703 - weighted avg OT 
    *				EN 12/10/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Insert trigger for PR Craft Class table
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
   
   -- #18703 - Check Weighted Average OT option
   if exists(select 1 from inserted where WghtAvgOT not in ('Y','N'))
   	begin
       select @errmsg = 'Weighted Average Overtime option must ''Y'' or ''N''.'
       goto error
       end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRCC',
   	 'Craft:' + Craft + ' Class:' + Class,
   	 i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.PRCO a with (nolock)
   	 on i.PRCo=a.PRCo where a.AuditCraftClass='Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Class!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
/****** Object:  Trigger [dbo].[btPRCCu]    Script Date: 12/27/2007 08:43:42 ******/
   CREATE  trigger [dbo].[btPRCCu] on [dbo].[bPRCC] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created: EN 4/17/00
    *          EN 10/09/00 - Checking for key changes incorrectly
    *			EN 10/9/02 - issue 18877 change double quotes to single
    *			01/20/2003 GG - #18703 - weighted avg OT
    *			EN 12/10/03 - issue 23061  added isnull check, with (nolock), and dbo
	*			EN 12/27/08 - #126315  allow for 20 character OldCapLimit and NewCapLimit when logging to HQMA
    *
    * Update trigger for PR Craft Class table
    *
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
   
   -- #18703 - Check Weighted Average OT option
   if update(WghtAvgOT)
   	begin
   	if exists(select 1 from inserted where WghtAvgOT not in ('Y','N'))
   		begin
           select @errmsg = 'Weighted Average Overtime option must ''Y'' or ''N''.'
           goto error
           end
   	end
   
   
   /* Insert records into HQMA for changes made to audited fields */
   if exists (select * from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditCraftClass = 'Y')
   	begin
   	if update(Description)
       	insert dbo.bHQMA
   		select 'bPRCC', 'Craft:' + i.Craft + ' Class:' + i.Class,
       		i.PRCo, 'C','Description', d.Description, i.Description, getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where isnull(i.Description,'') <> isnull(d.Description,'') and p.AuditCraftClass='Y'
   	if update(EEOClass)
       	insert dbo.bHQMA
   		select 'bPRCC', 'Craft:' + i.Craft + ' Class:' + i.Class,
       		i.PRCo, 'C','EEO Class', d.EEOClass, i.EEOClass, getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where isnull(i.EEOClass,'') <> isnull(d.EEOClass,'') and p.AuditCraftClass='Y'
   	if update(OldCapLimit)
       	insert dbo.bHQMA
   		select 'bPRCC', 'Craft:' + i.Craft + ' Class:' + i.Class,
       		i.PRCo, 'C','Old Cap Limit', convert(varchar(20),d.OldCapLimit), Convert(varchar(20),i.OldCapLimit),
       		getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where i.OldCapLimit <> d.OldCapLimit and p.AuditCraftClass='Y'
   	if update(NewCapLimit)
       	insert dbo.bHQMA
   		select 'bPRCC', 'Craft:' + i.Craft + ' Class:' + i.Class,
       		i.PRCo, 'C','New Cap Limit', convert(varchar(20),d.NewCapLimit), Convert(varchar(20),i.NewCapLimit),
       		getdate(), SUSER_SNAME()
       	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where i.NewCapLimit <> d.NewCapLimit and p.AuditCraftClass='Y'
   	if update(WghtAvgOT)	-- #18703
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bPRCC','Craft: ' + i.Craft + ' Class: ' + i.Class,
   			i.PRCo, 'C', 'Wght Avg OT',  d.WghtAvgOT, i.WghtAvgOT, getdate(), SUSER_SNAME()
       	from inserted i
   		join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Class = d.Class
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
       	where d.WghtAvgOT <> i.WghtAvgOT and p.AuditCraftClass = 'Y'
       end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Class!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRCC] ON [dbo].[bPRCC] ([PRCo], [Craft], [Class]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCC].[OldCapLimit]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRCC].[NewCapLimit]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRCC].[WghtAvgOT]'
GO
