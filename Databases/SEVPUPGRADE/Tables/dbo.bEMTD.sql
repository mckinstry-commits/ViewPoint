CREATE TABLE [dbo].[bEMTD]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[RevTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Category] [dbo].[bCat] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Rate] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMTDd    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE  trigger [dbo].[btEMTDd] on [dbo].[bEMTD] for delete as
   
   

/*--------------------------------------------------------------
    *
    *  Delete trigger for EMTD
    *  Created By:  bc  04/17/99
    *  Modified by: bc  04/02/01 - removed deletion validation against EMTF
    *				 TV 02/11/04 - 23061 added isnulls
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
           @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMTD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMTDi    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE  trigger [dbo].[btEMTDi] on [dbo].[bEMTD] for insert as
   
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMTD
    *  Created By:  bc  04/17/99
    *  Modified by: TV 02/11/04 - 23061 added isnulls
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
   
   
   /* Validate EMCo */
   select @validcnt = count(*) from bEMCO r JOIN inserted i ON i.EMCo = r.EMCo
   if @validcnt <> @numrows
      begin
      select @errmsg = 'EM Company is Invalid '
      goto error
      end
   
   /* Validate EM Group */
   select @validcnt = count(*) from bHQGP r JOIN inserted i ON i.EMGroup = r.Grp
   if @validcnt <> @numrows
      begin
      select @errmsg = 'EM Group is Invalid '
      goto error
      end
   
   /* Validate RevTemplate */
   select @validcnt = count(*) from bEMTH r JOIN inserted i ON i.EMCo = r.EMCo and i.RevTemplate = r.RevTemplate
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Revenue template is Invalid '
      goto error
      end
   
   /* Validate Category */
   select @validcnt = count(*) from bEMCM r JOIN inserted i ON i.EMCo = r.EMCo and i.Category = r.Category
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Category is Invalid '
      goto error
      end
   
   /* Validate RevCode */
   select @validcnt = count(*) from bEMRC r JOIN inserted i ON i.EMGroup = r.EMGroup and i.RevCode = r.RevCode
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Revenue Code is Invalid '
      goto error
      end
   
   /* Validate RevBdownCode */
   select @validcnt = count(*) from bEMRT r JOIN inserted i ON i.EMGroup = r.EMGroup and i.RevBdownCode = r.RevBdownCode
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Revenue Breakdown Code is Invalid '
      goto error
      end
   
   if not exists(select * from EMTC r join inserted i on
   i.EMCo = r.EMCo and i.RevTemplate = r.RevTemplate and i.Category = r.Category and i.EMGroup = r.EMGroup and r.RevCode = i.RevCode)
      begin
      select @errmsg = 'Revenue Code is missing in EMRevRateCatgyTemp '
      goto error
      end
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMTD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMTDu    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE   trigger [dbo].[btEMTDu] on [dbo].[bEMTD] for update as
   
   

/*--------------------------------------------------------------
    *
    *  Update trigger for EMTD
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
   
   
   
     /* cannot change key fields */
     if update(EMCo) or Update(EMGroup) or update(RevTemplate) or Update(Category) or Update(RevCode) or Update(RevBdownCode)
         begin
         select @validcnt = count(*)
         from inserted i JOIN deleted d ON d.EMCo = i.EMCo and i.RevTemplate = d.RevTemplate and i.EMGroup = d.EMGroup and
                                           d.Category=i.Category and d.RevCode = i.RevCode and d.RevBdownCode = i.RevBdownCode
         if @validcnt <> @numrows
             begin
             select @errmsg = 'Primary key fields may not be changed'
             GoTo error
             End
         End
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot update into EMTD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMTD] ON [dbo].[bEMTD] ([EMCo], [EMGroup], [RevTemplate], [Category], [RevCode], [RevBdownCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMTD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
