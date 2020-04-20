CREATE TABLE [dbo].[bINLG]
(
[INCo] [dbo].[bCompany] NOT NULL,
[LocGroup] [dbo].[bGroup] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btINLGd] on [dbo].[bINLG] for DELETE as
   

/*--------------------------------------------------------------
    *  Created By: GG 03/06/00
    *  Modified By: GR 7/14/00 - added HQ Auditing
    *
    *  Delete trigger for IN Location Groups
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- check for use in other tables
   if exists(select * from deleted d
           join bINLM l on d.INCo = l.INCo and d.LocGroup = l.LocGroup)
       begin
       select @errmsg = 'Still has assigned Locations'
       goto error
       end
   
   -- HQ Auditing
   insert bHQMA select 'bINLG','INCo:' + convert(varchar(3),d.INCo) + ' LocGroup:' + convert(varchar(3), d.LocGroup),
       d.INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from deleted d
   join bINCO c on d.INCo = c.INCo
   where c.AuditLoc = 'Y'   -- check audit
   
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete IN Location Groups'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btINLGi] on [dbo].[bINLG] for INSERT as
    

/*--------------------------------------------------------------
     * Created By: GG 03/06/00
     * Modified By: GR 07/14/00 - added Master Audit insert
     *
     * Insert trigger for IN Location Group
     *
     *--------------------------------------------------------------*/
    declare @numrows int, @errmsg varchar(255), @validcnt int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
   
    set nocount on
   
   -- validate IN Company
    select @validcnt = count(*) from bINCO c JOIN inserted i on i.INCo = c.INCo
    if @validcnt<>@numrows
        begin
     	select @errmsg = 'Invalid IN Company '
     	goto error
     	end
   
   -- HQ Auditing
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bINLG',' LocGroup: ' + convert(varchar(3), i.LocGroup), i.INCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM inserted i join bINCO c on c.INCo = i.INCo and c.AuditLoc = 'Y'
   
    return
   
    error:
        select @errmsg = @errmsg + ' - cannot insert IN Location Group.'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btINLGu] on [dbo].[bINLG] for UPDATE as
   

/*--------------------------------------------------------------
    *  Created By : GR 7/14/00
    *
    *  Update trigger for IN Location Group
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- verify primary key not changed
   select @validcnt = count(*) from inserted i
   join deleted d on d.INCo = i.INCo and d.LocGroup=i.LocGroup
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Cannot change IN Company/Location Group '
    	goto error
    	end
   
   
   -- HQ Auditing
   if exists(select * from inserted i
       join bINCO a on i.INCo = a.INCo
       where a.AuditLoc = 'Y')
       begin
       insert into bHQMA select 'bINLG', ' LocGroup: ' + convert(varchar(3), i.LocGroup), i.INCo, 'C',
           'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.LocGroup=i.LocGroup
       join bINCO a on a.INCo = i.INCo
    	where isnull(d.Description, '') <> isnull(i.Description, '') and a.AuditLoc = 'Y'
   
       end
   
   return
   
    error:
       select @errmsg = @errmsg + ' - cannot update IN Location Group'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biINLG] ON [dbo].[bINLG] ([INCo], [LocGroup]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINLG] ([KeyID]) ON [PRIMARY]
GO
