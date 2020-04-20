CREATE TABLE [dbo].[bJCAT]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[PhaseGroup] [tinyint] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJCAT] ON [dbo].[bJCAT] ([JCCo], [AllocCode], [PhaseGroup], [CostType]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btJCATi    Script Date: 8/28/99 9:37:40 AM ******/
   
    CREATE trigger [dbo].[btJCATi] on [dbo].[bJCAT] for INSERT as
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int
   
    /*--------------------------------------------------------------
     *
     *  Insert trigger for JCAT
     *  Created By: SAE 12/18/96
     *  Modified By: SAE 12/18/96
     *
     *
     *--------------------------------------------------------------*/
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
    /* Validate AllocCode */
   
    select @validcnt = count(*) from bJCAC r JOIN inserted i ON
     i.JCCo = r.JCCo
     and i.AllocCode = r.AllocCode
   
    if @validcnt <> @numrows
       begin
       select @errmsg = 'AllocCode is Invalid '
   
       goto error
       end
   
    /* Validate CostType */
   
    select @validcnt = count(*) from bJCCT r JOIN inserted i ON
     i.PhaseGroup = r.PhaseGroup
     and i.CostType = r.CostType
   
    if @validcnt <> @numrows
       begin
       select @errmsg = 'CostType is Invalid '
       goto error
       end
   
   
    return
   
    error:
       select @errmsg = @errmsg + ' - cannot insert into JCAT'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btJCATu    Script Date: 8/28/99 9:37:40 AM ******/
   CREATE trigger [dbo].[btJCATu] on [dbo].[bJCAT] for UPDATE as 
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int
   
   /*-------------------------------------------------------------- 
    *
    *  Update trigger for JCAT
    *  Created By: SAE 12/18/96
    *  Modified By: SAE 12/18/96
    *
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
    set nocount on
   
   /* Validate AllocCode */
   
   
   /* check for changes to JCCo */
   if update(JCCo)
      begin
      select @errmsg = 'Cannot change JCCo'
      goto error
      end
   
   /* check for changes to AllocCode */
   if update(AllocCode)
      begin
      select @errmsg = 'Cannot change AllocCode'
      goto error
      end
   
   /* check for changes to PhaseGroup */
   if update(PhaseGroup)
      begin
      select @errmsg = 'Cannot change PhaseGroup'
      goto error
      end
   
   /* check for changes to CostType */
   if update(CostType)
      begin
      select @errmsg = 'Cannot change CostType'
      goto error
      end
   
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update JCAT'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
