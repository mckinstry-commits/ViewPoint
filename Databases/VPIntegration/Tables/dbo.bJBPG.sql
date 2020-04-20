CREATE TABLE [dbo].[bJBPG]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[ProcessGroup] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ProgressFormat] [dbo].[bDesc] NULL,
[TMFormat] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btJBPGd] ON [dbo].[bJBPG] FOR DELETE AS
    

/**************************************************************
     *	This trigger rejects delete of bJBPG (JB Process Group)
     *	 if the following error condition exists:
     *		none
     *
     *              Updates corresponding fields in JBPG.
     *
     **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int
   
    select @numrows = @@rowcount
   
    if @numrows = 0 return
    set nocount on
   
    if exists (select * from JBGC c, deleted d where c.JBCo = d.JBCo and c.ProcessGroup = d.ProcessGroup)
      begin
      select @errmsg = 'Rows exist in JBGC '
      goto error
      end
   
   
    return
   
    error:
    select @errmsg = @errmsg + ' - cannot delete JB Delete Order Header!'
   
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJBPG] ON [dbo].[bJBPG] ([JBCo], [ProcessGroup]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBPG] ([KeyID]) ON [PRIMARY]
GO
