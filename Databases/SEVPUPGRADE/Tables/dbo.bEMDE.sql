CREATE TABLE [dbo].[bEMDE]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[EarnType] [dbo].[bEarnType] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDEd    Script Date: 8/28/99 9:37:17 AM ******/
   
   CREATE   trigger [dbo].[btEMDEd] on [dbo].[bEMDE] for delete as
   

/*--------------------------------------------------------------
    *
    *  Delete trigger for EMDE
    *  Created By:  kb 2/11/2
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
   
   
   /* Audit inserts */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMDE','EM Company: ' + convert(char(3), d.EMCo) + ' Department: ' +
              d.Department + ' EarnType: ' + convert(char(5),d.EarnType),
              d.EMCo, 'D',	null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, EMCO e
       where d.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y'
   
   return
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMDE'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMDEi    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE  trigger [dbo].[btEMDEi] on [dbo].[bEMDE] for insert as
   
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMDE
    *  Created By:  kb 2/11/2
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
   
   /* Validate Department */
   select @validcnt = count(*) from bEMDM r JOIN inserted i ON i.EMCo = r.EMCo and i.Department = r.Department
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Department is Invalid '
      goto error
      end
   
   /* Validate CostCode */
   select @validcnt = count(*) from bHQET r JOIN inserted i ON i.EarnType = r.EarnType
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Liab Type is Invalid '
      goto error
      end
   
   /* Validate GLCo */
   select @validcnt = count(*) from bGLCO r JOIN inserted i ON i.GLCo = r.GLCo
   if @validcnt <> @numrows
      begin
      select @errmsg = 'GL Company is Invalid '
      goto error
      end
   
   /* Validate GL Acct */
   select @validcnt = count(*) from bGLAC r JOIN inserted i ON i.GLCo = r.GLCo and i.GLAcct = r.GLAcct
   if @validcnt <> @numrows
      begin
      select @errmsg = 'GL Account is Invalid '
      goto error
      end
   
   
   /* Audit inserts */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMDE','EM Company: ' + convert(char(3), i.EMCo) +
              ' Department: ' + i.Department + ' EarnType: ' + convert(char(5),i.EarnType),
              i.EMCo, 'A',	null, null, null, getdate(), SUSER_SNAME()
   	from inserted i, EMCO e
       where i.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y'
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMDE'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDEu    Script Date: 8/28/99 9:37:17 AM ******/
   CREATE   trigger [dbo].[btEMDEu] on [dbo].[bEMDE] for update as
   
    

/*--------------------------------------------------------------
     *
     *  update trigger for EMDE
     *  Created By:  kb 2/11/2 - issue #11997
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
   
     /* see if any fields have changed that is not allowed */
     if update(EMCo) or update(Department) or update(EarnType)
         begin
         select @validcnt = count(*) from inserted i
         JOIN deleted d ON d.EMCo = i.EMCo and i.Department = d.Department and i.EarnType = d.EarnType
         if @validcnt <> @numrows
             begin
             select @errmsg = 'Primary key fields may not be changed'
             GoTo error
             End
         End
   
    /* Validate GLCo */
    if update(GLCo)
    begin
    select @validcnt = count(*) from bGLCO r JOIN inserted i ON i.GLCo = r.GLCo
    if @validcnt <> @numrows
       begin
       select @errmsg = 'GL Company is Invalid '
       goto error
       end
    end
   
    /* Validate GLAcct */
    if update(GLAcct)
    begin
    select @validcnt = count(*) from bGLAC r JOIN inserted i ON i.GLCo = r.GLCo and i.GLAcct = r.GLAcct
    if @validcnt <> @numrows
       begin
       select @errmsg = 'GL Account is Invalid '
       goto error
       end
    end
   
   
    /* Audit inserts */
    if not exists (select * from inserted i, EMCO e where i.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y')
    	return
   
    insert into bHQMA select 'bEMDE', 'EM Company: ' +
       ' Department: ' + i.Department + ' EarnType: ' + convert(char(5),i.EarnType),
       i.EMCo, 'C', 'GLCo', convert(char(3),d.GLCo), convert(char(3),i.GLCo), getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and d.Department = i.Department and
       d.EarnType = i.EarnType and d.GLCo <> i.GLCo and e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
   
     insert into bHQMA select 'bEMDE', 'EM Company: ' +
       ' Department: ' + i.Department + ' EarnType: ' + convert(char(5),i.EarnType),
       i.EMCo, 'C', 'GLCo', convert(char(3),d.GLAcct), convert(char(3),i.GLAcct), getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and d.Department = i.Department and
       d.EarnType = i.EarnType and d.GLAcct <> i.GLAcct and e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMDE'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMDE] ON [dbo].[bEMDE] ([EMCo], [Department], [EarnType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMDE] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
