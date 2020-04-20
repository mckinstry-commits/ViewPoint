CREATE TABLE [dbo].[bEMSL]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[StdMaintGroup] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[LinkedMaintGrp] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
/****** Object:  Trigger dbo.btEMSLu    Script Date: 8/28/99 9:37:21 AM ******/
CREATE   trigger [dbo].[btEMSLu] on [dbo].[bEMSL] for UPDATE as

declare @errmsg varchar(255), @numrows int, @validcnt int, @changeinprogress bYN
   	
/*-----------------------------------------------------------------
*	CREATED BY: JM 5/19/99
*	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
*		 TRL 09/02/08 -- Issue 126196 add code to allow Equipment to change if
*		 the EM Equipment code is being changed
*		 GF 05/16/2013 TFS-49039
*
*	This trigger rejects update in bEMSL (EM Std Maint Links) if  the following error condition exists:
*
*		Change in key fields (EMCo, Equipment, StdMaintGroup or LinkeMaintGrp)
*
*/----------------------------------------------------------------
   
select @numrows = @@rowcount, @changeinprogress ='N'

if @numrows = 0 return 
   
set nocount on
   
----TFS-49039  
SELECT @validcnt = COUNT(*) FROM dbo.bEMEM EMEM JOIN inserted i ON i.EMCo = EMEM.EMCo AND i.Equipment = EMEM.Equipment and EMEM.ChangeInProgress = 'Y'
IF @validcnt = @numrows RETURN

/* Check for changes to key fields. */
if update(EMCo)
begin
   	select @errmsg = 'Cannot change EMCo'
   	goto error
end 

if update(Equipment)
begin
	/* Issue 126196 Check to see if equipment code is being changed.
	Select Where EMEM.LastUsedEquipmentCode = EMWH.Equipment*/
	select @changeinprogress=IsNull(ChangeInProgress,'N')
	from bEMEM e, inserted i where e.EMCo = i.EMCo and e.LastUsedEquipmentCode = i.Equipment
	and e.ChangeInProgress = 'Y'

	--Issue 126196 Only run code if Equipment Code is not being changed
	If @changeinprogress = 'N' 
	begin
		select @errmsg = 'Cannot change Equipment'
   		goto error
	end
end

if update(StdMaintGroup)
begin
   	select @errmsg = 'Cannot change StdMaintGroup'
   	goto error
end
if update(LinkedMaintGrp)
begin
--   	select @errmsg = 'Cannot change LinkedMaintGrp'
   	goto error
end	
   							
return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Std Maint Link!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biEMML] ON [dbo].[bEMSL] ([EMCo], [Equipment], [StdMaintGroup], [LinkedMaintGrp]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMSL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMSL] WITH NOCHECK ADD CONSTRAINT [FK_bEMSL_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMSL] WITH NOCHECK ADD CONSTRAINT [FK_bEMSL_bEMSH_EquipLinkedMaintGrp] FOREIGN KEY ([EMCo], [Equipment], [LinkedMaintGrp]) REFERENCES [dbo].[bEMSH] ([EMCo], [Equipment], [StdMaintGroup])
GO
ALTER TABLE [dbo].[bEMSL] WITH NOCHECK ADD CONSTRAINT [FK_bEMSL_bEMSH_EquipStdMaintGroup] FOREIGN KEY ([EMCo], [Equipment], [StdMaintGroup]) REFERENCES [dbo].[bEMSH] ([EMCo], [Equipment], [StdMaintGroup]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[bEMSL] NOCHECK CONSTRAINT [FK_bEMSL_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMSL] NOCHECK CONSTRAINT [FK_bEMSL_bEMSH_EquipLinkedMaintGrp]
GO
ALTER TABLE [dbo].[bEMSL] NOCHECK CONSTRAINT [FK_bEMSL_bEMSH_EquipStdMaintGroup]
GO
