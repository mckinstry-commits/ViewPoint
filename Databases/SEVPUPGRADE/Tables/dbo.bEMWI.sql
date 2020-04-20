CREATE TABLE [dbo].[bEMWI]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[WorkOrder] [dbo].[bWO] NOT NULL,
[WOItem] [smallint] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[ComponentTypeCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[CostCode] [dbo].[bCostCode] NOT NULL,
[StdMaintGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[StdMaintItem] [dbo].[bItem] NULL,
[Description] [dbo].[bItemDesc] NULL,
[InHseSubFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[StatusCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[RepairType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[RepairCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Mechanic] [dbo].[bEmployee] NULL,
[EstHrs] [dbo].[bHrs] NULL,
[QuoteAmt] [dbo].[bDollar] NULL,
[Priority] [char] (1) COLLATE Latin1_General_BIN NULL,
[PartCode] [dbo].[bMatl] NULL,
[SerialNo] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[DateCreated] [dbo].[bDate] NOT NULL,
[DateDue] [dbo].[bDate] NULL,
[DateSched] [dbo].[bDate] NULL,
[DateCompl] [dbo].[bDate] NULL,
[CurrentHourMeter] [dbo].[bHrs] NULL,
[TotalHourMeter] [dbo].[bHrs] NULL,
[CurrentOdometer] [dbo].[bHrs] NULL,
[TotalOdometer] [dbo].[bHrs] NULL,
[FuelUse] [dbo].[bUnits] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  CREATE       trigger [dbo].[btEMWId] on [dbo].[bEMWI] for DELETE as
/*-----------------------------------------------------------------
*	CREATED BY: JM 5/19/99
*	MODIFIED By : TV 9/17/03 22231 Check for costs in EMCD
*		TV 02/11/04 - 23061 added isnulls
*		TRL 12/16/08 - 131453  update join statements
*
*	This trigger rejects delete in bEMWI (EM Work Order Items) if  the following error condition exists:
*
*	Entry exists in bEMWP - EM Work Order Items by EMCo/WorkOrder/WOItem
*
*----------------------------------------------------------------*/
declare @errmsg varchar(255), @validcnt int 
   
if @@rowcount = 0 return

set nocount on
   
/* Check bEMWP. */
if exists(select top 1 1  from deleted d inner join bEMWP e with(nolock) on d.EMCo = e.EMCo and d.WorkOrder=e.WorkOrder and d.WOItem=e.WOItem)
begin
	select @errmsg = 'Entries exist in bEMWP with this EMCo/WorkOrder/WOItem'
   	goto error
end
   
--Check EMCD for costs.
if exists(select top 1 1 from bEMCD d with(nolock) inner join deleted e on e.EMCo = d.EMCo and e.WorkOrder = d.WorkOrder and e.WOItem = d.WOItem)
begin
	select @errmsg = 'Cost detail records exist in bEMCD with this EMCo/WorkOrder/WorkOrderItem'
   	goto error
end
   
update bEMWH
set Complete = case when 
	(select count(1) from  bEMWI i with (nolock) 
		Inner join deleted h on i.EMCo = h.EMCo and i.WorkOrder = h.WorkOrder
		Inner join bEMWS s on  s.EMGroup = i.EMGroup and s.StatusCode = i.StatusCode
		where i.EMCo = h.EMCo and i.WorkOrder = h.WorkOrder and s.StatusType <> 'F') = 0 
	and 
	(select count(1) from bEMWI i2 with(nolock) where h.EMCo = i2.EMCo and h.WorkOrder = i2.WorkOrder) > 0
   then 'Y' else 'N' end
   from bEMWH h join deleted d on d.EMCo = h.EMCo and d.WorkOrder = h.WorkOrder

return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Work Order Item!'
    RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 CREATE      trigger [dbo].[btEMWIi] on [dbo].[bEMWI] for INSERT as
/*-----------------------------------------------------------------
*	CREATED BY: JM 5/19/99
*	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
*				TRL 06/20/07 made changes for frmEMWOItemInit so null values could be updated.
*				TRL 02/20/08 - Issue 271172 add PRCo to EMWI
*				TRL 05/13/08 - Issue 128308 changed validation for PRCo and Mechanic
*				TRL 12/16/08 - 131453  update join statements
*				TRL 03/05/08 - 132360, Fixed triggers to handle a mass update
*				TRL 10/26/09 -  135769 Fix PRCo and Mechanic validation
*
*	This trigger rejects insertion in bEMWI (EM Work Order Items) if the following error condition exists:
*
*		Invalid EMCo vs bEMCO
*		Invalid WorkOrder vs bEMWH
*		Invalid Equipment vs bEMEM by EMCo and Equipment
*		Invalid ComponentTypeCode vs bEMTY by EMGroup and ComponentTypeCode
*		Invalid Component vs bEMEM by EMCo and Equipment=Component
*		Component not attached to Equipment by EMCo and Equipment=Component and
*		CompOfEquip=Equipment
*		Invalid EMGroup vs bHQGP
*		Invald CostCode vs bEMCC by EMGroup and CostCode
*		Invalid StdMaintGroup vs bEMSH by EMCo and Equipment and StdMaintGroup
*		Invalid StdMaintItem vs bEMSI by EMCo and Equipment and StdMaintGroup and StdMaintItem
*		Invalid InHseSubFlag - not in (I,O)
*		Invalid StatusCode vs bEMWS by EMGroup and StatusCode
*		Invalid RepairType vs bEMRX by EMGroup and RepairType
*		Invalid Mechanic vs bPREH  by Mechanic = Employee and bEMCO.PRCo
*		Invalid Priority - not in (U,N,L)
*		
----------------------------------------------------------------*/
   
declare @errmsg varchar(255),@numrows int,@validcnt int,@prconumrows int,@mechanicnumrows int
	
select @numrows = @@rowcount

if @numrows = 0 
begin
	return
end
   
set nocount on
   
/* Validate EMCo. */
select @validcnt = count(*) from bEMCO e  Inner Join inserted i on e.EMCo = i.EMCo
if @validcnt <> @numrows
begin
	select @errmsg = 'Invalid EMCo'
	goto error
end
   
/* Validate WorkOrder. */
select @validcnt = count(*) from bEMWH e with(nolock)
inner join inserted i on e.EMCo = i.EMCo and e.WorkOrder = i.WorkOrder
if @validcnt <> @numrows
begin
 	select @errmsg = 'Invalid WorkOrder'-- + '= x' +@x + 'x'
 	goto error
end
   
/* Validate Equipment. */
select @validcnt = count(*) from  bEMEM e with(nolock) 
inner join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment
if @validcnt <> @numrows
begin
 	select @errmsg = 'Invalid Equipment'
 	goto error
end
   
/* Validate Component. */   
if IsNull((select Component from inserted),'')<>''
begin
 	select @validcnt = count(*) from bEMEM e with(nolock)
	inner join inserted i on e.EMCo=i.EMCo and e.Equipment = i.Component 
	Where e.Type = 'C'
 	if @validcnt <> @numrows
	begin
 		select @errmsg = 'Invalid Component - not in bEMEM or not Type C'
 		goto error
 	end
 	
	select @validcnt = count(*) from bEMEM e with(nolock)
	inner join inserted i on e.EMCo=i.EMCo and e.Equipment = i.Component and e.CompOfEquip = i.Equipment
 	if @validcnt <> @numrows
 	begin
 		select @errmsg = 'Invalid Component - not a Component for this Equipment'
 		goto error
 	end
end

/* Validate ComponentTypeCode. */
if IsNull((select ComponentTypeCode from inserted),'') <> ''
begin
	select @validcnt = count(*) from bEMTY e with(nolock) 
	inner join inserted i on e.ComponentTypeCode = i.ComponentTypeCode and e.EMGroup = i.EMGroup
 	if @validcnt <> @numrows
 	begin
 		select @errmsg = 'Invalid ComponentTypeCode'
 		goto error
 	end
end
   
/* Validate EMGroup. */
select @validcnt = count(*) from bHQGP h with(nolock) inner Join inserted i on h.Grp = i.EMGroup
if @validcnt <> @numrows
begin
   	select @errmsg = 'Invalid EMGroup'
   	goto error
end
   
/* Validate CostCode. */
select @validcnt = count(*) from bEMCC e with(nolock)
inner join inserted i on  e.EMGroup = i.EMGroup and e.CostCode = i.CostCode
if @validcnt <> @numrows
begin
   	select @errmsg = 'Invalid CostCode'
   	goto error
end
   
/* Validate StdMaintGroup. Note that because an WOItem can exist for a Component when the Component's parent Equipment
does not have the same SMG or no SMG, we must compare bEMSH.Equipment to Component if the WorkOrder
being created is for a Component. */
if IsNull((select StdMaintGroup from inserted),'')<> ''
begin
   	select @validcnt = count(*) from bEMSH e 
	inner Join  inserted i on e.EMCo = i.EMCo
	and e.Equipment = case when IsNull(i.ComponentTypeCode,'')=''then i.Equipment else i.Component end
   	and e.StdMaintGroup = i.StdMaintGroup
 	if @validcnt <> @numrows
 	begin
  		select @errmsg = 'Invalid StdMaintGroup'
 		goto error
 	end
end
   
/* Validate StdMaintItem. Note that because an WOItem can exist for a Component when the Component's parent Equipment
does not have the same SMG or no SMG, we must compare bEMSH.Equipment to Component if the WorkOrder
being created is for a Component. */
if (select StdMaintItem from inserted) is not null
begin
	select @validcnt = count(*) from bEMSI e with(nolock)
	inner join inserted i on e.EMCo = i.EMCo
	and e.Equipment = case When IsNull(i.ComponentTypeCode,'')=''then i.Equipment else i.Component end
   	and e.StdMaintGroup = i.StdMaintGroup and e.StdMaintItem = i.StdMaintItem
 	if @validcnt <> @numrows
 	begin
 		select @errmsg = 'Invalid StdMaintItem'
 		goto error
 	end
 end
   
/* Validate InHseSubFlag. */
select @validcnt=count(*) from inserted i where i.InHseSubFlag in ('I', 'O')
if @validcnt <> @numrows 
begin
   	select @errmsg = 'Invalid InHseSubFlag - must be I or O'
   	goto error
end
   
/* Validate StatusCode. */
select @validcnt = count(*) from bEMWS e with(nolock)
inner Join inserted i on e.EMGroup = i.EMGroup and e.StatusCode = i.StatusCode
if @validcnt <> @numrows
begin
   	select @errmsg = 'Invalid StatusCode'
   	goto error
end
   
/* Validate RepairType. */
if IsNull((select RepairType from inserted),'')<>''
begin
	select @validcnt=count(*) from bEMRX e with(nolock) 
	inner join inserted i on e.EMGroup = i.EMGroup and e.RepType = i.RepairType
 	if @validcnt <> @numrows
	begin
    	select @errmsg = 'Invalid RepairType'
   		goto error
   	end
end


/*Validate PRCo and Mechanic*/   
If (select PRCo from inserted) is not null
begin
	select @prconumrows = count(*) from inserted where PRCo is not null
	select @validcnt = count(*) from bPRCO p with(nolock) inner join inserted i on p.PRCo= i.PRCo
	if @validcnt <> @prconumrows
	begin
   		select @errmsg = 'Invalid PR Co'
   		goto error
   	end	
end

/*Validate Mechanic*/
if (Select Mechanic from inserted) is not null 
begin
	select @mechanicnumrows = count(*) from inserted where PRCo is not null and Mechanic is not null
	select  @validcnt = count(*) from bPREH p with(nolock) 
	inner Join  inserted i on p.Employee = i.Mechanic and p.PRCo= i.PRCo
	if @validcnt <> @mechanicnumrows
	begin
   		select @errmsg = 'Invalid Mechanic'
   		goto error
   	end	
end
   
/* Validate Priority. */
if IsNull((select Priority from inserted),'') <> ''
begin
   	select @validcnt=count(*) from inserted i where i.Priority not in ('U','N','L')
 	if @validcnt <>0
   	begin
   		select @errmsg = 'Invalid Priority - must be U, N or L'
		goto error
   	end
end

--update Complete flag in EMWH
update bEMWH
set Complete =  'N' 
from bEMWH h with(nolock)
Inner Join inserted i on i.EMCo = h.EMCo and i.WorkOrder = h.WorkOrder

return
   
error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Work Order Item!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE             trigger [dbo].[btEMWIu] on [dbo].[bEMWI] for UPDATE as
/*******************************************************************************************************
*	CREATED BY: JM 5/19/99
*	MODIFIED By : MH 9/2/99 See comments below - this date.
*		JM 12/19/00 - Added deletion of StdMaintItem when WOItem marked complete 
*		if StdMaintGroup is flagged as 'AutoDelete'.
*		JM 4/3/01 - Ref Issue 12811: Added update of last done columns in bEMSI.
*		JM 07/24/01 - Corrected subquery error, approx line 280.
*       TV 01/13/03 - Cleanup Allow the update of mulitple records in one update call
*		TV 02/11/04 - 23061 added isnulls
*		TRL 09/02/08 -- Issue 126196 add code to allow Equipment to change if
*		the EM Equipment code is being changed
*		TRL 12/02/2008 -- Issue 125342(6.2), Add restriction to EMSI (Std Maint Item)update
*						when Status code with a Final type changes
*		TRL 12/16/08 - 131453  update join statements
*		TRL 03/05/08 - 132360, Fixed triggers to handle a mass update
*		TRL 08/10/09 - 135096 Fixed Last Done Update
*		TRL 10/26/09 -  135769 Fix PRCo and Mechanic validation
*		JVH 6/8/11	- TK-05982 Added to the update keeping track of the replace odometer and hour meter readings at the time of the update.
*
*		Change in key fields (EMCo, WorkOrder, WOItem)
*		Invalid Equipment vs bEMEM by EMCo and Equipment
*		Invalid ComponentTypeCode vs bEMTY by EMGroup and ComponentTypeCode
*		Invalid Component vs bEMEM by EMCo and Equipment=Component
*		Component not attached to Equipment by EMCo and Equipment=Component and
*			CompOfEquip=Equipment
*		Invalid EMGroup vs bHQGP
*		Invald CostCode vs bEMCC by EMGroup and CostCode
*		Invalid StdMaintGroup vs bEMSH by EMCo and Equipment and StdMaintGroup
*		Invalid StdMaintItem vs bEMSI by EMCo and Equipment and StdMaintGroup and StdMaintItem
*		Invalid InHseSubFlag - not in (I,O)
*		Invalid StatusCode vs bEMWS by EMGroup and StatusCode
*		Invalid RepairType vs bEMRX by EMGroup and RepairType
*		Invalid Mechanic vs bPREH  by Mechanic = Employee and bEMCO.PRCo
*		Invalid Priority - not in (U,N,L)
*
*	Updates bEMSI per the following:
*		bEMWI		->>	bEMSI
*		CurrentHourMeter	LastHourMeter
*		CurrentOdometer	LastOdometer
*		FuelUse			LastGallons
*		DateCompl		LastDoneDate
*
****************************************************************************************************/
declare @errmsg varchar(255),@numrows int,@validcnt int,@prconumrows int,@mechanicnumrows int,@nullcnt int
   
select @numrows = @@rowcount

if @numrows = 0 
begin
	return
end

set nocount on
   
-- Check for changes to key fields. 
if update(EMCo)
begin
	 /* Validate EMCo. */
	select @validcnt = count(*) from bEMCO e, inserted i where e.EMCo = i.EMCo
	if @validcnt <> @numrows
 	begin
 		select @errmsg = 'Invalid EMCo'
 		goto error
 	end
end
if update(WorkOrder)
begin
	select @errmsg = 'Cannot change WorkOrder'
	goto error
end

if update(WOItem)
begin
	select @errmsg = 'Cannot change WOItem'
   	goto error
end
   
/* Issue 126196 Check to see if equipment code is being changed*/
/* If an Equipment code or Component is being changed stop all updates*/
If exists (select top 1 1 from bEMEM e with(nolock) 
			inner join  inserted i on e.EMCo = i.EMCo and e.LastUsedEquipmentCode = i.Equipment
			Where e.ChangeInProgress = 'Y')
begin
	select @errmsg = 'Equipment code change in progress'
   	goto error
end
If exists (select top 1 1 from bEMEM e with(nolock) 
			inner join  inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment
			Where e.ChangeInProgress = 'Y')
begin
	select @errmsg = 'Equipment code change in progress'
   	goto error
end
/* Issue 126196 Check to see if Component code is being changed*/
If exists (select top 1 1 from bEMEM e with(nolock) 
			inner join  inserted i on e.EMCo = i.EMCo and e.LastUsedEquipmentCode = i.Component
			Where e.ChangeInProgress = 'Y')
begin
	select @errmsg = 'Equipment code change in progress for Component'
   	goto error
end
If exists (select top 1 1 from bEMEM e with(nolock) 
			inner join  inserted i on e.EMCo = i.EMCo and e.Equipment = i.Component
			Where e.ChangeInProgress = 'Y')
begin
	select @errmsg = 'Equipment code change in progress for Component'
   	goto error
end


-- Validate Equipment. 
if update(Equipment)
begin
	select @validcnt = count(*) from  bEMEM e with(nolock) inner join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment
	select @nullcnt = count(*) from inserted where IsNull(Equipment,'')=''
	if @validcnt +@nullcnt <> @numrows
	begin
		select @errmsg = 'Invalid Equipment'
		goto error
	end
end
  
-- Validate Component. 
if update(Component)
begin
	select @validcnt = count(*) from bEMEM e with(nolock) 
	inner join inserted i on e.EMCo=i.EMCo and e.Equipment = i.Component 
	Where e.Type = 'C'
	select @nullcnt = count(*) from inserted where IsNull(Component,'')=''
	if @validcnt + @nullcnt <> @numrows
	begin
		select @errmsg = 'Invalid Component - not in bEMEM or not Type C'
		goto error
	end

	select @validcnt = count(*) from bEMEM e with(nolock)
	inner join inserted i on e.EMCo=i.EMCo and e.Equipment = i.Component and e.CompOfEquip = i.Equipment
	select @nullcnt = count(*) from inserted where IsNull(Component,'')=''
	if @validcnt + @nullcnt <> @numrows
	begin
		select @errmsg = 'Invalid Component - not a Component for this Equipment'
		goto error
	end
end
   
-- Validate ComponentTypeCode. 
if update(ComponentTypeCode)
begin
	select @validcnt = count(*) from bEMTY e with(nolock) 
	inner join inserted i on e.ComponentTypeCode = i.ComponentTypeCode and e.EMGroup = i.EMGroup
	select @nullcnt = count(*) from inserted where IsNull(ComponentTypeCode,'')=''
 	if @validcnt + @nullcnt <> @numrows
 	begin
 		select @errmsg = 'Invalid ComponentTypeCode'
 		goto error
 	end
end

-- Validate EMGroup. 
if update(EMGroup)
begin
	select @validcnt = count(*) from bHQGP h with(nolock) inner Join inserted i on h.Grp = i.EMGroup
	select @nullcnt = count(*) from inserted where EMGroup is null
	if @validcnt + @nullcnt <> @nullcnt
	begin
   		select @errmsg = 'Invalid EMGroup'
   		goto error
	end
end
   
-- Validate CostCode. 
if update(CostCode)
begin
	select @validcnt = count(*) from bEMCC e with(nolock)
	inner join inserted i on  e.EMGroup = i.EMGroup and e.CostCode = i.CostCode
	select @nullcnt = count(*) from inserted where IsNull(CostCode,'')=''
	if @validcnt + @nullcnt <> @numrows
	begin
   		select @errmsg = 'Invalid CostCode'
   		goto error
	end
end
   
-- Validate StdMaintGroup. 
if update(StdMaintGroup)
begin
	if IsNull((select StdMaintGroup from inserted),'')<> ''
	begin
		select @validcnt = count(*) from bEMSH e 
		inner Join  inserted i on e.EMCo = i.EMCo
		and e.Equipment = case when IsNull(i.ComponentTypeCode,'')=''then i.Equipment else i.Component end
		and e.StdMaintGroup = i.StdMaintGroup
		select @nullcnt = count(*) from inserted where IsNull(StdMaintGroup,'')=''
		if @validcnt + @nullcnt <> @numrows
		begin
			select @errmsg = 'Invalid StdMaintGroup'
			goto error
		end
	end
end

if update(StdMaintItem)
begin
	select @validcnt = count(*) from bEMSI e with(nolock)
	inner join inserted i on e.EMCo = i.EMCo
	and e.Equipment = case When IsNull(i.ComponentTypeCode,'')=''then i.Equipment else i.Component end
   	and e.StdMaintGroup = i.StdMaintGroup and e.StdMaintItem = i.StdMaintItem
	select @nullcnt = count(*) from inserted where StdMaintItem is null
 	if @validcnt + @nullcnt <> @numrows
 	begin
 		select @errmsg = 'Invalid StdMaintItem'
 		goto error
 	end
end
   
-- Validate InHseSubFlag. 
if update(InHseSubFlag)
begin
	select @validcnt=count(*) from inserted i where i.InHseSubFlag not in ('I', 'O')
	if @validcnt <> 0 
	begin
   		select @errmsg = 'Invalid InHseSubFlag - must be I or O'
   		goto error
	end
end

-- Validate StatusCode. 
if update(StatusCode)
begin
	select @validcnt = count(*) from bEMWS e with(nolock)
	inner Join inserted i on e.EMGroup = i.EMGroup and e.StatusCode = i.StatusCode
	select @nullcnt = count(*) from inserted where IsNull(StatusCode,'')=''
	if @validcnt + @nullcnt <> @numrows
	begin
   		select @errmsg = 'Invalid StatusCode'
   		goto error
	end

   	-- Rev 02/12/01 JM - Correction of above cascade delete per Issue 12283 
   	delete bEMSI --If changing StatusCode to a StatusType 'F', delete corresponding record in bEMSI 
   	from bEMSI
   	join inserted i on bEMSI.EMCo = i.EMCo and bEMSI.Equipment=i.Equipment and bEMSI.StdMaintGroup=i.StdMaintGroup	and bEMSI.StdMaintItem=i.StdMaintItem
   	join bEMWS w on  w.EMGroup = i.EMGroup 	and w.StatusCode = i.StatusCode
   	join bEMSH h on h.EMCo = i.EMCo and h.Equipment=i.Equipment and h.StdMaintGroup=i.StdMaintGroup
   	where w.StatusType  = 'F' and h.AutoDelete  = 'Y'--if StdMaintGroup is flagged 'AutoDelete'.
    
	--update Complete flag in EMWH
	update bEMWH
	set Complete = case when 
	(select count(1)  
	from  bEMWI i with (nolock) join inserted h on i.EMCo = h.EMCo and i.WorkOrder = h.WorkOrder
	join bEMWS s on  s.EMGroup = i.EMGroup and s.StatusCode = i.StatusCode
	where i.EMCo = h.EMCo and i.WorkOrder = h.WorkOrder and s.StatusType <> 'F') = 0 and 
	(select count(1) from bEMWI i2 with (nolock) where h.EMCo = i2.EMCo and h.WorkOrder = i2.WorkOrder) > 0
	then 'Y' else 'N' end
	from bEMWH h join inserted d on d.EMCo = h.EMCo and d.WorkOrder = h.WorkOrder
end
   
-- Validate RepairType. 
if update(RepairType)
begin
	select @validcnt=count(*) from bEMRX e with(nolock) 
	inner join inserted i on e.EMGroup = i.EMGroup and e.RepType = i.RepairType
	select @nullcnt = count(*) from inserted where IsNull(RepairType,'')=''
	if @validcnt + @nullcnt <> @numrows
	begin
		select @errmsg = 'Invalid RepairType'
		goto error
 	end
end

-- Validate PRCo. 
If update (PRCo)
begin
	select @prconumrows = count(*) from inserted where PRCo is not null
	select @validcnt = count(*) from bPRCO p with(nolock) inner join inserted i on p.PRCo= i.PRCo
	if @validcnt <> @prconumrows 
	begin
		select @errmsg = 'Invalid PR Co'
		goto error
	end
End

-- Validate Mechanic. 
if update(Mechanic)
begin
	select @mechanicnumrows = count(*) from inserted where  PRCo is not null and Mechanic is not null
	select  @validcnt = count(*) from bPREH p with(nolock) 
	inner Join  inserted i on p.Employee = i.Mechanic and p.PRCo= i.PRCo
	if @validcnt <> IsNull(@mechanicnumrows,0) 
	begin
		select @errmsg = 'Invalid Mechanic'
		goto error
	end
end
   	
-- Validate Priority. 
if update(Priority)
begin
   	select @validcnt=count(*) from inserted i where i.Priority not in ('U','N','L')
 	if @validcnt <>0
   	begin
   		select @errmsg = 'Invalid Priority - must be U, N or L'
		goto error
   	end
end

---- Update bEMSI LastDone data if Status is final. 
----135096 Fixed Last Done Update
update bEMSI
set bEMSI.LastHourMeter = isnull(i.CurrentHourMeter,s.LastHourMeter),
bEMSI.LastReplacedHourMeter = bEMEM.ReplacedHourReading,
bEMSI.LastOdometer = isnull(i.CurrentOdometer,s.LastOdometer),
bEMSI.LastReplacedOdometer = bEMEM.ReplacedOdoReading,
bEMSI.LastGallons = isnull(i.FuelUse,s.LastGallons),
bEMSI.LastDoneDate = isnull(i.DateCompl,s.LastDoneDate)
from inserted i
inner join  bEMSI s on s.EMCo=i.EMCo and  s.Equipment = i.Equipment
and s.StdMaintGroup = i.StdMaintGroup and s.StdMaintItem = i.StdMaintItem 
inner join  bEMWS w on w.EMGroup=i.EMGroup and w.StatusCode=i.StatusCode
inner join bEMEM on i.EMCo = bEMEM.EMCo and i.Equipment = bEMEM.Equipment
where s.EMCo = i.EMCo and s.Equipment =  i.Equipment and isnull(i.Component ,'') ='' and
s.StdMaintGroup = i.StdMaintGroup and s.StdMaintItem = i.StdMaintItem and
w.StatusType = 'F' and 	/* New Code Issue 125342*/
i.DateCompl >= IsNull(s.LastDoneDate,'01/01/1950') and IsNull(i.DateCompl,'') <>''
   	
update bEMSI
set bEMSI.LastHourMeter = isnull(i.CurrentHourMeter,s.LastHourMeter),
bEMSI.LastReplacedHourMeter = bEMEM.ReplacedHourReading,
bEMSI.LastOdometer = isnull(i.CurrentOdometer,s.LastOdometer),
bEMSI.LastReplacedOdometer = bEMEM.ReplacedOdoReading,
bEMSI.LastGallons = isnull(i.FuelUse,s.LastGallons),
bEMSI.LastDoneDate = isnull(i.DateCompl,s.LastDoneDate)
from inserted i
inner join  bEMSI s on s.EMCo=i.EMCo and  s.Equipment = i.Component
and s.StdMaintGroup = i.StdMaintGroup and s.StdMaintItem = i.StdMaintItem 
inner join  bEMWS w on w.EMGroup=i.EMGroup and w.StatusCode=i.StatusCode
inner join bEMEM on i.EMCo = bEMEM.EMCo and i.Component = bEMEM.Equipment
where s.EMCo = i.EMCo and s.Equipment = i.Component  and isnull(i.Component ,'') <>''  and
s.StdMaintGroup = i.StdMaintGroup and s.StdMaintItem = i.StdMaintItem and
w.StatusType = 'F' and 	/* New Code Issue 125342*/
i.DateCompl >= IsNull(s.LastDoneDate,'01/01/1950') and IsNull(i.DateCompl,'') <>''

return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Work Order Item!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
   
   
   
  
 







GO
CREATE NONCLUSTERED INDEX [biEMWIComponent] ON [dbo].[bEMWI] ([EMCo], [Equipment], [Component], [StdMaintGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biEMWIDelete] ON [dbo].[bEMWI] ([EMCo], [WorkOrder], [Equipment], [DateCompl]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMWI] ON [dbo].[bEMWI] ([EMCo], [WorkOrder], [WOItem]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMWI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMWI] WITH NOCHECK ADD CONSTRAINT [FK_bEMWI_bEMCC] FOREIGN KEY ([EMGroup], [CostCode]) REFERENCES [dbo].[bEMCC] ([EMGroup], [CostCode])
GO
