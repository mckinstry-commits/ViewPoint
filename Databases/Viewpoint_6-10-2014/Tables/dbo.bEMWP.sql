CREATE TABLE [dbo].[bEMWP]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[WorkOrder] [dbo].[bWO] NOT NULL,
[WOItem] [smallint] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[PartsStatusCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[InvLoc] [dbo].[bLoc] NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[QtyNeeded] [dbo].[bUnits] NOT NULL,
[PSFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Required] [dbo].[bYN] NOT NULL,
[INCo] [dbo].[bCompany] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Seq] [int] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE    trigger [dbo].[btEMWPi] on [dbo].[bEMWP] for INSERT as


declare @errmsg varchar(255), @numrows int, @validcnt int, @matlvalid char(1), @subrcode int, 
   		@matlgroup bGroup, @material bMatl, @purchum bUM, @hqmatl bMatl, @nullcnt int, 
		@itemcnt int,@hqmatlcnt int,@equipmatlcnt int
     
/*-----------------------------------------------------------------
*	CREATED BY: JM 5/19/99
*	MODIFIED By : JM 6/28/2000 - Revised Material validation to comply with frmEMWOEdit (Issue 5280 rejection.)
*			JM 11/27/00 - Added missing @purchum output param to call to bspHQMatlVal
*			JM 3/21/01 - Changed validation of material to translate Material to bEMEP.HQMatl where
*				PartCode = Material. 
*			JM 4/2/01 - Corrected 3/21 change to validate Material vs either bEMEP (first) or bHQMT.
*			GF 10/01/2002 - Issue #18398 - changed validation for InvLoc using INCo from EMWP.
*			 TV 02/11/04 - 23061 added isnulls
*			TRL 10/16/07 - 125587 recode issue
*			TRL 01/14/09 - 130714 Fix Inv Validation Queries
*			TRL 10/13/09 - 135894 Change Part Code validation
*			TRL 02/17/09 - 135894 Removied Active flag from INCo and In Location validation
*			GF 05/05/2013 TFS-49039
*
*
*	This trigger rejects insertion in bEMWP (EM Work Order Parts) if the following error condition exists:
*
*		Invalid EMCo vs bEMCO
*		Invalid WorkOrder vs bEMWH by EMCo
*		Invalid WOItem vs bEMWI by EMCo/WorkOrder
*		Invalid MatlGroup vs bEMCo by HQCo
*		Invalid bEMEP.HQMatl by bEMEP.PartCode = i.PartCode by bspHQMatlVal if EMCO.MatlValid = 'Y'
*		Invalid Equipment vs bEMEM by EMCo
*		Invalid EMGroup vs bHQGP
*		Invald PartsStatusCode vs bEMPS by EMGroup
*		Invalid InvLocvs bINLM by bEMCO.INCo
*		Invalid UM vs bHQUM
*		Invalid PSFlag - not in (P,S)
*		Invalid Required - not in (Y,N)
*
*/----------------------------------------------------------------
     
select @numrows = @@rowcount

if @numrows = 0 return
     
set nocount on
     



/* Validate UM. */
select @validcnt = count(*) from dbo.bHQUM h with(nolock)
Inner Join inserted i on h.UM = i.UM
if @validcnt <> @numrows
begin
	select @errmsg = 'Invalid UM'
    goto error
end

--Validate PartCode or Material
/*135894*/
/* Get MatlValid flag in bEMCO. */
select @matlvalid = MatlValid from dbo.bEMCO e with(nolock) Inner Join Inserted i on e.EMCo = i.EMCo

