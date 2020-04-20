CREATE TABLE [dbo].[bMSVT]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Truck] [dbo].[bTruck] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[TruckType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Axles] [tinyint] NULL,
[GrossWght] [dbo].[bUnits] NOT NULL,
[TareWght] [dbo].[bUnits] NOT NULL,
[WghtCap] [dbo].[bUnits] NOT NULL,
[WghtUM] [dbo].[bUM] NULL,
[LicPlateNo] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[LicState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[LicExpDate] [dbo].[bDate] NULL,
[Driver] [dbo].[bDesc] NULL,
[PermitDate] [dbo].[bDate] NULL,
[InsDate] [dbo].[bDate] NULL,
[PayCode] [dbo].[bPayCode] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSVTd] on [dbo].[bMSVT] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/06/2000
    *  Modified By:
    *
    *	This trigger rejects delete in bMSVT (MS Vendor Trucks)
    *	if the following error condition exists:
    *
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int
   if @@rowcount = 0 return
   set nocount on
   
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot delete MS Vendor Truck!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSVTi] on [dbo].[bMSVT] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/06/2000
    *  Modified By: GF 10/25/2000 Issue #11115
    *
    *	This trigger rejects insertion in bMSVT (MS Vendor Trucks)
    *	if the following error condition exists:
    *
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- validate vendor group
   select @validcnt = count(*) from inserted i join bHQGP g on g.Grp = i.VendorGroup
   if @validcnt <> @numrows
       begin
   	select @errmsg = 'Invalid Vendor Group'
   	goto error
   	end
   
   -- validate AP Vendor
   select @validcnt = count(*) from inserted i join bAPVM c on
       c.VendorGroup = i.VendorGroup and c.Vendor=i.Vendor
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid AP Vendor!'
       goto error
       end
   
   
   /*
   -- validate Truck Type
   select @validcnt = count(*) from inserted i join bMSTT t on
       t.TruckType = i.TruckType
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid MS Truck Type!'
       goto error
       end
   
   -- validate Pay Code
   select @validcnt = count(*) from inserted i join bMSPC p on
       p.PayCode = i.PayCode
   select @nullcnt = count(*) from inserted where PayCode is null
   if @validcnt+@nullcnt <> @numrows
       begin
       select @errmsg = 'Invalid Pay Code!'
       goto error
       end
   */
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert MS Vendor Truck!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSVTu] on [dbo].[bMSVT] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/06/2000
    *  Modified By:
    *
    *	This trigger rejects update in bMSVT (MS Vendor Trucks)
    *  if any of the following error conditions exist:
    *
    *  Cannot change Vendor Group
    *  Cannot change Vendor
    *  Cannot change Vendor Truck
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for changes to Vendor Group
   if update(VendorGroup)
   	begin
   	select @errmsg = 'Cannot change Vendor Group'
   	goto error
   	end
   
   -- check for changes to Vendor
   if update(Vendor)
   	begin
   	select @errmsg = 'Cannot change Vendor'
   	goto error
   	end
   
   -- check for changes to Truck
   if update(Truck)
   	begin
   	select @errmsg = 'Cannot change Vendor Truck'
   	goto error
   	end
   
   /*
   -- validate Truck Type
   select @validcnt = count(*) from inserted i join bMSTT t on
       t.TruckType = i.TruckType
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid MS Truck Type!'
       goto error
       end
   
   -- validate Pay Code
   select @validcnt = count(*) from inserted i join bMSPC p on
       p.PayCode = i.PayCode
   select @nullcnt = count(*) from inserted where PayCode is null
   if @validcnt+@nullcnt <> @numrows
       begin
       select @errmsg = 'Invalid Pay Code!'
       goto error
       end
   */
   
   return
   
   
   
   error:
       select @errmsg = @errmsg + ' - cannot update Vendor Trucks!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSVT] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSVT] ON [dbo].[bMSVT] ([VendorGroup], [Vendor], [Truck]) ON [PRIMARY]
GO
