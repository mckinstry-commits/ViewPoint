CREATE TABLE [dbo].[bINLC]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[Co] [dbo].[bCompany] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[GLCo] [dbo].[bCompany] NULL,
[JobSalesGLAcct] [dbo].[bGLAcct] NULL,
[InvSalesGLAcct] [dbo].[bGLAcct] NULL,
[EquipSalesGLAcct] [dbo].[bGLAcct] NULL,
[JobQtyGLAcct] [dbo].[bGLAcct] NULL,
[InvQtyGLAcct] [dbo].[bGLAcct] NULL,
[JobHaulRevEquipGLAcct] [dbo].[bGLAcct] NULL,
[InvHaulRevEquipGLAcct] [dbo].[bGLAcct] NULL,
[JobHaulRevOutGLAcct] [dbo].[bGLAcct] NULL,
[InvHaulRevOutGLAcct] [dbo].[bGLAcct] NULL,
[JobHaulExpEquipGLAcct] [dbo].[bGLAcct] NULL,
[InvHaulExpEquipGLAcct] [dbo].[bGLAcct] NULL,
[JobHaulExpOutGLAcct] [dbo].[bGLAcct] NULL,
[InvHaulExpOutGLAcct] [dbo].[bGLAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[JobMatlExpGLAcct] [dbo].[bGLAcct] NULL,
[InvMatlExpGLAcct] [dbo].[bGLAcct] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biINLC] ON [dbo].[bINLC] ([INCo], [Loc], [Co], [MatlGroup], [Category]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINLC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btINLCd] on [dbo].[bINLC] for DELETE as
   

