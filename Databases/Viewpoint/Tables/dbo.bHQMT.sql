CREATE TABLE [dbo].[bHQMT]
(
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[StdUM] [dbo].[bUM] NOT NULL,
[Cost] [dbo].[bUnitCost] NOT NULL,
[CostECM] [dbo].[bECM] NOT NULL,
[Price] [dbo].[bUnitCost] NOT NULL,
[PriceECM] [dbo].[bECM] NOT NULL,
[PayDiscType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[PurchaseUM] [dbo].[bUM] NOT NULL,
[SalesUM] [dbo].[bUM] NOT NULL,
[WeightConv] [dbo].[bUnits] NULL,
[Stocked] [dbo].[bYN] NOT NULL,
[Taxable] [dbo].[bYN] NOT NULL,
[MatlPhase] [dbo].[bPhase] NULL,
[MatlJCCostType] [dbo].[bJCCType] NULL,
[HaulPhase] [dbo].[bPhase] NULL,
[HaulJCCostType] [dbo].[bJCCType] NULL,
[HaulCode] [dbo].[bHaulCode] NULL,
[Active] [dbo].[bYN] NOT NULL,
[PriceServiceId] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[PayDiscRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bHQMT_PayDiscRate] DEFAULT ((0)),
[MetricUM] [dbo].[bUM] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHQMT] ON [dbo].[bHQMT] ([MatlGroup], [Material]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQMT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btHQMTd    Script Date: 8/28/99 9:37:34 AM ******/
   CREATE  trigger [dbo].[btHQMTd] on [dbo].[bHQMT] for DELETE as
   

/*----------------------------------------------------------
    *  Created: ?
    *  Modified by: CMW 04/10/02 - added HQMA update using MatlGroup for Co # (issue # 16840).
    *               CMW 07/11/02 - fixed multiple entry problem (issue # 17902).
    *               CMW 08/12/02 - fixed varchar/int convert error (issue # 18249).
    *               DANF 09/24/02 - Fixed insert into HQMA by removing min around Materail and the group by. 18659
    *		RBT 05/06/03 - disallow delete if material is used in INBM (issue #21163).
    *		DANF 01/07/04 - Issue 26744 Correct update of HQMA
    *		DC 06/23/06 - disallow delete if material is used in POVM (issue #27669)
    *
    *	This trigger rejects delete in bHQMT (HQ Matls)
    *	if a dependent record is found in:
    *
    *		HQMU Material Unit of Measure
    *  	INMT   Inventory - Added toTrigger 02/13/01 RM
    *
    *
    *	Audit deletions if any HQ Company using the Mat'l Group has the
    *	AuditMatl option set.
    */---------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @INCo bCompany, @Loc bLoc, @LocGroup bGroup,
	@vendorgroup bGroup, @vendor bVendor, @um bUM
	
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   -- deleted 9/8/97 to enable cascade delete of associated records in HQMU
   --/* check HQ Units of Measure */
   --if exists(select * from bHQMU s, deleted d where s.Material = d.Material and
   --	s.MatlGroup = d.MatlGroup)
   --	begin
   --	select @errmsg = 'HQ Material Units of Measure with this Material exist'
   --	goto error
   --	end
   
   --Exit if material exists in POVM  - DC 6/23/06
	IF exists(select 1 from deleted d join bPOVM v on d.Material  = v.Material and d.MatlGroup = v.MatlGroup)
		BEGIN
		select Top 1 @vendorgroup = VendorGroup, 
				@vendor = Vendor,
				@um = UM
		from deleted d join bPOVM v on d.Material  = v.Material and d.MatlGroup = v.MatlGroup
		select @errmsg = 'This Material exists in PO Vendor Materials for Vendor Group: ' + convert(varchar(1),@vendorgroup) + ' Vendor: ' + convert(varchar(10),@vendor) + ' and UM: ' + convert(varchar(3),@um)
		goto error
		END
   
   
   if exists(select * from deleted d join bINMT t on
   	d.Material  = t.Material and d.MatlGroup = t.MatlGroup)
   begin
   	select @INCo = (select max(t.INCo) from deleted d join bINMT t on
   	d.Material  = t.Material and d.MatlGroup = t.MatlGroup)
   
   	select @Loc = (select max(Loc) from deleted d join bINMT t on
   	d.Material  = t.Material and d.MatlGroup = t.MatlGroup and t.INCo = @INCo)
   
   	select @errmsg = 'This Material exists in INMaterials for IN Company ' + convert(varchar(10),@INCo) + ' at location ' + convert(varchar(30),@Loc)
   	goto error
   end
   
   /* Don't allow Material to be deleted if it is used in IN Bill of Materials (issue #21163). */
   if exists(select * from deleted d join bINBM m on
   	d.MatlGroup = m.MatlGroup and (d.Material = m.CompMatl or d.Material = m.FinMatl))
   begin
   	select @INCo = (select max(m.INCo) from deleted d join bINBM m on
   	(d.Material = m.CompMatl or d.Material = m.FinMatl) and d.MatlGroup = m.MatlGroup)
   
   	select @LocGroup = (select max(LocGroup) from deleted d join bINBM m on
   	(d.Material = m.CompMatl or d.Material = m.FinMatl) and d.MatlGroup = m.MatlGroup
   	and m.INCo = @INCo)
   
   	select @errmsg = 'This Material exists in IN Bill of Materials for IN Company ' + convert(varchar(10),@INCo) + ' for location group ' + convert(varchar(30),@LocGroup)
   	goto error
   end
   
   -- delete associated records in HQMU (no warning)
   delete from bHQMU
   from deleted d
   where bHQMU.Material = d.Material and bHQMU.MatlGroup = d.MatlGroup
   
   /* Audit HQ Material deletions */
   insert into dbo.bHQMA
       	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQMT', 'MatlGroup: ' + convert(varchar(3),d.MatlGroup) + ' Matl: ' + d.Material,
           d.MatlGroup, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d
   	join dbo.bHQCO c with (nolock)
   	on d.MatlGroup = c.MatlGroup
   	where  c.AuditMatl = 'Y'
   	group by d.MatlGroup, d.Material
   
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete HQ Material!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   /****** Object:  Trigger dbo.btHQMTi    Script Date: 8/28/99 9:37:35 AM ******/
   CREATE          trigger [dbo].[btHQMTi] on [dbo].[bHQMT] for INSERT as
   

/****************************************************************
    * Created: ??
    * Modified: 02/13/00 GG - Added validation for Metirc UM, Material Type, and Payment Disc Type
    *           04/10/02 CMW - Replaced NULL for HQMA.Company with MaterialGroup (issue # 16840)
    *			 07/11/02 CMW - Fixed duplicate entry problem (issue # 17902)
    *           08/12/02 CMW - Fixed sting/numeric problem (issue # 18249).
    *           09/24/02 DANF - Fixed insert into HQMA by removing min around Material and the group by. 18659
    *
    * Insert trigger for HQ Materials - validates and audits
    *
    ****************************************************************/
   
   declare @errmsg varchar(255), @numrows int, @validcount int, @nullcount int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate Category
   select @validcount = count(*) from bHQMC c
   join inserted i on i.MatlGroup = c.MatlGroup and i.Category = c.Category
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Invalid Category'
   	goto error
   	end
   
   -- validate Standard UM
   select @validcount = count(*) from bHQUM u
   join inserted i on i.StdUM = u.UM
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Invalid Standard Unit of Measure'
   	goto error
   	end
   
   -- validate Payment Discount Type
   if exists(select * from inserted where PayDiscType not in ('N','U','R'))
       begin
   	select @errmsg = 'Invalid Payment Discount Type.  Must be (N),(U), or (R)'
   	goto error
   	end
	
	--Issue 28325
  	 if exists(select * from inserted where StdUM ='LS')
     begin
	   	select @errmsg = 'Invalid Material Standard Unit of Measure.'
   		goto error
   	end   
	if exists(select * from inserted where SalesUM ='LS')
    begin
   		select @errmsg = 'Invalid Material Sales Unit of Measure.'
   		goto error
   	end
	if exists(select * from inserted where PurchaseUM ='LS')
    begin
   		select @errmsg = 'Invalid Material Purchase Unit of Measure.'
   		goto error
   	end   
	if exists(select * from inserted where MetricUM ='LS')
	begin
   		select @errmsg = 'Invalid Material Metric Unit of Measure.'
   		goto error
   	end   


   -- validate Purchase UM
   select @validcount = count(*) from bHQUM u
   join inserted i on i.PurchaseUM = u.UM
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Invalid Purchase Unit of Measure'
   	goto error
   	end
   
   -- validate Sales UM
   select @validcount = count(*) from bHQUM u
   join inserted i on i.SalesUM = u.UM
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Invalid Sales Unit of Measure'
   	goto error
   	end
   
   -- validate Metric UM
   select @validcount = count(*) from bHQUM u
   join inserted i on i.MetricUM = u.UM
   select @nullcount = count(*) from inserted where MetricUM is null
   if @numrows <> @validcount + @nullcount
   	begin
   	select @errmsg = 'Invalid Metric Unit of Measure'
   	goto error
   	end
   
   -- Phase, Cost Type, and Haul Code validation not needed
   
   -- validate Type
   if exists(select * from inserted where Type not in ('E','S'))
       begin
   	select @errmsg = 'Invalid Material Type.  Must be (E) or (S)'
   	goto error
   	end
   
   
   /* add HQ Master Audit entry */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'bHQMT',  'MatlGroup: ' + convert(varchar(3), i.MatlGroup) + ', Material: ' + Material ,
   			i.MatlGroup, 'A', null, null, null, getdate(), SUSER_SNAME() 
   		from inserted i
           join bHQCO a on i.MatlGroup=a.MatlGroup where a.AuditMatl='Y'
   		group by i.MatlGroup, i.Material
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert HQ Material!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btHQMTu    Script Date: 8/28/99 9:38:22 AM ******/
   CREATE       trigger [dbo].[btHQMTu] on [dbo].[bHQMT] for UPDATE as
   

/***************************************************************
    * Created: ??
    * Modified: 02/13/00 GG - Changed HQ Audit updates, removed cursor
    *           04/10/02 CMW - Replaced NULL for HQMA.Company with MaterialGroup (issue # 16840).
    *			 05/15/02 RM - Added validation to not allow change of StdUM if in use in INDT
    *           07/11/02 CMW - Fixed duplicate entry problem (issue # 17902).
    *           08/12/02 CMW - Fixed string/integer problem (issue # 18249).
	*			 04/17/07 AL	 - Added auditing for the Active field 
    *
    * Update trigger for HQ Mateials - validates and audits
    *
    **************************************************************/
   
   declare @numrows int, @validcount int, @nullcount int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* reject key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.MatlGroup = i.MatlGroup and d.Material = i.Material
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change Material Group or Material'
   	goto error
   	end
   
   -- validate Category
   select @validcount = count(*) from bHQMC c
   join inserted i on i.MatlGroup = c.MatlGroup and i.Category = c.Category
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Invalid Category'
   	goto error
   	end
   
   -- validate Standard UM
   select @validcount = count(*) from bHQUM u
   join inserted i on i.StdUM = u.UM
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Invalid Standard Unit of Measure'
   	goto error
   	end
   
   -- validate Payment Discount Type
   if exists(select * from inserted where PayDiscType not in ('N','U','R'))
       begin
   	select @errmsg = 'Invalid Payment Discount Type.  Must be (N, U, or R)'
   	goto error
   	end
   
   -- validate Purchase UM
   select @validcount = count(*) from bHQUM u
   join inserted i on i.PurchaseUM = u.UM
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Invalid Purchase Unit of Measure'
   	goto error
   	end
   
   -- validate Sales UM
   select @validcount = count(*) from bHQUM u
   join inserted i on i.SalesUM = u.UM
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Invalid Sales Unit of Measure'
   	goto error
   	end
   
   -- validate Metric UM
   select @validcount = count(*) from bHQUM u
   join inserted i on i.MetricUM = u.UM
   select @nullcount = count(*) from inserted where MetricUM is null
   if @numrows <> @validcount + @nullcount
   	begin
   	select @errmsg = 'Invalid Metric Unit of Measure'
   	goto error
   	end
   
   -- Phase, Cost Type, and Haul Code validation not needed
   
   -- validate Type
   if exists(select * from inserted where Type not in ('E','S'))
    begin
   	select @errmsg = 'Invalid Material Type.  Must be (E or S)'
   	goto error
   	end

   	--Issue 28325
	 if exists(select * from inserted where StdUM ='LS')
     begin
	   	select @errmsg = 'Invalid Material Standard Unit of Measure.'
   		goto error
   	end   
	if exists(select * from inserted where SalesUM ='LS')
    begin
   		select @errmsg = 'Invalid Material Sales Unit of Measure.'
   		goto error
   	end
	if exists(select * from inserted where PurchaseUM ='LS')
    begin
   		select @errmsg = 'Invalid Material Purchase Unit of Measure.'
   		goto error
   	end   
	if exists(select * from inserted where MetricUM ='LS')
	begin
   		select @errmsg = 'Invalid Material Metric Unit of Measure.'
   		goto error
   	end   




   if update(StdUM)
   begin
   	if exists(select * from INDT i join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material)
   	begin
   		select @errmsg = 'Cannot change StdUM while IN Detail Entries exist for this material.'
   		goto error
   	end
   end
   
   
   
   -- update HQ Master Audit if any Company using this Material Group has auditing selected
   if exists(select * from inserted i join bHQCO c on c.MatlGroup = i.MatlGroup and c.AuditMatl = 'Y')
   	begin
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Category', min(d.Category), min(i.Category), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.Category <> d.Category and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Description', min(d.Description), min(i.Description), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where isnull(i.Description,'') <> isnull(d.Description,'') and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Std UM', min(d.StdUM), min(i.StdUM), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.StdUM <> d.StdUM and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Cost', convert(varchar(20),min(d.Cost)), convert(varchar(20),min(i.Cost)), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.Cost <> d.Cost and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Cost ECM', min(d.CostECM), min(i.CostECM), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.CostECM <> d.CostECM and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Price', convert(varchar(20),min(d.Price)), convert(varchar(20),min(i.Price)), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.Price <> d.Price and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Price ECM', min(d.PriceECM), min(i.PriceECM), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.PriceECM <> d.PriceECM and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Pay Disc Type', min(d.PayDiscType), min(i.PayDiscType), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.PayDiscType <> d.PayDiscType and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Pay Disc Rate', convert(varchar(20),min(d.PayDiscRate)), convert(varchar(20),min(i.PayDiscRate)), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.PayDiscRate <> d.PayDiscRate and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Purchase UM', min(d.PurchaseUM), min(i.PurchaseUM), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.PurchaseUM <> d.PurchaseUM and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Sales UM', min(d.SalesUM), min(i.SalesUM), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.SalesUM <> d.SalesUM and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Metric UM', min(d.MetricUM), min(i.MetricUM), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where isnull(i.MetricUM,'') <> isnull(d.MetricUM,'') and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Weight Conv',convert(varchar(20),min(d.WeightConv)),convert(varchar(20),min(i.WeightConv)), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where isnull(i.WeightConv,-1) <> isnull(d.WeightConv,-1) and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Stocked', min(d.Stocked), min(i.Stocked), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.Stocked <> d.Stocked and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Taxable', min(d.Taxable), min(i.Taxable), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.Taxable <> d.Taxable and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Matl Phase', min(d.MatlPhase), min(i.MatlPhase), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where isnull(i.MatlPhase,'') <> isnull(d.MatlPhase,'') and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Matl Cost Type', convert(varchar(4),min(d.MatlJCCostType)), convert(varchar(4),min(i.MatlJCCostType)), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where isnull(i.MatlJCCostType,'') <> isnull(d.MatlJCCostType,'') and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Haul Phase', min(d.HaulPhase), min(i.HaulPhase), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where isnull(i.HaulPhase,'') <> isnull(d.HaulPhase,'') and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Haul Cost Type', convert(varchar(4),min(d.HaulJCCostType)), convert(varchar(4),min(i.HaulJCCostType)), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where isnull(i.HaulJCCostType,'') <> isnull(d.HaulJCCostType,'') and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Haul Code', min(d.HaulCode), min(i.HaulCode), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where isnull(i.HaulCode,'') <> isnull(d.HaulCode,'') and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
       insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Type', min(d.Type), min(i.Type), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.Type <> d.Type and c.AuditMatl = 'Y'
       group by i.MatlGroup

		insert into bHQMA select 'bHQMT', 'MatlGroup:' + convert(varchar(3),i.MatlGroup) + ' Material: ' + min(i.Material),
           i.MatlGroup, 'C', 'Active', min(d.Active), min(i.Active), getdate(), SUSER_SNAME()
    	from inserted i
       join deleted d on i.MatlGroup = d.MatlGroup and i.Material = d.Material
       join bHQCO c on c.MatlGroup = i.MatlGroup
       where i.Active <> d.Active and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
   	end
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update HQ Material!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
  
 





GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bHQMT].[Cost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bHQMT].[CostECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bHQMT].[Price]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bHQMT].[PriceECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQMT].[Stocked]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQMT].[Taxable]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQMT].[Active]'
GO
