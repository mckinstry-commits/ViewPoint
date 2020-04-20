CREATE TABLE [dbo].[bEMTH]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[RevTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NOT NULL,
[TypeFlag] [char] (1) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CopyFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMTH_CopyFlag] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMTHd    Script Date: 8/28/99 9:37:23 AM ******/
    
    CREATE  trigger [dbo].[btEMTHd] on [dbo].[bEMTH] for delete as 
    
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
    
    /*-------------------------------------------------------------- 
     *
     *  delete trigger for EMTH
     *  Created By: bc 11/13/98
     *  Modified by:  TV 02/11/04 - 23061 added isnulls 
	 *				  GP 05/01/2008 - #127252 added cascade delete ability for EMRevTemplate. Deletes
	 *									bEMTC, bEMTE, and bEMTH records in that order. Removed pseudo
	 *									cursor.
     *
     *
     *--------------------------------------------------------------*/
     
     /*** declare local variables ***/
    declare @emgroup int, @revcode varchar(10), @catgy varchar(10)
    
    select @numrows = @@rowcount 
    if @numrows = 0 return
    set nocount on
   
		delete bEMTE
		from bEMTE e join deleted d on e.EMCo = d.EMCo and e.RevTemplate = d.RevTemplate

		delete bEMTC
		from bEMTC e join deleted d on e.EMCo = d.EMCo and e.RevTemplate = d.RevTemplate  

		delete bEMTH
		from bEMTH e join deleted d on e.EMCo = d.EMCo and e.RevTemplate = d.RevTemplate 
		
    return
    
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMTH'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
    
    
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMTHi    Script Date: 8/28/99 9:37:23 AM ******/
   
    CREATE   trigger [dbo].[btEMTHi] on [dbo].[bEMTH] for insert as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  insert trigger for EMTH
     *  Created By: bc 11/13/98
     *  Modified by:  TV 02/11/04 - 23061 added isnulls
     *
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   select @validcnt = count(*) from EMCO e join inserted i on e.EMCo = i.EMCo
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid EM Company '
     goto error
     end
   
   select @validcnt = count(*) from inserted where TypeFlag in('P','O')
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid Type Flag '
     goto error
     end
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMTH'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMTH] ON [dbo].[bEMTH] ([EMCo], [RevTemplate]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMTH] ([KeyID]) ON [PRIMARY]
GO
