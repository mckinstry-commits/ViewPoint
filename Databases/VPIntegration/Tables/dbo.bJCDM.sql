CREATE TABLE [dbo].[bJCDM]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[OpenRevAcct] [dbo].[bGLAcct] NULL,
[ClosedRevAcct] [dbo].[bGLAcct] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btJCDMd    Script Date: 8/28/99 9:37:44 AM ******/
   CREATE    trigger [dbo].[btJCDMd] on [dbo].[bJCDM] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   /*-----------------------------------------------------------------
    *	This trigger rejects delete in bJCDM (JC Dept Master)
    *	 if the following error condition exists:
    *  	Modified By DanF 06/21/2005 - Issue 28749 - Added check for Phase Overrides.
    *
    *		entries exist in JCAD
    *		entries exist in JCCI
    *		entries exist in JCCM
    *		entries exist in JCDC
    *		entries exist in JCDE
    *		entries exist in JCDL
    *		(Future checks AR,JB,PM,???)
    */
   
   declare  @errno   int, @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   begin
   /* check JCAD */
   if exists(select top 1 1 from deleted
   	join dbo.bJCAD
   	on bJCAD.JCCo = deleted.JCCo and bJCAD.Department = deleted.Department)
   	begin
   	  select @errmsg = 'Entries exist in JC Allocation Departments'
   	  goto error
   	end
   /* check JCCI */
   if exists(select top 1 1 from deleted
   	join dbo.bJCCI
   	on bJCCI.JCCo = deleted.JCCo and bJCCI.Department = deleted.Department)
   	begin
   	  select @errmsg = 'Entries exist in JC Contract Items'
   	  goto error
   	end
   /* check JCCM */
   if exists(select top 1 1 from deleted
   	join dbo.bJCCM
   	on bJCCM.JCCo = deleted.JCCo and bJCCM.Department = deleted.Department)
   	begin
   	  select @errmsg = 'Entries exist in JC Contract Master'
   	  goto error
   	end
   /* check JCDC */
   if exists(select top 1 1 from deleted
   	join dbo.bJCDC
   	on bJCDC.JCCo = deleted.JCCo and bJCDC.Department = deleted.Department)
   	begin
   	  select @errmsg = 'Entries exist in JC Department Cost Types'
   	  goto error
   	end
   /* check JCDE */
   if exists(select top 1 1 from deleted
   	join dbo.bJCDE
   	on bJCDE.JCCo = deleted.JCCo and bJCDE.Department = deleted.Department)
   	begin
   	  select @errmsg = 'Entries exist in JC Department Earnings Types'
   	  goto error
   	end
   /* check JCDL */
   if exists(select top 1 1 from deleted
   	join dbo.bJCDL
   	on bJCDL.JCCo = deleted.JCCo and bJCDL.Department = deleted.Department)
   	begin
   	  select @errmsg = 'Entries exist in JC Department Liabilities Types'
   	  goto error
   	end
   /* check JCDO */
   if exists(select top 1 1 from deleted d
   	join dbo.bJCDO o
   	on o.JCCo = d.JCCo and o.Department = d.Department)
   	begin
   	  select @errmsg = 'Entries exist in JC Department Phase Overrides'
   	  goto error
   	end
   
   /* Audit inserts */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bJCDM',  'JC Dept: ' + deleted.Department, deleted.JCCo, 'D',
   		null, null, null, getdate(), SUSER_SNAME() from deleted, bJCCO
   		where deleted.JCCo=bJCCO.JCCo and bJCCO.AuditDepts='Y'
   return
   error:
       select @errmsg = @errmsg + ' - cannot delete Department!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   end

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btJCDMi    Script Date: 8/28/99 9:37:44 AM ******/
   CREATE  trigger [dbo].[btJCDMi] on [dbo].[bJCDM] for INSERT as
   

