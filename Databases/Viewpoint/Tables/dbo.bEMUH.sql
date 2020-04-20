CREATE TABLE [dbo].[bEMUH]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AUTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMUH] ON [dbo].[bEMUH] ([EMCo], [AUTemplate]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMUH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMUHd    Script Date: 8/28/99 9:37:24 AM ******/
   CREATE   trigger [dbo].[btEMUHd] on [dbo].[bEMUH] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: bc  08/11/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   /* Check EMUE. */
   if exists(select * from deleted d, bEMUE e where d.EMCo = e.EMCo and d.AUTemplate = e.AUTemplate)
   	begin
   	select @errmsg = 'Entries exist in EMUE for this Auto Template'
   	goto error
   	end
   
   /* Check EMUC. */
   if exists(select * from deleted d, bEMUC e where d.EMCo = e.EMCo and d.AUTemplate = e.AUTemplate)
   	begin
   	select @errmsg = 'Entries exist in EMUC for this Auto Template'
   	goto error
   	end
   
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EMUH!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMUHu    Script Date: 8/28/99 9:37:24 AM ******/
   CREATE   trigger [dbo].[btEMUHu] on [dbo].[bEMUH] for update as
   

declare @errmsg varchar(255), @validcnt int, @numrows int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: bc  08/11/99
    *	MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *						TRL 08/05/09 134938 changed where set no count is called
    *
    */----------------------------------------------------------------
       select @numrows = @@rowcount
       if @numrows = 0 return
       set nocount on
   
   if update(EMCo) or update(AUTemplate)
     begin
     select @validcnt = count(*) from inserted i join deleted d on i.EMCo = d.EMCo and i.AUTemplate = d.AUTemplate
     if @validcnt = @numrows
       begin
       select @errmsg = 'Cannot change key fields '
       goto error
       end
     end
   
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMUH!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
   
  
 




GO
