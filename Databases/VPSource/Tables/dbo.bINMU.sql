CREATE TABLE [dbo].[bINMU]
(
[INCo] [dbo].[bCompany] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[Conversion] [dbo].[bUnitCost] NOT NULL,
[StdCost] [dbo].[bUnitCost] NOT NULL,
[StdCostECM] [dbo].[bECM] NOT NULL,
[Price] [dbo].[bUnitCost] NOT NULL,
[PriceECM] [dbo].[bECM] NOT NULL,
[LastCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bINMU_LastCost] DEFAULT ((0)),
[LastECM] [dbo].[bECM] NOT NULL CONSTRAINT [DF_bINMU_LastECM] DEFAULT ('E'),
[LastCostUpdate] [dbo].[bDate] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bINMU] ADD
CONSTRAINT [CK_bINMU_LastECM] CHECK (([LastECM]='M' OR [LastECM]='C' OR [LastECM]='E'))
ALTER TABLE [dbo].[bINMU] ADD
CONSTRAINT [CK_bINMU_PriceECM] CHECK (([PriceECM]='M' OR [PriceECM]='C' OR [PriceECM]='E'))
ALTER TABLE [dbo].[bINMU] ADD
CONSTRAINT [CK_bINMU_StdCostECM] CHECK (([StdCostECM]='M' OR [StdCostECM]='C' OR [StdCostECM]='E'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btINMUd] on [dbo].[bINMU] for DELETE as
   

/*--------------------------------------------------------------
    *  Created By: GR 11/16/99
    *  Modified:
    *
    *  Delete trigger for IN Materials
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- HQ Auditing
   insert bHQMA select 'bINMU','INCo:' + convert(varchar(3),d.INCo) + ' Loc:' + d.Loc + ' Material:' + d.Material + ' UM:' + d.UM,
       d.INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from deleted d
   join bINCO c on d.INCo = c.INCo
   where c.AuditMatl = 'Y'   -- check audit
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete IN Materials'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btINMUi] on [dbo].[bINMU] for INSERT as
   

/*--------------------------------------------------------------
     *  Created By: GR 11/04/99
     *
     *
     * Insert trigger for IN Material_UM
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
   select @validcnt = count(*) from bINLM a JOIN inserted i on i.Loc = a.Loc and i.INCo = a.INCo
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Invalid Location for this Company '
    	goto error
    	end
   
   --validate Material group
   select @validcnt = count(*) from bHQCO c
   JOIN inserted i on i.INCo = c.HQCo and i.MatlGroup = c.MatlGroup
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Material Group for this Company '
    	goto error
    	end
   
   --validate Material
   select @validcnt = count(*) from bHQMT b
   JOIN inserted i on i.MatlGroup = b.MatlGroup and i.Material = b.Material
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Material '
    	goto error
    	end
   
   --validate UM
   select @validcnt=count(*) from bHQMU a
   JOIN inserted i on i.MatlGroup=a.MatlGroup and i.Material=a.Material and i.UM=a.UM
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Unit of Measure '
       goto error
       end
   
   -- HQ Auditing
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bINMU',' UM: ' + i.UM, i.INCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM inserted i join bINCO c on c.INCo = i.INCo and c.AuditMatl = 'Y'
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert IN Material_UM'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btINMUu] on [dbo].[bINMU] for UPDATE as
   

/*--------------------------------------------------------------
    *  Created By : GR 11/04/99
    *
    *  Update trigger for IN Material_UM
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- verify primary key not changed
   select @validcnt = count(*) from inserted i
   join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup
   and d.Loc=i.Loc and d.UM=i.UM
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Cannot change IN Company/Location/Material/UM '
    	goto error
    	end
   
   
   -- HQ Auditing
   if exists(select * from inserted i join bINCO a on i.INCo = a.INCo and a.AuditMatl = 'Y'
               join bINMT b on b.INCo=i.INCo and b.AuditYN='Y')
       begin
       insert into bHQMA select 'bINMU', ' UM: ' + i.UM, i.INCo, 'C',
           'Conversion', convert(varchar(15),d.Conversion), convert(varchar(15),i.Conversion), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc and d.UM=i.UM
       join bINCO a on a.INCo = i.INCo
    	where d.Conversion <> i.Conversion and a.AuditMatl = 'Y'
   
       insert into bHQMA select 'bINMU', ' UM: ' + i.UM, i.INCo, 'C',
           'StdCost', convert(varchar(20),d.StdCost), convert(varchar(20),i.StdCost), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc and d.UM=i.UM
       join bINCO a on a.INCo = i.INCo
    	where d.StdCost <> i.StdCost and a.AuditMatl = 'Y'
   
       insert into bHQMA select 'bINMU', ' UM: ' + i.UM, i.INCo, 'C',
           'StdCostECM', d.StdCostECM, i.StdCostECM, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc and d.UM=i.UM
       join bINCO a on a.INCo = i.INCo
    	where d.StdCostECM <> i.StdCostECM and a.AuditMatl = 'Y'
   
       insert into bHQMA select 'bINMU', ' UM: ' + i.UM, i.INCo, 'C',
           'Price', convert(varchar(20),d.Price), convert(varchar(20),i.Price), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc and d.UM=i.UM
       join bINCO a on a.INCo = i.INCo
    	where d.Price <> i.Price and a.AuditMatl = 'Y'
   
       insert into bHQMA select 'bINMU', ' UM: ' + i.UM, i.INCo, 'C',
           'PriceECM', d.PriceECM, i.PriceECM, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc and d.UM=i.UM
       join bINCO a on a.INCo = i.INCo
    	where d.PriceECM <> i.PriceECM and a.AuditMatl = 'Y'
       end
   
   return
   
    error:
       select @errmsg = @errmsg + ' - cannot update IN Material_UM'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINMU] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biINMU] ON [dbo].[bINMU] ([MatlGroup], [INCo], [Material], [Loc], [UM]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMU].[StdCostECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMU].[PriceECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMU].[LastECM]'
GO
