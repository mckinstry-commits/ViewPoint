CREATE TABLE [dbo].[bJCDL]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[LiabType] [dbo].[bLiabilityType] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[OpenBurdenAcct] [dbo].[bGLAcct] NULL,
[ClosedBurdenAcct] [dbo].[bGLAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCDLd    Script Date: 8/28/99 9:37:43 AM ******/
   CREATE  trigger [dbo].[btJCDLd] on [dbo].[bJCDL] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   /*-----------------------------------------------------------------
    *	This trigger logs deletion in bJCDL (JC Dept Liabilities)
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
   	select 'bJCDL',  'JC Co#: ' + convert(char(3), deleted.JCCo), deleted.JCCo, 'D',
   		null, null, null, getdate(), SUSER_SNAME() from deleted, bJCCO
   		where deleted.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCDLi    Script Date: 8/28/99 9:37:43 AM ******/
   CREATE  trigger [dbo].[btJCDLi] on [dbo].[bJCDL] for INSERT as
   

declare @errmsg varchar(255), @validcnt int, @msgstart char(12)
   /* Modified By SAE  2/18/97  */
   /*-----------------------------------------------------------------
    *	This trigger rejects insert in bJCDL (JC Department Liab Types)
    *	if any of the following conditions exist:
    *
    *		invalid Department vs JCDM.Department for JCCo
    *		invalid LiabType vs HQLT.LiabType
    *		OpenBurdenAcct not Header, not Inactive, or not (null or 'J')
    *		invalid OpenBurdenAcct vs GLCo.GLAcct
    *		ClosedBurdenAcct not Header, not Inactive, or not (null or 'J')
    *		invalid ClosedBurdenAcct vs GLCo.GLAcct
    */
   declare  @errno int, @numrows int, @nullcnt int, @department bDept, @liabtype bLiabilityType,
   @closedburdenacct bGLAcct, @openburdenacct bGLAcct,
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
   /* validate Liab Type */
   select @validcnt = count(*) from bHQLT l, inserted i where l.LiabType = i.LiabType
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Liability Type'
   	goto error
   	end
   /* validate OpenBurdenAcct */
   select @validcnt=count(*),
   /* check if header */
      @header=IsNull(sum(case g.AcctType when 'H' then 1 when 'M' then 1 else 0 end),0),
   /* check if valid subtype */
      @subtype=IsNull(sum(case when g.SubType IS NULL OR g.SubType='J' then 1 else 0 end),0),
   /* check if inactive  */
      @inactive=IsNull(sum(case g.Active when 'N' then 1 else 0 end),0)
   from bGLAC g JOIN inserted i on g.GLCo=i.GLCo and g.GLAcct=i.OpenBurdenAcct
   select @nullcnt = count(*) from inserted i where i.OpenBurdenAcct is null
   /* check if header */
   if @header <> 0
   	begin
   	select @errmsg = @msgstart + 'OpenBurdenAcct is a Heading or Memo account'
   	goto error
   	end
   /* check if inactive */
   if @inactive <> 0
   	begin
   	select @errmsg = @msgstart + 'OpenBurdenAcct is Inactive'
   	goto error
   	end
   /* check if valid subledger */
   if (@subtype+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'OpenBurdenAcct is not a Job Subledger type'
   	goto error
   	end
   /* check if account exists */
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'OpenBurdenAcct is missing'
   	goto error
   	end
   /* validate ClosedBurdenAcct */
   select @validcnt=count(*),
   /* check if header */
      @header=IsNull(sum(case g.AcctType when 'H' then 1 when 'M' then 1 else 0 end),0),
   /* check if valid subtype */
      @subtype=IsNull(sum(case when g.SubType IS NULL OR g.SubType='J' then 1 else 0 end),0),
   /* check if inactive  */
      @inactive=IsNull(sum(case g.Active when 'N' then 1 else 0 end),0)
   from bGLAC g JOIN inserted i on g.GLCo=i.GLCo and g.GLAcct=i.ClosedBurdenAcct
   select @nullcnt = count(*) from inserted i where i.ClosedBurdenAcct is null
   /* check if header */
   if @header <> 0
   	begin
   	select @errmsg = @msgstart + 'ClosedBurdenAcct is a Heading or Memo account'
   	goto error
   	end
   /* check if inactive */
   if @inactive <> 0
   	begin
   	select @errmsg = @msgstart + 'ClosedBurdenAcct is Inactive'
   	goto error
   	end
   /* check if valid subledger */
   if (@subtype+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'ClosedBurdenAcct is not a Job Subledger type'
   	goto error
   	end
   /* check if account exists */
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'ClosedBurdenAcct is missing'
   	goto error
   	end
   /* Audit inserts */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bJCDL',  'JC LiabType: ' + convert(char(4),inserted.LiabType), inserted.JCCo, 'A',
   		null, null, null, getdate(), SUSER_SNAME() from inserted, bJCCO
   		where inserted.JCCo=bJCCO.JCCo and bJCCO.AuditDepts='Y'
   return
   error:
       select @errmsg = @errmsg + ' - cannot insert Liability Type!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   end
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCDLu    Script Date: 8/28/99 9:37:44 AM ******/
   CREATE  trigger [dbo].[btJCDLu] on [dbo].[bJCDL] for update as
   

declare @errmsg varchar(255), @validcnt int, @msgstart char(12)
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bJCDE (JC Dept Liab Types)
    *	 if any of the following conditions exist:
    *		cannot revise Department (key)
    *		cannot revise LiabType (key)
    *		OpenBurdenAcct not Header, not Inactive, or not (null or 'J')
    *		invalid OpenBurdenAcct vs GLCo.GLAcct
    *		ClosedBurdenAcct not Header, not Inactive, or not (null or 'J')
    *		invalid ClosedBurdenAcct vs GLCo.GLAcct
    *-----------------------------------------------------------------*/
   declare  @errno int, @numrows int, @nullcnt int, @glco bCompany,
   @closedburdenacct bGLAcct, @openburdenacct bGLAcct
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   if @numrows > 1
   	select @msgstart = 'At least 1 '
   else
   	select @msgstart = ''
   begin
    if update(Department) or update(LiabType)
     begin
        select @validcnt = count(*) from deleted d, inserted i
       	where d.JCCo = i.JCCo and d.Department = i.Department
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Cannot change Department'
   		goto error
   		end
        select @validcnt = count(*) from deleted d, inserted i
   	where d.JCCo = i.JCCo and d.LiabType = i.LiabType
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Cannot change Liab Type'
   		goto error
   		end
     end
   /* validate OpenBurdenAcct */
   /* check if header */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenBurdenAcct and (AcctType='H' or AcctType='M')
   if @validcnt <> 0
   	begin
   	select @errmsg = @msgstart + 'GL Account is a Heading account'
   	goto error
   	end
   /* check if inactive  */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenBurdenAcct and g.Active='N'
   if @validcnt <> 0
   	begin
   	select @errmsg = @msgstart + 'GL Account is Inactive'
   	goto error
   	end
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenBurdenAcct and g.SubType not in (null,'J')
   if @validcnt <> 0
   	begin
   	select @errmsg = @msgstart + 'GL Account is not a Job Subledger type'
   	goto error
   	end
   /* check if account exists */
   select @nullcnt = count(*) from inserted i where i.OpenBurdenAcct is null
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.OpenBurdenAcct
   if (@validcnt+@nullcnt) <> @numrows
   	begin
   	select @errmsg = @msgstart + 'GL Account is missing'
   	goto error
   	end
   /* validate ClosedBurdenAcct */
   /* check if header */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedBurdenAcct and (AcctType='H' or AcctType='M')
   if @validcnt <> 0
   	begin
   	select @errmsg = @msgstart + 'GL Account is a Heading account'
   	goto error
   	end
   /* check if inactive  */
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedBurdenAcct and g.Active='N'
   if @validcnt <> 0
   	begin
   	select @errmsg = @msgstart + 'GL Account is Inactive'
   	goto error
   	end
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedBurdenAcct and g.SubType not in (null,'J')
   if @validcnt <> 0
   	begin
   	select @errmsg = @msgstart + 'GL Account is not a Job Subledger type'
   	goto error
   	end
   /* check if account exists */
   select @nullcnt = count(*) from inserted i where i.ClosedBurdenAcct is null
   select @validcnt = count(*) from bGLAC g, inserted i
   where  g.GLCo=i.GLCo and g.GLAcct=i.ClosedBurdenAcct
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
   /* Department and LiabType audits not necessary per Jim 12/10/96 */
   /* GLCo audit into HQMA */
   insert into bHQMA select  'bJCDL', 'Dept: ' + i.Department + ' LiabType: ' +
   	convert(char(3),i.LiabType), i.JCCo, 'C',
   	'GLCo', convert(char(4),d.GLCo), convert(char(4),i.GLCo),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bJCCO j
   	where i.JCCo = j.JCCo and j.AuditDepts='Y'
   	and i.JCCo = d.JCCo and i.Department=d.Department and i.GLCo <> d.GLCo
   /* OpenBurdenAcct audit into HQMA */
   insert into bHQMA select  'bJCDL', 'Dept: ' + i.Department + ' LiabType: ' +
   	convert(char(3),i.LiabType), i.JCCo, 'C',
   	'OpenBurdenAcct', d.OpenBurdenAcct, i.OpenBurdenAcct,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bJCCO j
   	where i.JCCo = j.JCCo and j.AuditDepts='Y'
   	and i.JCCo = d.JCCo and i.Department=d.Department and
   	i.OpenBurdenAcct <> d.OpenBurdenAcct
   /* ClosedBurdenAcct audit into HQMA */
   insert into bHQMA select  'bJCDL', 'Dept: ' + i.Department + ' LiabType: ' +
   	convert(char(3),i.LiabType), i.JCCo, 'C',
   	'ClosedBurdenAcct', d.ClosedBurdenAcct, i.ClosedBurdenAcct,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bJCCO j
   	where i.JCCo = j.JCCo and j.AuditDepts='Y'
   	and i.JCCo = d.JCCo and i.Department=d.Department and
   	i.ClosedBurdenAcct <> d.ClosedBurdenAcct
   /*----------*/
   return
   error:
       select @errmsg = @errmsg + ' - cannot insert Liability Type!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   end
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJCDL] ON [dbo].[bJCDL] ([JCCo], [Department], [LiabType]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCDL] ([KeyID]) ON [PRIMARY]
GO
