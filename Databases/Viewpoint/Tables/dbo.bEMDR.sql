CREATE TABLE [dbo].[bEMDR]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMDR] ON [dbo].[bEMDR] ([EMCo], [Department], [EMGroup], [RevCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMDR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDRd    Script Date: 8/28/99 9:37:17 AM ******/
   
   CREATE   trigger [dbo].[btEMDRd] on [dbo].[bEMDR] for delete as
   

/*--------------------------------------------------------------
    *
    *  Delete trigger for EMDR
    *  Created By:  bc  04/15/99
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
   
   
   /* Audit inserts */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMDR','EM Company: ' + convert(char(3), d.EMCo) + ' EMGroup: ' + convert(varchar(3),d.EMGroup) + ' Department: ' +
              d.Department + ' RevCode: ' + d.RevCode,
              d.EMCo, 'D',	null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, EMCO e
       where d.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y'
   
   return
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMDR'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMDRi    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE  trigger [dbo].[btEMDRi] on [dbo].[bEMDR] for insert as
   
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMDR
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
   
   /* Validate Department */
   select @validcnt = count(*) from bEMDM r JOIN inserted i ON i.EMCo = r.EMCo and i.Department = r.Department
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Department is Invalid '
      goto error
      end
   
   /* Validate RevBdownCode */
   select @validcnt = count(*) from bEMRC r JOIN inserted i ON i.EMGroup = r.EMGroup and i.RevCode = r.RevCode
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Revenue Code is Invalid '
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
   	select 'bEMDR','EM Company: ' + convert(char(3), i.EMCo) + ' EM Group: ' + convert(varchar(3),i.EMGroup) +
              ' Department: ' + i.Department + ' RevCode: ' + i.RevCode,
              i.EMCo, 'A',	null, null, null, getdate(), SUSER_SNAME()
   	from inserted i, EMCO e
       where i.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y'
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMDR'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDRu    Script Date: 8/28/99 9:37:17 AM ******/
   CREATE   trigger [dbo].[btEMDRu] on [dbo].[bEMDR] for update as
   
    

/*--------------------------------------------------------------
     *
     *  update trigger for EMDR
     *  Created By:  bc  04/14/99
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
   
     /* see if any fields have changed that is not allowed */
     if update(EMCo) or Update(EMGroup) or update(Department) or update(RevCode)
         begin
         select @validcnt = count(*) from inserted i
         JOIN deleted d ON d.EMCo = i.EMCo and d.EMGroup=i.EMGroup and i.Department = d.Department and i.RevCode = d.RevCode
         if @validcnt <> @numrows
             begin
             select @errmsg = 'Primary key fields may not be changed'
             GoTo error
             End
         End
   
    /* Validate GLCo */
    if update(GLCo)
    begin
    select @validcnt = count(*) from bGLCo r JOIN inserted i ON i.GLCo = r.GLCo
    if @validcnt <> @numrows
       begin
       select @errmsg = 'GL Company is Invalid '
       goto error
       end
    end
   
    /* Validate GLAcct */
    if update(GLAcct)
    begin
    select @validcnt = count(*) from bGLAC r JOIN inserted i ON  i.GLCo = r.GLCo and i.GLAcct = r.GLAcct
    if @validcnt <> @numrows
       begin
       select @errmsg = 'GL Account is Invalid '
       goto error
       end
    end
   
   
    /* Audit inserts */
    if not exists (select * from inserted i, EMCO e where i.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y')
    	return
   
    insert into bHQMA select 'bEMDR', 'EM Company: ' + convert(char(3),i.EMCo)	+ ' EMGroup: ' + convert(char(3),d.EMGroup) +
       ' Department: ' + i.Department + ' RevCode: ' + i.RevCode,
       i.EMCo, 'C', 'GLCo', convert(char(3),d.GLCo), convert(char(3),i.GLCo), getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.EMGroup = d.EMGroup and d.Department = i.Department and
       d.RevCode = i.RevCode and d.GLCo <> i.GLCo and e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
   
    insert into bHQMA select 'bEMDR', 'EM Company: ' + convert(char(3),i.EMCo) + ' EMGroup: ' + convert(char(3),d.EMGroup) +
       ' Department: ' + i.Department + ' RevCode: ' + i.RevCode,
       i.EMCo, 'C', 'GLAcct', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.EMGroup = d.EMGroup and d.Department = i.Department and
       d.RevCode = i.RevCode and d.GLAcct <> i.GLAcct and  e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMDR'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
  
 



GO
