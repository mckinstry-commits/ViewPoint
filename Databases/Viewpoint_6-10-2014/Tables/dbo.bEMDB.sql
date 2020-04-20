CREATE TABLE [dbo].[bEMDB]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
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
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDBd    Script Date: 8/28/99 9:37:17 AM ******/
   
   CREATE   trigger [dbo].[btEMDBd] on [dbo].[bEMDB] for delete as
   

/*--------------------------------------------------------------
    *
    *  Delete trigger for EMDB
    *  Created By:  bc  04/15/99
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
   	select 'bEMDB','EM Company: ' + convert(char(3), d.EMCo) + ' EMGroup: ' + convert(varchar(3),d.EMGroup) + ' Department: ' +
              d.Department + ' RevBdownCode: ' + d.RevBdownCode,
              d.EMCo, 'D',	null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, EMCO e
       where d.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y'
   
   return
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMDB'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btEMDBi] on [dbo].[bEMDB] for insert as
   
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMDB
    *  Created By:  bc  04/17/99
    *  Modified by: TV 02/11/04 - 23061 added isnulls
	*				GF 05/05/2013 TFS-49039
    *
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255),
           @validcnt int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   
   
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
   	select 'bEMDB','EM Company: ' + convert(char(3), i.EMCo) + ' EM Group: ' + convert(varchar(3),i.EMGroup) +
              ' Department: ' + i.Department + ' RevBdownCode: ' + i.RevBdownCode,
              i.EMCo, 'A',	null, null, null, getdate(), SUSER_SNAME()
   	from inserted i, EMCO e
       where i.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y'
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMDB'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDBu    Script Date: 8/28/99 9:37:17 AM ******/
   CREATE   trigger [dbo].[btEMDBu] on [dbo].[bEMDB] for update as
   
    

/*--------------------------------------------------------------
     *
     *  update trigger for EMDB
     *  Created By:  bc  04/14/99
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
     if update(EMCo) or Update(EMGroup) or update(Department) or update(RevBdownCode)
         begin
         select @validcnt = count(*) from inserted i
         JOIN deleted d ON d.EMCo = i.EMCo and d.EMGroup=i.EMGroup and i.Department = d.Department and i.RevBdownCode = d.RevBdownCode
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
    select @validcnt = count(*) from bGLAC r JOIN inserted i ON i.GLCo = r.GLCo and i.GLAcct = r.GLAcct
    if @validcnt <> @numrows
       begin
       select @errmsg = 'GL Account is Invalid '
       goto error
       end
    end
   
   
    /* Audit inserts */
    if not exists (select * from inserted i, EMCO e
    	where i.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y')
    	return
   
    insert into bHQMA select 'bEMDB', 'EM Company: ' + convert(char(3),i.EMCo)	+ ' EMGroup: ' + convert(char(3),d.EMGroup) +
       ' Department: ' + i.Department + ' RevBdownCode: ' + i.RevBdownCode,
       i.EMCo, 'C', 'GLCo', convert(char(3),d.GLCo), convert(char(3),i.GLCo), getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.EMGroup = d.EMGroup and d.Department = i.Department and
       d.RevBdownCode = i.RevBdownCode and d.GLCo <> i.GLCo and e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
   
    insert into bHQMA select 'bEMDB', 'EM Company: ' + convert(char(3),i.EMCo)	+ ' EMGroup: ' + convert(char(3),d.EMGroup) +
       ' Department: ' + i.Department + ' RevBdownCode: ' + i.RevBdownCode,
       i.EMCo, 'C', 'GLAcct', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.EMGroup = d.EMGroup and d.Department = i.Department and
       d.RevBdownCode = i.RevBdownCode and d.GLAcct <> i.GLAcct and e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMDB'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMDB] ON [dbo].[bEMDB] ([EMCo], [Department], [EMGroup], [RevBdownCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMDB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMDB] WITH NOCHECK ADD CONSTRAINT [FK_bEMDB_bEMDM_Department] FOREIGN KEY ([EMCo], [Department]) REFERENCES [dbo].[bEMDM] ([EMCo], [Department])
GO
ALTER TABLE [dbo].[bEMDB] WITH NOCHECK ADD CONSTRAINT [FK_bEMDB_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMDB] WITH NOCHECK ADD CONSTRAINT [FK_bEMDB_bEMRT_RevBdownCode] FOREIGN KEY ([EMGroup], [RevBdownCode]) REFERENCES [dbo].[bEMRT] ([EMGroup], [RevBdownCode])
GO
ALTER TABLE [dbo].[bEMDB] NOCHECK CONSTRAINT [FK_bEMDB_bEMDM_Department]
GO
ALTER TABLE [dbo].[bEMDB] NOCHECK CONSTRAINT [FK_bEMDB_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMDB] NOCHECK CONSTRAINT [FK_bEMDB_bEMRT_RevBdownCode]
GO
