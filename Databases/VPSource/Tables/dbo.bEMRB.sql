CREATE TABLE [dbo].[bEMRB]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[Trans] [dbo].[bTrans] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Equipment] [dbo].[bEquip] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[Amount] [dbo].[bDollar] NULL,
[GLCo] [dbo].[bCompany] NULL,
[Account] [dbo].[bGLAcct] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMRB] ADD
CONSTRAINT [FK_bEMRB_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
ALTER TABLE [dbo].[bEMRB] ADD
CONSTRAINT [FK_bEMRB_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
ALTER TABLE [dbo].[bEMRB] ADD
CONSTRAINT [FK_bEMRB_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
ALTER TABLE [dbo].[bEMRB] ADD
CONSTRAINT [FK_bEMRB_bEMRT_RevBdownCode] FOREIGN KEY ([EMGroup], [RevBdownCode]) REFERENCES [dbo].[bEMRT] ([EMGroup], [RevBdownCode])
ALTER TABLE [dbo].[bEMRB] ADD
CONSTRAINT [FK_bEMRB_bEMRC_RevCode] FOREIGN KEY ([EMGroup], [RevCode]) REFERENCES [dbo].[bEMRC] ([EMGroup], [RevCode])
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE   trigger [dbo].[btEMRBu] on [dbo].[bEMRB] for update as
   
   

/*--------------------------------------------------------------
    *
    *  Update trigger for EMRB
    *  Created By:  bc  04/17/99
    *  Modified by:  TV 02/11/04 - 23061 added isnulls
	*				GF 05/05/2103 TFS-49039
    *
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
----TFS-49039  
SELECT @validcnt = COUNT(*) FROM dbo.bEMEM EMEM JOIN inserted i ON i.EMCo = EMEM.EMCo AND i.Equipment = EMEM.Equipment and EMEM.ChangeInProgress = 'Y'
IF @validcnt = @numrows RETURN
   
   if update(Mth) or update(Trans)
     begin
     select @validcnt = count(*) from inserted i join deleted d on i.EMCo = d.EMCo and i.Mth = d.Mth and i.Trans = d.Trans
     if @validcnt <> @numrows
       begin
       select @errmsg = 'Cannot change key fields '
       goto error
       end
     end
   
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot update into EMRB'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO

CREATE UNIQUE CLUSTERED INDEX [biEMRB] ON [dbo].[bEMRB] ([EMCo], [Mth], [Trans], [EMGroup], [RevBdownCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
