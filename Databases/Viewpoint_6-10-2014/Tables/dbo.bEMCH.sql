CREATE TABLE [dbo].[bEMCH]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[CostType] [dbo].[bEMCType] NOT NULL,
[CostCode] [dbo].[bCostCode] NOT NULL,
[UM] [dbo].[bUM] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMCHd    Script Date: 8/28/99 9:37:15 AM ******/
   CREATE   trigger [dbo].[btEMCHd] on [dbo].[bEMCH] for Delete
   as
   
   

/**************************************************************
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects delete in bEMCH (EM Cost Header) if  the following error condition exists:
    *
    *		Records exist in bEMMC for EMCo/Equipment/EMGroup/Cost Code/Cost Type
    *
   **************************************************************/
   declare @errmsg varchar(255), @validcnt int, @numrows int, @rcode int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* Check bEMMC. */
   if exists(select * from deleted d, bEMMC e 
   where d.EMCo = e.EMCo and d.Equipment = e.Equipment
   	and d.EMGroup = e.EMGroup and d.CostCode = e.CostCode
   	and d.CostType=e.CostType)
   	begin
   	select @errmsg = 'Entries exist in bEMMC for this EMCo/Equipment/EMGroup/Cost Code/Cost Type'
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Cost Header!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE   trigger [dbo].[btEMCHi] on [dbo].[bEMCH] for insert
   as
   

/**************************************************************
   *	CREATED BY: JM 5/19/99
   *	MODIFIED By : TV 02/11/04 - 23061 added isnulls
   *				  GF 05/05/2013 TFS-49039
   *
   *	This trigger rejects insert in bEMCH (EM Cost Header) if the following error condition exists:
   *
   *		Invalid EMCo vs bEMCO
   *		Invalid Equipment vs bEMEM by EMCo
   *		Invalid EMGroup vs bHQGP
   *		Invalid Cost Code vs (1) bEMCC by EMGroup and (2) bEMCX by EMGroup/CostType
   *		Invalid Cost Type vs (1) bEMCT by EMGroup and (2) bEMCX by EMGroup/CostCode
   *	  	Invalid UM vs (1) bHQUM and (2) bEMCX by EMGroup/CostCode/CostType
   *		
   *
   **************************************************************/
   declare @errmsg varchar(255), @validcnt int, @numrows int, @rcode int
   
   select @numrows = @@rowcount
   
   if @numrows = 0 return
   
   set nocount on
   

   select @validcnt = count(*) from bEMCX e, inserted i 
   where i.EMGroup =e.EMGroup and i.CostCode = e.CostCode and i.CostType = e.CostType
   if @validcnt<> @numrows
   	begin
   	select @errmsg = 'Invalid CostCode - not in bEMCX for EMGroup and CostType'
   	goto error
   	end
   

   select @validcnt = count(*) from bEMCX e, inserted i 
   where i.EMGroup =e.EMGroup and i.CostCode = e.CostCode and i.CostType = e.CostType
   if @validcnt<> @numrows
   	begin
   	select @errmsg = 'Invalid CostType - not in bEMCX for EMGroup and CostCode'
   	goto error
   	end
   
   /* Validate UM. */
   select @validcnt = count(*) from bHQUM h, inserted i 
   where i.UM =h.UM
   if @validcnt<> @numrows
   	begin
   	select @errmsg = 'Invalid UM - not in bHQUM'
   	goto error
   	end
   select @validcnt = count(*) from bEMCX e, inserted i 
   where i.EMGroup =e.EMGroup and i.CostCode = e.CostCode and i.CostType = e.CostType and i.UM = e.UM
   if @validcnt<> @numrows
   	begin
   	select @errmsg = 'Invalid UM - not in bEMCX for EMGroup, CostType and CostCode'
   	goto error
   	end
   	
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Cost Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 

CREATE   trigger [dbo].[btEMCHu] on [dbo].[bEMCH] for Update
as

/**************************************************************
   *	CREATED BY: JM 5/19/99
   *	MODIFIED By : TV 02/11/04 - 23061 added isnulls
   *					GF 05/15/2013 TFS-49039
   *
   *
   *	This trigger rejects insert in bEMCH (EM Cost Header) if the following error condition exists:
   *
   *		Change to any key field (EMCo/EMGroup/Equipment/CostType/CostCode)
   *		Invalid UM vs (1) bHQUM and (2) bEMCX by EMGroup/CostCode/CostType
   *
   **************************************************************/
   declare @errmsg varchar(255), @validcnt int, @numrows int, @rcode int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   ----TFS-49039  
SELECT @validcnt = COUNT(*) FROM dbo.bEMEM EMEM JOIN inserted i ON i.EMCo = EMEM.EMCo AND i.Equipment = EMEM.Equipment and EMEM.ChangeInProgress = 'Y'
IF @validcnt = @numrows RETURN

   /* Check for changes to key fields. */
   if update(EMGroup)
   	begin
   	select @errmsg = 'Cannot change EMGroup'
   	goto error
   	end 
   if update(CostType)
   	begin
   	select @errmsg = 'Cannot change CostType'
   	goto error
   	end 
   if update(CostCode)
   	begin
   	select @errmsg = 'Cannot change CostCode'
   	goto error
   	end 				
   
   /* Validate UM. */
   if update(UM)
   	begin
   	select @validcnt = count(*) from bHQUM h, inserted i 
   	where i.UM =h.UM
   	if @validcnt<> @numrows
   		begin
   		select @errmsg = 'Invalid UM - not in bHQUM'
   		goto error
   		END
        
   	select @validcnt = count(*) from bEMCX e, inserted i 
   	where i.EMGroup =e.EMGroup and i.CostCode = e.CostCode and i.CostType = e.CostType and i.UM = e.UM
   	if @validcnt<> @numrows
   		begin
   		select @errmsg = 'Invalid UM - not in bEMCX for EMGroup, CostType and CostCode'
   		goto error
   		end
   	end
   	
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Cost Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 




GO
CREATE UNIQUE CLUSTERED INDEX [biEMCH] ON [dbo].[bEMCH] ([EMCo], [EMGroup], [Equipment], [CostType], [CostCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMCH] WITH NOCHECK ADD CONSTRAINT [FK_bEMCH_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMCH] WITH NOCHECK ADD CONSTRAINT [FK_bEMCH_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bEMCH] WITH NOCHECK ADD CONSTRAINT [FK_bEMCH_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMCH] WITH NOCHECK ADD CONSTRAINT [FK_bEMCH_bEMCC_CostCode] FOREIGN KEY ([EMGroup], [CostCode]) REFERENCES [dbo].[bEMCC] ([EMGroup], [CostCode])
GO
ALTER TABLE [dbo].[bEMCH] WITH NOCHECK ADD CONSTRAINT [FK_bEMCH_bEMCT_CostType] FOREIGN KEY ([EMGroup], [CostType]) REFERENCES [dbo].[bEMCT] ([EMGroup], [CostType])
GO
ALTER TABLE [dbo].[bEMCH] NOCHECK CONSTRAINT [FK_bEMCH_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMCH] NOCHECK CONSTRAINT [FK_bEMCH_bEMEM_Equipment]
GO
ALTER TABLE [dbo].[bEMCH] NOCHECK CONSTRAINT [FK_bEMCH_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMCH] NOCHECK CONSTRAINT [FK_bEMCH_bEMCC_CostCode]
GO
ALTER TABLE [dbo].[bEMCH] NOCHECK CONSTRAINT [FK_bEMCH_bEMCT_CostType]
GO
