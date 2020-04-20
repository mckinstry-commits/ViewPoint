CREATE TABLE [dbo].[bJCAJ]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[Job] [dbo].[bJob] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btJCAJi    Script Date: 8/28/99 9:37:40 AM ******/
   CREATE trigger [dbo].[btJCAJi] on [dbo].[bJCAJ] for INSERT as 
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int
   
   /*-------------------------------------------------------------- 
    *
    *  Insert trigger for JCAJ
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
      select @errmsg = 'Allocation Code is Invalid '
      goto error
      end
   
   /* Validate Job */
   
   select @validcnt = count(*) from bJCJM r JOIN inserted i ON
    i.JCCo = r.JCCo
    and i.Job = r.Job
   
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Job is Invalid '
      goto error
      end
   
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot insert into JCAJ'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btJCAJu    Script Date: 8/28/99 9:37:40 AM ******/
   CREATE trigger [dbo].[btJCAJu] on [dbo].[bJCAJ] for UPDATE as 
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int
   
   /*-------------------------------------------------------------- 
    *
    *  Update trigger for JCAJ
    *  Created By: SAE 12/18/96
    *  Modified By: SAE 12/18/96
    *
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
    set nocount on
   
   
   
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
   
   /* check for changes to Job */
   if update(Job)
      begin
      select @errmsg = 'Cannot change Job'
      goto error
      end
   
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update JCAJ'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJCAJ] ON [dbo].[bJCAJ] ([JCCo], [AllocCode], [Job]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
