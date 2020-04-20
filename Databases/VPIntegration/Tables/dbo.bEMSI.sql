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
[Description] [dbo].[bDesc] NULL,
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
/****** Object:  Trigger dbo.btEMSId    Script Date: 8/28/99 9:37:20 AM ******/
   CREATE   trigger [dbo].[btEMSId] on [dbo].[bEMSI] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By : JM 7/26/99 - added cascade delete of bEMSP per RH.
    *				 TV 02/11/04 - 23061 added isnulls
    *  Trigger deletes all associated records in bEMSP for the StdMaintItem.
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   /* Following removed 7/26/99 per RH and converted to cascade delete. */
   /* Check EMSP. */
   /*if exists(select * from deleted d, bEMSP e where d.EMCo = e.EMCo and d.Equipment=e.Equipment
   	and d.StdMaintGroup=e.StdMaintGroup and d.StdMaintItem=e.StdMaintItem)
   	begin
   	select @errmsg = 'Entries exist in bEMSP for this EMCo/Equipment/StdMaintGroup/StdMaintItem'
   	goto error
   	end */
   
   /* Cascade delete of bEMSP of matching Parts for Std Maint Item. */
   delete from bEMSP
   from deleted d
   where bEMSP.EMCo = d.EMCo
       and bEMSP.Equipment = d.Equipment
       and bEMSP.StdMaintGroup = d.StdMaintGroup
       and bEMSP.StdMaintItem = d.StdMaintItem
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Std Maint Item!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btEMSIi    Script Date: 8/28/99 9:37:21 AM ******/
   CREATE   trigger [dbo].[btEMSIi] on [dbo].[bEMSI] for INSERT as
   

/*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects insertion in bEMSI (EMStd Maint Items) if the following error condition exists:
    *
    *		Invalid EMCo vs bEMCO
    *		Invalid Equipment vs bEMEM
    *		Invalid StdMaintGroup vs bEMSH
    *		Invalid EMGroup vs bHQGP
    *		Invalid CostCode vs bEMCC
    *		Invalid RepairType vs bEMRX
    *		Invalid InOutFlag - not in (I, O)
    *
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), 
   	@numrows int, 
   	@repairtype varchar(10),
   	@validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* Validate EMCo. */
   select @validcnt = count(*) from bEMCO e, inserted i where e.EMCo = i.EMCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid EMCo'
   	goto error
   	end
   
   /* Validate Equipment. */
   select @validcnt = count(*) from bEMEM e, inserted i where e.EMCo = i.EMCo and e.Equipment = i.Equipment
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Equipment'
   	goto error
   	end
   
   /* Validate StdMaintGroup. */
   select @validcnt = count(*) from bEMSH e, inserted i where e.EMCo = i.EMCo and e.Equipment = i.Equipment 
   	and e.StdMaintGroup=i.StdMaintGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid StdMaintGroup'
   	goto error
   	end
   
   /* Validate EMGroup. */
   select @validcnt = count(*) from bHQGP h, inserted i where h.Grp = i.EMGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid EMGroup'
   	goto error
   	end	
   		
   /* Validate CostCode. */
   select @validcnt = count(*) from bEMCC e, inserted i where e.EMGroup = i.EMGroup and e.CostCode=i.CostCode
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid CostCode'
   	goto error
   	end				
   
   /* Validate RepairType. */
   select @repairtype = RepairType from inserted
   if @repairtype is not null
   	begin
   	select @validcnt = count(*) from bEMRX e, inserted i where e.EMGroup = i.EMGroup and e.RepType=i.RepairType
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid RepairType'
   		goto error
   		end				
   	end
   											
   /* Validate InOutFlag. */
   select @validcnt=count(*) from inserted i
   where i.InOutFlag not in ('I', 'O')
   if @validcnt <>0  
   	begin  
   	select @errmsg = 'Invalid InOutFlag - must be I or O'
   	goto error
   	end
   		
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Std Maint Item!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btEMSIu    Script Date: 8/28/99 9:37:21 AM ******/
   CREATE   trigger [dbo].[btEMSIu] on [dbo].[bEMSI] for UPDATE as
   

/*-----------------------------------------------------------------
*	CREATED BY: JM 5/19/99
*	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
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

if update(StdMaintItem)
begin
   	select @errmsg = 'Cannot change StdMaintItem'
   	goto error
end	
   	
/* Validate EMGroup. */
if update(EMGroup)
begin
	select @validcnt = count(*) from bHQGP h, inserted i where h.Grp = i.EMGroup
   	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid EMGroup'
   		goto error
   	end	
end
   	
/* Validate CostCode. */
if update(CostCode)
begin
	select @validcnt = count(*) from bEMCC e, inserted i where e.EMGroup = i.EMGroup and e.CostCode=i.CostCode
   	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid CostCode'
   		goto error
   	end				
end
   	
/* Validate RepairType. */
if update(RepairType)
begin
   	select @repairtype = RepairType from inserted
   	if @repairtype is not null	
	begin
   		select @validcnt = count(*) from bEMRX e, inserted i where e.EMGroup = i.EMGroup and e.RepType=i.RepairType
   		if @validcnt <> @numrows
   		begin
   			select @errmsg = 'Invalid RepairType'
   			goto error
		end				
   	end
 end
   		
 /* Validate InOutFlag. */
 if update(InOutFlag)
 begin
	select @validcnt=count(*) from inserted i
   	where i.InOutFlag not in ('I', 'O')
   	if @validcnt <>0  
   	begin  
   		select @errmsg = 'Invalid InOutFlag - must be I or O'
   		goto error
   	end
end
   							
return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Std Maint Item!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biEMSI] ON [dbo].[bEMSI] ([EMCo], [Equipment], [StdMaintGroup], [StdMaintItem]) ON [PRIMARY]
GO