--If not validating or requiring valid HQ Materials only validate records with IN Co and Inv Locations
if @matlvalid = 'Y'
begin
	--Count all records with no Inv Location.
	select @itemcnt=count(*)  from inserted where  isnull(InvLoc,'') =''
	
	--Count records From HQ Materials
	select @hqmatlcnt = count (*) from dbo.bHQMT h with(nolock) 
	Inner Join inserted i on h.MatlGroup = i.MatlGroup and h.Material = i.Material
	where isnull(i.InvLoc,'') = ''
	
	--Count records from EM Equipment Parts, exclude PartNo's that might be HQ Materials'
	select  @equipmatlcnt = count(*) from dbo.bEMEP e with(nolock)
	Inner Join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment and e.PartNo = i.Material
	left join dbo.bHQMT m on e.MatlGroup=m.MatlGroup and e.PartNo=m.Material
	where isnull(i.InvLoc,'') = '' and isnull(m.Material,'')=''
	
	if @itemcnt <> isnull(@hqmatlcnt,0) + isnull(@equipmatlcnt,0)
	begin
		select @errmsg='Invalid Part Code! '
    		goto error
	end
END
	
--Validate InCo,InvLoc and Material.  records with INCo and InvLocation must be valid.
if (select top 1 1 from inserted where INCo is not null and isnull(InvLoc ,'')<> '') >=1 
begin
	--Validate IN Company
	select @itemcnt=count(*)  from inserted where INCo is not null
	
	select @validcnt=count(*)  from dbo.bINCO c with(nolock) Inner Join inserted i on i.INCo = c.INCo
	if @itemcnt<>@validcnt
	begin
		select @errmsg = 'Invalid INCo!'
		goto error
	end

	--Validate Inv Loc
	select @itemcnt=count(*)  from inserted where INCo is not null and isnull(InvLoc,'') <>''
	select @validcnt=count(*)  from dbo.bINLM l with(nolock) Inner Join inserted i on i.INCo = l.INCo and i.InvLoc=l.Loc
	where i.INCo is not null and isnull(i.InvLoc,'') <>''
	If @itemcnt<>@validcnt 
	begin
		select @errmsg = 'Invalid Inv Loc!'
		goto error
	end

	--Validate IN Co, Inv Location an Material
	select @itemcnt=count(*)  from inserted where INCo is not null and isnull(InvLoc,'') <> ''
	select @validcnt=count(*)  from  dbo.bINMT m with(nolock) 
	Inner Join inserted i on i.INCo=m.INCo and i.InvLoc=m.Loc and i.MatlGroup=m.MatlGroup and i.Material=m.Material
	Inner join dbo.bHQMT h with(nolock)on h.MatlGroup = m.MatlGroup and h.Material = m.Material
	where i.INCo is not null and isnull(i.InvLoc,'') <> '' and isnull(i.Material,'') <> '' --and h.Active = 'Y' 135894
	
	If @itemcnt<>@validcnt 
	begin
		select @errmsg='Invalid INCo and Location Material!'
		goto error
	end
end

return
     
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Work Order Part!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

 CREATE  trigger [dbo].[btEMWPu] on [dbo].[bEMWP] for UPDATE as
    


declare @errmsg varchar(255), @numrows int, @validcnt int,@changeinprogress bYN
/*-----------------------------------------------------------------
*	CREATED BY: JM 5/19/99
*	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
*			TRL 09/02/08 -- Issue 126196 add code to allow Equipment to change if
*			the EM Equipment code is being changed
*			GF 05/05/2013 TFS-49039
*
*			
*	This trigger rejects update in bEMWP (EM Work Order Parts) if  the following error condition exists:
*
*		Change in key fields (EMCo, WorkOrder, WOItem, Material, MatlGroup)
*		Invalid Equipment vs bEMEM by EMCo
*		Invalid EMGroup vs bHQGP
*		Invald PartsStatusCode vs bEMPS by EMGroup
*		Invalid InvLocvs bINLM by bEMCO.INCo
*		Invalid UM vs bHQUM
*		Invalid PSFlag - not in (P,S)
*		Invalid Required - not in (Y,N)
*
*/----------------------------------------------------------------
   
select @numrows = @@rowcount
   
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

if update(Material)
begin
	select @errmsg = 'Cannot change Material'
	goto error
