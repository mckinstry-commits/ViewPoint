CREATE TABLE [dbo].[bEMSP]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[StdMaintGroup] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[StdMaintItem] [dbo].[bItem] NOT NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[QtyNeeded] [dbo].[bUnits] NOT NULL,
[PSFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Required] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMSPd    Script Date: 8/28/99 9:37:21 AM ******/
   CREATE   trigger [dbo].[btEMSPd] on [dbo].[bEMSP] for DELETE as
   

declare @errmsg varchar(255), @validcnt int 
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects delete in bEMSP (EM Std Maint Parts) if  the following error condition exists:
    *
    *		None - Created to show that no conditions are necessary.
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   return
   
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Std Maint Parts!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMSPi    Script Date: 8/28/99 9:37:21 AM ******/
   CREATE     trigger [dbo].[btEMSPi] on [dbo].[bEMSP] for INSERT as
   

declare @errmsg varchar(255), @numrows int, @validcnt int, @matlvalid char(1),
   	@subrcode int, @matlgroup bGroup, @hqmatl bMatl, @purchum bUM
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By : JM 4/2/01 - Changed validation of material to be against either bEMEP or bHQMT.
    *				 TV 02/11/04 - 23061 added isnulls
    *	This trigger rejects insertion in bEMSP (EM Std Maint Parts) if the following error condition exists:
    *
    *		Invalid EMCo vs bEMCO
    *		Invalid Equipment vs bEMEM by EMCo/Equipment
    *		Invalid StdMaintGroup vs bEMSH by EMCo/Equipment/StdMaintGroup
    *		Invalid StdMaintItem vs bEMSI by EMCo/Equipment/StdMaintGroup/StdMaintItem
    *		Invalid MatlGroup vs bHQCO by EMCo
    *		Invalid Material vs bEMEP or bHQMT
    *		Invalid UM vs bHQUM
    *		Invalid PSFlag - not in (P,S)
    *		Invalid Required flag - not in (Y,N)
    *
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* Validate EMCo. */
   select @validcnt = count(*) from bEMCO e, inserted i
   where e.EMCo = i.EMCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid EMCo'
   	goto error
   	end
   
   /* Validate Equipment. */
   select @validcnt = count(*) from bEMEM e, inserted i
   where e.EMCo = i.EMCo and e.Equipment = i.Equipment
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Equipment'
   	goto error
   	end
   
   /* Validate StdMaintGroup. */
   select @validcnt = count(*) from bEMSH e, inserted i
   where e.EMCo = i.EMCo and e.Equipment = i.Equipment
   	and e.StdMaintGroup=i.StdMaintGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid StdMaintGroup'
   	goto error
   	end
   
   /* Validate StdMaintItem. */
   select @validcnt = count(*) from bEMSI e, inserted i
   where e.EMCo = i.EMCo and e.Equipment = i.Equipment
   	and e.StdMaintGroup=i.StdMaintGroup
   	and e.StdMaintItem=i.StdMaintItem
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid StdMaintItem'
   	goto error
   	end
   
   /* Validate MatlGroup. */
   select @validcnt = count(*) from bHQCO h, inserted i
   where h.HQCo = i.EMCo and h.MatlGroup = i.MatlGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg =  'Invalid MatlGroup'
   	goto error
   	end
   
   /* Validate Material. */
   /* See explanation for rejection to Issue 11586 for logic behind validation of bEMSP.Material. */
    /* Get MatlValid flag in bEMCO. */
    select @matlvalid = MatlValid from bEMCO e, Inserted i where e.EMCo = i.EMCo
   /* Try bEMEP first - if not valid there try HQMT. */
   select  @validcnt = count(*) from bEMEP e, inserted i where e.EMCo = i.EMCo and e.Equipment = i.Equipment and e.PartNo = i.Material
   if @validcnt <> 0
   	begin
   	/* If MatlValid = 'Y' validate i.Material vs bHQMT. */
   	if @matlvalid = 'Y'
   		begin
   		if @hqmatl is not null
   			begin
   			select  @hqmatl = HQMatl from bEMEP e, inserted i where e.EMCo = i.EMCo and e.Equipment = i.Equipment and e.PartNo = i.Material
   			exec @subrcode = bspHQMatlVal @matlgroup, @hqmatl, @purchum, @errmsg output
   			/* If valn failed, return normal error msg with null values to overwrite form inputs.  */
   			if @subrcode = 1
   				begin
   				select @errmsg='Equipment part invalid in HQMT!'
   				goto error
   				end
   			end
   		end
   	end
   else
   	/* Not in bEMEP so go against bHQMT. */
   	begin
   	select @validcnt = count(*) from bHQMT h, inserted i where h.MatlGroup = i.MatlGroup and h.Material = i.Material
   	if @validcnt = 0
   		begin
   		/* If MatlValid = 'Y' send error msg. */
   		if @matlvalid = 'Y'
   			begin
   			select @errmsg='Part Code invalid in HQMT!'
   			goto error
   			end
   		end
   	end
   
   /* Validate UM.. */
   select @validcnt = count(*) from bHQUM h, inserted i
   where h.UM = i.UM
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid UM'
   	goto error
   	end
   
   /* Validate PSFlag. */
   select @validcnt=count(*) from inserted i
   where i.PSFlag not in ('P', 'S')
   if @validcnt <>0
   	begin
   	select @errmsg = 'Invalid PSFlag - must be P or S'
   	goto error
   	end
   
   /* Validate Required. */
   select @validcnt=count(*) from inserted i
   where i.Required not in ('Y', 'N')
   if @validcnt <>0
   	begin
   	select @errmsg = 'Invalid Required - must be Y or N'
   	goto error
   	end
   
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Std Maint Part!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMSPu    Script Date: 8/28/99 9:37:21 AM ******/
   CREATE   trigger [dbo].[btEMSPu] on [dbo].[bEMSP] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: JM 5/19/99
    *	MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    *	This trigger rejects update in bEMSP (EM Std Maint Parts) if  the following error condition exists:
    *
    *		Change in key fields (EMCo, Equipment, StdMaintGroup, StdMaintItem or Material)
    *		Invalid UM vs bHQUM
    *		Invalid PSFlag - not in (P,S)
    *		Invalid Required - not in (Y,N)
    *
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
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
   	select @errmsg = 'Cannot change Equipment'
   	goto error
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
   if update(MatlGroup)
   	begin
   	select @errmsg = 'Cannot change MatlGroup'
   	goto error
   	end
   if update(Material)
   	begin
   	select @errmsg = 'Cannot change Material'
   	goto error
   	end
   
   /* Validate UM. */
   if update(UM)
   	begin
   	select @validcnt = count(*) from bHQUM h, inserted i
   	where h.UM = i.UM
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid UM'
   		goto error
   		end
   	end
   
   /* Validate PSFlag. */
   if update(PSFlag)
   	begin
   	select @validcnt=count(*) from inserted i
   	where i.PSFlag not in ('P', 'S')
   	if @validcnt <>0
   		begin
   		select @errmsg = 'Invalid PSFlag - must be P or S'
   		goto error
   		end
   	end
   
   /* Validate Required. */
   if update(Required)
   	begin
   	select @validcnt=count(*) from inserted i
   	where i.Required not in ('Y', 'N')
   
   	if @validcnt <>0
   		begin
   		select @errmsg = 'Invalid Required - must be Y or N'
   		goto error
   		end
   	end
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Std Maint Part!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMSP] ON [dbo].[bEMSP] ([EMCo], [Equipment], [StdMaintGroup], [StdMaintItem], [MatlGroup], [Material]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMSP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMSP].[Required]'
GO
