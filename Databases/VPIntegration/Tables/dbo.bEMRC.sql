CREATE TABLE [dbo].[bEMRC]
(
[EMGroup] [dbo].[bGroup] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Basis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[WorkUM] [dbo].[bUM] NULL,
[TimeUM] [dbo].[bUM] NULL,
[HrsPerTimeUM] [dbo].[bHrs] NOT NULL,
[UpdateHourMeter] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[HaulBased] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMRC_HaulBased] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[MonthlyRevCodeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMRC_MonthlyRevCodeYN] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMRCd    Script Date: 8/28/99 9:37:17 AM ******/
   
    CREATE   trigger [dbo].[btEMRCd] on [dbo].[bEMRC] for DELETE as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  Delete trigger for EMRC
     *  Created By: bc 11/18/98
     *  Modified by:  bc 03/04/99
     *                bc 03/12/01 - added check on EMUD
     *				 TV 02/11/04 - 23061 added isnulls
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
    declare @emgroup int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* check for revenue codes in department */
    if exists(select * from bEMDR e join deleted d on e.EMGroup = d.EMGroup and e.RevCode = d.RevCode)
      begin
      select @errmsg = 'Department Revenue Codes exist '
      goto error
      end
   
   /* No Delete if revcode is assigned to equipment */
    if exists(select * from bEMEM e join deleted d on e.EMGroup = d.EMGroup and e.RevenueCode = d.RevCode)
      begin
      select @errmsg = 'Revenue Code is in use by the equipment master '
      goto error
      end
   
   /* No Delete if revcode is in a batch */
    if exists(select * from bEMBF e join deleted d on e.EMGroup = d.EMGroup and e.RevCode = d.RevCode)
      begin
      select @errmsg = 'Revenue Code is in an existing batch '
      goto error
      end
   
   /* No Delete if revcode is in rev rates by category */
    if exists(select * from bEMRR e join deleted d on e.EMGroup = d.EMGroup and e.RevCode = d.RevCode)
      begin
      select @errmsg = 'Revenue Code is in use in revenue rates by category '
      goto error
      end
   
   /* No Delete if revcode is in revenue detail */
    if exists(select * from bEMRD e join deleted d on e.EMGroup = d.EMGroup and e.RevCode = d.RevCode)
      begin
      select @errmsg = 'Revenue Code is in revenue detail table '
      goto error
      end
   
   /* No Delete if revcode is in rules table */
    if exists(select * from bEMUD e join deleted d on e.EMGroup = d.EMGroup and e.RevCode = d.RevCode)
      begin
      select @errmsg = 'Revenue Code is in rules table '
      goto error
      end
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMRC'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMRCi    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE  trigger [dbo].[btEMRCi] on [dbo].[bEMRC] for insert as
   
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMRC
    *  Created By:  bc  04/17/99
    *  Modified by:  TV 02/11/04 - 23061 added isnulls
    *
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
           @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   /* Validate EMGroup */
   select @validcnt = count(*) from bHQGP r JOIN inserted i ON i.EMGroup = r.Grp
   if @validcnt <> @numrows
      begin
      select @errmsg = 'EM Group is Invalid '
      goto error
      end
   
   /* Validate basis */
   select @validcnt = count(*) from inserted i where i.Basis in('H','U')
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Missing basis '
      goto error
      end
   
   /* Validate UpdateHourMeter */
   select @validcnt = count(*) from inserted i where i.UpdateHourMeter in('Y','N')
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Missing update hour meter value '
      goto error
      end
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMRC'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMRCu    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE   trigger [dbo].[btEMRCu] on [dbo].[bEMRC] for update as
   
   

/*--------------------------------------------------------------
    *
    *  Update trigger for EMRC
    *  Created By:     bc 04/17/99
    *  Modified by:    bc 06/06/00
    *					 TV 02/11/04 - 23061 added isnulls
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
           @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   if update(EMGroup) or update(RevCode)
     begin
     select @validcnt = count(*) from inserted i
     join deleted d on i.EMGroup = d.EMGroup and i.RevCode = d.RevCode
     if @validcnt <> @numrows
       begin
       select @errmsg = 'Cannot change key fields '
       goto error
       end
     end
   
   /* Validate Basis */
   if update(Basis)
   begin
   select @validcnt = count(*) from inserted i where i.Basis in('H','U')
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Missing basis '
      goto error
      end
   end
   
   /* Validate Updatehourmeter */
   if update(UpdateHourMeter)
   begin
   select @validcnt = count(*) from inserted i where i.UpdateHourMeter in('Y','N')
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Missing update hour meter value '
      goto error
      end
   end
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot update EMRC'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMRC] ON [dbo].[bEMRC] ([EMGroup], [RevCode]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMRC] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMRC].[UpdateHourMeter]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMRC].[HaulBased]'
GO
