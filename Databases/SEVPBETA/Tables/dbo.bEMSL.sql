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
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMSLd    Script Date: 8/28/99 9:37:21 AM ******/
   CREATE   trigger [dbo].[btEMSLd] on [dbo].[bEMSL] for DELETE as
   

declare @errmsg varchar(255), @validcnt int 
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects delete in bEMSL (EM Maint Links) if  the following error condition exists:
    *
    *		None - Created to show that no conditions are necessary.
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Maint Links!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMSLi    Script Date: 8/28/99 9:37:21 AM ******/
   CREATE   trigger [dbo].[btEMSLi] on [dbo].[bEMSL] for INSERT as
   

declare @errmsg varchar(255), @numrows int,	@validcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects insertion in bEMSL (EM Std Maint Links) if the following error condition exists:
    *
    *		Invalid EMCo vs bEMCO
    *		Invalid Equipment vs bEMEM
    *		Invalid StdMaintGroup vs bEMSH by EMCo, Equipment and StdMaintGroup
    *		Equipment in bEMSH for StdMaintGroup = Equipment by EMCo, Equipment and StdMaintGroup
    *		Equipment in bEMSH for LinkedMaintGrp = Equipment by EMCo, Equipment and
    *			LinkedMaintGrp
    *
    */----------------------------------------------------------------
   
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
   
   /* Validate LinkedMaintGrp. */
   select @validcnt = count(*) from bEMSH e, inserted i where e.EMCo = i.EMCo and e.Equipment = i.Equipment
   	and e.StdMaintGroup=i.LinkedMaintGrp
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid LinkedMaintGrp'
   	goto error
   	end
   
   /* Validate Equipment for StdMaintGroup = Equipment. */
   select @validcnt = count(*) from bEMSH e, inserted i where e.EMCo = i.EMCo and e.Equipment=i.Equipment
   	and e.StdMaintGroup=i.StdMaintGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid StdMaintGroup - not for same Equip as in bEMSH'
   	goto error
   	end
   
   /* Validate Equipment for LinkedMaintGroup = Equipment. */
   select @validcnt = count(*) from bEMSH e, inserted i where e.EMCo = i.EMCo and e.Equipment=i.Equipment
   	and e.StdMaintGroup=i.LinkedMaintGrp
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid LinkedMaintGrp - not for same Equip as in bEMSH'
   	goto error
   	end
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Std Maint Link!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



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
*
*	This trigger rejects update in bEMSL (EM Std Maint Links) if  the following error condition exists:
*
*		Change in key fields (EMCo, Equipment, StdMaintGroup or LinkeMaintGrp)
*
*/----------------------------------------------------------------
   
select @numrows = @@rowcount, @changeinprogress ='N'

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