declare @errmsg varchar(255), @validcnt int, @msgstart char(12)
   /*-----------------------------------------------------------------
    *	This trigger rejects insert in bJCDM (JC Department Master)
    *	 if the following error condition exists:
    *
    *		invalid JCCo vs JCCO.JCCo
    *		invalid GLCo vs JCCO.GLCo
    *		OpenRevAcct not Header, not Inactive, or not (null or 'J')
    *		invalid OpenRevAcct vs GLCo.GLAcct
    *		ClosedRevAcct not Header, not Inactive, or not (null or 'J')
    *		invalid ClosedRevAcct vs GLCo.GLAcct
    *		(Future checks AR,JB,PM,???)
    *
    *   Modified: 08/20/99 bc  replace the 'in (null,'J')' statement when checking for valid SubType becuase it fails in 7.0
    */
   declare  @errno int, @numrows int, @nullcnt int, @glco bCompany,
   @closedrevacct bGLAcct, @openrevacct bGLAcct
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   if @numrows > 1
   	select @msgstart = 'At least 1 '
   else
   	select @msgstart = ''
   begin
   /* validate JC Company */
   select @validcnt = count(*) from bJCCO j, inserted i where j.JCCo = i.JCCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid JC Company'
   	goto error
   	end
   /* validate GL Company */
   select @validcnt = count(*) from bJCCO j, inserted i where j.JCCo = i.JCCo and
   j.GLCo = i.GLCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid GL Company'
   	goto error
   	end
   /* validate OpenRevAcct */
   /* check if header */
   select @nullcnt = count(*) from inserted i where i.OpenRevAcct is null
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenRevAcct and (g.AcctType<>'H' and g.AcctType <> 'M')
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'GL Account is a Heading or Memo account'
   	goto error
   	end
   /* check if inactive  */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenRevAcct and g.Active='Y'
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'GL Account is Inactive'
   	goto error
   	end
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenRevAcct and (g.SubType is null or g.SubType = 'J')
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'GL Account is not a Job Subledger type'
   	goto error
   	end
   /* check if account exists */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenRevAcct
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'GL Account is missing'
   	goto error
   	end
   /* validate ClosedRevAcct */
   /* check if header */
   select @nullcnt = count(*) from inserted i where i.ClosedRevAcct is null
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedRevAcct and (AcctType<>'H' and AcctType <> 'M')
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'GL Account is a Heading or Memo account'
   	goto error
   	end
   /* check if inactive  */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedRevAcct and g.Active='Y'
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'GL Account is Inactive'
   	goto error
   	end
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedRevAcct and (g.SubType is null or g.SubType = 'J')
   if (@validcnt+@nullcnt) <>  @numrows
   	begin
   	select @errmsg = @msgstart + 'GL Account is not a Job Subledger type'
   	goto error
   	end
   /* check if account exists */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedRevAcct
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'GL Account is missing'
   	goto error
   	end
   /* Audit inserts */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bJCDM',  'JC Dept: ' + inserted.Department, inserted.JCCo, 'A',
   		null, null, null, getdate(), SUSER_SNAME() from inserted, bJCCO
   		where inserted.JCCo=bJCCO.JCCo and bJCCO.AuditDepts='Y'
   return
   error:
       select @errmsg = @errmsg + ' - cannot insert Department!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   end

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btJCDMu    Script Date: 8/28/99 9:37:44 AM ******/
   CREATE  trigger [dbo].[btJCDMu] on [dbo].[bJCDM] for update as
   

