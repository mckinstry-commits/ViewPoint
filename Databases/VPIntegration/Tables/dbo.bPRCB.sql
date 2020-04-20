CREATE TABLE [dbo].[bPRCB]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[ELType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ELCode] [dbo].[bEDLCode] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCBd    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE  trigger [dbo].[btPRCBd] on [dbo].[bPRCB] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/10/00
    *	Modified:	EN 12/10/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   /* Audit Craft Capped Basis deletions */
   insert into dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCB', 'Craft: ' + d.Craft + ' ELType:' + d.ELType + ' ELCode:' + convert(varchar(5),d.ELCode),
       d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d join dbo.PRCO p with (nolock) on d.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Craft Capped Basis!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRCBi    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE     trigger [dbo].[btPRCBi] on [dbo].[bPRCB] for INSERT as
   

/*-----------------------------------------------------------------
    *   Created by: EN 4/10/00
    *	Modified by: MV 1/28/02 added calc category validation
    *				GG 02/21/03 - #20364 - allow Employee based liab codes
    *				EN 12/10/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *  Validates PR Company, Craft, ELType and ELCode.
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
   
   /* validate ELType */
   select @validcnt = count(*) from inserted where ELType = 'E' or ELType = 'L'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Earn/Liab Type Code '
   	goto error
   	end
   
   /* validate ELCode */
   select @validcnt = count(*) from inserted where ELType = 'E'
   select @validcnt2 = count(*) from inserted i join dbo.PREC c with (nolock) on i.PRCo = c.PRCo and i.ELCode = c.EarnCode
   where i.ELType = 'E'
   if @validcnt <> @validcnt2
   	begin
   	select @errmsg = 'Invalid Earnings Code '
   	goto error
   	end
   select @validcnt = count(*) from inserted where ELType = 'L'
   select @validcnt2 = count(*) from inserted i join dbo.PRDL c with (nolock) on i.PRCo = c.PRCo and i.ELCode = c.DLCode
   where i.ELType = 'L'
   if @validcnt <> @validcnt2
   	begin
   	select @errmsg = 'Invalid Liability Code '
   	goto error
   	end
   
   /*validate CalCategory.*/
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.ELType = c.DLType and i.ELCode = c.DLCode
       where i.PRCo = c.PRCo and i.ELType = 'L' and c.CalcCategory not in ('C', 'A', 'E') 
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Liability Code calculation category must be C, E, or A. '
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCB', 'Craft:' + i.Craft + ' ELType:' + i.ELType + ' ELCode:' + convert(varchar(5),i.ELCode),
       i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME()
       from inserted i join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Craft Capped Basis!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCBu    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE  trigger [dbo].[btPRCBu] on [dbo].[bPRCB] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/10/00
    *  Modified: EN 10/09/00 - Checking for key changes incorrectly
    *				EN 12/10/03 - issue 23061  added isnull check
    *
    * Cannot change primary key.
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
   if update(ELType)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.ELType = i.ELType
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change ELType '
        	goto error
        	end
       end
   if update(ELCode)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.ELType = i.ELType and d.ELCode = i.ELCode
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change ELCode '
        	goto error
        	end
       end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Craft Capped Basis!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCB] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRCB] ON [dbo].[bPRCB] ([PRCo], [Craft], [ELType], [ELCode]) ON [PRIMARY]
GO