end

   
/* Validate Equipment. */
if update(Equipment)
begin
	/* Issue 126196 Check to see if equipment code is being changed.
	Select Where EMEM.LastUsedEquipmentCode = EMWH.Equipment*/
	select @changeinprogress=IsNull(ChangeInProgress,'N')
	from bEMEM e, inserted i where e.EMCo = i.EMCo and e.LastUsedEquipmentCode = i.Equipment
	and e.ChangeInProgress = 'Y'

end
   
   
   
/* Validate InvLoc. */
if update(InvLoc)
begin
	if (select InvLoc from inserted) is not null
    begin
		select @validcnt = count(*) from dbo.INLM x with(nolock), inserted i
    	where x.INCo = (select INCo from dbo.EMCO e with(nolock) where e.EMCo = i.EMCo)
    	and x.Loc = i.InvLoc
    	if @validcnt <> @numrows
    	begin
    		select @errmsg = 'Invalid InvLoc'
    		goto error
    	end
    end
end
   
/* Validate UM. */
if update(UM)
begin
	select @validcnt = count(*) from dbo.HQUM h with(nolock), inserted i
    where h.UM = i.UM
    if @validcnt <> @numrows
    begin
    	select @errmsg = 'Invalid UM'
    	goto error
    end
end
   
   
return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Work Order Part!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
  
 




GO
ALTER TABLE [dbo].[bEMWP] WITH NOCHECK ADD CONSTRAINT [CK_bEMWP_PSFlag] CHECK (([PSFlag]='S' OR [PSFlag]='P'))
GO
ALTER TABLE [dbo].[bEMWP] WITH NOCHECK ADD CONSTRAINT [CK_bEMWP_Required] CHECK (([Required]='N' OR [Required]='Y'))
GO
CREATE UNIQUE CLUSTERED INDEX [biEMWP] ON [dbo].[bEMWP] ([EMCo], [WorkOrder], [WOItem], [MatlGroup], [Material]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biEMWPSeq] ON [dbo].[bEMWP] ([EMCo], [WorkOrder], [WOItem], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMWP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMWP] WITH NOCHECK ADD CONSTRAINT [FK_bEMWP_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMWP] WITH NOCHECK ADD CONSTRAINT [FK_bEMWP_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bEMWP] WITH NOCHECK ADD CONSTRAINT [FK_bEMWP_bEMWH_WorkOrder] FOREIGN KEY ([EMCo], [WorkOrder]) REFERENCES [dbo].[bEMWH] ([EMCo], [WorkOrder])
GO
ALTER TABLE [dbo].[bEMWP] WITH NOCHECK ADD CONSTRAINT [FK_bEMWP_bEMWI_WOItem] FOREIGN KEY ([EMCo], [WorkOrder], [WOItem]) REFERENCES [dbo].[bEMWI] ([EMCo], [WorkOrder], [WOItem])
GO
ALTER TABLE [dbo].[bEMWP] WITH NOCHECK ADD CONSTRAINT [FK_bEMWP_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMWP] WITH NOCHECK ADD CONSTRAINT [FK_bEMWP_bEMPS_PartsStatusCode] FOREIGN KEY ([EMGroup], [PartsStatusCode]) REFERENCES [dbo].[bEMPS] ([EMGroup], [PartsStatusCode])
GO
ALTER TABLE [dbo].[bEMWP] NOCHECK CONSTRAINT [FK_bEMWP_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMWP] NOCHECK CONSTRAINT [FK_bEMWP_bEMEM_Equipment]
GO
ALTER TABLE [dbo].[bEMWP] NOCHECK CONSTRAINT [FK_bEMWP_bEMWH_WorkOrder]
GO
ALTER TABLE [dbo].[bEMWP] NOCHECK CONSTRAINT [FK_bEMWP_bEMWI_WOItem]
GO
ALTER TABLE [dbo].[bEMWP] NOCHECK CONSTRAINT [FK_bEMWP_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMWP] NOCHECK CONSTRAINT [FK_bEMWP_bEMPS_PartsStatusCode]
GO
