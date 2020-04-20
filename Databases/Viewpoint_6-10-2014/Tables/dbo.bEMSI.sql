CREATE TABLE [dbo].[bEMSI]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[StdMaintGroup] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[StdMaintItem] [dbo].[bItem] NOT NULL,
[EMGroup] [tinyint] NOT NULL,
[CostCode] [dbo].[bCostCode] NOT NULL,
[RepairType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[InOutFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[EstHrs] [dbo].[bHrs] NULL,
[EstCost] [dbo].[bDollar] NULL,
[LastHourMeter] [dbo].[bHrs] NULL,
[LastOdometer] [dbo].[bHrs] NULL,
[LastGallons] [dbo].[bHrs] NULL,
[LastDoneDate] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[LastReplacedHourMeter] [dbo].[bHrs] NULL,
[LastReplacedOdometer] [dbo].[bHrs] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


   CREATE   trigger [dbo].[btEMSIu] on [dbo].[bEMSI] for UPDATE as
   

/*-----------------------------------------------------------------
*	CREATED BY: JM 5/19/99
*	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
*					GF 05/05/2013 TFS-49039
*
*
*		 TRL 09/02/08 -- Issue 126196 add code to allow Equipment to change if
*		 the EM Equipment code is being changed
*
*	This trigger rejects update in bEMSI (EM Std Maint Items) if  the following error condition exists:
*
*		Change in key fields (EMCo, Equipment, StdMaintGroup or StdMaintItem)
*		Invalid EMGroup vs bHQGP
*		Invalid CostCode vs bEMCC
*		Invalid RepairType vs bEMRX
*   
*		Invalid InOutFlag - not in (I, O)
*
*/----------------------------------------------------------------
  
declare @errmsg varchar(255),@numrows int,@repairtype varchar(10),@validcnt int, @changeinprogress bYN
   
select @numrows = @@rowcount, @changeinprogress='N'

if @numrows = 0 return 
   
set nocount on

----TFS-49039  
SELECT @validcnt = COUNT(*) FROM dbo.bEMEM EMEM JOIN inserted i ON i.EMCo = EMEM.EMCo AND i.Equipment = EMEM.Equipment and EMEM.ChangeInProgress = 'Y'
IF @validcnt = @numrows RETURN

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

if update(StdMaintItem)
begin
   	select @errmsg = 'Cannot change StdMaintItem'
   	goto error
end	
   	


   							
return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Std Maint Item!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction


GO
ALTER TABLE [dbo].[bEMSI] WITH NOCHECK ADD CONSTRAINT [CK_bEMSI_InOutFlag] CHECK (([InOutFlag]='O' OR [InOutFlag]='I'))
GO
CREATE UNIQUE CLUSTERED INDEX [biEMSI] ON [dbo].[bEMSI] ([EMCo], [Equipment], [StdMaintGroup], [StdMaintItem]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMSI] WITH NOCHECK ADD CONSTRAINT [FK_bEMSI_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMSI] WITH NOCHECK ADD CONSTRAINT [FK_bEMSI_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bEMSI] WITH NOCHECK ADD CONSTRAINT [FK_bEMSI_bEMSH_EquipStdMaintGroup] FOREIGN KEY ([EMCo], [Equipment], [StdMaintGroup]) REFERENCES [dbo].[bEMSH] ([EMCo], [Equipment], [StdMaintGroup]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[bEMSI] WITH NOCHECK ADD CONSTRAINT [FK_bEMSI_bEMCC_CostCode] FOREIGN KEY ([EMGroup], [CostCode]) REFERENCES [dbo].[bEMCC] ([EMGroup], [CostCode])
GO
ALTER TABLE [dbo].[bEMSI] WITH NOCHECK ADD CONSTRAINT [FK_bEMSI_bEMRX_RepairType] FOREIGN KEY ([EMGroup], [RepairType]) REFERENCES [dbo].[bEMRX] ([EMGroup], [RepType])
GO
ALTER TABLE [dbo].[bEMSI] NOCHECK CONSTRAINT [FK_bEMSI_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMSI] NOCHECK CONSTRAINT [FK_bEMSI_bEMEM_Equipment]
GO
ALTER TABLE [dbo].[bEMSI] NOCHECK CONSTRAINT [FK_bEMSI_bEMSH_EquipStdMaintGroup]
GO
ALTER TABLE [dbo].[bEMSI] NOCHECK CONSTRAINT [FK_bEMSI_bEMCC_CostCode]
GO
ALTER TABLE [dbo].[bEMSI] NOCHECK CONSTRAINT [FK_bEMSI_bEMRX_RepairType]
GO
