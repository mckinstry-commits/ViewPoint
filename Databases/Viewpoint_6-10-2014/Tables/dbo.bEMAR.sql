CREATE TABLE [dbo].[bEMAR]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[Month] [dbo].[bMonth] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[AvailableHrs] [dbo].[bHrs] NOT NULL,
[EstWorkUnits] [dbo].[bUnits] NOT NULL,
[EstTime] [dbo].[bHrs] NOT NULL,
[EstAmt] [dbo].[bDollar] NOT NULL,
[ActualWorkUnits] [dbo].[bUnits] NOT NULL,
[Actual_Time] [dbo].[bHrs] NOT NULL,
[ActualAmt] [dbo].[bDollar] NOT NULL,
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMARd    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE  trigger [dbo].[btEMARd] on [dbo].[bEMAR] for delete as
   
   

/*--------------------------------------------------------------
    *
    *  Delete trigger for EMAR
    *  Created By:  bc  04/17/99
    *  Modified by: TV 02/11/04 - 23061 added isnulls
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
   
   
   if exists(select * from deleted d
   join bEMRD r on r.EMCo = d.EMCo and r.RevCode = d.RevCode and r.Equipment = d.Equipment and r.Mth = d.Month)
      begin
      select @errmsg = 'Transactions exist in EMRD for the same EMCo, Month, Revenue Code and Equipment '
      goto error
      end
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMAR'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btEMARi] on [dbo].[bEMAR] for insert as
   
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMAR
    *  Created By:  bc  04/17/99
    *  Modified by: TV 02/11/04 - 23061 added isnulls
	*				GF 05/05/2013 TFS-49039
    *
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255),
           @validcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   

   
   
   select @validcnt = count(*) from inserted i
   join bEMEM e on i.EMCo = e.EMCo and i.Equipment = e.Equipment
   join bEMRR r on r.EMCo = i.EMCo and r.RevCode = i.RevCode and r.EMGroup = i.EMGroup and r.Category = e.Category
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Revenue Code must be set up in Revenue Rates by Category '
      goto error
      end
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMAR'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 

CREATE   trigger [dbo].[btEMARu] on [dbo].[bEMAR] for UPDATE as

   /*-----------------------------------------------------------------
    *	This trigger rejects insertion in bEMAR
    *      if the following error
    *      condition exists:
    *		TV 02/11/04 - 23061 added isnulls
	*					GF 05/15/2013 TFS-49039
	*
    *	key fields have changed
    */----------------------------------------------------------------
 declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, @rcode int 

   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check if key values have changed */
   if update(EMGroup)
   	begin select @errmsg='Update to EM Group not allowed'
   	goto error
   	end
   if update(RevCode) 
   	begin select @errmsg='Update to Revenue Code not allowed'
   	goto error
   	end
   
   if update(Month)
   	begin select @errmsg='Update to Month not allowed'
   	goto error
   	end
   
   return
   
   
   error:
   	
       	select @errmsg = isnull(@errmsg,'') + ' - cannot update EMAR!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
  
 




GO
CREATE UNIQUE CLUSTERED INDEX [biEMAR] ON [dbo].[bEMAR] ([EMCo], [Equipment], [RevCode], [Month], [EMGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMAR] WITH NOCHECK ADD CONSTRAINT [FK_bEMAR_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMAR] WITH NOCHECK ADD CONSTRAINT [FK_bEMAR_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bEMAR] WITH NOCHECK ADD CONSTRAINT [FK_bEMAR_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMAR] WITH NOCHECK ADD CONSTRAINT [FK_bEMAR_bEMRC_RevCode] FOREIGN KEY ([EMGroup], [RevCode]) REFERENCES [dbo].[bEMRC] ([EMGroup], [RevCode])
GO
ALTER TABLE [dbo].[bEMAR] NOCHECK CONSTRAINT [FK_bEMAR_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMAR] NOCHECK CONSTRAINT [FK_bEMAR_bEMEM_Equipment]
GO
ALTER TABLE [dbo].[bEMAR] NOCHECK CONSTRAINT [FK_bEMAR_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMAR] NOCHECK CONSTRAINT [FK_bEMAR_bEMRC_RevCode]
GO
