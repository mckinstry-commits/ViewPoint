CREATE TABLE [dbo].[bEMRX]
(
[EMGroup] [dbo].[bGroup] NOT NULL,
[RepType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bEMRX] ADD
CONSTRAINT [FK_bEMRX_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMRXd    Script Date: 8/28/99 9:37:20 AM ******/
   CREATE   trigger [dbo].[btEMRXd] on [dbo].[bEMRX] for DELETE as
   

declare @errmsg varchar(255), @validcnt int 
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects delete in bEMRX (EM Repair Types) if  the following error condition exists:
    *
    *		Entry exists in EMWI - EM Work Order Items by EMGroup/RepairType
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   /* Check EMWI. */
   
   if exists(select * from deleted d, bEMWI e where d.EMGroup = e.EMGroup and d.RepType=e.RepairType)
   	begin
   	select @errmsg = 'Entries exist in EM Work Order Items'
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Repair Type!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMRXu    Script Date: 8/28/99 9:37:20 AM ******/
   CREATE   trigger [dbo].[btEMRXu] on [dbo].[bEMRX] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcnt int
   	
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects update in bEMRX (EM Repair Types) if any
    *	of the following error conditions exist:
    *
    *		Change in key fields (EMGroup or RepType)
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
   if update(RepType)
   	begin
   	select @errmsg = 'Cannot change RepType'
   	goto error
   
   
   	end
   	
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Repair Type!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMRX] ON [dbo].[bEMRX] ([EMGroup], [RepType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMRX] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
