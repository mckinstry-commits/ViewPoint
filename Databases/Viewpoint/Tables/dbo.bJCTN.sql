CREATE TABLE [dbo].[bJCTN]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[InsTemplate] [smallint] NOT NULL,
[Description] [dbo].[bDesc] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJCTN] ON [dbo].[bJCTN] ([JCCo], [InsTemplate]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCTN] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btJCTNd    Script Date: 8/28/99 9:37:49 AM ******/
   CREATE  trigger [dbo].[btJCTNd] on [dbo].[bJCTN] for DELETE as
   

declare @errmsg varchar(255)
   
   /*-----------------------------------------------------------------
    *	This trigger rejects delete in bJCTN (JC Insurance Templates) if  
    *	the following error condition exists:
    *
    *		entries exist in JCTI
    *		entries exist in JCJM
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   /* check JCTI */
   if exists(select * from deleted d, bJCTI p where d.JCCo = p.JCCo and d.InsTemplate=p.InsTemplate)
   	begin
   	select @errmsg = 'Cannot delete, Phases are setup for a template you are trying to delete.'
   	goto error
   	end
   
   /* check JCJM */
   if exists(select * from deleted d, bJCJM j where d.JCCo = j.JCCo and d.InsTemplate=j.InsTemplate)
   	begin
   	select @errmsg = 'Entries exist in JCJM.'
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot delete insurance template!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCTNi    Script Date: 8/28/99 9:37:49 AM ******/
   CREATE  trigger [dbo].[btJCTNi] on [dbo].[bJCTN] for INSERT as
   
   

declare @errmsg varchar(255), @errno int, @numrows int, 
   	@validcnt int
   	
   /*-----------------------------------------------------------------
    *	This trigger rejects insertion in bJCTN (JC Insurance Templates) if the
    *	following error condition exists:
    *         Invalid JCCo
    *	
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* validate Cost Type */
   select @validcnt = count(*) from bJCCO j, inserted i where i.JCCo=j.JCCo
   
   if @validcnt <> @numrows 
   	begin
   	select @errmsg = 'Invalid JC Company.'
   	goto error
   	end
   
   
   return
   
   error:
   	
   	select @errmsg = @errmsg + ' - cannot insert JC Insurance Template!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCTNu    Script Date: 8/28/99 9:37:49 AM ******/
   CREATE  trigger [dbo].[btJCTNu] on [dbo].[bJCTN] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcnt int 
   	
   /*-----------------------------------------------------------------
    *	This trigger rejects inserts in bJCTN (JC Insurance templated) if any
    *	of the following error conditions exist:
    *
    *		Cannot change JCCo
    *		Cannot change Insurance template
    *
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   set nocount on
   
   /* check for changes to JCCo */
   If update(JCCo)
   	begin
   	select @errmsg = 'Cannot change Job Cost Company'
   	goto error
   	end
   
   
   /* check for changes to Instemplate */
   
   If update(InsTemplate)
   	begin
   	select @errmsg = 'Cannot change Insurance Template'
   	goto error
   
   	end
   
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update Insurance Tamplate!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
