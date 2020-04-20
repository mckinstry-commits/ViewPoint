CREATE TABLE [dbo].[bPOJC]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PriceDisc] [dbo].[bPct] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPOJCi    Script Date: 8/28/99 9:38:08 AM ******/
   CREATE  trigger [dbo].[btPOJCi] on [dbo].[bPOJC] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: EN 11/17/98
    *  Modified: EN 11/17/98
    *
    *  This trigger rejects insertion in bPOJC (PO Vendor Job Category)
    *  if any of the following error conditions exist:
    *
    *	Header entry does not exist in POVC
    *	Matl Group/Category does not exist in HQMC
    *	JCCo and/or Job is invalid
    *
    *-----------------------------------------------------------------*/
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* check for existence of POVC entry */
   select @validcnt = count(*) from bPOVC a, inserted i
       where i.VendorGroup = a.VendorGroup and i.Vendor = a.Vendor and i.MatlGroup = a.MatlGroup
       and i.Category = a.Category
   if @validcnt <> @numrows
   	begin
   	select @errmsg='Vendor category does not exist for this job category'
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
   
   /* Validate job company */
   select @validcnt = count(*) from bJCCO j join inserted i on i.JCCo = j.JCCo
   if @validcnt<> @numrows
      begin
      select @errmsg = 'JCCo is Invalid '
      goto error
      end
   
   /* Validate job */
   select @validcnt = count(*) from bJCJM j join inserted i on i.JCCo = j.JCCo and i.Job = j.Job
   if @validcnt<> @numrows
      begin
      select @errmsg = 'Job is Invalid '
      goto error
      end
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert PO Vendor Job Category!'
       	RAISERROR(@errmsg, 11, -1);
   
       	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPOJCu    Script Date: 8/28/99 9:38:08 AM ******/
   CREATE  trigger [dbo].[btPOJCu] on [dbo].[bPOJC] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 11/16/98
    *  Modified: EN 11/16/98
    *
    *	This trigger rejects update in bPOJC (PO Vendor Job Category) if any of the 
    *	following error conditions exist:
    *
    *		Cannot change VendorGroup
    *		Cannot change Vendor
    *		Cannot change MatlGroup
    *		Cannot change Category
    *		Cannot change JCCo
    *		Cannot change Job
    *		
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   
   set nocount on
   
   /* verify primary key not changed */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.VendorGroup = i.VendorGroup and d.Vendor = i.Vendor and
   	d.MatlGroup = i.MatlGroup and d.Category = i.Category and
   	d.JCCo = i.JCCo and d.Job = i.Job
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Primary Key'
   	goto error
   	end
   	
   	
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update PO Vendor Job Category!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOJC] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPOJC] ON [dbo].[bPOJC] ([VendorGroup], [Vendor], [MatlGroup], [Category], [JCCo], [Job]) ON [PRIMARY]
GO
