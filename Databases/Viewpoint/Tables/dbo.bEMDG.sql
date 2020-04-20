CREATE TABLE [dbo].[bEMDG]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[CostType] [dbo].[bEMCType] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMDG] ON [dbo].[bEMDG] ([EMCo], [Department], [EMGroup], [CostType]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDGd    Script Date: 8/28/99 9:37:17 AM ******/
   
   CREATE   trigger [dbo].[btEMDGd] on [dbo].[bEMDG] for delete as
   

/*--------------------------------------------------------------
    *
    *  Delete trigger for EMDG
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
   	select 'bEMDG','EM Company: ' + convert(char(3), d.EMCo) + ' EMGroup: ' + convert(varchar(3),d.EMGroup) + ' Department: ' +
              d.Department + ' CostType: ' + convert(varchar(5),d.CostType),
              d.EMCo, 'D',	null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, EMCO e
       where d.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y'
   
   return
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMDG'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDGi    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE   trigger [dbo].[btEMDGi] on [dbo].[bEMDG] for insert as
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMDG
    *  Created By:  bc  04/17/99
    *  Modified by: GF 01/28/2003 - allow null GLAcct
    *
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int, @nullcnt int, @rcode int,
   		@errmsg varchar(255), @audit bYN
           
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   -- Validate EMCo
   select @validcnt = count(*) from bEMCO r JOIN inserted i ON i.EMCo = r.EMCo
   if @validcnt <> @numrows
      begin
      select @errmsg = 'EM Company is Invalid '
      goto error
      end
   
   -- Validate EM Group
   select @validcnt = count(*) from bHQGP r JOIN inserted i ON i.EMGroup = r.Grp
   if @validcnt <> @numrows
      begin
      select @errmsg = 'EM Group is Invalid '
      goto error
      end
   
   -- Validate Department
   select @validcnt = count(*) from bEMDM r JOIN inserted i ON i.EMCo = r.EMCo and i.Department = r.Department
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Department is Invalid '
      goto error
      end
   
   -- Validate Cost Type
   select @validcnt = count(*) from bEMCT r JOIN inserted i ON i.EMGroup = r.EMGroup and i.CostType = r.CostType
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Cost Type Code is Invalid '
      goto error
      end
   
   -- Validate GLCo
   select @validcnt = count(*) from bGLCO r JOIN inserted i ON i.GLCo = r.GLCo
   if @validcnt <> @numrows
      begin
      select @errmsg = 'GL Company is Invalid '
      goto error
      end
   
   /* Validate GL Acct
   select @validcnt = count(*) from bGLAC r JOIN inserted i ON i.GLCo = r.GLCo and i.GLAcct = r.GLAcct
   if @validcnt <> @numrows
      begin
      select @errmsg = 'GL Account is Invalid '
      goto error
      end*/
   
   -- Validate GL Acct
   select @validcnt = count(*) from bGLAC r JOIN inserted i ON i.GLCo = r.GLCo and i.GLAcct = r.GLAcct
   select @nullcnt = count(*) from inserted where GLAcct is null
   IF @validcnt + @nullcnt <> @numrows
      begin
      select @errmsg = 'GL Account is Invalid '
      goto error
      end
   
   
   -- Audit inserts
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMDG','EM Company: ' + convert(char(3), i.EMCo) + ' EM Group: ' + convert(varchar(3),i.EMGroup) +
              ' Department: ' + i.Department + ' CostType: ' + convert(varchar(3),i.CostType),
              i.EMCo, 'A',	null, null, null, getdate(), SUSER_SNAME()
   	from inserted i, EMCO e
       where isnull(i.EMCo,'') = isnull(e.EMCo,'') and e.AuditDepartmentGL = 'Y'
   
   
   return
   
   
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMDG'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDGu    Script Date: 8/28/99 9:37:17 AM ******/
   CREATE  trigger [dbo].[btEMDGu] on [dbo].[bEMDG] for update as
    

/*--------------------------------------------------------------
     *
     *  update trigger for EMDG
     *  Created By:  bc  04/14/99
     *  Modified by: GF 01/28/2003 - allow null GLAcct
     *
     *
     *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int, @nullcnt int, @rcode int,
   		@audit bYN, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- see if any fields have changed that is not allowed
     if update(EMCo) or Update(EMGroup) or update(Department) or update(CostType)
         begin
         select @validcnt = count(*) from inserted i
         JOIN deleted d ON d.EMCo = i.EMCo and d.EMGroup=i.EMGroup and i.Department = d.Department and i.CostType = d.CostType
         if @validcnt <> @numrows
             begin
             select @errmsg = 'Primary key fields may not be changed'
             GoTo error
             End
         End
   
   -- Validate GLCo
   if update(GLCo)
   	begin
   	select @validcnt = count(*) from bGLCO r JOIN inserted i ON  i.GLCo = r.GLCo
   	if @validcnt <> @numrows
       	begin
       	select @errmsg = 'GL Company is Invalid '
       	goto error
       	end
   	end
   
   
   -- Validate GLAcct
   if update(GLAcct)
   	begin
   	select @validcnt = count(*) from bGLAC r JOIN inserted i ON i.GLCo = r.GLCo and i.GLAcct = r.GLAcct
   	select @nullcnt = count(*) from inserted where GLAcct is null
   	IF @validcnt + @nullcnt <> @numrows
       	begin
       	select @errmsg = 'GL Account is Invalid '
       	goto error
       	end
   	end
   
   
   -- Audit inserts
    if not exists (select * from inserted i, EMCO e where i.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y')
    	return
   
    insert into bHQMA select 'bEMDG', 'EM Company: ' + convert(char(3),i.EMCo)	+ ' EMGroup: ' + convert(char(3),d.EMGroup) +
       ' Department: ' + i.Department + ' CostType: ' + convert(varchar(5),i.CostType),
       i.EMCo, 'C', 'GLCo', convert(char(3),d.GLCo), convert(char(3),i.GLCo), getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.EMGroup = d.EMGroup and d.Department = i.Department and
       d.CostType = i.CostType and d.GLCo <> i.GLCo and e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
   
    insert into bHQMA select 'bEMDG', 'EM Company: ' + convert(char(3),i.EMCo)	+ ' EMGroup: ' + convert(char(3),d.EMGroup) +
       ' Department: ' + i.Department + ' CostType: ' + convert(varchar(5),i.CostType),
       i.EMCo, 'C', 'GLAcct', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.EMGroup = d.EMGroup and d.Department = i.Department and
       d.CostType = i.CostType and d.GLAcct <> i.GLAcct and e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
   
   
   return
   
   
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMDG'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
