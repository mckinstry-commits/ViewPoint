CREATE TABLE [dbo].[bPOVC]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PriceDisc] [dbo].[bPct] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPOVC] ON [dbo].[bPOVC] ([VendorGroup], [Vendor], [MatlGroup], [Category]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOVC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPOVCd    Script Date: 8/28/99 9:38:08 AM ******/
   CREATE  trigger [dbo].[btPOVCd] on [dbo].[bPOVC] for DELETE as
   

/*-----------------------------------------------------------------
    *	This trigger restricts deletion of any POVC records if 
    *	entries exist in POJC.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   
   set nocount on
   
   if exists(select * from bPOJC a, deleted d where a.VendorGroup=d.VendorGroup
   		and a.Vendor=d.Vendor and a.MatlGroup=d.MatlGroup
   		and a.Category=d.Category)
   	begin
   	select @errmsg='Job categories exist for this vendor category'
   	goto error
   	end
   
   	
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete PO Vendor Category!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPOVCi    Script Date: 8/28/99 9:38:08 AM ******/
   CREATE  trigger [dbo].[btPOVCi] on [dbo].[bPOVC] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: EN 11/16/98
    *  Modified: EN 11/16/98
    *
    *  This trigger rejects insertion in bPOVC (PO Vendor Category)
    *  if any of the following error conditions exist:
    *
    *	VendorGroup/Vendor does not exist in APVM
    *	Matl Group/Category does not exist in HQMC
    *		
    *-----------------------------------------------------------------*/
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
    
   /* validate Vendor Group/Vendor in APVM */
   select @validcnt = count(*) from bAPVM v, inserted i 
   	where i.VendorGroup = v.VendorGroup and i.Vendor = v.Vendor  
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Vendor not setup in AP Vendor Master'
   	goto error
   	end
   	
   /* validate MatlGroup/Category in HQMC */
   select @validcnt = count(*) from bHQMC m, inserted i 
   	where i.MatlGroup = m.MatlGroup and i.Category = m.Category 
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Group not setup in HQ Material Category'
   	goto error
   	end
   	
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert PO Vendor Category!'
       	RAISERROR(@errmsg, 11, -1);
   
       	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPOVCu    Script Date: 8/28/99 9:38:08 AM ******/
   CREATE  trigger [dbo].[btPOVCu] on [dbo].[bPOVC] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 11/16/98
    *  Modified: EN 11/16/98
    *
    *	This trigger rejects update in bPOVC (PO Vendor Category) if any of the 
    *	following error conditions exist:
    *
    *		Cannot change VendorGroup
    *		Cannot change Vendor
    *		Cannot change MatlGroup
    *		Cannot change Category
    *		
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   
   set nocount on
   
   /* verify primary key not changed */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.VendorGroup = i.VendorGroup and d.Vendor = i.Vendor and
   	d.MatlGroup = i.MatlGroup and d.Category = i.Category
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Primary Key'
   	goto error
   	end
   	
   	
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update PO Vendor Category!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
  
 



GO
