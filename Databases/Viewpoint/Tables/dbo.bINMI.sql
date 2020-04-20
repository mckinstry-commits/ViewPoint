CREATE TABLE [dbo].[bINMI]
(
[INCo] [dbo].[bCompany] NOT NULL,
[MO] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[MOItem] [dbo].[bItem] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[ReqDate] [dbo].[bDate] NULL,
[UM] [char] (3) COLLATE Latin1_General_BIN NOT NULL,
[OrderedUnits] [dbo].[bUnits] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[TotalPrice] [dbo].[bDollar] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxAmt] [dbo].[bDollar] NOT NULL,
[ConfirmedUnits] [dbo].[bUnits] NOT NULL,
[RemainUnits] [dbo].[bUnits] NOT NULL,
[PostedDate] [dbo].[bDate] NOT NULL,
[AddedMth] [dbo].[bMonth] NULL,
[AddedBatchId] [dbo].[bBatchID] NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biINMI] ON [dbo].[bINMI] ([INCo], [MO], [MOItem]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINMI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE          trigger [dbo].[btINMId] on [dbo].[bINMI] for DELETE as
   

/*--------------------------------------------------------------
    *  Created:	GF	02/18/2002
    *  Modified: GG 04/29/02 - added validation and HQ auditing	
    *			GF 10/20/2004 - issue #25830 changed logic to update related PMMF records
	*			GF 02/14/2006 - issue #120167 when purging to not update bPMMF
	*
	*
    *
    *  Delete trigger for IN Material Order Items
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- Remaining must equal 0.00
   if exists(select 1 from deleted where RemainUnits <> 0)
       begin
       select @errmsg = 'Remaining units must be 0.00 '
       goto error
       end


-- -- -- Update related PMMF records
-- -- -- if not purging MO's then set interface date to null and send flag to 'N'
-- -- -- otherwise do not do anything with PMMF records
update bPMMF Set InterfaceDate=null, SendFlag='N'
from bPMMF p
join deleted d on p.INCo = d.INCo and p.MO = d.MO and p.MOItem = d.MOItem
join bINMO h on d.INCo=h.INCo and d.MO=h.MO and h.Purge = 'N'
where p.InterfaceDate is not null
-- -- -- update related PM Materials
-- -- -- update bPMMF set InterfaceDate=null, SendFlag='N'
-- -- -- from bPMMF p join deleted d on p.INCo = d.INCo and p.MO = d.MO and p.MOItem = d.MOItem
-- -- -- where p.InterfaceDate is not null



-- -- -- HQ Auditing
insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bINMI','Co:' + convert(varchar(3),d.INCo) + ' MO:' + d.MO + ' Item:' + convert(varchar(6),d.MOItem),
       d.INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d
join bINCO c on d.INCo = c.INCo
join bINMO h on d.INCo = h.INCo and d.MO = h.MO
where c.AuditMOs = 'Y' and h.Purge = 'N'  -- check audit and purge flags

return



error:
      select @errmsg = @errmsg + ' - cannot delete Material Order Items (bINMI)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE trigger [dbo].[btINMIi] on [dbo].[bINMI] for INSERT as
   

/*--------------------------------------------------------------
    *  Created: GG 04/29/02
    *  Modified:
    *
    *  Insert trigger on IN Material Order Items
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   --validation IN Co#
   select @validcnt = count(*)
   from bINCO r
   join inserted i ON i.INCo = r.INCo 
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid IN Company '
      goto error
      end
   -- validate MO Header
   select @validcnt = count(*)
   from bINMO r
   join inserted i ON i.INCo = r.INCo and i.MO = r.MO
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid Material Order '
      goto error
      end
   -- validate Location
   select @validcnt = count(*)
   from bINLM r
   join inserted i ON i.INCo = r.INCo and i.Loc = r.Loc
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid Location '
      goto error
      end
   -- validate Material
   select @validcnt = count(*)
   from bINMT r
   join inserted i ON i.INCo = r.INCo and i.Loc = r.Loc
   	and i.MatlGroup = r.MatlGroup and i.Material = r.Material
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid Location Material '
      goto error
      end
   -- validate Job
   select @validcnt = count(*)
   from bJCJM r
   join inserted i ON i.JCCo = r.JCCo and i.Job = r.Job
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid Job '
      goto error
      end
   
   
   -- HQ Auditing
   insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMI',  'MO:' + i.MO + ' Item#: ' + convert(varchar,i.MOItem), i.INCo, 'A', null, null,
   	null, getdate(), SUSER_SNAME()
   from inserted i
   join bINCO c on i.INCo = c.INCo
   where c.AuditMOs = 'Y'
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert IN Material Order Items (bINMI)'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE trigger [dbo].[btINMIu] on [dbo].[bINMI] for UPDATE as
   

/*--------------------------------------------------------------
    *  Created: 04/29/02
    *  Modified:
    *
    *  Update trigger for IN Material Order Items
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- check for key changes
   select @validcnt = count(*)
   from deleted d
   join inserted i on d.INCo = i.INCo and d.MO = i.MO and d.MOItem = i.MOItem
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Cannot change IN Company, Material Order, or Item '
    	goto error
    	end
   -- validate Location
   if update(Loc)
   	begin
   	select @validcnt = count(*)
   	from bINLM r
   	join inserted i ON i.INCo = r.INCo and i.Loc = r.Loc
   	if @validcnt <> @numrows
   	   begin
   	   select @errmsg = 'Invalid Location '
   	   goto error
   	   end
   	end
   -- validate Material
   if update(Loc) or update(MatlGroup) or update(Material)
   	begin
   	select @validcnt = count(*)
   	from bINMT r
   	join inserted i ON i.INCo = r.INCo and i.Loc = r.Loc
   		and i.MatlGroup = r.MatlGroup and i.Material = r.Material
   	if @validcnt <> @numrows
   	   begin
   	   select @errmsg = 'Invalid Location Material '
   	   goto error
   	   end
   	end
   -- validate Job
   if update(JCCo) or update(Job)
   	begin
   	select @validcnt = count(*)
   	from bJCJM r
   	join inserted i ON i.JCCo = r.JCCo and i.Job = r.Job
   	if @validcnt <> @numrows
   	   begin
   	   select @errmsg = 'Invalid Job '
   	   goto error
   	   end
   	end
   
   -- HQ Audting
   if exists (select * from inserted i join bINCO c on c.INCo = i.INCo where c.AuditMOs = 'Y')
   	begin
   	if update(Loc)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'Loc', d.Loc, i.Loc, getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.Loc <> d.Loc and c.AuditMOs = 'Y'
   	if update(MatlGroup)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'MatlGroup', convert(varchar,d.MatlGroup), convert(varchar,i.MatlGroup),
   			getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.MatlGroup <> d.MatlGroup and c.AuditMOs = 'Y'
   	if update(Material)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'Material', d.Material, i.Material, getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.Material <> d.Material and c.AuditMOs = 'Y'
   	if update(Description)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where isnull(i.Description,'') <> isnull(d.Description,'') and c.AuditMOs = 'Y'
   	if update(JCCo)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'JCCo', convert(varchar,d.JCCo), convert(varchar,i.JCCo),
   			getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.JCCo <> d.JCCo and c.AuditMOs = 'Y'
   	if update(Job)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'Job', d.Job, i.Job, getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.Job <> d.Job and c.AuditMOs = 'Y'
   	if update(PhaseGroup)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'PhaseGroup', convert(varchar,d.PhaseGroup), convert(varchar,i.PhaseGroup),
   			getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.PhaseGroup <> d.PhaseGroup and c.AuditMOs = 'Y'
   	if update(Phase)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'Phase', d.Phase, i.Phase, getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.Phase <> d.Phase and c.AuditMOs = 'Y'
   	if update(JCCType)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'JCCType', convert(varchar,d.JCCType), convert(varchar,i.JCCType),
   			getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.JCCType <> d.JCCType and c.AuditMOs = 'Y'
   	if update(GLCo)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'GLCo', convert(varchar,d.GLCo), convert(varchar,i.GLCo),
   			getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.GLCo <> d.GLCo and c.AuditMOs = 'Y'
   	if update(GLAcct)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'GLAcct', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.GLAcct <> d.GLAcct and c.AuditMOs = 'Y'
   	if update(ReqDate)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'ReqDate', convert(varchar,d.ReqDate,1), convert(varchar,i.ReqDate,1),
   			getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where isnull(i.ReqDate,'') <> isnull(d.ReqDate,'') and c.AuditMOs = 'Y'
   	if update(UM)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'UM', d.UM, i.UM, getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.UM <> d.UM and c.AuditMOs = 'Y'
   	if update(OrderedUnits)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'OrderedUnits', convert(varchar,d.OrderedUnits), convert(varchar,i.OrderedUnits),
   			getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.OrderedUnits <> d.OrderedUnits and c.AuditMOs = 'Y'
   	if update(UnitPrice)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'UnitPrice', convert(varchar,d.UnitPrice), convert(varchar,i.UnitPrice),
   			getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.UnitPrice <> d.UnitPrice and c.AuditMOs = 'Y'
   	if update(ECM)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'ECM', d.ECM, i.ECM, getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.ECM <> d.ECM and c.AuditMOs = 'Y'
   	if update(TotalPrice)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'TotalPrice', convert(varchar,d.TotalPrice), convert(varchar,i.TotalPrice),
   			getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.TotalPrice <> d.TotalPrice and c.AuditMOs = 'Y'
   	if update(TaxGroup)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'TaxGroup', convert(varchar,d.TaxGroup), convert(varchar,i.TaxGroup),
   			getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where isnull(i.TaxGroup,0) <> isnull(d.TaxGroup,0) and c.AuditMOs = 'Y'
   	if update(TaxCode)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'TaxCode', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where isnull(i.TaxCode,'') <> isnull(d.TaxCode,'') and c.AuditMOs = 'Y'
   	if update(TaxAmt)
   		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 	select 'bINMI', 'MO:' + i.MO + ' Item: ' + convert(varchar,i.MOItem), i.INCo, 'C',
   		 	'TaxAmt', convert(varchar,d.TaxAmt), convert(varchar,i.TaxAmt),
   			getdate(), SUSER_SNAME()
   	 	from inserted i
   	    join deleted d on i.INCo = d.INCo and i.MO = d.MO and i.MOItem = d.MOItem
   	    join bINCO c on c.INCo = i.INCo
   	    where i.TaxAmt <> d.TaxAmt and c.AuditMOs = 'Y'
   	
   	-- ConfirmedUnits, RemainingUnits and others updated by system - not audited in HQ
   
       end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update IN Material Order Items (bINMI)'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMI].[ECM]'
GO
