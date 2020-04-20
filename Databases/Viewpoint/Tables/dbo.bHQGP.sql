CREATE TABLE [dbo].[bHQGP]
(
[Grp] [dbo].[bGroup] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHQGP] ON [dbo].[bHQGP] ([Grp]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQGP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btHQGPd    Script Date: 8/28/99 9:37:34 AM ******/
   CREATE  trigger [dbo].[btHQGPd] on [dbo].[bHQGP] for DELETE as
   

/*----------------------------------------------------------
    *	This trigger rejects delete in bHQGP (HQ Groups) if a 
    *	dependent record is found in:
    *
    *		Used in bHQCO
    *		VendorGroup, MatlGroup, PhaseGroup, CustGroup, TaxGroup
    *		Detail exists in bAPVM, bHQMC or bHQMT, bJCPM, bARCM, bHQTX	
    *
    */---------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* check HQCo.VendorGroup */
   if exists(select * from bHQCO h, deleted d where h.VendorGroup = d.Grp)
   	begin
   	select @errmsg = 'Assigned as a Vendor Group in HQ Company'
   	goto error
   	end
   	   
   /* check HQCo.MatlGroup */
   if exists(select * from bHQCO h, deleted d where h.MatlGroup = d.Grp)
   	begin
   	select @errmsg = 'Assigned as a Material Group in HQ Company'
   	goto error
   	end
   	   
   
   /* check HQCo.PhaseGroup */
   if exists(select * from bHQCO h, deleted d where h.PhaseGroup = d.Grp)
   	begin
   	select @errmsg = 'Assigned as a Phase Group in HQ Company'
   	goto error
   	end
   	   
   /* check HQCo.CustGroup */
   if exists(select * from bHQCO h, deleted d where h.CustGroup = d.Grp)
   	begin
   	select @errmsg = 'Assigned as a Customer Group in HQ Company'
   	goto error
   	end
   	   
   /* check HQCo.TaxGroup */
   if exists(select * from bHQCO h, deleted d where h.TaxGroup = d.Grp)
   	begin
   	select @errmsg = 'Assigned as a Tax Group in HQ Company'
   	goto error
   	end
   
   /* check Vendors */
   if exists(select * from bAPVM s, deleted d where s.VendorGroup = d.Grp)
   	begin
   	select @errmsg = 'AP Vendors exist for the Group'
   	goto error
   	end
   
   /* check Materials */
   if exists(select * from bHQMT s, deleted d where s.MatlGroup = d.Grp)
   	begin
   
   	select @errmsg = 'HQ Materials exist for the Group'
   	goto error
   	end
      
   /* check Material Categories */
   if exists(select * from bHQMC s, deleted d where s.MatlGroup = d.Grp)
   	begin
   	select @errmsg = 'HQ Material Categories exist for the Group'
   
   	goto error
   	end	
   
   /* check Phases */
   if exists(select * from bJCPM s, deleted d where s.PhaseGroup = d.Grp)
   	begin
   	select @errmsg = 'JC Phases exist for the Group'
   	goto error
   	end
   
   /* check Customers */
   if exists(select * from bARCM s, deleted d where s.CustGroup = d.Grp)
   	begin
   	select @errmsg = 'AR Customers exist for the Group'
   	goto error
   	end
   
   /* check Taxes */
   if exists(select * from bHQTX s, deleted d where s.TaxGroup = d.Grp)
   	begin
   	select @errmsg = 'HQ Taxes exist for the Group'
   	goto error
   	end
   
   return
   
   error:
   	
   	select @errmsg = @errmsg + ' - cannot delete HQ Group!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQGPu    Script Date: 8/28/99 9:37:34 AM ******/
   CREATE  trigger [dbo].[btHQGPu] on [dbo].[bHQGP] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bHQCO (HQ Groups) if the 
   
    *	following error condition exists:
    *
    *		Cannot change HQ Group
    *
    */----------------------------------------------------------------
   
   /* initialize */
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* reject key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.Grp = i.Grp
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change HQ Group'
   	goto error
   	end
   
   return
   
   error:
   		
   	select @errmsg = @errmsg + ' - cannot update HQ Group!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
