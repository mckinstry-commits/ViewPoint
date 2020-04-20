CREATE TABLE [dbo].[bEMDM]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Reviewer] [char] (3) COLLATE Latin1_General_BIN NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[DepreciationAcct] [dbo].[bGLAcct] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[LaborFixedRateAcct] [dbo].[bGLAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PurchReviewer] [char] (3) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ReviewerGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDMd    Script Date: 8/28/99 9:37:17 AM ******/
   
    CREATE   trigger [dbo].[btEMDMd] on [dbo].[bEMDM] for DELETE as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  Delete trigger for EMDM
     *  Created By: bc 11/18/98
     *  Modified by:  bc 03/04/99
     *					TV 02/11/04 - 23061 added isnulls
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
    declare @emgroup int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   /* get the emgroup for this company */
    select @emgroup = EMGroup
    from HQCO h, deleted d
    where h.HQCo = d.EMCo
   
   
   /* check for cost types from grid */
    if exists(select * from bEMDG e join deleted d on e.EMCo = d.EMCo and e.Department = d.Department and e.EMGroup = @emgroup)
     begin
     select @errmsg = 'Department Cost Type records exist '
     goto error
     end
   
   /* check for revenue codes from grid */
    if exists(select * from bEMDR e join deleted d on e.EMCo = d.EMCo and e.Department = d.Department and e.EMGroup = @emgroup)
      begin
      select @errmsg = 'Department Revenue Codes exist '
      goto error
      end
   
   /* check for cost codes from grid */
    if exists(select * from bEMDO e join deleted d on e.EMCo = d.EMCo and e.Department = d.Department and e.EMGroup = @emgroup)
      begin
      select @errmsg = 'Department Cost Codes exist '
      goto error
      end
   
   /* check for revenue breakdown codes from grid */
    if exists(select * from bEMDB e join deleted d on e.EMCo = d.EMCo and e.Department = d.Department and e.EMGroup = @emgroup)
      begin
      select @errmsg = 'Department Revenue Breakdown Codes exist '
      goto error
      end
   
   /* No Delete if equipment is assigned to Department */
    if exists(select * from bEMEM e join deleted d on e.EMCo = d.EMCo and e.Department = d.Department)
      begin
      select @errmsg = 'Department is in use by the equipment master '
      goto error
      end
   
   
   /* Audit inserts */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMDG','EM Company: ' + convert(char(3), d.EMCo) + ' Department: ' + d.Department,
              d.EMCo, 'D',	null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, EMCO e
       where d.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y'
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMDM'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMDMi    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE  trigger [dbo].[btEMDMi] on [dbo].[bEMDM] for insert as
   
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMDM
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
   
   /* Validate Reviewer */
   select @validcnt = count(*) from bHQRV r JOIN inserted i ON i.Reviewer = r.Reviewer
   select @nullcnt = count(*) from inserted i Where i.Reviewer is null
   if @validcnt + @nullcnt <> @numrows
      begin
      select @errmsg = 'Reviewer is Invalid '
      goto error
      end
   
   /* Validate GLCo */
   select @validcnt = count(*) from bGLCO r JOIN inserted i ON i.GLCo = r.GLCo
   if @validcnt <> @numrows
      begin
      select @errmsg = 'GL Company is Invalid '
      goto error
      end
   
   /* Validate DepreciationAcct */
   select @validcnt = count(*) from bGLAC r JOIN inserted i ON i.GLCo = r.GLCo and i.DepreciationAcct = r.GLAcct
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Depreciation Account is Invalid '
      goto error
      end
   
   
   /* Audit inserts */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMDM','EM Company: ' + convert(char(3), i.EMCo) + ' Department: ' + i.Department,
              i.EMCo, 'A',	null, null, null, getdate(), SUSER_SNAME()
   	from inserted i, EMCO e
       where i.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y'
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMDM'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMDMu    Script Date: 8/28/99 9:37:17 AM ******/
   CREATE   trigger [dbo].[btEMDMu] on [dbo].[bEMDM] for update as
   
    

/*--------------------------------------------------------------
     *
     *  update trigger for EMDM
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
     if update(EMCo)  or update(Department)
         begin
         select @validcnt = count(*) from inserted i
         JOIN deleted d ON d.EMCo = i.EMCo and i.Department = d.Department
         if @validcnt <> @numrows
             begin
             select @errmsg = 'Primary key fields may not be changed'
             GoTo error
             End
         End
   
    /* Validate GLCo */
    if update(GLCo)
    begin
    select @validcnt = count(*) from bGLCO r JOIN inserted i ON  i.GLCo = r.GLCo
    if @validcnt <> @numrows
       begin
       select @errmsg = 'GL Company is Invalid '
       goto error
       end
    end
   
    /* Validate Depreciation Account */
    if update(DepreciationAcct)
    begin
    select @validcnt = count(*) from bGLAC r JOIN inserted i ON  i.GLCo = r.GLCo and i.DepreciationAcct = r.GLAcct
    if @validcnt <> @numrows
       begin
       select @errmsg = 'Depreciation Account is Invalid '
       goto error
       end
    end
   
   
    /* Audit inserts */
    if not exists (select * from inserted i, EMCO e where i.EMCo = e.EMCo and e.AuditDepartmentGL = 'Y')
    	return
   
    insert into bHQMA select 'bEMDM', 'EM Company: ' + convert(char(3),i.EMCo)	+ ' Department: ' + i.Department,
       i.EMCo, 'C', 'GLCo', convert(char(3),d.GLCo), convert(char(3),i.GLCo), getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and d.Department = i.Department and e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
    insert into bHQMA select 'bEMDM', 'EM Company: ' + convert(char(3),i.EMCo)	+ ' Department: ' + i.Department,
       i.EMCo, 'C', 'DepreciationAcct', d.DepreciationAcct, i.DepreciationAcct, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and d.Department = i.Department and e.EMCo = i.EMCo and e.AuditDepartmentGL = 'Y'
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMDM'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMDM] ON [dbo].[bEMDM] ([EMCo], [Department]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMDM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
