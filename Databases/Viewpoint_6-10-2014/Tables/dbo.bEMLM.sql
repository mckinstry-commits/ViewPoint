CREATE TABLE [dbo].[bEMLM]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[EMLoc] [dbo].[bLoc] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Active] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bEMLM_Active] DEFAULT ('Y')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   /****** Object:  Trigger dbo.btEMLMd    Script Date: 8/28/99 9:37:18 AM ******/
   CREATE   trigger [dbo].[btEMLMd] on [dbo].[bEMLM] for delete as
/*--------------------------------------------------------------
*
*  Delete trigger for EMLM
*  Created By:		bc	06/15/99
*  Modified by:		TV	02/11/04 - 23061 added isnulls
*					CHS 11/07/08 - #130950
*
*--------------------------------------------------------------*/
/***  basic declares for SQL Triggers ****/
declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
	   @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
	   @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   if exists(select * from EMEM e join deleted d on e.EMCo = d.EMCo and e.Location = d.EMLoc)
     begin
     select @errmsg = 'Location in use by Equipment Master '
     goto error
     end
   
	-- CHS 11/07/08 - #130950
   if exists(select * from EMLB b join deleted d on b.Co = d.EMCo and (b.ToLocation = d.EMLoc or b.FromLocation = d.EMLoc))
     begin
     select @errmsg = 'Location in use by Equipment Location Batch '
     goto error
     end
   
	-- CHS 11/07/08 - #130950
    if exists(select * from EMLH h join deleted d on h.EMCo = d.EMCo and h.ToLocation = d.EMLoc and h.DateOut is NULL)
     begin
     select @errmsg = 'Location in use by Equipment Location History '
     goto error
     end

  
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMLM'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMLMu    Script Date: 8/28/99 9:37:18 AM ******/
   CREATE   trigger [dbo].[btEMLMu] on [dbo].[bEMLM] for update as
   

/*--------------------------------------------------------------
    *
    *  Update trigger for EMLM
    *  Created By:  bc  06/15/99
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
   
   if update(EMCo) or update(EMLoc)
     begin
     select @validcnt = count(*) from inserted i join deleted d on i.EMCo = d.EMCo and i.EMLoc = d.EMLoc
     if @validcnt <> @numrows
       begin
       select @errmsg = 'Cannot change key fields '
       goto error
       end
     end
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot update EMLM'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bEMLM] WITH NOCHECK ADD CONSTRAINT [CK_bEMLM_Active] CHECK (([Active]='N' OR [Active]='Y'))
GO
CREATE UNIQUE CLUSTERED INDEX [biEMLM] ON [dbo].[bEMLM] ([EMCo], [EMLoc]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMLM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMLM] WITH NOCHECK ADD CONSTRAINT [FK_bEMLM_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMLM] NOCHECK CONSTRAINT [FK_bEMLM_bEMCO_EMCo]
GO
