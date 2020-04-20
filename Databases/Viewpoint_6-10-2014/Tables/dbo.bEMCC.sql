CREATE TABLE [dbo].[bEMCC]
(
[EMGroup] [dbo].[bGroup] NOT NULL,
[CostCode] [dbo].[bCostCode] NOT NULL,
[RevBdownCode] [dbo].[bRevCode] NULL,
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
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMCCd    Script Date: 8/28/99 9:37:14 AM ******/
   
    CREATE  trigger [dbo].[btEMCCd] on [dbo].[bEMCC] for DELETE as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  Delete trigger for EMCC
     *  Created By: bc 11/18/98
     *  Modified by: TV 02/11/04 - 23061 added isnulls
     *
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* No Delete if EMCX record exists with Group/Cost Code */
    if exists(select * from bEMCX e, deleted d
    where e.EMGroup = d.EMGroup and e.CostCode = d.CostCode)
      begin
      select @errmsg = 'Cost Type records are assigned to this cost code '
      goto error
      end
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMCC'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMCCu    Script Date: 8/28/99 9:37:14 AM ******/
   
    CREATE   trigger [dbo].[btEMCCu] on [dbo].[bEMCC] for update as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  update trigger for EMCC
     *  Created By: bc 11/18/98
     *  Modified by: TV 02/11/04 - 23061 added isnulls
     *
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   if update(EMGroup) or update(CostCode)
     begin
     select @validcnt = count(*)
     from inserted i
     join deleted d ON i.EMGroup = d.EMGroup and d.CostCode=i.CostCode
     if @validcnt <> @numrows
       begin
       select @errmsg = 'Primary key fields may not be changed'
       goto error
       end
     end
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMCC'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMCC] ON [dbo].[bEMCC] ([EMGroup], [CostCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMCC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMCC] WITH NOCHECK ADD CONSTRAINT [FK_bEMCC_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMCC] WITH NOCHECK ADD CONSTRAINT [FK_bEMCC_bEMRT_RevBdownCode] FOREIGN KEY ([EMGroup], [RevBdownCode]) REFERENCES [dbo].[bEMRT] ([EMGroup], [RevBdownCode])
GO
ALTER TABLE [dbo].[bEMCC] NOCHECK CONSTRAINT [FK_bEMCC_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMCC] NOCHECK CONSTRAINT [FK_bEMCC_bEMRT_RevBdownCode]
GO
