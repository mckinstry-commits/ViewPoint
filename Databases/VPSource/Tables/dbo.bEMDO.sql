CREATE TABLE [dbo].[bEMDO]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[CostCode] [dbo].[bCostCode] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[ExcludePR] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMDO_ExcludePR] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMDO] ADD
CONSTRAINT [CK_bEMDO_ExcludePR] CHECK (([ExcludePR]='N' OR [ExcludePR]='Y'))
ALTER TABLE [dbo].[bEMDO] ADD
CONSTRAINT [FK_bEMDO_bEMCC_CostCode] FOREIGN KEY ([EMGroup], [CostCode]) REFERENCES [dbo].[bEMCC] ([EMGroup], [CostCode])
ALTER TABLE [dbo].[bEMDO] ADD
CONSTRAINT [FK_bEMDO_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
ALTER TABLE [dbo].[bEMDO] ADD
CONSTRAINT [FK_bEMDO_bEMDM_Department] FOREIGN KEY ([EMCo], [Department]) REFERENCES [dbo].[bEMDM] ([EMCo], [Department])
ALTER TABLE [dbo].[bEMDO] ADD
CONSTRAINT [FK_bEMDO_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDOd    Script Date: 8/28/99 9:37:17 AM ******/
   
   CREATE   trigger [dbo].[btEMDOd] on [dbo].[bEMDO] for delete as
   

/*--------------------------------------------------------------
    *
    *  Delete trigger for EMDO
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
   	select 'bEMDO','EM Company: ' + convert(char(3), d.EMCo) + ' EMGroup: ' + convert(varchar(3),d.EMGroup) + ' Department: ' +
              d.Department + ' CostCode: ' + d.CostCode,
              d.EMCo, 'D',	null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, EMCO e
       where d.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y'
   
   return
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMDO'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btEMDOi] on [dbo].[bEMDO] for insert as
   
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMDO
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
   	select 'bEMDO','EM Company: ' + convert(char(3), i.EMCo) + ' EM Group: ' + convert(varchar(3),i.EMGroup) +
              ' Department: ' + i.Department + ' CostCode: ' + i.CostCode,
              i.EMCo, 'A',	null, null, null, getdate(), SUSER_SNAME()
   	from inserted i, EMCO e
       where i.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y'
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMDO'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMDOu    Script Date: 8/28/99 9:37:17 AM ******/
   CREATE    trigger [dbo].[btEMDOu] on [dbo].[bEMDO] for update as
   
    

/*--------------------------------------------------------------
     *  update trigger for EMDO
     *  Created By:  bc  04/14/99
     *  Modified by: kb 2/11/2 - issue #11997
     *				  TV 02/11/04 - 23061 added isnulls
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
     if update(EMCo) or Update(EMGroup) or update(Department) or update(CostCode)
         begin
         select @validcnt = count(*) from inserted i
         JOIN deleted d ON d.EMCo = i.EMCo and d.EMGroup=i.EMGroup and i.Department = d.Department and i.CostCode = d.CostCode
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
   
    insert into bHQMA select 'bEMDO', 'EM Company: ' + convert(char(3),i.EMCo)	+ ' EMGroup: ' + convert(char(3),d.EMGroup) +
       ' Department: ' + i.Department + ' CostCode: ' + i.CostCode,
       i.EMCo, 'C', 'GLCo', convert(char(3),d.GLCo), convert(char(3),i.GLCo), getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.EMGroup = d.EMGroup and d.Department = i.Department and
       d.CostCode = i.CostCode and d.GLCo <> i.GLCo and e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
   
    insert into bHQMA select 'bEMDO', 'EM Company: ' + convert(char(3),i.EMCo)	+ ' EMGroup: ' + convert(char(3),d.EMGroup) +
       ' Department: ' + i.Department + ' CostCode: ' + i.CostCode,
       i.EMCo, 'C', 'GLAcct', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.EMGroup = d.EMGroup and d.Department = i.Department and
       d.CostCode = i.CostCode and d.GLAcct <> i.GLAcct and e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
   --issue #11997
    insert into bHQMA select 'bEMDO', 'EM Company: ' + convert(char(3),i.EMCo)	+ ' EMGroup: ' + convert(char(3),d.EMGroup) +
       ' Department: ' + i.Department + ' CostCode: ' + i.CostCode,
       i.EMCo, 'C', 'ExcludePR', d.ExcludePR, i.ExcludePR, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.EMGroup = d.EMGroup and d.Department = i.Department and
       d.CostCode = i.CostCode and d.ExcludePR <> i.ExcludePR and e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMDO'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMDO] ON [dbo].[bEMDO] ([EMCo], [Department], [CostCode], [EMGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMDO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMDO].[ExcludePR]'
GO
