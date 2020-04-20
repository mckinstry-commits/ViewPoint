CREATE TABLE [dbo].[bEMTY]
(
[EMGroup] [dbo].[bGroup] NOT NULL,
[ComponentTypeCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMTYd    Script Date: 8/28/99 9:37:23 AM ******/
   CREATE   trigger [dbo].[btEMTYd] on [dbo].[bEMTY] for DELETE as
   

declare @errmsg varchar(255), @validcnt int 
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects delete in bEMTY (EM Component Type Codes) if  the following error condition exists:
    *
    *		Entry exists in EMEM - EM Equipment Master by EMGroup
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   
   /* Check EMEM. */
   if exists(select * from deleted d, bEMEM e where d.EMGroup = e.EMGroup and d.ComponentTypeCode=e.ComponentTypeCode)
   	begin
   	select @errmsg = 'Entries exist in EMEM with this EMGroup'
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Component Type Code!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMTYi    Script Date: 8/28/99 9:37:23 AM ******/
   CREATE   trigger [dbo].[btEMTYi] on [dbo].[bEMTY] for INSERT as
   

/*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects insertion in bEMTY (EM Component Type Codes) if the
    *	following error condition exists:
    *
    *		Invalid EMGroup vs bHQGP
    *		Invalid CostCode vs bEMCC by EMGroup
    *
    */----------------------------------------------------------------
   
   declare @costcode varchar(10), 
   	@errmsg varchar(255), 
   	@numrows int, 
   	@validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* Validate EMGroup. */
   select @validcnt = count(*) from bHQGP p, inserted i where p.Grp = i.EMGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid EMGroup'
   
   	goto error
   	end
   
   /* Validate CostCode. */
   select @costcode = CostCode from inserted
   if @costcode is not null
   	begin
   	select @validcnt = count(*) from bEMCC e, inserted i 
   	where e.EMGroup = i.EMGroup and e.CostCode = i.CostCode
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid CostCode'
   		goto error
   		end
   	end
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Component Type Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMTYu    Script Date: 8/28/99 9:37:23 AM ******/
   CREATE   trigger [dbo].[btEMTYu] on [dbo].[bEMTY] for UPDATE as
   

/*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects update in bEMTY (EM Component Type Codes) if any
    *	of the following error conditions exist:
    *
    *		Change in key fields (EMGroup or ComponentTypeCode)
    *		Invalid CostCode vs bEMCC by EMGroup
    *
    */----------------------------------------------------------------
   
   declare @costcode varchar(10),
   	@errmsg varchar(255), 
   	@numrows int, 
   	@validcnt int
   	
   select @numrows = @@rowcount
   if @numrows = 0 return 
   
   set nocount on
   
   /* Check for changes to key fields. */
   if update(EMGroup)
   	begin
   	select @errmsg = 'Cannot change EMGroup'
   	goto error
   	end 
   if update(ComponentTypeCode)
   	begin
   	select @errmsg = 'Cannot change ComponentTypeCode'
   	goto error
   
   	end
   
   /* Validate CostCode. */
   if update(CostCode)
   	begin
   	select @costcode = CostCode from inserted
   	if @costcode is not null
   		begin
   		select @validcnt = count(*) from bEMCC e, inserted i 
   		where e.EMGroup = i.EMGroup and e.CostCode = i.CostCode
   		if @validcnt <> @numrows
   			begin
   			select @errmsg = 'Invalid CostCode'
   			goto error
   			end
   		end
   	end
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Component Type Code!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMTY] ON [dbo].[bEMTY] ([EMGroup], [ComponentTypeCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMTY] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
