CREATE TABLE [dbo].[bEMUR]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[RulesTable] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NOT NULL,
[JTDorPDFlag] [char] (1) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMURd    Script Date: 8/28/99 9:37:24 AM ******/
   CREATE   trigger [dbo].[btEMURd] on [dbo].[bEMUR] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: bc  08/11/99
    *	MODIFIED By : bc 03/06/01 - added new checks and the cascade delete
    *				 TV 02/11/04 - 23061 added isnulls
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   if exists(select * from EMUE e join deleted d on e.EMCo = d.EMCo and e.RulesTable = d.RulesTable)
     begin
     select @errmsg = 'Rules Table exists in an equipment auto usage template '
     goto error
     end
   
   if exists(select * from EMUC e join deleted d on e.EMCo = d.EMCo and e.RulesTable = d.RulesTable)
     begin
     select @errmsg = 'Rules Table exists in a category auto usage template  '
     goto error
     end
   
   /* cascade delete on the lines in the grid */
   delete bEMUD
   from bEMUD e, deleted d
   where d.EMCo = e.EMCo and d.RulesTable = e.RulesTable
   
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EMUR!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMURu    Script Date: 8/28/99 9:37:24 AM ******/
   CREATE   trigger [dbo].[btEMURu] on [dbo].[bEMUR] for update as
   

declare @errmsg varchar(255), @validcnt int, @numrows int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: bc  08/11/99
    *	MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *						TRL 08134938 changed where set no count is called
    *
    */----------------------------------------------------------------
         select @numrows = @@rowcount
       if @numrows = 0 return
       set nocount on

   
   if update(EMCo) or update(RulesTable)
     begin
     select @validcnt = count(*) from inserted i join deleted d on i.EMCo = d.EMCo and i.RulesTable = d.RulesTable
     if @validcnt <> @numrows
       begin
       select @errmsg = 'Cannot change key fields '
       goto error
       end
     end
   
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMUR!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
   
  
 




GO
CREATE UNIQUE CLUSTERED INDEX [biEMUR] ON [dbo].[bEMUR] ([EMCo], [RulesTable]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMUR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
