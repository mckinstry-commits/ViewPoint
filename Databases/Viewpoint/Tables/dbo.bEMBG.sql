CREATE TABLE [dbo].[bEMBG]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[Category] [dbo].[bCat] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Rate] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMBG] ON [dbo].[bEMBG] ([EMGroup], [EMCo], [Category], [RevCode], [RevBdownCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMBG] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMBGd    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE  trigger [dbo].[btEMBGd] on [dbo].[bEMBG] for delete as
   
   

/*--------------------------------------------------------------
    *
    *  Delete trigger for EMBG
    *  Created By:  bc  04/17/99
    *  Modified by: bc 04/02/01 - removed the code that validates deletion against EMBE
    *				 TV 02/11/04 - 23061 added isnulls
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
           @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMBG'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMBGi    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE  trigger [dbo].[btEMBGi] on [dbo].[bEMBG] for insert as
   
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMBG
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
   
   
   /* Validate EMCo */
   select @validcnt = count(*) from bEMCO r JOIN inserted i ON i.EMCo = r.EMCo
   if @validcnt <> @numrows
      begin
      select @errmsg = 'EM Company is Invalid '
      goto error
      end
   
   /* Validate EM Group */
   select @validcnt = count(*) from bHQGP r JOIN inserted i ON i.EMGroup = r.Grp
   if @validcnt <> @numrows
      begin
      select @errmsg = 'EM Group is Invalid '
      goto error
      end
   
   /* Validate Category */
   select @validcnt = count(*) from bEMCM r JOIN inserted i ON i.EMCo = r.EMCo and i.Category = r.Category
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Category is Invalid '
      goto error
      end
   
   /* Validate RevCode */
   select @validcnt = count(*) from bEMRC r JOIN inserted i ON i.EMGroup = r.EMGroup and i.RevCode = r.RevCode
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Revenue Code is Invalid '
      goto error
      end
   
   /* Validate RevBdownCode */
   select @validcnt = count(*) from bEMRT r JOIN inserted i ON i.EMGroup = r.EMGroup and i.RevBdownCode = r.RevBdownCode
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Revenue Breakdown Code is Invalid '
      goto error
      end
   
   if not exists(select * from EMRR r join inserted i on
   i.EMCo = r.EMCo and i.Category = r.Category and i.EMGroup = r.EMGroup and r.RevCode = i.RevCode)
      begin
      select @errmsg = 'Revenue Code is missing in EMRevRateCatgy '
      goto error
      end
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMBG'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btEMBGu    Script Date: 8/28/99 9:37:14 AM ******/
CREATE   trigger [dbo].[btEMBGu] on [dbo].[bEMBG] for update as
/*--------------------------------------------------------------
*
*  Update trigger for EMBG
*  Created By:  bc  04/17/99
*  Modified by: TV 02/11/04 - 23061 added isnulls
*				TRL 03/19/09 - 130856 added hqma audit for rate change
*
*--------------------------------------------------------------*/

/***  basic declares for SQL Triggers ****/
declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
@errno tinyint, @audit bYN, @validcnt int, @nullcnt int,@rcode int

select @numrows = @@rowcount

if @numrows = 0 return

set nocount on

/* cannot change key fields */
if update(EMCo) or Update(EMGroup) or Update(Category) or Update(RevCode) or Update(RevBdownCode)
begin
	select @validcnt = count(*)	from inserted i 
	Inner JOIN deleted d ON d.EMCo = i.EMCo and i.EMGroup = d.EMGroup and d.Category=i.Category and
                           d.RevCode = i.RevCode and d.RevBdownCode = i.RevBdownCode
	if @validcnt <> @numrows
	begin
		select @errmsg = 'Primary key fields may not be changed'
		GoTo error
	End
End

/*Issue 130856*/
if update(Rate)
begin
	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    select 'bEMBG', 'EM Company: ' + convert(char(3),i.EMCo)+ ' EM Group: ' + convert(char(3),i.EMGroup)
    + ' Category: ' + i.Category+ ' Rev Code: ' + i.RevCode+ ' RevBdownCode: ' + i.RevBdownCode, 
	i.EMCo, 'C', 'Rate', convert(varchar(12),d.Rate), convert(varchar(12),i.Rate), getdate(), SUSER_SNAME()
    from inserted i
	Inner Join deleted d on i.EMCo = d.EMCo and i.EMGroup=d.EMGroup and i.Category = d.Category and i.RevCode=d.RevCode 
							and i.RevBdownCode=d.RevBdownCode
	where i.Rate <> d.Rate
end

return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update into EMBG'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
