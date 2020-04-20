CREATE TABLE [dbo].[bEMJT]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[AUTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[RevTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMJTd    Script Date: 8/28/99 9:37:17 AM ******/
   CREATE   trigger [dbo].[btEMJTd] on [dbo].[bEMJT] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: bc  08/11/99
    *	MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EMJT!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMJTi    Script Date: 8/28/99 9:37:17 AM ******/
   CREATE   trigger [dbo].[btEMJTi] on [dbo].[bEMJT] for insert as
   

declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: bc  08/11/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @@rowcount = 0 return
   set nocount on
   
   
   select @validcnt = count(*) from bEMCO e join inserted i on e.EMCo = i.EMCo
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid EM Company '
     goto error
     end
   
   select @validcnt = count(*) from bJCCO e join inserted i on e.JCCo = i.JCCo
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid JC Company '
     goto error
     end
   
   select @validcnt = count(*) from bJCJM e join inserted i on e.JCCo = i.JCCo and e.Job = i.Job
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid Job '
     goto error
     end
   
   select @validcnt = count(*) from bEMUH e join inserted i on e.EMCo = i.EMCo and e.AUTemplate = i.AUTemplate
   select @nullcnt = count(*) from inserted i where i.AUTemplate is null
   if @validcnt + @nullcnt <> @numrows
     begin
     select @errmsg = 'Invalid auto usage template '
     goto error
     end
   
   select @validcnt = count(*) from bEMTH e join inserted i on e.EMCo = i.EMCo and e.RevTemplate = i.RevTemplate
   select @nullcnt = count(*) from inserted i where RevTemplate is null
   if @validcnt + @nullcnt <> @numrows
     begin
     select @errmsg = 'Invalid revenue template '
     goto error
     end
   
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMJT!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMJTu    Script Date: 8/28/99 9:37:17 AM ******/
   CREATE   trigger [dbo].[btEMJTu] on [dbo].[bEMJT] for update as
   

declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: bc  08/11/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @@rowcount = 0 return
   set nocount on
   
   if update(EMCo) or update(JCCo) or update(Job)
     begin
     select @validcnt = count(*) from inserted i join deleted d on i.EMCo = d.EMCo and i.JCCo = d.JCCo and i.Job = d.Job
     if @validcnt <> @numrows
       begin
       select @errmsg = 'Cannot change key fields '
       goto error
       end
     end
   
   if update(AUTemplate)
     begin
     select @validcnt = count(*) from EMUH e join inserted i on e.EMCo = i.EMCo and e.AUTemplate = i.AUTemplate
     select @nullcnt = count(*) from inserted i where i.AUTemplate is null
     if @validcnt + @nullcnt <> @numrows
       begin
       select @errmsg = 'Invalid auto usage template '
       goto error
       end
     end
   
   if update(RevTemplate)
     begin
     select @validcnt = count(*) from EMTH e join inserted i on e.EMCo = i.EMCo and e.RevTemplate = i.RevTemplate
     select @nullcnt = count(*) from inserted i where RevTemplate is null
     if @validcnt + @nullcnt <> @numrows
       begin
       select @errmsg = 'Invalid revenue template '
       goto error
       end
     end
   
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMJT!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMJT] ON [dbo].[bEMJT] ([EMCo], [JCCo], [Job]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMJT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
