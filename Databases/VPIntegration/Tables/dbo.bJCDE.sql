CREATE TABLE [dbo].[bJCDE]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[EarnType] [dbo].[bEarnType] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[OpenLaborAcct] [dbo].[bGLAcct] NULL,
[ClosedLaborAcct] [dbo].[bGLAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCDEd    Script Date: 8/28/99 9:37:43 AM ******/
   CREATE  trigger [dbo].[btJCDEd] on [dbo].[bJCDE] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   /*-----------------------------------------------------------------
    *	This trigger logs deletion in bJCDE (JC Dept Earnings Types)
    *	to bHQMA.
    *-----------------------------------------------------------------
    */
   declare  @errno   int, @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* Audit insert */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bJCDE',  'JC Co#: ' + convert(char(3), deleted.JCCo), deleted.JCCo, 'D',
   		null, null, null, getdate(), SUSER_SNAME() from deleted, bJCCO
   		where deleted.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCDEi    Script Date: 8/28/99 9:37:43 AM ******/
   CREATE  trigger [dbo].[btJCDEi] on [dbo].[bJCDE] for INSERT as
   

declare @errmsg varchar(255), @validcnt int, @msgstart char(12)
   /*-----------------------------------------------------------------
    *	This trigger rejects insert in bJCDE (JC Department Earning Types)
    *	if any of the following conditions exist:
    *
    *		invalid Department vs JCDM.Department for JCCo
    *		invalid EarnType vs HQET.EarnType
    *		OpenLaborAcct not Header, not Inactive, or not (null or 'J')
    *		invalid OpenLaborAcct vs GLCo.GLAcct
    *		ClosedLaborAcct not Header, not Inactive, or not (null or 'J')
    *		invalid ClosedLaborAcct vs GLCo.GLAcct
    */
   declare  @errno int, @numrows int, @nullcnt int, @dept bDept, @et bEarnType,
   @closedlaboracct bGLAcct, @openlaboracct bGLAcct,
   @header int, @subtype int,@inactive int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   if @numrows > 1
   	select @msgstart = 'At least 1 '
   else
   	select @msgstart = ''
   begin
   /* validate Department */
   select @validcnt = count(*) from bJCDM j, inserted i where i.JCCo = j.JCCo and
   i.Department = j.Department
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Department'
   	goto error
   	end
   /* validate Earn Type */
   select @validcnt = count(*) from bHQET e, inserted i where e.EarnType = i.EarnType
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Earn Type'
   	goto error
   	end
   /* validate OpenLaborAcct */
   select @validcnt=count(*),
   /* check if header */
      @header=IsNull(sum(case g.AcctType when 'H' then 1 when 'M' then 1 else 0 end),0),
   /* check if valid subtype */
      @subtype=IsNull(sum(case when g.SubType IS NULL OR g.SubType='J' then 1 else 0 end),0),
   /* check if inactive  */
      @inactive=IsNull(sum(case g.Active when 'N' then 1 else 0 end),0)
   from bGLAC g JOIN inserted i on g.GLCo=i.GLCo and g.GLAcct=i.OpenLaborAcct
   select @nullcnt = count(*) from inserted i where i.OpenLaborAcct is null
   /* check if header */
   if @header <> 0
   	begin
   	select @errmsg = @msgstart + 'OpenLaborAcct is a Heading or Memo account'
   	goto error
   	end
   /* check if inactive */
   if @inactive <> 0
   	begin
   	select @errmsg = @msgstart + 'OpenLaborAcct is Inactive'
   	goto error
   	end
   /* check if valid subledger */
   if (@subtype+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'OpenLaborAcct is not a Job Subledger type'
   	goto error
   	end
   /* check if account exists */
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'OpenLaborAcct is missing'
   	goto error
   	end
   /* validate ClosedLaborAcct */
   select @validcnt=count(*),
   /* check if header */
      @header=IsNull(sum(case g.AcctType when 'H' then 1 when 'M' then 1 else 0 end),0),
   /* check if valid subtype */
      @subtype=IsNull(sum(case when g.SubType IS NULL OR g.SubType='J' then 1 else 0 end),0),
   /* check if inactive  */
      @inactive=IsNull(sum(case g.Active when 'N' then 1 else 0 end),0)
   from bGLAC g JOIN inserted i on g.GLCo=i.GLCo and g.GLAcct=i.ClosedLaborAcct
   select @nullcnt = count(*) from inserted i where i.ClosedLaborAcct is null
   /* check if header */
   if @header <> 0
   	begin
   	select @errmsg = @msgstart + 'ClosedLaborAcct is a Heading or Memo account'
   	goto error
   	end
   /* check if inactive */
   if @inactive <> 0
   	begin
   	select @errmsg = @msgstart + 'ClosedLaborAcct is Inactive'
   	goto error
   	end
   /* check if valid subledger */
   if (@subtype+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'ClosedLaborAcct is not a Job Subledger type'
   	goto error
   	end
   /* check if account exists */
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'ClosedLaborAcct is missing'
   	goto error
   	end
   /* Audit inserts */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bJCDE',  'JC EarnType: ' + convert(char(4),inserted.EarnType), inserted.JCCo, 'A',
   		null, null, null, getdate(), SUSER_SNAME() from inserted, bJCCO
   		where inserted.JCCo=bJCCO.JCCo and bJCCO.AuditDepts='Y'
   return
   error:
       select @errmsg = @errmsg + ' - cannot insert Earn Type!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   end
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCDEu    Script Date: 8/28/99 9:37:43 AM ******/
   CREATE  trigger [dbo].[btJCDEu] on [dbo].[bJCDE] for update as
   

declare @errmsg varchar(255), @validcnt int, @msgstart char(12)
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bJCDE (JC Department Earn Types)
    *	 if any of the following conditions exist:
    *		cannot revise Department (key)
    *		cannot revise EarnType (key)
    *		OpenLaborAcct not Header, not Inactive, or not (null or 'J')
    *		invalid OpenLaborAcct vs GLCo.GLAcct
    *		ClosedLaborAcct not Header, not Inactive, or not (null or 'J')
    *		invalid ClosedLaborAcct vs GLCo.GLAcct
    *-----------------------------------------------------------------*/
   declare  @errno int, @numrows int, @nullcnt int, @glco bCompany,
   @closedlaboracct bGLAcct, @openlaboracct bGLAcct
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   if @numrows > 1
   	select @msgstart = 'At least 1 '
   else
   	select @msgstart = ''
   begin
    if update(Department) or update(EarnType)
     begin
        select @validcnt = count(*) from deleted d, inserted i
       	where d.JCCo = i.JCCo and d.Department = i.Department
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Cannot change Department'
   		goto error
   		end
        select @validcnt = count(*) from deleted d, inserted i
   	where d.JCCo = i.JCCo and d.EarnType = i.EarnType
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Cannot change Earn Type'
   		goto error
   		end
     end
   /* validate OpenLaborAcct */
   /* check if header */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenLaborAcct and (AcctType='H' or AcctType = 'M')
   if @validcnt <> 0
   	begin
   	select @errmsg = @msgstart + 'GL Account is a Heading or Memo account'
   	goto error
   	end
   /* check if inactive  */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenLaborAcct and g.Active='N'
   if @validcnt <> 0
   	begin
   	select @errmsg = @msgstart + 'GL Account is Inactive'
   	goto error
   	end
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenLaborAcct and g.SubType not in (null,'J')
   if @validcnt <> 0
   	begin
   	select @errmsg = @msgstart + 'GL Account is not a Job Subledger type'
   	goto error
   	end
   /* check if account exists */
   select @nullcnt = count(*) from inserted i where i.OpenLaborAcct is null
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenLaborAcct
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'GL Account is missing'
   	goto error
   	end
   /* validate ClosedLaborAcct */
   /* check if header */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedLaborAcct and (AcctType='H' or AcctType = 'M')
   if @validcnt <> 0
   	begin
   	select @errmsg = @msgstart + 'GL Account is a Heading or Memo account'
   	goto error
   	end
   /* check if inactive  */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedLaborAcct and g.Active='N'
   if @validcnt <> 0
   	begin
   	select @errmsg = @msgstart + 'GL Account is Inactive'
   	goto error
   	end
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedLaborAcct and g.SubType not in (null,'J')
   if @validcnt <> 0
   	begin
   	select @errmsg = @msgstart + 'GL Account is not a Job Subledger type'
   	goto error
   	end
   select @nullcnt = count(*) from inserted i where i.ClosedLaborAcct is null
   /* check if account exists */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedLaborAcct
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
   /* Department or EarnType audits not necessary per Jim 12/10/96 */
   /* GLCo audit into HQMA */
   insert into bHQMA select  'bJCDE', 'Dept: ' + i.Department + ' EarnType: ' +
   	convert(char(3),i.EarnType), i.JCCo, 'C',
   	'GLCo', convert(char(4),d.GLCo), convert(char(4),i.GLCo),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bJCCO j
   	where i.JCCo = j.JCCo and j.AuditDepts='Y'
   	and i.JCCo = d.JCCo and i.Department=d.Department and i.GLCo <> d.GLCo
   /* OpenLaborAcct audit into HQMA */
   insert into bHQMA select  'bJCDE', 'Dept: ' + i.Department + ' EarnType: ' +
   	convert(char(3),i.EarnType), i.JCCo, 'C',
   	'OpenLaborAcct', d.OpenLaborAcct, i.OpenLaborAcct,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bJCCO j
   	where i.JCCo = j.JCCo and j.AuditDepts='Y'
   	and i.JCCo = d.JCCo and i.Department=d.Department and
   	i.OpenLaborAcct <> d.OpenLaborAcct
   /* ClosedLaborAcct audit into HQMA */
   insert into bHQMA select  'bJCDE', 'Dept: ' + i.Department + ' EarnType: ' +
   	convert(char(3),i.EarnType), i.JCCo, 'C',
   	'ClosedLaborAcct', d.ClosedLaborAcct, i.ClosedLaborAcct,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bJCCO j
   	where i.JCCo = j.JCCo and j.AuditDepts='Y'
   	and i.JCCo = d.JCCo and i.Department=d.Department and
   	i.ClosedLaborAcct <> d.ClosedLaborAcct
   /*----------*/
   return
   error:
       select @errmsg = @errmsg + ' - cannot insert Earn Type!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   end
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJCDE] ON [dbo].[bJCDE] ([JCCo], [Department], [EarnType]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCDE] ([KeyID]) ON [PRIMARY]
GO
