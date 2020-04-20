CREATE TABLE [dbo].[bPOJM]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[CostOpt] [tinyint] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NULL,
[CostECM] [dbo].[bECM] NULL,
[PriceDisc] [dbo].[bPct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btPOJMi    Script Date: 12/16/99 02:32:00 PM ******/
   
   CREATE trigger [dbo].[btPOJMi] on [dbo].[bPOJM] for INSERT as
   

/*--------------------------------------------------------------
    *  Insert trigger for POJM
    *  Created By: EN
    *  Date:       12/18/99
    *
    *  Insert trigger for POJM - PO Vendor Job Material
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
   
   -- validate JC company
   select @validcnt = count(*)
   from bJCCO r
   JOIN inserted i ON i.JCCo = r.JCCo
   if @validcnt <> @numrows
      begin
      select @errmsg = 'JC company is Invalid '
      goto error
      end
   
   -- validate Job
   select @validcnt = count(*)
   from bJCJM r
   JOIN inserted i ON i.JCCo = r.JCCo and i.Job = r.Job
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Job is Invalid '
      goto error
      end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert PO Job Material'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPOJMu    Script Date: 8/28/99 9:38:06 AM ******/
   
    CREATE  trigger [dbo].[btPOJMu] on [dbo].[bPOJM] for UPDATE as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int,@errmsg varchar(255), @errno tinyint, @validcnt int, @validcnt2 int, @rcode tinyint
   
    /*--------------------------------------------------------------
     *
     *  Update trigger for POJM
     *  Created By: EN
     *  Date:       12/18/99
     *
     *  Rejects any primary key changes and validates JCCo and Job.
     *--------------------------------------------------------------*/
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
    /* check for key changes */
    select @validcnt = count(*) from deleted d, inserted i
    	where d.VendorGroup = i.VendorGroup and d.Vendor = i.Vendor and d.MatlGroup = i.MatlGroup
       and d.Material = i.Material and d.UM = i.UM and d.JCCo = i.JCCo and d.Job = i.Job
    if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change VendorGroup, Vendor, Material Group, Unit of Measure, JC Company, or Job ', @rcode = 1
    	goto error
    	end
   
   
    return
   
    error:
       select @errmsg = @errmsg + ' - cannot update PO Job Material'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOJM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPOJM] ON [dbo].[bPOJM] ([VendorGroup], [Vendor], [MatlGroup], [Material], [UM], [JCCo], [Job]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPOJM].[UnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bPOJM].[CostECM]'
GO
