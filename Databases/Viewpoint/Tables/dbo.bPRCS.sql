CREATE TABLE [dbo].[bPRCS]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Seq] [tinyint] NOT NULL,
[ELType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ELCode] [dbo].[bEDLCode] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRCS] ON [dbo].[bPRCS] ([PRCo], [Craft], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCS] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRCSd    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE  trigger [dbo].[btPRCSd] on [dbo].[bPRCS] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/10/00
    *	Modified:	EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   /* Audit Craft Capped Codes deletions */
   insert into dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCS', 'Craft: ' + d.Craft + ' Seq:' + convert(varchar(3),d.Seq),
       d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d join dbo.PRCO p with (nolock) on d.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Craft Capped Sequence!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRCSi    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE      trigger [dbo].[btPRCSi] on [dbo].[bPRCS] for INSERT as
   

/*-----------------------------------------------------------------
    *   	Created by: EN 4/10/00
    *	Modified by: MV 1/28/02 added calc category validation
    *				 EN 4/4/02 fixed error where column name ELCode was being used mistakenly for ELType
    *				EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *											and corrected old syle joins
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
   
   /*validate DLCode's CalCategory.*/
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.ELType = c.DLType and i.ELCode = c.DLCode
       where i.PRCo = c.PRCo and i.ELType = 'L' and c.CalcCategory not in ('C', 'A') --issue 16786 changed ELCode to ELType
   if @validcnt <> 0
   	begin
   	select @errmsg = 'DLCode calculation category must be C or A. '
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRCS', 'Craft: ' + i.Craft + ' Seq:' + convert(varchar(3),i.Seq),
       i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME()
       from inserted i join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Craft Capped Sequence!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRCSu    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE   trigger [dbo].[btPRCSu] on [dbo].[bPRCS] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/10/00
    *                EN 10/09/00 - Checking for key changes incorrectly
    *  Modified by: MV 1/28/02 added calc category validation
    *				EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *											and corrected old syle joins
    *
    * Cannot change primary key.
    * Validates and inserts HQ Master Audit entry.
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
   if update(Seq)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Craft = i.Craft and d.Seq = i.Seq
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Sequence '
        	goto error
        	end
       end
   
   /* validate ELType */
   select @validcnt = count(*) from inserted where ELType = 'E' or ELType = 'L'
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Earn/Liab Code '
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
       where i.PRCo = c.PRCo and i.ELType = 'L' and c.CalcCategory not in ('C', 'A') 
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Liab Code calculation category must be C or A. '
   	goto error
   	end
   
   /* Insert records into HQMA for changes made to audited fields */
   if exists(select * from inserted i join PRCO a on i.PRCo = a.PRCo and a.AuditCraftClass = 'Y')
       begin
       insert into dbo.bHQMA select 'bPRCS',
      	    'Craft: ' + i.Craft + ' Seq:' + convert(varchar(3),i.Seq),
           i.PRCo, 'C', 'ELType', d.ELType, i.ELType, getdate(), SUSER_SNAME()
          	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Seq = d.Seq
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where i.ELType <> d.ELType and p.AuditCraftClass = 'Y'
       insert into dbo.bHQMA select 'bPRCS',
       	'Craft: ' + i.Craft + ' Seq:' + convert(varchar(3),i.Seq),
       	i.PRCo, 'C', 'ELCode', convert(varchar(10),d.ELCode), convert(varchar(10),i.ELCode),
       	getdate(), SUSER_SNAME()	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.Craft = d.Craft and i.Seq = d.Seq
           join dbo.PRCO p with (nolock) on i.PRCo = p.PRCo
           where i.ELCode <> d.ELCode and p.AuditCraftClass = 'Y'
       end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Craft Capped Sequence!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