declare @errmsg varchar(255), @validcnt int, @msgstart char(12)
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bJCDM (JC Department Master)
    *	 if the following error condition exists:
    *		cannot revise JCCo (key)
    *		cannot revise Department (key)
    *		invalid JCCo vs JCCO.JCCo
    *		invalid GLCo vs JCCO.GLCo
    *		OpenRevAcct not Header, not Inactive, or not (null or 'J')
    *		invalid OpenRevAcct vs GLCo.GLAcct
    *		ClosedRevAcct not Header, not Inactive, or not (null or 'J')
    *		invalid ClosedRevAcct vs GLCo.GLAcct
    *		(Future checks AR,JB,PM,???)
    *
    *   Modified: 08/20/99 bc  replace the 'in (null,'J')' statement when checking for valid SubType becuase it fails in 7.0
    */
   declare  @errno int, @numrows int, @nullcnt int, @glco bCompany,
   @closedrevacct bGLAcct, @openrevacct bGLAcct
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   if @numrows > 1
   	select @msgstart = 'At least 1 '
   else
   	select @msgstart = ''
   begin
    if update(JCCo) or update(Department)
     begin
        select @validcnt = count(*) from deleted d, inserted i where d.JCCo = i.JCCo
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Cannot change JC Company Number'
   		goto error
   		end
        select @validcnt = count(*) from deleted d, inserted i
   	where d.JCCo = i.JCCo and d.Department = i.Department
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Cannot change Department'
   		goto error
   		end
     end
   /* validate GL Company */
   select @validcnt = count(*) from bJCCO j, inserted i where j.JCCo = i.JCCo and
   j.GLCo = i.GLCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid GL Company'
   	goto error
   	end
   /* validate OpenRevAcct */
   /* check if header */
   select @nullcnt = count(*) from inserted i where i.OpenRevAcct is null
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenRevAcct and (AcctType <> 'H' and AcctType <> 'M')
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'Open GL Account is a Heading or Memo account'
   	goto error
   	end
   /* check if inactive  */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenRevAcct and g.Active = 'Y'
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'Open GL Account is Inactive'
   	goto error
   	end
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenRevAcct and (g.SubType is null or g.SubType = 'J')
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'Open GL Account is not a Job Subledger type'
   	goto error
   	end
   /* check if account exists */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenRevAcct
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'Open GL Account is missing'
   	goto error
   	end
   /* validate ClosedRevAcct */
   /* check if header */
   select @nullcnt = count(*) from inserted i where i.ClosedRevAcct is null
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedRevAcct and (AcctType <> 'H' and AcctType <> 'M')
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'Closed GL Account is a Heading account'
   	goto error
   	end
   /* check if inactive  */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedRevAcct and g.Active = 'Y'
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'Closed GL Account is Inactive'
   	goto error
   	end
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedRevAcct and (g.SubType is null or g.SubType = 'J')
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'Closed GL Account is not a Job Subledger type'
   	goto error
   	end
   /* check if account exists */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedRevAcct
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'GL Account is missing'
   	goto error
   	end
   /*----------------------------*/
   /*
    * if auditing is not on for any of the companies then return (skip audit)
    */
   select @validcnt = count(*) from inserted i, bJCCO j where i.JCCo=j.JCCo and
   	AuditDepts='Y'
   if @validcnt=0 return
   /* Audit inserts */
   /* Description audit into HQMA */
   insert into bHQMA select  'bJCDM', 'Department: ' + i.Department, i.JCCo, 'C',
   	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bJCCO j
   	where i.JCCo = j.JCCo and j.AuditDepts='Y'
   	and i.JCCo = d.JCCo and i.Department=d.Department and i.Description <> d.Description
   /* GLCo audit into HQMA */
   insert into bHQMA select  'bJCDM', 'Department: ' + i.Department, i.JCCo, 'C',
   	'GLCo', convert(char(4),d.GLCo), convert(char(4),i.GLCo), getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bJCCO j
   	where i.JCCo = j.JCCo and j.AuditDepts='Y'
   	and i.JCCo = d.JCCo and i.Department=d.Department and i.GLCo <> d.GLCo
   /* OpenRevAcct audit into HQMA */
   insert into bHQMA select  'bJCDM', 'Department: ' + i.Department, i.JCCo, 'C',
   	'OpenRevAcct', d.OpenRevAcct, i.OpenRevAcct, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bJCCO j
   	where i.JCCo = j.JCCo and j.AuditDepts='Y'
   	and i.JCCo = d.JCCo and i.Department=d.Department and i.OpenRevAcct <> d.OpenRevAcct
   /* ClosedRevAcct audit into HQMA */
   insert into bHQMA select  'bJCDM', 'Department: ' + i.Department, i.JCCo, 'C',
   	'ClosedRevAcct', d.ClosedRevAcct, i.ClosedRevAcct, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bJCCO j
   	where i.JCCo = j.JCCo and j.AuditDepts='Y'
   	and i.JCCo = d.JCCo and i.Department=d.Department and i.ClosedRevAcct <> d.ClosedRevAcct
   /*----------*/
   return
   error:
       select @errmsg = @errmsg + ' - cannot insert Department!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   end

GO
CREATE UNIQUE CLUSTERED INDEX [biJCDM] ON [dbo].[bJCDM] ([JCCo], [Department]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCDM] ([KeyID]) ON [PRIMARY]
GO
