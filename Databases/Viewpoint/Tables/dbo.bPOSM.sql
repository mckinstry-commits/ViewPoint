CREATE TABLE [dbo].[bPOSM]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[VendMatId] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPOSM] ON [dbo].[bPOSM] ([VendorGroup], [Vendor], [MatlGroup], [Material], [UM], [VendMatId]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOSM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btPOSMi    Script Date: 12/16/99 02:32:00 PM ******/
   
   CREATE trigger [dbo].[btPOSMi] on [dbo].[bPOSM] for INSERT as
   

/*--------------------------------------------------------------
    *  Insert trigger for POSM
    *  Created By: EN
    *  Date:       12/19/99
    *
    *  Insert trigger for POSM - PO Substitute Materials
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate Header exists in bPOVM
   select @validcnt = count(*)
   from bPOVM r
   JOIN inserted i ON i.VendorGroup = r.VendorGroup and i.Vendor = r.Vendor and i.MatlGroup = r.MatlGroup
       and i.Material = r.Material and i.UM = r.UM
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Vendor Materials header is missing '
      goto error
      end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert PO Substitute Materials'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPOSMu    Script Date: 8/28/99 9:38:06 AM ******/
   
    CREATE  trigger [dbo].[btPOSMu] on [dbo].[bPOSM] for UPDATE as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int,@errmsg varchar(255), @errno tinyint, @validcnt int, @rcode tinyint
   
    /*--------------------------------------------------------------
     *
     *  Update trigger for POSM
     *  Created By: EN
     *  Date:       12/19/99
     *
     *  Rejects any primary key changes.
     *--------------------------------------------------------------*/
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
    /* check for key changes */
    select @validcnt = count(*) from deleted d, inserted i
    	where d.VendorGroup = i.VendorGroup and d.Vendor = i.Vendor and d.MatlGroup = i.MatlGroup
       and d.Material = i.Material and d.UM = i.UM and d.VendMatId = i.VendMatId
    if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change Vendor Group, Vendor, Material Group, Material, Unit of Measure, or Vendor Material ID ', @rcode = 1
    	goto error
    	end
   
   
    return
   
    error:
       select @errmsg = @errmsg + ' - cannot update PO Substitute Materials'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
  
 



GO
