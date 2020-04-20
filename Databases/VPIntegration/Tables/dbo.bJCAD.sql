CREATE TABLE [dbo].[bJCAD]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[Department] [dbo].[bDept] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btJCADi    Script Date: 8/28/99 9:37:40 AM ******/
   CREATE trigger [dbo].[btJCADi] on [dbo].[bJCAD] for INSERT as
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int
   
   /*-------------------------------------------------------------- 
    *
    *  Insert trigger for JCAD
    *  Created By: SAE 12/18/96
    *  Modified By: SAE 12/18/96
    *  
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
   
   /* Validate Department */
   
   select @validcnt = count(*) from bJCDM r JOIN inserted i ON
    i.JCCo = r.JCCo
    and i.Department = r.Department
   
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Department is Invalid '
      goto error
      end
   
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot insert into JCAD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btJCADu    Script Date: 8/28/99 9:37:40 AM ******/
   CREATE trigger [dbo].[btJCADu] on [dbo].[bJCAD] for UPDATE as 
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int
   
   /*-------------------------------------------------------------- 
    *
    *  Update trigger for JCAD
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
   
   /* check for changes to Department */
   if update(Department)
      begin
      select @errmsg = 'Cannot change Department'
      goto error
      end
   
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update JCAD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJCAD] ON [dbo].[bJCAD] ([JCCo], [AllocCode], [Department]) ON [PRIMARY]
GO
