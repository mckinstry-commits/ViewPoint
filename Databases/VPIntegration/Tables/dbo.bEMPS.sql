CREATE TABLE [dbo].[bEMPS]
(
[EMGroup] [dbo].[bGroup] NOT NULL,
[PartsStatusCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMPSd    Script Date: 8/28/99 9:37:18 AM ******/
   CREATE   trigger [dbo].[btEMPSd] on [dbo].[bEMPS] for DELETE as
   

declare @errmsg varchar(255), @validcnt int 
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects delete in bEMPS (EM Parts Status Codes) if  the following error condition exists:
    *
    *		Entry exists in EMWP - EM Work Order Parts by EMGroup/PartsStatusCode
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   /* Check EMWP. */
   if exists(select * from deleted d, bEMWP e where d.EMGroup = e.EMGroup and d.PartsStatusCode=e.PartsStatusCode)
   	begin
   	select @errmsg = 'Entries exist in EMWP for this EMGroup'
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Parts Status Code!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMPSi    Script Date: 8/28/99 9:37:18 AM ******/
   CREATE   trigger [dbo].[btEMPSi] on [dbo].[bEMPS] for INSERT as
   

declare @errmsg varchar(255), @numrows int,	@validcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects insertion in bEMPS (EM Parts Stats Codes) if the following error condition exists:
    *
    *		Invalid EMGroup vs bHQGP
    *
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* Validate EMGroup */
   select @validcnt = count(*) from bHQGP p, inserted i where p.Grp = i.EMGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid EMGroup'
   	goto error
   	end
   
   return
   
   error:
   
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Parts Status Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   	
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMPSu    Script Date: 8/28/99 9:37:19 AM ******/
   CREATE   trigger [dbo].[btEMPSu] on [dbo].[bEMPS] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcnt int
   	
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects update in bEMPS (EM Parts Status Codes) if the following error condition exists:
    *
    *		Change in key fields (EMGroup or PartsStatusCode)
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
   if update(PartsStatusCode)
   	begin
   	select @errmsg = 'Cannot change PartsStatusCode'
   	goto error
   
   	end
   	
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Parts Status Code!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMPS] ON [dbo].[bEMPS] ([EMGroup], [PartsStatusCode]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMPS] ([KeyID]) ON [PRIMARY]
GO
