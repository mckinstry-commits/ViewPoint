CREATE TABLE [dbo].[bINMT]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[LastVendor] [dbo].[bVendor] NULL,
[LastCost] [dbo].[bUnitCost] NOT NULL,
[LastECM] [dbo].[bECM] NOT NULL,
[LastCostUpdate] [dbo].[bDate] NULL,
[AvgCost] [dbo].[bUnitCost] NOT NULL,
[AvgECM] [dbo].[bECM] NOT NULL,
[StdCost] [dbo].[bUnitCost] NOT NULL,
[StdECM] [dbo].[bECM] NOT NULL,
[StdPrice] [dbo].[bUnitCost] NOT NULL,
[PriceECM] [dbo].[bECM] NOT NULL,
[LowStock] [dbo].[bUnits] NOT NULL,
[ReOrder] [dbo].[bUnits] NOT NULL,
[WeightConv] [dbo].[bUnits] NOT NULL,
[PhyLoc] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[LastCntDate] [dbo].[bDate] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[CostPhase] [dbo].[bPhase] NULL,
[Active] [dbo].[bYN] NOT NULL,
[AutoProd] [dbo].[bYN] NOT NULL,
[GLSaleUnits] [dbo].[bYN] NOT NULL,
[CustRate] [dbo].[bRate] NOT NULL,
[JobRate] [dbo].[bRate] NOT NULL,
[InvRate] [dbo].[bRate] NOT NULL,
[EquipRate] [dbo].[bRate] NOT NULL,
[OnHand] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bINMT_OnHand] DEFAULT ((0)),
[RecvdNInvcd] [dbo].[bUnits] NOT NULL,
[Alloc] [dbo].[bUnits] NOT NULL,
[OnOrder] [dbo].[bUnits] NOT NULL,
[AuditYN] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Booked] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bINMT_Booked] DEFAULT ((0)),
[GLProdUnits] [dbo].[bYN] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AllowNegWarnMSTickets] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bINMT_AllowNegWarnMSTickets] DEFAULT ('N'),
[ServiceRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bINMT_ServiceRate] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************************/
CREATE   trigger [dbo].[btINMTd] on [dbo].[bINMT] for DELETE as
/*--------------------------------------------------------------
* Created By:	GR 11/16/99
* Modified By:	GG 03/02/00 - add checks for use in other tables
*				GR 05/31/00 - deleting IN materials unit of measure on deletion of IN Materials
*				RM 02/13/01 - add checks for use in Physical Count Worksheet table (bINCW)
*				GF 01/08/2007 - issue #126309 added checks for INIB and INMI.
*				GP 07/10/2008 - Issue 128881 added check for existing OnHands, OnOrder, Alloc, or
*									RecvdNInvcd. Also added checks for bill of materials.
*
*
*
*  Delete trigger for IN Materials
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), 
@OnHand bUnits, @OnOrder bUnits, @Alloc bUnits, @Recvd bUnits

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- check for use in other tables
if exists(select * from deleted d join bINBL l on d.INCo = l.INCo and d.Loc = l.Loc
				and d.MatlGroup = l.MatlGroup and d.Material = l.FinMatl)
	begin
	select @errmsg = 'Still in use as a Finished Material in Bill of Materials Override table'
	goto error
	end

if exists(select * from deleted d join bINBO o on d.INCo = o.INCo and d.Loc = o.CompLoc
			and d.MatlGroup = o.MatlGroup and d.Material = o.CompMatl)
	begin
	select @errmsg = 'Still in use as a Component in Bill of Materials Override table'
	goto error
	end

---- check if material is being used in PO, MO, or MS, 128881.
select @OnHand = OnHand, @OnOrder = OnOrder, @Alloc = Alloc, @Recvd = RecvdNInvcd from deleted with(nolock)

if @OnHand <> 0 or @OnOrder <> 0 or @Alloc <> 0 or @Recvd <> 0
begin
	select @errmsg = 'Material OnHand, OnOrder, Alloc, or Received not Invoiced still exist, cannot delete.'
	goto error
end

if exists(select * from deleted d join bINDT t on d.INCo = t.INCo and d.Loc = t.Loc
			and d.MatlGroup = t.MatlGroup and d.Material = t.Material)
	begin
	select @errmsg = 'Detail, bINDT, exists for this Material.'
	goto error
	end

if exists(select * from deleted d join bINCW w on d.INCo = w.INCo and d.Loc = w.Loc 
			and d.MatlGroup = w.MatlGroup and d.Material = w.Material)
	begin
	select @errmsg = 'Materials assigned to Physical Count Worksheet.'
	goto error
	end

---- check INIB Batch Table
if exists(select * from deleted d join bINIB i on d.INCo = i.Co and d.Loc = i.Loc
			and d.MatlGroup = i.MatlGroup and d.Material = i.Material)
	begin
	select @errmsg = 'Materials assigned to an Open Material Order Batch, cannot delete.'
	goto error
	end

---- check INMI for material order items with the MO status not closed.
if exists(select * from deleted d join bINMI i on d.INCo = i.INCo and d.Loc = i.Loc
			and d.MatlGroup = i.MatlGroup and d.Material = i.Material)
	begin
	select @errmsg = 'Materials assigned to Material Order Items, cannot delete.'
	goto error
	end

---- check for material in bill of materials override header, 128881.
if exists(select top 1 1 from deleted d join bINBL i with(nolock) on d.INCo = i.INCo and d.Loc = i.Loc 
			and d.MatlGroup = i.MatlGroup and d.Material = i.FinMatl)
begin
	select @errmsg = 'Material exists in Bill Of Materials Override Header, cannot delete.'
	goto error
end

---- check for material in bill of materials override detail, 128881.
if exists(select top 1 1 from deleted d join bINBO i with(nolock) on d.INCo = i.INCo and d.Loc = i.Loc 
			and d.MatlGroup = i.MatlGroup and d.Material = i.FinMatl)
begin
	select @errmsg = 'Material exists in Bill of Materials Override Detail, cannot delete.'
	goto error
end


---- delete from IN Materials Unit of Measure on deletion of IN Materials
delete bINMU from deleted d
join bINMU u on d.INCo = u.INCo and d.Loc = u.Loc  and d.MatlGroup = u.MatlGroup and d.Material = u.Material


---- HQ Auditing
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bINMT','INCo:' + convert(varchar(3),d.INCo) + ' Loc:' + d.Loc + ' Material:' + d.Material,
		d.INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d join bINCO c on d.INCo = c.INCo
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
 
  
   
   
   
   
   CREATE   trigger [dbo].[btINMTi] on [dbo].[bINMT] for INSERT as
   

/*--------------------------------------------------------------
    * Created By: GR 11/03/99
    * Modified: GG 03/02/00 - added checks for Active and Stocked flags in bHQMT
    *		ES 3/29/04 - Issue 24115 added INCo and Loc to HQMA record
    *
    *
    * Insert trigger for IN Material
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
   where b.Stocked = 'Y' and b.Active = 'Y'
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid HQ Material, must be Active and Stocked '
    	goto error
    	end
   
   
   -- HQ Auditing
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material,
   	i.INCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM inserted i join bINCO c on c.INCo = i.INCo and c.AuditMatl = 'Y'
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert IN Material.'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE   trigger [dbo].[btINMTu] on [dbo].[bINMT] for UPDATE as
   

/*--------------------------------------------------------------
    *  Created By : GR 11/03/99
    *				 GF 08/12/2003 - issue #22112 - performance
    *				GG 02/02/04 - #20538 - rename GLUnits to GLSaleUnits, add GLProdUnits
    *				ES 03/30/04 - #24115 - Add INCo and Loc to HQMA records
    *
    *
    *  Update trigger for IN Material
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- verify primary key not changed
   select @validcnt = count(*) from inserted i
   join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Cannot change IN Company/Location/Material '
    	goto error
    	end
   
   
   -- HQ Auditing
   if not exists(select top 1 1 from inserted i join bINCO a with (nolock) on i.INCo=a.INCo 
   					where a.AuditMatl='Y' and i.AuditYN='Y')
   	return
   
   
   -- Insert records into HQMA for changes made to audited fields
   if update(VendorGroup)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
   	'VendorGroup', convert(varchar(3),d.VendorGroup), convert(varchar(3),i.VendorGroup), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.VendorGroup <> i.VendorGroup and a.AuditMatl = 'Y'
   END
   
   if update(LastVendor)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'LastVendor', convert(varchar(6),d.LastVendor), convert(varchar(6),i.LastVendor), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where isnull(d.LastVendor, 0) <> isnull(i.LastVendor, 0) and a.AuditMatl = 'Y'
   END
   
   if update(LastCost)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'LastCost', convert(varchar(20),d.LastCost), convert(varchar(20),i.LastCost), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.LastCost <> i.LastCost and a.AuditMatl = 'Y'
   END
   
   if update(LastECM)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'LastECM', d.LastECM, i.LastECM, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.LastECM <> i.LastECM and a.AuditMatl = 'Y'
   END
   
   if update(LastCostUpdate)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'LastCostUpdate', convert(varchar(8),d.LastCostUpdate,1), convert(varchar(8),i.LastCostUpdate,1), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where isnull(d.LastCostUpdate,'') <> isnull(i.LastCostUpdate,'') and a.AuditMatl = 'Y'
   END
   
   if update(AvgCost)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'AvgCost', convert(varchar(20),d.AvgCost), convert(varchar(20),i.AvgCost), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
      join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.AvgCost <> i.AvgCost and a.AuditMatl = 'Y'
   END
   
   if update(AvgECM)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
   		'AvgECM', d.AvgECM, i.AvgECM, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.AvgECM <> i.AvgECM and a.AuditMatl = 'Y'
   END
   
   if update(StdCost)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'StdCost', convert(varchar(20),d.StdCost), convert(varchar(20),i.StdCost), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.StdCost <> i.StdCost and a.AuditMatl = 'Y'
   END
   
   if update(StdECM)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'StdECM', d.StdECM, i.StdECM, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.StdECM <> i.StdECM and a.AuditMatl = 'Y'
   END
   
   if update(StdPrice)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'StdPrice', convert(varchar(20),d.StdPrice), convert(varchar(20),i.StdPrice), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.StdPrice <> i.StdPrice and a.AuditMatl = 'Y'
   END
   
   if update(PriceECM)	
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'PriceECM', d.PriceECM, i.PriceECM, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.PriceECM <> i.PriceECM and a.AuditMatl = 'Y'
   END
   
   if update(LowStock)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'LowStock', convert(varchar(15),d.LowStock), convert(varchar(15),i.LowStock), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.LowStock <> i.LowStock and a.AuditMatl = 'Y'
   END
   
   if update(ReOrder)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'ReOrder', convert(varchar(15),d.ReOrder), convert(varchar(15),i.ReOrder), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.ReOrder <> i.ReOrder and a.AuditMatl = 'Y'
   END
   
   if update(WeightConv)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'WeightConv', convert(varchar(15),d.WeightConv), convert(varchar(15),i.WeightConv), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.WeightConv <> i.WeightConv and a.AuditMatl = 'Y'
   END
   
   if update(PhyLoc)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'PhyLoc', d.PhyLoc, i.PhyLoc, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where isnull(d.PhyLoc,'') <> isnull(i.PhyLoc,'') and a.AuditMatl = 'Y'
   END
   
   if update(LastCntDate)
   BEGIN
   
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'LastCntDate', convert(varchar(8),d.LastCntDate,1), convert(varchar(8),i.LastCntDate,1), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where isnull(d.LastCntDate,'') <> isnull(i.LastCntDate,'') and a.AuditMatl = 'Y'
   END
   
   if update(PhaseGroup)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'PhaseGroup', convert(varchar(3), d.PhaseGroup), convert(varchar(3), i.PhaseGroup), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where isnull(d.PhaseGroup,'') <> isnull(i.PhaseGroup,'') and a.AuditMatl = 'Y'
   END
   
   if update(CostPhase)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'CostPhase', convert(varchar(10), d.CostPhase), convert(varchar(10), i.CostPhase), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where isnull(d.CostPhase,'') <> isnull(i.CostPhase,'') and a.AuditMatl = 'Y'
   END
   
   if update(Active)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'Active', d.Active, i.Active, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.Active <> i.Active and a.AuditMatl = 'Y'
   END
   
   if update(AutoProd)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'AutoProd', d.AutoProd, i.AutoProd, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.AutoProd <> i.AutoProd and a.AuditMatl = 'Y'
   END
   
   if update(GLSaleUnits)	-- #20538
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'GLSaleUnits', d.GLSaleUnits, i.GLSaleUnits, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.GLSaleUnits <> i.GLSaleUnits and a.AuditMatl = 'Y'
   END
   if update(GLProdUnits)	-- #20538
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'GLProdUnits', d.GLProdUnits, i.GLProdUnits, getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.GLProdUnits <> i.GLProdUnits and a.AuditMatl = 'Y'
   END
   if update(CustRate)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'CustRate', convert(varchar(9), d.CustRate), convert(varchar(9), i.CustRate), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where isnull(d.CustRate,'') <> isnull(i.CustRate,'') and a.AuditMatl = 'Y'
   END
   
   if update(JobRate)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'JobRate', convert(varchar(9), d.JobRate), convert(varchar(9), i.JobRate), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.JobRate <> i.JobRate and a.AuditMatl = 'Y'
   END
   
   if update(InvRate)
   BEGIN
   insert into bHQMA
  
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'InvRate', convert(varchar(9), d.InvRate), convert(varchar(9), i.InvRate), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.InvRate <> i.InvRate and a.AuditMatl = 'Y'
   END
   
   if update(EquipRate)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'EquipRate', convert(varchar(9), d.EquipRate), convert(varchar(9), i.EquipRate), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.EquipRate <> i.EquipRate and a.AuditMatl = 'Y'
   END
   
   if update(OnHand)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'OnHand', convert(varchar(15), d.OnHand), convert(varchar(15), i.OnHand), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.OnHand <> i.OnHand and a.AuditMatl = 'Y'
   END
   
   if update(RecvdNInvcd)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'RecvdNInvcd', convert(varchar(15), d.RecvdNInvcd), convert(varchar(15), i.RecvdNInvcd), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.RecvdNInvcd <> i.RecvdNInvcd and a.AuditMatl = 'Y'
   END
   
   if update(Alloc)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'Alloc', convert(varchar(15), d.Alloc), convert(varchar(15), i.Alloc), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.Alloc <> i.Alloc and a.AuditMatl = 'Y'
   END
   
   if update(OnOrder)
   BEGIN
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bINMT','INCo:' + convert(varchar(3),i.INCo) + ' Loc:' + i.Loc + ' Material:' + i.Material, i.INCo, 'C', 
           'OnOrder', convert(varchar(15), d.OnOrder), convert(varchar(15), i.OnOrder), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on d.INCo = i.INCo and d.Material = i.Material and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc
       join bINCO a with (nolock) on a.INCo = i.INCo
    	where d.OnOrder <> i.OnOrder and a.AuditMatl = 'Y'
   END
   
   
   return
   
   
   
   error:
       select @errmsg = @errmsg + ' - cannot update IN Material'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bINMT] ADD CONSTRAINT [PK_bINMT] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=100) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bINMT_IncoAudit] ON [dbo].[bINMT] ([INCo], [AuditYN]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_bINMT_MatlGroupMatlLocInco] ON [dbo].[bINMT] ([MatlGroup], [Material], [Loc], [INCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMT].[LastECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMT].[AvgECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMT].[StdECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINMT].[PriceECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINMT].[Active]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINMT].[AutoProd]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINMT].[GLSaleUnits]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINMT].[AuditYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINMT].[GLProdUnits]'
GO
