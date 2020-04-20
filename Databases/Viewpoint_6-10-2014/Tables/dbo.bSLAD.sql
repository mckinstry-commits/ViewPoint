CREATE TABLE [dbo].[bSLAD]
(
[SLCo] [dbo].[bCompany] NOT NULL,
[Addon] [tinyint] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Pct] [dbo].[bPct] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ApplyPct] [dbo].[bYN] NOT NULL,
[Phase] [dbo].[bPhase] NULL,
[JCCType] [dbo].[bJCCType] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btSLADd    Script Date: 8/28/99 9:38:17 AM ******/
   CREATE    trigger [dbo].[btSLADd] on [dbo].[bSLAD] for DELETE as
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255)
   
   /*--------------------------------------------------------------
    *
    *  Delete trigger for SLAD
    *  Created By: EN  12/29/99
    *
    *  Reject if exists in bSLIT.
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount
    if @numrows = 0 return
   
   set nocount on
   
   -- check for Addon in bSLIT
   if exists(select * from deleted d join bSLIT a on d.SLCo = a.SLCo and d.Addon = a.Addon)
   	begin
   	select @errmsg = 'Addon in use in SL Items '
   	goto error
   	end
   
   return
   
   
   error:
      select @errmsg = @errmsg + ' - cannot remove SL Addons'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btSLADi    Script Date: 8/28/99 9:38:17 AM ******/
   
    CREATE  trigger [dbo].[btSLADi] on [dbo].[bSLAD] for INSERT as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @errmsg varchar(255), @validcnt int
   
    /*--------------------------------------------------------------
     *
     *  Insert trigger for SLAD
     *  Created By: EN  12/29/99
     *
     *  Validate SLCo.
     *  Type must be 'A' or 'P'.
     *--------------------------------------------------------------*/
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
    /*validate SL Company */
    select @validcnt = count(*) from bSLCO r
       JOIN inserted i on i.SLCo = r.SLCo
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid SL company.'
    	goto error
    	end
   
    -- make sure Type value is either 'A' or 'P'
    select @validcnt = count(*) from inserted
       where Type = 'A' or Type = 'P'
    if @validcnt <> @numrows
       begin
       select @errmsg = 'Type must be either (A or P) '
       goto error
       end
   
    return
   
    error:
       select @errmsg = @errmsg + ' - cannot insert into SL Addons'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btSLADu    Script Date: 8/28/99 9:38:18 AM ******/
   CREATE  trigger [dbo].[btSLADu] on [dbo].[bSLAD] for UPDATE as
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   /*--------------------------------------------------------------
    *
    *  Update trigger for SLAD
    *  Created By: EN  12/29/99
    *
    *  Reject primary key changes.
    *  Type must be 'A' or 'P'.
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount
    if @numrows = 0 return
   
    select @validcnt=0
   
    set nocount on
   
    -- check for key changes
    select @validcnt = count(*) from deleted d
       join inserted i on i.SLCo = d.SLCo and i.Addon = d.Addon
    if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change SL Company, or Addon '
    	goto error
    	end
   
    -- make sure Type value is either 'A' or 'P'
    select @validcnt = count(*) from inserted
       where Type = 'A' or Type = 'P'
    if @validcnt <> @numrows
       begin
       select @errmsg = 'Type must be either (A or P) '
       goto error
       end
   
   return
   
   
   error:
      select @errmsg = @errmsg + ' - cannot update into SL Addons'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bSLAD] WITH NOCHECK ADD CONSTRAINT [CK_bSLAD_ApplyPct] CHECK (([ApplyPct]='Y' OR [ApplyPct]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bSLAD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biSLAD] ON [dbo].[bSLAD] ([SLCo], [Addon]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
