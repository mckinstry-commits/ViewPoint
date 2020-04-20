CREATE TABLE [dbo].[bINLO]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[CostMethod] [tinyint] NULL,
[RecType] [tinyint] NULL,
[GLCo] [dbo].[bCompany] NULL,
[InvGLAcct] [dbo].[bGLAcct] NULL,
[AdjGLAcct] [dbo].[bGLAcct] NULL,
[CostGLAcct] [dbo].[bGLAcct] NULL,
[CostVarGLAcct] [dbo].[bGLAcct] NULL,
[MiscGLAcct] [dbo].[bGLAcct] NULL,
[TaxGLAcct] [dbo].[bGLAcct] NULL,
[CostProdGLAcct] [dbo].[bGLAcct] NULL,
[ValProdGLAcct] [dbo].[bGLAcct] NULL,
[ProdQtyGLAcct] [dbo].[bGLAcct] NULL,
[CustSalesGLAcct] [dbo].[bGLAcct] NULL,
[CustQtyGLAcct] [dbo].[bGLAcct] NULL,
[CustHaulRevEquipGLAcct] [dbo].[bGLAcct] NULL,
[CustHaulExpEquipGLAcct] [dbo].[bGLAcct] NULL,
[CustHaulRevOutGLAcct] [dbo].[bGLAcct] NULL,
[CustHaulExpOutGLAcct] [dbo].[bGLAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[CustMatlExpGLAcct] [dbo].[bGLAcct] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btINLOd] on [dbo].[bINLO] for DELETE as
   

