CREATE TABLE [dbo].[bEMBE]
(
[EMGroup] [dbo].[bGroup] NOT NULL,
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Rate] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMBEi    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE  trigger [dbo].[btEMBEi] on [dbo].[bEMBE] for insert as
   
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMBE
    *  Created By:  bc  04/17/99
    *  Modified by: TV 02/11/04 - 23061 added isnulls
	*				GF 05/05/2013 TFS-49039
    *
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int,  @errmsg varchar(255),
           @validcnt int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   

   if not exists(select * from EMRH r join inserted i on
   i.EMCo = r.EMCo and i.Equipment = r.Equipment and i.EMGroup = r.EMGroup and r.RevCode = i.RevCode)
      begin
      select @errmsg = 'Revenue Code is missing in EMRevRateEquip '
      goto error
      end
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMBE'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btEMBEu    Script Date: 8/28/99 9:37:14 AM ******/
CREATE   trigger [dbo].[btEMBEu] on [dbo].[bEMBE] for update as
/*--------------------------------------------------------------
*  Update trigger for EMBE
*  Created By:  bc  04/17/99
*  Modified by: TV 02/11/04 - 23061 added isnulls
*				TRL 03/19/09 - 130856 added hqma audit for rate change
*				GF 05/15/2013 TFS-49039
*
*--------------------------------------------------------------*/

/***  basic declares for SQL Triggers ****/
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int,@rcode int

select @numrows = @@rowcount

if @numrows = 0 return

set nocount on

----TFS-49039  
SELECT @validcnt = COUNT(*) FROM dbo.bEMEM EMEM JOIN inserted i ON i.EMCo = EMEM.EMCo AND i.Equipment = EMEM.Equipment and EMEM.ChangeInProgress = 'Y'
IF @validcnt = @numrows RETURN

/* cannot change key fields */
if Update(EMGroup) or Update(RevCode) or Update(RevBdownCode)
begin
	--select @validcnt = count(*) from inserted i 
	--Inner Join deleted d ON d.EMCo = i.EMCo and i.EMGroup = d.EMGroup and d.Equipment=i.Equipment and
 --                          d.RevCode = i.RevCode and d.RevBdownCode = i.RevBdownCode
	--if @validcnt <> @numrows
	--begin
		select @errmsg = 'Primary key fields may not be changed'
		GoTo error
	--End
End

/*Issue 130856*/
if update(Rate)
begin
	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    select 'bEMBE', 'EM Company: ' + convert(char(3),i.EMCo)+ ' EM Group: ' + convert(char(3),i.EMGroup)
    + ' Equipment: ' + i.Equipment+ ' Rev Code: ' + i.RevCode+ ' RevBdownCode: ' + i.RevBdownCode, 
	i.EMCo, 'C', 'Rate', convert(varchar(12),d.Rate), convert(varchar(12),i.Rate), getdate(), SUSER_SNAME()
    from inserted i
	Inner Join deleted d on i.EMCo = d.EMCo and i.EMGroup=d.EMGroup and i.Equipment = d.Equipment and i.RevCode=d.RevCode 
							and i.RevBdownCode=d.RevBdownCode
	where i.Rate <> d.Rate
end

return

error:
select @errmsg = isnull(@errmsg,'') + ' - cannot update into EMBE'
RAISERROR(@errmsg, 11, -1);
rollback transaction











GO
CREATE UNIQUE CLUSTERED INDEX [biEMBE] ON [dbo].[bEMBE] ([EMGroup], [EMCo], [Equipment], [RevCode], [RevBdownCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMBE] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMBE] WITH NOCHECK ADD CONSTRAINT [FK_bEMBE_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMBE] WITH NOCHECK ADD CONSTRAINT [FK_bEMBE_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bEMBE] WITH NOCHECK ADD CONSTRAINT [FK_bEMBE_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMBE] WITH NOCHECK ADD CONSTRAINT [FK_bEMBE_bEMRT_RevBdownCode] FOREIGN KEY ([EMGroup], [RevBdownCode]) REFERENCES [dbo].[bEMRT] ([EMGroup], [RevBdownCode])
GO
ALTER TABLE [dbo].[bEMBE] WITH NOCHECK ADD CONSTRAINT [FK_bEMBE_bEMRC_RevCode] FOREIGN KEY ([EMGroup], [RevCode]) REFERENCES [dbo].[bEMRC] ([EMGroup], [RevCode])
GO
ALTER TABLE [dbo].[bEMBE] NOCHECK CONSTRAINT [FK_bEMBE_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMBE] NOCHECK CONSTRAINT [FK_bEMBE_bEMEM_Equipment]
GO
ALTER TABLE [dbo].[bEMBE] NOCHECK CONSTRAINT [FK_bEMBE_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMBE] NOCHECK CONSTRAINT [FK_bEMBE_bEMRT_RevBdownCode]
GO
ALTER TABLE [dbo].[bEMBE] NOCHECK CONSTRAINT [FK_bEMBE_bEMRC_RevCode]
GO
