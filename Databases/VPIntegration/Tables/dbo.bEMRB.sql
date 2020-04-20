CREATE TABLE [dbo].[bEMRB]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[Trans] [dbo].[bTrans] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Equipment] [dbo].[bEquip] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[Amount] [dbo].[bDollar] NULL,
[GLCo] [dbo].[bCompany] NULL,
[Account] [dbo].[bGLAcct] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMRBi    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE  trigger [dbo].[btEMRBi] on [dbo].[bEMRB] for insert as
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMRB
    *  Created By:  bc  04/17/99
    *  Modified by: GF 08/01/2003 - issue #21933 - speed improvements
    *				  TV 02/11/04 - 23061 added isnulls
    *
    *--------------------------------------------------------------*/
   
   -------  basic declares for SQL Triggers -------
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @rcode int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   -- Validate EMCo
   select @validcnt = count(*) from bEMCO r with (nolock) JOIN inserted i ON i.EMCo = r.EMCo
   if @validcnt <> @numrows
      begin
      select @errmsg = 'EM Company is Invalid '
      goto error
      end
   
   -- Validate EM Group
   select @validcnt = count(*) from bHQGP r with (nolock) JOIN inserted i ON i.EMGroup = r.Grp
   if @validcnt <> @numrows
      begin
      select @errmsg = 'EM Group is Invalid '
      goto error
      end
   
   -- Validate RevBdownCode
   select @validcnt = count(*) from bEMRT r with (nolock) 
   JOIN inserted i ON i.EMGroup = r.EMGroup and i.RevBdownCode = r.RevBdownCode
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Revenue Breakdown Code is Invalid '
      goto error
      end
   
   -- Validate Equipment
   select @validcnt = count(*) from bEMEM r with (nolock) 
   JOIN inserted i ON i.EMCo = r.EMCo and i.Equipment = r.Equipment
   select @nullcnt = count(*) from inserted i where i.Equipment is null
   if @validcnt + @nullcnt <> @numrows
      begin
      select @errmsg = 'Equipment is Invalid '
      goto error
      end
   
   -- Validate RevCode
   select @validcnt = count(*) from bEMRC r with (nolock) 
   JOIN inserted i ON i.EMGroup = r.EMGroup and i.RevCode = r.RevCode
   select @nullcnt = count(*) from inserted i where i.RevCode is null
   if @validcnt + @nullcnt <> @numrows
      begin
      select @errmsg = 'Revenue Code is Invalid '
      goto error
      end
   
   
   
   return
   
   
   
   
   
   
   
   
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMRB'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMRBu    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE   trigger [dbo].[btEMRBu] on [dbo].[bEMRB] for update as
   
   

/*--------------------------------------------------------------
    *
    *  Update trigger for EMRB
    *  Created By:  bc  04/17/99
    *  Modified by:  TV 02/11/04 - 23061 added isnulls
    *
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
           @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   if update(EMCo) or update(Mth) or update(Trans)
     begin
     select @validcnt = count(*) from inserted i join deleted d on i.EMCo = d.EMCo and i.Mth = d.Mth and i.Trans = d.Trans
     if @validcnt <> @numrows
       begin
       select @errmsg = 'Cannot change key fields '
       goto error
       end
     end
   
   
   
   /* Validate Equipment */
   if update(Equipment)
   begin
   select @validcnt = count(*) from bEMEM r JOIN inserted i ON i.EMCo = r.EMCo and i.Equipment = r.Equipment
   select @nullcnt = count(*) from inserted i where i.Equipment is null
   if @validcnt + @nullcnt <> @numrows
      begin
      select @errmsg = 'Equipment is Invalid '
      goto error
      end
   end
   
   /* Validate RevCode */
   if update(RevCode)
   begin
   select @validcnt = count(*) from bEMRC r JOIN inserted i ON i.EMGroup = r.EMGroup and i.RevCode = r.RevCode
   select @nullcnt = count(*) from inserted i where i.RevCode is null
   if @validcnt + @nullcnt <> @numrows
      begin
      select @errmsg = 'Revenue Code is Invalid '
      goto error
      end
   end
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot update into EMRB'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMRB] ON [dbo].[bEMRB] ([EMCo], [Mth], [Trans], [EMGroup], [RevBdownCode]) ON [PRIMARY]
GO