/*--------------------------------------------------------------
    *  Created By: GR 7/18/00
    *  Modified:
    *
    *  Delete trigger for IN Location Category Override
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- HQ Auditing
   insert bHQMA select 'bINLO','INCo:' + convert(varchar(3),d.INCo) + ' Loc:' + d.Loc + ' Category:' + d.Category,
       d.INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from deleted d
   join bINCO c on d.INCo = c.INCo
   where c.AuditLoc = 'Y'   -- check audit
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete IN Location Category Override'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btINLOi] on [dbo].[bINLO] for INSERT as
   

/*--------------------------------------------------------------
    * Created By: GR 7/18/00
    *
    *
    *
    * Insert trigger for IN Location Category Override
    * Adds to master audit table
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate IN Company
   select @validcnt = count(*) from bINCO c JOIN inserted i on i.INCo = c.INCo
   if @validcnt<>@numrows
       begin
    	select @errmsg = 'Invalid IN Company '
    	goto error
    	end
   
   --validate Location
   select @validcnt = count(*) from bINLM m join inserted i on i.INCo = m.INCo and i.Loc = m.Loc
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Location'
       goto error
       end
   
   --validate category
   select @validcnt = count(*) from bHQMC c join inserted i on i.MatlGroup = c.MatlGroup and i.Category = c.Category
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Category'
       goto error
       end
   
   -- HQ Auditing
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bINLO',' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM inserted i join bINCO c on c.INCo = i.INCo and c.AuditLoc = 'Y'
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert IN Location Category Override.'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE    trigger [dbo].[btINLOu] on [dbo].[bINLO] for UPDATE as
   

/*--------------------------------------------------------------
    *  Created By : GR 7/18/00
    *				GG 02/14/05 - #19185 - audit new column - CustMatlExpGLAcct
    *
    *  Update trigger for IN Location Company Override
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- verify primary key not changed
   select @validcnt = count(*) from inserted i
   join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup = i.MatlGroup
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Cannot change IN Location or Category '
    	goto error
    	end
   
   
   -- HQ Auditing
   if exists(select * from inserted i
       		join dbo.bINCO a (nolock) on i.INCo = a.INCo
       		where a.AuditLoc = 'Y')
       begin
   	if update(CostMethod)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'CostMethod', convert(varchar(6), d.CostMethod), convert(varchar(6), i.CostMethod), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CostMethod, 0) <> isnull(i.CostMethod, 0) and a.AuditLoc = 'Y'
   		end
   	if update(RecType)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           'RecType', convert(varchar(6), d.RecType), convert(varchar(6), i.RecType), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.RecType, 0) <> isnull(i.RecType, 0) and a.AuditLoc = 'Y'
   		end
   	if update(GLCo)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'GLCo', convert(varchar(6), d.GLCo), convert(varchar(6), i.GLCo), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.GLCo, 0) <> isnull(i.GLCo, 0) and a.AuditLoc = 'Y'
   		end
   	if update(InvGLAcct)
   		begin
   		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'InvGLAcct', d.InvGLAcct, i.InvGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvGLAcct, '') <> isnull(i.InvGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(AdjGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'AdjGLAcct', d.AdjGLAcct, i.AdjGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.AdjGLAcct, '') <> isnull(i.AdjGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CostGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'CostGLAcct', d.CostGLAcct, i.CostGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CostGLAcct, '') <> isnull(i.CostGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CostVarGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'CostVarGLAcct', d.CostVarGLAcct, i.CostVarGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CostVarGLAcct, '') <> isnull(i.CostVarGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(MiscGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'MiscGLAcct', d.MiscGLAcct, i.MiscGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.MiscGLAcct, '') <> isnull(i.MiscGLAcct, '') and a.AuditLoc = 'Y'
   		end
    	if update(TaxGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'TaxGLAcct', d.TaxGLAcct, i.TaxGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.TaxGLAcct, '') <> isnull(i.TaxGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CostProdGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'CostProdGLAcct', d.CostProdGLAcct, i.CostProdGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CostProdGLAcct, '') <> isnull(i.CostProdGLAcct, '') and a.AuditLoc = 'Y'
   		end 
   	if update(ValProdGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'ValProdGLAcct', d.ValProdGLAcct, i.ValProdGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.ValProdGLAcct, '') <> isnull(i.ValProdGLAcct, '') and a.AuditLoc = 'Y'
   		end 
   	if update(ProdQtyGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'ProdQtyGLAcct', d.ProdQtyGLAcct, i.ProdQtyGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.ProdQtyGLAcct, '') <> isnull(i.ProdQtyGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustSalesGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'CustSalesGLAcct', d.CustSalesGLAcct, i.CustSalesGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustSalesGLAcct, '') <> isnull(i.CustSalesGLAcct, '') and a.AuditLoc = 'Y'
   		end 
   	if update(CustQtyGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'CustQtyGLAcct', d.CustQtyGLAcct, i.CustQtyGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustQtyGLAcct, '') <> isnull(i.CustQtyGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustHaulRevEquipGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'CustHaulRevEquipGLAcct', d.CustHaulRevEquipGLAcct, i.CustHaulRevEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustHaulRevEquipGLAcct, '') <> isnull(i.CustHaulRevEquipGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustHaulExpEquipGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'CustHaulExpEquipGLAcct', d.CustHaulExpEquipGLAcct, i.CustHaulExpEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustHaulExpEquipGLAcct, '') <> isnull(i.CustHaulExpEquipGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustHaulRevOutGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'CustHaulRevOutGLAcct', d.CustHaulRevOutGLAcct, i.CustHaulRevOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustHaulRevOutGLAcct, '') <> isnull(i.CustHaulRevOutGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustHaulExpOutGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'CustHaulExpOutGLAcct', d.CustHaulExpOutGLAcct, i.CustHaulExpOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustHaulExpOutGLAcct, '') <> isnull(i.CustHaulExpOutGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(CustMatlExpGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLO', ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'CustMatlExpGLAcct', d.CustMatlExpGLAcct, i.CustMatlExpGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.CustMatlExpGLAcct, '') <> isnull(i.CustMatlExpGLAcct, '') and a.AuditLoc = 'Y'
   		end
       end
   
   return
   
    error:
       select @errmsg = @errmsg + ' - cannot update IN Location Category Override'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biINLO] ON [dbo].[bINLO] ([INCo], [Loc], [MatlGroup], [Category]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINLO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
