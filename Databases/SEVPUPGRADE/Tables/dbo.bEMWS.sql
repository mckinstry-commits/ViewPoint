CREATE TABLE [dbo].[bEMWS]
(
[EMGroup] [dbo].[bGroup] NOT NULL,
[StatusCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[StatusType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMWSd    Script Date: 8/28/99 9:37:25 AM ******/
   CREATE   trigger [dbo].[btEMWSd] on [dbo].[bEMWS] for DELETE as
   

declare @errmsg varchar(255), @validcnt int 
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects delete in bEMWS (EM WO Status Codes) if  the following error condition exists:
    *
    *		Entry exist in bEMWI - EM Work Order Items by EMGroup
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   /* Check EMCX. */
   if exists(select top 1 1 from deleted d, bEMWI e where d.EMGroup = e.EMGroup and d.StatusCode=e.StatusCode)
   	begin
   	select @errmsg = 'Entries exist in EMWI for this StatusCode/EMGroup'
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM WO Status Code!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMWSi    Script Date: 8/28/99 9:37:26 AM ******/
   CREATE   trigger [dbo].[btEMWSi] on [dbo].[bEMWS] for INSERT as
   

declare @errmsg varchar(255), @numrows int,	@validcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By : JM 3/12/01 - Added validation of StatusType removed from rule.
    *				 TV 02/11/04 - 23061 added isnulls
    *	This trigger rejects insertion in bEMWS (EM WO Status Codes) if the following error condition exists:
    *
    *		Invalid EMGroup vs bHQGP
    *		Invalid StatusType - not in (B,F,N)
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
   
   /* Validate StatusType. */
   select @validcnt=count(*) from inserted i
   where i.StatusType not in ('B', 'F','N')
   if @validcnt <>0  
   	begin  
   	select @errmsg = 'Invalid StatusType - must be B, F or N'
   	goto error
   	end
   
   /* Validate StatusType. */
   if update(StatusType)
   	begin
   	select @validcnt=count(*) from inserted i
   	where i.StatusType not in ('B','F','N')
   	if @validcnt <>0
   		begin
   		select @errmsg = 'Invalid StatusType - must be B, F or N'
   		goto error
   		end
   	end
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM WO Status Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   	
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMWSu    Script Date: 8/28/99 9:37:26 AM ******/
   CREATE   trigger [dbo].[btEMWSu] on [dbo].[bEMWS] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcnt int
   	
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By : JM 3/12/01 - Added validation of StatusType removed from rule.
    *				 TV 02/11/04 - 23061 added isnulls
    *	This trigger rejects update in bEMWS (EM WO Status Codes) if  the following error condition exists:
    *
    *		Change in key fields (EMGroup or StatusCode)
    *		Invalid StatusType - not in (B,F,N)
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
   if update(StatusCode)
   	begin
   	select @errmsg = 'Cannot change StatusCode'
   	goto error
   
   	end
   	
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EM WO Status Code!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMWS] ON [dbo].[bEMWS] ([EMGroup], [StatusCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMWS] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
