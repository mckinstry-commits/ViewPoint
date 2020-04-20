CREATE TABLE [dbo].[bPOVM]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[VendMatId] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[CostOpt] [tinyint] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NULL,
[CostECM] [dbo].[bECM] NULL,
[BookPrice] [dbo].[bUnitCost] NULL,
[PriceECM] [dbo].[bECM] NULL,
[PriceDisc] [dbo].[bPct] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPOVMd    Script Date: 8/28/99 9:38:06 AM ******/
   CREATE  trigger [dbo].[btPOVMd] on [dbo].[bPOVM] for DELETE as
   

/*--------------------------------------------------------------
    *  Created By: EN 12/28/99
    *
    *  Delete trigger for PO Vendor Material
    *  Rejects delete if entries in bPOSM or bPOJM exist.
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- check for POSM entries
   if exists(select * from deleted d join bPOSM t on d.VendorGroup = t.VendorGroup and d.Vendor = t.Vendor
               and d.MatlGroup = t.MatlGroup and d.Material = t.Material and d.UM = t.UM)
   	begin
   	select @errmsg = 'PO Substitute Materials exist '
   	goto error
   	end
   
   -- check for POJM entries
   if exists(select * from deleted d join bPOJM t on d.VendorGroup = t.VendorGroup and d.Vendor = t.Vendor
               and d.MatlGroup = t.MatlGroup and d.Material = t.Material and d.UM = t.UM)
   	begin
   	select @errmsg = 'PO Job Materials exist '
   	goto error
   	end
   
   return
   error:
      select @errmsg = @errmsg + ' - cannot remove PO Vendor Material'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btPOVMi    Script Date: 12/16/99 02:32:00 PM ******/
   
   CREATE trigger [dbo].[btPOVMi] on [dbo].[bPOVM] for INSERT as
   

/*--------------------------------------------------------------
    *  Insert trigger for POVM - PO Vendor Materials
    *  Created By: EN
    *  Date:       12/28/99
    *
    *  Validates Vendor Group, Vendor, Material Group, Material, and UM.
    *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate Vendor Group/Vendor
   select @validcnt = count(*)
   from bAPVM r
   JOIN inserted i ON i.VendorGroup = r.VendorGroup and i.Vendor = r.Vendor
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid Vendor Group or Vendor '
      goto error
      end
   
   -- validate Matl' Group/Material
   select @validcnt = count(*)
   from bHQMT r
   JOIN inserted i ON i.MatlGroup = r.MatlGroup and i.Material = r.Material
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid Material Group or Material '
      goto error
      end
   
   -- validate that UM is either std UM for material, or exists in bHQMU
   if not exists(select * from bHQMT r
                 join inserted i on i.MatlGroup = r.MatlGroup and i.Material = r.Material
                 and i.UM = r.StdUM)
   and not exists(select * from bHQMU r
                 join inserted i on i.MatlGroup = r.MatlGroup and i.Material = r.Material
                 and i.UM = r.UM)
       begin
   	select @errmsg='Unit of Measure must either be standard UM for material or set up as additional UM '
   	goto error
   	end
   
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert PO Vendor Material'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPOVMu    Script Date: 8/28/99 9:38:06 AM ******/
   
    CREATE  trigger [dbo].[btPOVMu] on [dbo].[bPOVM] for UPDATE as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int,@errmsg varchar(255), @errno tinyint, @validcnt int, @rcode tinyint
   
    /*--------------------------------------------------------------
     *  Update trigger for POVM
     *  Created By: EN
     *  Date:       12/28/99
     *
     *  Rejects any primary key changes.
     *--------------------------------------------------------------*/
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
    /* check for key changes */
    select @validcnt = count(*) from deleted d, inserted i
    	where d.VendorGroup = i.VendorGroup and d.Vendor = i.Vendor and d.MatlGroup = i.MatlGroup
       and d.Material = i.Material and d.UM = i.UM
    if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change Vendor Group, Vendor, Material Group, Material or Unit of Measure', @rcode = 1
    	goto error
    	end
   
   
    return
   
    error:
       select @errmsg = @errmsg + ' - cannot update PO Vendor Materials'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOVM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPOVM] ON [dbo].[bPOVM] ([VendorGroup], [Vendor], [MatlGroup], [Material], [UM]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPOVM].[UnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bPOVM].[CostECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPOVM].[BookPrice]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bPOVM].[PriceECM]'
GO
