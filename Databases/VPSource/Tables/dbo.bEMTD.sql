CREATE TABLE [dbo].[bEMTD]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[RevTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Category] [dbo].[bCat] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Rate] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMTD] ADD
CONSTRAINT [FK_bEMTD_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
ALTER TABLE [dbo].[bEMTD] ADD
CONSTRAINT [FK_bEMTD_bEMCM_Category] FOREIGN KEY ([EMCo], [Category]) REFERENCES [dbo].[bEMCM] ([EMCo], [Category])
ALTER TABLE [dbo].[bEMTD] ADD
CONSTRAINT [FK_bEMTD_bEMTH_RevTemplate] FOREIGN KEY ([EMCo], [RevTemplate]) REFERENCES [dbo].[bEMTH] ([EMCo], [RevTemplate])
ALTER TABLE [dbo].[bEMTD] ADD
CONSTRAINT [FK_bEMTD_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
ALTER TABLE [dbo].[bEMTD] ADD
CONSTRAINT [FK_bEMTD_bEMRT_RevBdownCode] FOREIGN KEY ([EMGroup], [RevBdownCode]) REFERENCES [dbo].[bEMRT] ([EMGroup], [RevBdownCode])
ALTER TABLE [dbo].[bEMTD] ADD
CONSTRAINT [FK_bEMTD_bEMRC_RevCode] FOREIGN KEY ([EMGroup], [RevCode]) REFERENCES [dbo].[bEMRC] ([EMGroup], [RevCode])
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btEMTDi] on [dbo].[bEMTD] for insert as
   
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMTD
    *  Created By:  bc  04/17/99
    *  Modified by: TV 02/11/04 - 23061 added isnulls
	*				GF 05/05/2013 TFS-49039
    *
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
  
   
   if not exists(select * from EMTC r join inserted i on
   i.EMCo = r.EMCo and i.RevTemplate = r.RevTemplate and i.Category = r.Category and i.EMGroup = r.EMGroup and r.RevCode = i.RevCode)
      begin
      select @errmsg = 'Revenue Code is missing in EMRevRateCatgyTemp '
      goto error
      end
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMTD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE   trigger [dbo].[btEMTDu] on [dbo].[bEMTD] for update as
   
   

/*--------------------------------------------------------------
    *
    *  Update trigger for EMTD
    *  Created By:  bc  04/17/99
    *  Modified by:  TV 02/11/04 - 23061 added isnulls
	*				GF 05/05/2013 TFS-49039
    *
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int,
           @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   
     /* cannot change key fields */
     if update(EMCo) or Update(EMGroup) or update(RevTemplate) or Update(Category) or Update(RevCode) or Update(RevBdownCode)
         begin
         select @validcnt = count(*)
         from inserted i JOIN deleted d ON d.EMCo = i.EMCo and i.RevTemplate = d.RevTemplate and i.EMGroup = d.EMGroup and
                                           d.Category=i.Category and d.RevCode = i.RevCode and d.RevBdownCode = i.RevBdownCode
         if @validcnt <> @numrows
             begin
             select @errmsg = 'Primary key fields may not be changed'
             GoTo error
             End
         End
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot update into EMTD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO

CREATE UNIQUE CLUSTERED INDEX [biEMTD] ON [dbo].[bEMTD] ([EMCo], [EMGroup], [RevTemplate], [Category], [RevCode], [RevBdownCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMTD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
