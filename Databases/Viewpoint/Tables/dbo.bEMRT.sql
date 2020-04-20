CREATE TABLE [dbo].[bEMRT]
(
[EMGroup] [dbo].[bGroup] NOT NULL,
[RevBdownCode] [dbo].[bRevCode] NOT NULL,
[Description] [dbo].[bDesc] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMRT] ON [dbo].[bEMRT] ([EMGroup], [RevBdownCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMRT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMRTd    Script Date: 8/28/99 9:37:17 AM ******/
   
    CREATE   trigger [dbo].[btEMRTd] on [dbo].[bEMRT] for DELETE as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  Delete trigger for EMRT
     *  Created By: bc 11/18/98
     *  Modified by:  bc 03/04/99
     *					SR 02/17/03 - issue 20418
     *					 TV 02/11/04 - 23061 added isnulls
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
    declare @emgroup int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* check for revenue breaksown codes in department */
    if exists(select * from bEMDB e join deleted d on e.EMGroup = d.EMGroup and e.RevBdownCode = d.RevBdownCode)
      begin
      select @errmsg = 'Department Revenue Breakdown Codes exist '
      goto error
      end
   
   /* No Delete if revbdowncode is set up as the default from emco */
    if exists(select * from bEMCO e join deleted d on e.EMGroup = d.EMGroup and e.UseRevBkdwnCodeDefault = d.RevBdownCode)
      begin
      select @errmsg = 'Revenue Breakdown Code is in use by the company table '
      goto error
      end
   
   /* No Delete if revcode is in a batch */
    if exists(select * from bEMBC e join deleted d on e.EMGroup = d.EMGroup and e.RevBdownCode = d.RevBdownCode)
      begin
      select @errmsg = 'Revenue Breakdown Code is in an existing batch '
      goto error
      end
   
   /* No Delete if revbdowncode is in rev rates by category */
    if exists(select * from bEMBG e join deleted d on e.EMGroup = d.EMGroup and e.RevBdownCode = d.RevBdownCode)
      begin
      select @errmsg = 'Revenue Breakdown Code is in use in revenue rates by category '
      goto error
      end
   
   /* No Delete if revbdowncode is in rev rates by Equipment */--ISSUE 20418
    if exists(select * from bEMBE e join deleted d on e.EMGroup = d.EMGroup and e.RevBdownCode = d.RevBdownCode)
      begin
      select @errmsg = 'Revenue Breakdown Code is in use in revenue rates by equipment '
      goto error
      end
   
   /* No Delete if revcode is in revenue detail */
    if exists(select * from bEMRB e join deleted d on e.EMGroup = d.EMGroup and e.RevBdownCode = d.RevBdownCode)
      begin
      select @errmsg = 'Revenue Breakdown Code is in revenue breakdown detail table '
      goto error
      end
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMRT'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMRTi    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE  trigger [dbo].[btEMRTi] on [dbo].[bEMRT] for insert as
   
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMRT
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
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMRT'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 

CREATE   trigger [dbo].[btEMRTu] on [dbo].[bEMRT] for update as
/*--------------------------------------------------------------
*
*  Update trigger for EMRT
*  Created By:  bc  04/17/99
*  Modified by:  TV 02/11/04 - 23061 added isnulls
*				GF 08/23/2012 TK-17325 update EMBG EMBE descriptions
*
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int,
       @rcode int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


----TK-17325 update description in EMBG and EMBE when changed
IF UPDATE(Description)
	BEGIN
	---- category revenue override breakdown codes
	UPDATE dbo.bEMBG SET Description = i.Description
	FROM inserted i
	INNER JOIN deleted d ON d.KeyID = i.KeyID
	INNER JOIN dbo.bEMBG c ON c.EMGroup = i.EMGroup AND c.RevBdownCode = i.RevBdownCode
	WHERE ISNULL(d.Description, '') <> ISNULL(i.Description, '')
	
	---- equipment revenue override breakdown codes
	UPDATE dbo.bEMBE SET Description = i.Description
	FROM inserted i
	INNER JOIN deleted d ON d.KeyID = i.KeyID
	INNER JOIN dbo.bEMBE c ON c.EMGroup = i.EMGroup AND c.RevBdownCode = i.RevBdownCode
	WHERE ISNULL(d.Description, '') <> ISNULL(i.Description, '')
	
	END




RETURN




error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EMRT'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
  
 




GO
