CREATE TABLE [dbo].[bJCDC]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[OpenWIPAcct] [dbo].[bGLAcct] NULL,
[ClosedExpAcct] [dbo].[bGLAcct] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJCDC] ON [dbo].[bJCDC] ([JCCo], [Department], [PhaseGroup], [CostType]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btJCDCd    Script Date: 8/28/99 9:37:43 AM ******/
   CREATE      trigger [dbo].[btJCDCd] on [dbo].[bJCDC] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   /*-----------------------------------------------------------------
    *	This trigger logs deletion in bJCDC (JC Dept Cost Types)
    *	to bHQMA.
    * Created by  : CMW 07/30/02
    * Modified by : GF 10/16/2002 - Added Department and cost type to audit strings
    *
    *
    *-----------------------------------------------------------------
    */
   declare  @errno   int, @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* Audit insert */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bJCDC',
   	'JC Co#: ' + convert(char(3), d.JCCo) + ' Department: ' + d.Department + ' Cost Type: ' + convert(char(3),d.CostType),
   	d.JCCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, bJCCO
   	where d.JCCo=bJCCO.JCCo and bJCCO.AuditDepts='Y'
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btJCDCi    Script Date: 8/28/99 9:37:43 AM ******/
   CREATE      trigger [dbo].[btJCDCi] on [dbo].[bJCDC] for INSERT as
   

declare @errmsg varchar(255), @validcnt int
   /*-----------------------------------------------------------------
    * Created by  : CMW 07/30/02
    * Modified by : GF 10/16/2002 - added cost type to audit insert
    *
    *	This trigger logs insertion in bJCDC (JC Dept Cost Types)
    *	to bHQMA.
    *-----------------------------------------------------------------
    */
   declare  @errno   int, @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- Audit insert 
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bJCDC',  
   	'JC Co#: ' + convert(char(3), i.JCCo) + ' Department: ' + i.Department + ' Cost Type: ' + convert(char(3),i.CostType),
   	i.JCCo, 'A', null, null, null, getdate(), SUSER_SNAME()
   	from inserted i join bJCCO j on j.JCCo = i.JCCo
   	where i.JCCo = j.JCCo and j.AuditDepts = 'Y'
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCDCu    Script Date: 8/28/99 9:37:43 AM ******/
   CREATE      trigger [dbo].[btJCDCu] on [dbo].[bJCDC] for UPDATE as
   

declare @errmsg varchar(255), @validcnt int
   /*-----------------------------------------------------------------
    * Created by  : CMW 07/30/02
    * Modified by : GF 10/16/2002 - Added Department and cost type to audit strings
    *
    *	This trigger logs update of bJCDC (JC Dept Cost Types)
    *	to bHQMA.
    *-----------------------------------------------------------------
    */
   declare  @errno   int, @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for key changes
   
   /* Audit insert */
   IF UPDATE(GLCo)
   BEGIN
       INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bJCDC',
   	'JC Co#: ' + convert(char(3), i.JCCo) + ' Department: ' + i.Department + ' Cost Type: ' + convert(char(3),i.CostType),
   	i.JCCo, 'C', 'GL Company: ', convert(char(3),d.GLCo), convert(char(3),i.GLCo), getdate(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo AND d.Department=i.Department and d.CostType=i.CostType
       JOIN bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditDepts = 'Y'
       WHERE isnull(d.GLCo,0) <> isnull(i.GLCo,0)
   END
   
   IF UPDATE(OpenWIPAcct)
   BEGIN
       INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bJCDC',
   	'JC Co#: ' + convert(char(3), i.JCCo) + ' Department: ' + i.Department + ' Cost Type: ' + convert(char(3),i.CostType),
   	i.JCCo, 'C', 'Open WIP Acct: ', d.OpenWIPAcct, i.OpenWIPAcct, getdate(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo AND d.Department=i.Department and d.CostType=i.CostType
       JOIN bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditDepts = 'Y'
       WHERE isnull(d.OpenWIPAcct,'') <> isnull(i.OpenWIPAcct,'')
   END
   
   IF UPDATE(ClosedExpAcct)
   BEGIN
       INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bJCDC',
   	'JC Co#: ' + convert(char(3), i.JCCo) + ' Department: ' + i.Department + ' Cost Type: ' + convert(char(3),i.CostType),
   	i.JCCo, 'C', 'Closed Exp Acct: ', d.ClosedExpAcct, i.ClosedExpAcct, getdate(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo AND d.Department=i.Department and d.CostType=i.CostType
       JOIN bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditDepts = 'Y'
       WHERE isnull(d.ClosedExpAcct,'') <> isnull(i.ClosedExpAcct,'')
   END
   
   
   
   
   
  
 



GO
