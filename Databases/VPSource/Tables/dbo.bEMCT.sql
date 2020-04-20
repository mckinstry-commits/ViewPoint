CREATE TABLE [dbo].[bEMCT]
(
[EMGroup] [dbo].[bGroup] NOT NULL,
[CostType] [dbo].[bEMCType] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Abbreviation] [char] (10) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bEMCT] ADD
CONSTRAINT [FK_bEMCT_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMCTd    Script Date: 8/28/99 9:37:16 AM ******/
   CREATE   trigger [dbo].[btEMCTd] on [dbo].[bEMCT] for DELETE as
   

declare @errmsg varchar(255), @validcnt int 
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects delete in bEMCT (EM Cost Types) if  the following error condition exists:
    *
    *		Entry exist in EMCX - EM Cost Code/Type Master by EMGroup/CostType
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   /* Check EMCX. */
   if exists(select * from deleted d, bEMCX e where d.EMGroup = e.EMGroup and d.CostType=e.CostType)
   	begin
   	select @errmsg = 'Entries exist in EMCX for this EMGroup'
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Cost Type!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMCTi    Script Date: 8/28/99 9:37:16 AM ******/
   CREATE   trigger [dbo].[btEMCTi] on [dbo].[bEMCT] for INSERT as
   

declare @errmsg varchar(255), @errno int, @numrows int,
   	@validcnt int, @validcnt2 int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By : bc 06/30/99  added cost type onto the where clause of the abbr. validation
    *				 TV 02/11/04 - 23061 added isnulls
    *	This trigger rejects insertion in bEMCT (EM Cost Types) if the	following error condition exists:
	*				GF 05/05/2013 TFS-49039
    *
    *		CostType not between 1 - 255
    *		Invalid EMGroup vs bHQGP
    *		Abbreviation not unique by EMGroup
    *
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   
 
   /* Verify Abbreviation unique for EMGroup. */
   select @validcnt = count(*) from bEMCT e, inserted i where e.Abbreviation = i.Abbreviation and e.EMGroup = i.EMGroup and e.CostType <> i.CostType
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Invalid Abbreviation - must be unique for this EMGroup'
   	goto error
   	end
   
   
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Cost Type!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   	
   
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMCTu    Script Date: 8/28/99 9:37:16 AM ******/
   CREATE   trigger [dbo].[btEMCTu] on [dbo].[bEMCT] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By : bc 06/30/99  added cost type onto the where clause of the abbr. validation
    *				 TV 02/11/04 - 23061 added isnulls
    *	This trigger rejects update in bEMCT (EM Cost Types) if  the following error condition exists:
    *
    *		Change in key fields (EMGroup or CostType)
    *		Abbreviation not unique for EMGroup
    *
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
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
   
   /* Verify Abbreviation unique for EMGroup. */
   if update(Abbreviation)
   	begin
    	select @validcnt = count(*) from bEMCT e, inserted i
    	where e.Abbreviation = i.Abbreviation and i.EMGroup = e.EMGroup and e.CostType <> i.CostType
   	if @validcnt <> 0
   		begin
   		select @errmsg = 'Invalid Abbreviation - must be unique for this EMGroup'
   		goto error
   		end
   	end
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Cost Type!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMCT] ON [dbo].[bEMCT] ([EMGroup], [CostType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMCT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
