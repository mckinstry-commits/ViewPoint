CREATE TABLE [dbo].[bEMWH]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[WorkOrder] [dbo].[bWO] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[Shop] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[InvLoc] [dbo].[bLoc] NULL,
[Mechanic] [dbo].[bEmployee] NULL,
[DateCreated] [dbo].[bDate] NOT NULL,
[DateDue] [dbo].[bDate] NULL,
[DateSched] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[INCo] [dbo].[bCompany] NULL,
[PRCo] [dbo].[bCompany] NULL,
[AutoInitSessionID] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ShopGroup] [dbo].[bGroup] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Complete] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMWH_Complete] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMWH] ON [dbo].[bEMWH] ([EMCo], [WorkOrder]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMWH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    trigger [dbo].[btEMWHd] on [dbo].[bEMWH] for DELETE as
/*********************************************************************
*	CREATED BY: JM 5/19/99
*	MODIFIED By : TV 9/8/03 22231 needs to check for cost detail before delete.
*			TV 02/11/04 - 23061 added isnulls
*			TRL 12/16/08 - 131453  update join statements
*	This trigger rejects delete in bEMWH (EM Work Order Header) if  the following error condition exists:
*
*	Entry exists in bEMWI - EM Work Order Items by EMCo
*
********************************************************************/

declare @numrows int,@errmsg varchar(255)
   
select  @numrows = @@rowcount 

if @numrows = 0 
begin
	return 
end

set nocount on
   
--Check bEMWI. 
if exists(select * from deleted d with(nolock) Inner join bEMWI e on d.EMCo = e.EMCo and d.WorkOrder=e.WorkOrder)
begin
	select @errmsg = 'Entries exist in bEMWI with this EMCo/WorkOrder'
   	goto error
end
   
--Check EMCD for costs.
if exists(select * from deleted d with(nolock) inner join bEMCD e on d.EMCo = e.EMCo and d.WorkOrder=e.WorkOrder) 
begin
   	select @errmsg = 'Cost detail records exist in bEMCD with this EMCo/WorkOrder'
   	goto error
end
   
return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Work Order!'
    RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         trigger [dbo].[btEMWHi] on [dbo].[bEMWH] for INSERT as


/*-----------------------------------------------------------------
*	CREATED BY: JM 5/19/99
*	MODIFIED By :  JM 6/11/99 - Added conditions for Shop, InvLoc and Mechanic to only validate if
*		inserted value is not null (these cols are nullable in EMWH).
*       RM 12/03/01 - Added Shop Group to validation
*       TV 1/16/04 23512- Need to insert PRCo into EMWH (back up to the front end insert) 
*		TV 02/11/04 - 23061 added isnulls
*		TRL 04/28/08 - 126052 fixed Inv Loc validation
*		TRL 12/16/08 - 131453 fixed PR Co and Employee validation and update join statements
*		TRL 01/14/08 - 130714 fixed invalud select statement
*
*	     This trigger rejects insertion in bEMWH (EM Work Order Header) if the following error condition exists:
*
*		Invalid EMCo vs bEMCO
*		Invalid Equipment vs bEMEM by EMCo
*		Invalid Shop vs bEMSX
*		Invalid InvLoc vs bINLM by bEMCO.INCo
*		Invalid Mechanic vs bPREH by bEMCO.PRCo
*
*/----------------------------------------------------------------
   
declare @inco int, @invloc varchar(10),@mechanic bEmployee, @prco bCompany, 
@shop varchar(20),@shopgroup bGroup, @numrows int, @errmsg varchar(255)
   
select @numrows = @@rowcount
 
if @numrows = 0 
begin
	return
end
   
set nocount on

/* Validate EMCo. */
If not exists(select e.EMCo from bEMCO e with(nolock) Inner Join  inserted i on e.EMCo = i.EMCo)
begin
   	select @errmsg = 'Invalid EMCo'
   	goto error
end

/* Validate Equipment. */
If not exists (select e.Equipment from bEMEM e with(nolock) Inner Join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment)
begin
   	select @errmsg = 'Invalid Equipment'
   	goto error
end
   
/* Validate ShopGroup/Shop. */
select @shop = Shop,@shopgroup = ShopGroup from inserted
if @shop is not null
begin
	If @shopgroup is not null
	begin
		/*130714*/
		if not exists (select h.ShopGroup From bHQCO h with(nolock) inner join inserted i on i.EMCo=h.HQCo and i.ShopGroup=h.ShopGroup)
		begin
	   		select @errmsg = 'Invalid Shop for this company.'
   			goto error
		end
	end
   	If not exists(select e.Shop from bEMSX e with(nolock) inner Join inserted i on e.Shop = i.Shop and e.ShopGroup = i.ShopGroup)
   	begin
   		select @errmsg = 'Invalid Shop for this company.'
   		goto error
   end
end
   
Select @inco=INCo, @invloc=InvLoc from inserted
/* Validate INCo. */
--if @invloc is not null
If @inco is not null
begin
	if not exists (select c.INCo from bINCO c with(nolock)Inner join inserted i on i.INCo = c.INCo)
	begin
		select @errmsg = 'Invalid IN Company'
   		goto error
	end
end

If IsNull(@invloc,'')<> ''
begin
	--Revalidate IN Co
 	if not exists (select c.INCo from bINCO c with(nolock)Inner join inserted i on i.INCo = c.INCo)
	begin
		select @errmsg = 'Invalid IN Company'
   		goto error
   	end
	--Validate Inv Loc
	if not exists (select x.Loc from bINLM x with(nolock)Inner join inserted i on x.INCo = i.INCo and x.Loc = i.InvLoc)
	begin
		select @errmsg = 'Invalid Inv Loc'
   		goto error
   	end
end
   
/*Validate PRCo and Mechanic*/   
select @mechanic = Mechanic , @prco=PRCo from inserted
if @prco is not null
begin
	If not exists (select p.PRCo from bPRCO p with(nolock) inner join inserted i on p.PRCo= i.PRCo)
   	begin
   		select @errmsg = 'Invalid PR Co: ' + convert(varchar(3),@prco)
   		goto error
   	end	
end

if @mechanic is not null 
begin
	--Re Validate PR Co
	If not exists (select p.PRCo from bPRCO p with(nolock) inner join inserted i on p.PRCo= i.PRCo)
   	begin
   		select @errmsg = 'Invalid PR Co: ' + convert(varchar(3),@prco)
   		goto error
   	end	
	--Validate Employee
	If not exists (select p.Employee from bPREH p with(nolock) inner Join inserted i on p.Employee = i.Mechanic and p.PRCo= i.PRCo)
   	begin
   		select @errmsg =  'Invalid Mechanic for PR Company: ' + convert(varchar(3),@prco) 
   		goto error
   	end	
end

return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Work Order Header!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     trigger [dbo].[btEMWHu] on [dbo].[bEMWH] for UPDATE as
/*-----------------------------------------------------------------
*	CREATED BY: JM 5/19/99
*	MODIFIED By :  JM 6/11/99 - Added conditions for Shop, InvLoc and Mechanic to only validate if
*			inserted value is not null (these cols are nullable in EMWH).
*		JM 4/4/01 - Ref Issue 12928: Added condition to block change in Equipment if
*			WOItems exist for this WorkOrder.
*		RM 12/03/01 - Added ShopGroup to Validation
*    	TV 02/11/04 - 23061 added isnulls
*		TRL 03/24/08	-- Add PRCo validation
*		TRL 09/02/08 -- Issue 126196 add code to allow Equipment to change if
*			the EM Equipment code is being changed
*		TRL 12/16/08 - 131453 fixed PR Co and Employee validation and update join statements
*
*	This trigger rejects update in bEMWH (EM Work Order Header) if  the following error condition exists:
*
*		Change in key fields (EMCo WorkOrder)
*		Invalid Equipment vs bEMEM
*		Invalid Shop vs bEMSX
*		Invalid InvLoc vs bINLM by bEMCO.INCo
*		Invalid Mechanic vs bPREH by bEMCO.PRCo
*		Change in Equipment if WOItems exist (Ref Issue 12928)
*
*/----------------------------------------------------------------
declare  @inco bCompany, @invloc varchar(10), @prco bCompany ,@mechanic bEmployee,
@shop varchar(20), @shopgroup bGroup, @validcnt int,@changeinprogress bYN,
@errmsg varchar(255), @numrows int
   
select @numrows = @@rowcount

if @numrows = 0 
begin
	return 
end
   
set nocount on

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
   	
/* Issue 126196 Check to see if equipment code is being changed.
Select Where EMEM.LastUsedEquipmentCode = EMWH.Equipment*/
select @changeinprogress=IsNull(ChangeInProgress,'N')
from bEMEM e with(nolock)  inner join inserted i on e.EMCo = i.EMCo and e.LastUsedEquipmentCode = i.Equipment
and e.ChangeInProgress = 'Y'
If @@rowcount >=1 
begin
	select @errmsg = 'Cannot change Equipment WorkOrder, Equipment Code change in progress'
	goto error
end

/* Validate Equipment. */
if update(Equipment)
BEGIN	
	--Issue 126196 Only run code if Equipment Code is not being changed
	If @changeinprogress = 'N' 
	begin
		/* Now do std validation on Equipment. */
   		If not exists (select e.Equipment from bEMEM e with(nolock) inner join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment)
		begin
   			select @errmsg = 'Invalid Equipment'
   			goto error
   		end
		/* Do not allow update to Equipment if WOItems exist. */
   		if (select e.Equipment from bEMWI e with(nolock)
				inner join inserted i on e.EMCo = i.EMCo and e.WorkOrder = i.WorkOrder)> 0
   		begin
   			select @errmsg = 'Cannot change Equipment when WOItems exist'
   			goto error
   		end
   	end
END
   
/* Validate ShopGroup/Shop. */
select @shop = Shop,@shopgroup = ShopGroup from inserted
if @shop is not null
begin
	If @shopgroup is not null
	begin
		if not exists (select h.ShopGroup From bHQCO h with(nolock) inner join inserted i on i.EMCo=h.HQCo and i.ShopGroup=h.ShopGroup)
		begin
	   		select @errmsg = 'Invalid Shop for this company.'
   			goto error
		end
	end
   	If not exists(select e.Shop from bEMSX e with(nolock) inner Join inserted i on e.Shop = i.Shop and e.ShopGroup = i.ShopGroup)
   	begin
   		select @errmsg = 'Invalid Shop for this company.'
   		goto error
   end
end

--Validate IN Company
If update (INCo)
begin
	select @inco=INCo, @invloc = InvLoc from inserted
	if @inco is not null
	begin
		if not exists (select c.INCo from bINCO c with(nolock) Inner join inserted i on i.INCo = c.INCo)
		begin
			select @errmsg = 'Invalid IN Company'
   			goto error
   		end
		if IsNull(@invloc,'') <> ''
   		begin
   			If not exists (select x.Loc from bINLM x with(nolock) inner join inserted i on x.INCo=i.INCo and x.Loc=i.InvLoc)
   			begin
   				select @errmsg = 'Invalid InvLoc'
   				goto error
   			end
   		end	
	end
end
   	
/* Validate InvLoc. */
if update(InvLoc)
begin
	select @inco=INCo, @invloc = InvLoc from inserted
	if IsNull(@invloc,'') <> ''
	begin
		--Validate IN Co
		if not exists (select c.INCo from bINCO c with(nolock) Inner join inserted i on i.INCo = c.INCo)
		begin
			select @errmsg = 'Invalid IN Company'
   			goto error
   		end
		--Validae Inv Location
   		If not exists (select x.Loc from bINLM x with(nolock) inner join inserted i on x.INCo=i.INCo and x.Loc=i.InvLoc)
   		begin
   			select @errmsg = 'Invalid InvLoc'
   			goto error
   		end
   	end	
end
   
/* Validate Mechanic. */
-- Issue 27172
if update(PRCo)
BEGIN
	select @prco=PRCo,@mechanic = Mechanic from inserted
	--Validate PR Company
   	if @prco is not null
   	begin
   		If not exists (select p.PRCo from bPRCO p with(nolock) inner join inserted i on p.PRCo= i.PRCo)
		begin
   			select @errmsg = 'Invalid PR Co: ' + convert(varchar(3),@prco)
   			goto error
   		end	
   	end
	--Validate Employee if column has a value
	   	if @mechanic is not null 
   	begin
   		If not exists (select p.Employee from bPREH p with(nolock) inner join inserted i on p.Employee = i.Mechanic and p.PRCo= i.PRCo)
		begin
   			select @errmsg = 'Invalid Mechanic for PR Company: ' + convert(varchar(3),@prco)
   			goto error
   		end	
   	end
END   		

/* Validate Mechanic. */
if update(Mechanic)
begin
	select @prco=PRCo,@mechanic = Mechanic from inserted
   	if @mechanic is not null
	begin
		--Validate PR Co
		If not exists (select p.PRCo from bPRCO p with(nolock) inner join inserted i on p.PRCo= i.PRCo)
		begin
   			select @errmsg = 'Invalid PR Co: ' + convert(varchar(3),@prco)
   			goto error
   		end	
		--Validate Employee
   		If not exists (select p.Employee from bPREH p with(nolock) inner join inserted i on p.Employee = i.Mechanic)
   		begin
   			select @errmsg = 'Invalid Mechanic for PR Company: ' + convert(varchar(3),@prco)
   			goto error
   		end	
   	end
end

return
   
error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Work Order Header!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   

GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMWH].[Complete]'
GO