/*--------------------------------------------------------------
    *  Created By: GR 7/19/00
    *  Modified:
    *
    *  Delete trigger for IN Location Company Category Override
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- HQ Auditing
   insert bHQMA select 'bINLC','INCo:' + convert(varchar(3),d.INCo) + ' Co: ' + convert(varchar(3),d.Co) + ' Loc:' + d.Loc + ' Category:' + d.Category,
       d.INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from deleted d
   join bINCO c on d.INCo = c.INCo
   where c.AuditLoc = 'Y'   -- check audit
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete IN Location Company Category Override'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btINLCi] on [dbo].[bINLC] for INSERT as
   

/*--------------------------------------------------------------
    * Created By: GR 7/19/00
    * Modified by: RM 06/01/01 Updated to check category from HQMC instead of INLC per issue #13628
    *				CMW 07/09/02 - added Sell To Company validation.
    *
    *
    *
    * Insert trigger for IN Location Company Category Override
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
   
   -- validate TO Company
   select @validcnt = count(*) from bHQCO c JOIN inserted i on i.Co = c.HQCo
   if @validcnt<>@numrows
       begin
    	select @errmsg = 'Invalid Sell To Company '
    	goto error
    	end
   
   --validate Category
   select @validcnt = count(*) from bHQMC c join inserted i on i.MatlGroup = c.MatlGroup and i.Category = c.Category
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Category'
       goto error
       end
   
   -- HQ Auditing
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bINLC','Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM inserted i join bINCO c on c.INCo = i.INCo and c.AuditLoc = 'Y'
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert IN Location Company Category Override.'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE   trigger [dbo].[btINLCu] on [dbo].[bINLC] for UPDATE as
   

/*--------------------------------------------------------------
    *  Created By : GR 7/19/00
    *  Modified By: GR 8/16/00 - fixed the insert statement on HQMA
    *				GG 03/04/05 - #19185 - audit new columns - JobMatlExpGLAcct, InvMatlExpGLAcct
    *
    *  Update trigger for IN Location Company Category Override
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- verify primary key not changed
   select @validcnt = count(*) from inserted i
   join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup = i.MatlGroup
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Cannot change IN Location, Sell To Company, or Category '
    	goto error
    	end
   
   
   -- HQ Auditing
   if exists(select * from inserted i
       join bINCO a on i.INCo = a.INCo
       where a.AuditLoc = 'Y')
       begin
   	if update(GLCo)
   		begin
       	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'GLCo', convert(varchar(6), d.GLCo), convert(varchar(6), i.GLCo), getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.GLCo, 0) <> isnull(i.GLCo, 0) and a.AuditLoc = 'Y'
   		end
   	if update(JobSalesGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'JobSalesGLAcct', d.JobSalesGLAcct, i.JobSalesGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobSalesGLAcct, '') <> isnull(i.JobSalesGLAcct, '') and a.AuditLoc = 'Y'
   		end 
   	if update(InvSalesGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'InvSalesGLAcct', d.InvSalesGLAcct, i.InvSalesGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvSalesGLAcct, '') <> isnull(i.InvSalesGLAcct, '') and a.AuditLoc = 'Y'
   		end 
   	if update(EquipSalesGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'EquipSalesGLAcct', d.EquipSalesGLAcct, i.EquipSalesGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.EquipSalesGLAcct, '') <> isnull(i.EquipSalesGLAcct, '') and a.AuditLoc = 'Y'
   		end 
   	if update(JobQtyGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'JobQtyGLAcct', d.JobQtyGLAcct, i.JobQtyGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobQtyGLAcct, '') <> isnull(i.JobQtyGLAcct, '') and a.AuditLoc = 'Y'
   		end 
   	if update(InvQtyGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'InvQtyGLAcct', d.InvQtyGLAcct, i.InvQtyGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvQtyGLAcct, '') <> isnull(i.InvQtyGLAcct, '') and a.AuditLoc = 'Y'
   		end 
   	if update(JobHaulRevEquipGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'JobHaulRevEquipGLAcct', d.JobHaulRevEquipGLAcct, i.JobHaulRevEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobHaulRevEquipGLAcct, '') <> isnull(i.JobHaulRevEquipGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(InvHaulRevEquipGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'InvHaulRevEquipGLAcct', d.InvHaulRevEquipGLAcct, i.InvHaulRevEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvHaulRevEquipGLAcct, '') <> isnull(i.InvHaulRevEquipGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(JobHaulRevOutGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'JobHaulRevOutGLAcct', d.JobHaulRevOutGLAcct, i.JobHaulRevOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobHaulRevOutGLAcct, '') <> isnull(i.JobHaulRevOutGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(InvHaulRevOutGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'InvHaulRevOutGLAcct', d.InvHaulRevOutGLAcct, i.InvHaulRevOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvHaulRevOutGLAcct, '') <> isnull(i.InvHaulRevOutGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(JobHaulExpEquipGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'JobHaulExpEquipGLAcct', d.JobHaulExpEquipGLAcct, i.JobHaulExpEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobHaulExpEquipGLAcct, '') <> isnull(i.JobHaulExpEquipGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(InvHaulExpEquipGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'InvHaulExpEquipGLAcct', d.InvHaulExpEquipGLAcct, i.InvHaulExpEquipGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvHaulExpEquipGLAcct, '') <> isnull(i.InvHaulExpEquipGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(JobHaulExpOutGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'JobHaulExpOutGLAcct', d.JobHaulExpOutGLAcct, i.JobHaulExpOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobHaulExpOutGLAcct, '') <> isnull(i.JobHaulExpOutGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(InvHaulExpOutGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'InvHaulExpOutGLAcct', d.InvHaulExpOutGLAcct, i.InvHaulExpOutGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvHaulExpOutGLAcct, '') <> isnull(i.InvHaulExpOutGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(JobMatlExpGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'JobMatlExpGLAcct', d.JobMatlExpGLAcct, i.JobMatlExpGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.JobMatlExpGLAcct, '') <> isnull(i.JobMatlExpGLAcct, '') and a.AuditLoc = 'Y'
   		end
   	if update(InvMatlExpGLAcct)
   		begin
   	    insert dbo.bHQMA  (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bINLC', 'Co: ' + convert(varchar(6), i.Co) + ' Location: ' + i.Loc + ' Category: ' + i.Category, i.INCo, 'C',
           	'InvMatlExpGLAcct', d.InvMatlExpGLAcct, i.InvMatlExpGLAcct, getdate(), SUSER_SNAME()
    		from inserted i
       	join deleted d on d.INCo = i.INCo and d.Loc=i.Loc and d.Co=i.Co and d.Category=i.Category and d.MatlGroup=i.MatlGroup
       	join dbo.bINCO a (nolock) on a.INCo = i.INCo
    		where isnull(d.InvMatlExpGLAcct, '') <> isnull(i.InvMatlExpGLAcct, '') and a.AuditLoc = 'Y'
   		end
       end
   
   return
   
    error:
       select @errmsg = @errmsg + ' - cannot update IN Location Company Category Override'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
  
 



GO
