CREATE TABLE [dbo].[bPOSL]
(
[POCo] [dbo].[bCompany] NOT NULL,
[ShipLoc] [dbo].[bShipLoc] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPOSLd    Script Date: 8/28/99 9:38:07 AM ******/
   CREATE  trigger [dbo].[btPOSLd] on [dbo].[bPOSL] for DELETE as
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255)
   
   /*--------------------------------------------------------------
    *
    *  Delete trigger for POSL
    *  Created By: EN
    *  Date: 12/18/99
    *
    *  Reject if Shipping Location used in POHD.
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount
    if @numrows = 0 return
   
   set nocount on
   
   /* check for Shipping Location in POHD */
   if exists(select * from bPOHD a, deleted d where a.POCo = d.POCo and a.ShipLoc = d.ShipLoc)
   	begin
   	select @errmsg='Shipping Location in use in PO Header '
   	goto error
   	end
   
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot remove PO Shipping Location'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btPOSLi    Script Date: 12/16/99 02:32:00 PM ******/
   
   CREATE trigger [dbo].[btPOSLi] on [dbo].[bPOSL] for INSERT as
   

/*--------------------------------------------------------------
    *  Insert trigger for POSL
    *  Created By: EN
    *  Date:       12/18/99
    *
    *  Insert trigger for POSL - PO Shipping Locations
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate PO company
   select @validcnt = count(*)
   from bPOCO r
   JOIN inserted i ON i.POCo = r.POCo
   if @validcnt <> @numrows
      begin
      select @errmsg = 'PO company is Invalid '
      goto error
      end
   
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert PO Shipping Location'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPOSLu    Script Date: 8/28/99 9:38:06 AM ******/
   
    CREATE  trigger [dbo].[btPOSLu] on [dbo].[bPOSL] for UPDATE as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int,@errmsg varchar(255), @errno tinyint, @validcnt int, @rcode tinyint
   
    /*--------------------------------------------------------------
     *
     *  Update trigger for POSL
     *  Created By: EN
     *  Date:       12/18/99
     *
     *  Rejects any primary key changes.
     *--------------------------------------------------------------*/
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
    /* check for key changes */
    select @validcnt = count(*) from deleted d, inserted i
    	where d.POCo = i.POCo and d.ShipLoc = i.ShipLoc
    if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change PO Company, or Shipping Location ', @rcode = 1
    	goto error
    	end
   
   
    return
   
    error:
       select @errmsg = @errmsg + ' - cannot update PO Shipping Location'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOSL] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPOSL] ON [dbo].[bPOSL] ([POCo], [ShipLoc]) ON [PRIMARY]
GO
