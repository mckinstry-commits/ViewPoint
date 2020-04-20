SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE           procedure [dbo].[vspEMWOInitbySMGItem]
/*******************************************************************
* CREATED: TRL Issue 132439
* LAST MODIFIED:	 TRL Issue 138227 10/26/10 change AttachToEquip to CompOfEquip
*
* USAGE: Called by EMWOInit form to initalize a Work Order for a passed
*StdMaintGroup based on whether any items for the SMG are currently
*due.
*
* INPUT PARAMS:
*	@emco			To bEMWH.EMCo - Controlling EM Company.
*	@workorder		To bEMWH.WorkOrder - EMWH.WorkOrder to initialize.
*	@autoinitsessionid 
*	@passedequipment	To bEMWH.Equipment - for which Items/Parts are
*				to be copied into EMWI/EMWP.
*	@passedsmg		EMSH.StdMaintGroup whose items and parts
*				in EMSI/EMSP are to be copied into EMWI/EMWP.
*	@passedsmgitem
*	@overrideshop			To bEMWH.Shop - If null, use EMEM.Shop.
*	@inco			To bEMWH.INCo - Can be null
*	@invloc			To bEMWH.InvLoc - Can be null.
*	@mechanic		To bEMWH.Mechanic - Can be null.
*	@datecreated		To bEMWH.DateCreated - Cannot be null. Also
*				used in SMI selection process as WODate.
*	@datedue		To bEMWH.DateDue - Can be null.
*	@datesched		To bEMWH.DateSched - Can be null.
*	@repaircode		To bEMWI.RepairCode - Can be null.
*
* OUTPUT PARAMS:
*	@rcode		Return code; 0 = success and record added
*				     1 = code failure
*				     2 = smg not initialized
*
*	@errmsg		Error message; temp copied if success,
*			error message if failure
********************************************************************/
(@emco bCompany = null,
@workorder bWO = null,
@autoinitsessionid varchar(30) = null,

@passedequipment bEquip = null,
@passedcomponent bEquip = null,
@passedsmg varchar(10) = null,
@passedsmgitem bItem = null,

@shop varchar(20) = null,
@inco bCompany = null,
@invloc bLoc = null,
@prco bCompany = null,
@mechanic bEmployee = null,
@datecreated bDate = null,
@datedue bDate = null,
@datesched bDate = null,
@repaircode varchar(10) = null,


@errmsg varchar(255) output)
       
as
       
set nocount on

/* declare locals, listed in order of used*/
declare @rcode int,@subrcode int,

@emgroup bGroup,
@wobeginpartstatus varchar(10),
@wobeginstat varchar(10),
@emcoprco  bCompany ,
@shopgroup bGroup,

@initprco bCompany,


@componenttypecode varchar(10)

--@notes varchar(Max),
--@TotalStdMaintItems int,
--@WOCreated int,
-- @xx int
       
select @rcode = 0, @subrcode=0--, @woalreadycreated ='N',@TotalStdMaintItems =0,@WOCreated =0

/*START:   verify required parameters passed */
if @emco is null
begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
    goto vspexit
end
if IsNull(@workorder,'')=''
begin
	select @errmsg = 'Missing Beginning Work Order!', @rcode = 1
    goto vspexit
end
if IsNull(@passedequipment,'')=''
begin
	select @errmsg = 'Missing Equipment!', @rcode = 1
    goto vspexit
end
if IsNull(@passedsmg,'')=''
begin
	select @errmsg = 'Missing Std Maint Group!', @rcode = 1
    goto vspexit
end
if @passedsmgitem is null
begin
	select @errmsg = 'Missing Std Maint Item!', @rcode = 1
    goto vspexit
end
if IsNull(@datecreated,'')=''
begin
	select @errmsg = 'Missing Date Created!', @rcode = 1
    goto vspexit
end
/*END:   verify required parameters passed */
    
/* Get EMGroup, WOBeginStatus, WOBeginPartStatus PRCo from bEMCO */
/* Get ShopGroup from bHQCO for @emco */
select @emgroup = EMCO.EMGroup, @wobeginstat = WOBeginStat, @wobeginpartstatus = WOBeginPartStatus, 
@emcoprco = PRCo, @shopgroup = HQCO.ShopGroup
from dbo.EMCO with(nolock) 
Inner Join dbo.HQCO with(nolock)on EMCO.EMCo=HQCO.HQCo
where EMCo = @emco

/* START:   Verify above values pulled from bEMCO (RepairType is nullable in bEMWI). */
if @emgroup is null --needed as param in several other calls
begin
	select @errmsg = 'Missing EM Group in EM Company file!', @rcode = 1
    goto vspexit
end
if IsNull(@wobeginstat,'')='' --cannot be null in bEMWI
begin
	select @errmsg = 'Missing Work Order Begin Status in EM Company file!', @rcode = 1
    goto vspexit
end
if IsNull(@wobeginpartstatus,'')='' --cannot be null in bEMWP
begin
	select @errmsg = 'Missing Work Order Begin Parts Status in EM Company file!', @rcode = 1
    goto vspexit
end
/* END:   Verify above values pulled from bEMCO (RepairType is nullable in bEMWI). */

/*START:  Validate  Parameter Inputs */
/* Equipment */
if  isnull(@passedcomponent,'') <> ''
begin 
	--Validatie is Component Attached to Equipment
	if not exists (select top 1 1from dbo.EMEM with(nolock) 
		where EMCo = @emco and Equipment = @passedequipment	and EMEM.Type = 'E')
	begin
		select @errmsg = 'Invalid Equipment: '+@passedequipment, @rcode = 1
		goto vspexit	
	end
end

/* Component */
if  isnull(@passedcomponent,'') <> ''
begin 
	--Validatie is Component Attached to Equipment
	if not exists (select top 1 1 from dbo.EMEM with(nolock) 
		where EMCo = @emco and Equipment = @passedcomponent and CompOfEquip = @passedequipment
		and EMEM.Type = 'C')
	begin
		select @errmsg = 'Component: '+@passedcomponent +' not attached to Equipment:  '+@passedequipment, @rcode = 1
		goto vspexit	
	end
	--Get Component Type Code
	select @componenttypecode = IsNull(ComponentTypeCode,'')
	from dbo.EMEM with(nolock) 
	where EMCo = @emco and Equipment = @passedcomponent and CompOfEquip = @passedequipment
	and EMEM.Type = 'C'
END

--Std Maint Groups
if not exists (select top 1 1 from dbo.EMSH with(nolock)
Where EMCo=@emco and StdMaintGroup = @passedsmg 
and Equipment = case when IsNull(@passedcomponent,'')='' then @passedequipment else @passedcomponent end)
If @@rowcount = 0
begin
	select @errmsg = 'Invalid Std Maint Group.', @rcode = 1
	goto vspexit
end
--Std Maint Group Item
if not exists (select top 1 1 from dbo.EMSI with(nolock)
Where EMCo=@emco and StdMaintGroup = @passedsmg  and StdMaintItem=@passedsmgitem
and Equipment = case when IsNull(@passedcomponent,'')='' then @passedequipment else @passedcomponent end)
If @@rowcount = 0
begin
	select @errmsg = 'Invalid Std Maint Item.', @rcode = 1
	goto vspexit
end
/*END: Validate Parameter Input */

/******* Validate and Create WO Header ************/
If not exists(select top 1 1  from dbo.EMWH with(nolock)
	where EMCo = @emco and WorkOrder = @workorder and AutoInitSessionID = @autoinitsessionid and Equipment = @passedequipment )
begin
	--Check to see if passed in work order exists, if not add to EMWH
	If  exists(select top 1 1  from dbo.EMWH with(nolock)
		where EMCo = @emco and WorkOrder = @workorder and AutoInitSessionID <> @autoinitsessionid and Equipment <> @passedequipment )
	begin
		select @errmsg = 'Work Order Already Exists.' + IsNull(@errmsg,'') , @rcode = 1
		goto vspexit
		
	end
	/* Create WO (EMWH) , Select from EMSH to Insert Notes into EMWH*/
	insert dbo.EMWH (EMCo, WorkOrder, Equipment, Shop, Description,  INCo, InvLoc,PRCo,Mechanic, 
	DateCreated, DateDue, DateSched, Notes, ShopGroup, AutoInitSessionID)
	select @emco, @workorder,@passedequipment, @shop,'Auto-Init WO - ' + DateName(mm,getdate()) +  ' ' + DateName(Day,getdate())+', '+ DateName(YEAR,getdate()),
	@inco,  @invloc,IsNull(@prco,@emcoprco), @mechanic, 
	@datecreated, @datedue, @datesched, Notes, @shopgroup, @autoinitsessionid
	from dbo.EMSH with(nolock)
	where EMCo=@emco and StdMaintGroup=@passedsmg 
	and Equipment =  case when IsNull(@passedcomponent,'') = '' then @passedequipment else @passedcomponent end 
	if @@error<> 0
	begin
		If IsNull(@passedcomponent,'')=''
		begin
			select @errmsg ='Error creating Work Order for Equipment:' + @passedequipment ,@rcode = 2
			goto vspexit
		end	
	else
		begin
			select @errmsg ='Error creating Work Order for Equipment:' + @passedequipment + ' with Component: ' + @passedcomponent,@rcode = 2
			goto vspexit
		end	
	end
end

select @initprco = isnull(@prco,@emcoprco)
--If on an equipment std maintenance item on open work order, skip item 
If isnull(@passedcomponent,'') = ''
	begin
		--Check to see if Equipment's Std Maint Item "already exists on" or "recently added" to an Open Work Order 
		If  (select top 1 1 from dbo.EMSI i with(nolock)  
			inner Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Equipment=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
			inner Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
			where w.EMCo = @emco and w.StdMaintGroup = @passedsmg  and w.StdMaintItem=@passedsmgitem
			and w.Equipment = @passedequipment and IsNull(s.StatusType,'') <> 'F') >=1
		begin
			select @errmsg =  'Std Maint Item:  ' + convert(varchar,@passedsmgitem) + ' exists on one or more open work Orders',@rcode = 2
			goto vspexit
		end
		--Init Std Maint Item to Work Order
		exec @subrcode = dbo.bspEMWOInitItem @emco, @workorder,@passedequipment, 
		'','', @emgroup, @passedsmg, @passedsmgitem,
		@repaircode, @initprco,@mechanic, @datecreated, @datedue, @datesched, 
		@wobeginpartstatus, @wobeginstat, 'E',@inco, @invloc, @errmsg=@errmsg output
		if (select @subrcode) <> 0
		begin
			select @errmsg = 'Error adding Std Maint Item: ' + convert(varchar,@passedsmgitem) + ' - ' + @errmsg, @rcode = 2 
			goto vspexit
		end
	end
else 
	begin
		--Check to see if Component's Std Maint Item "already exists on" or "recently added" to an Open Work Order 
		If (select top 1 1 from dbo.EMSI i with(nolock)  
			inner Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Component=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
			inner Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
			where w.EMCo = @emco and w.StdMaintGroup = @passedsmg and w.StdMaintItem=@passedsmgitem  
			and w.Equipment = @passedequipment and w.Component = @passedcomponent	and w.Equipment = @passedequipment	
			and IsNull(s.StatusType,'') <> 'F') >=1
		begin
			select @errmsg = 'Std Maint Item:  ' + convert(varchar,@passedsmgitem) + ' exists on one or more open work Orders',@rcode = 2
			goto vspexit
		end
		--Initialize Std Maint Item to Work Oder
		exec @subrcode = dbo.bspEMWOInitItem @emco, @workorder, @passedequipment, 
		@componenttypecode,@passedcomponent, @emgroup, @passedsmg, @passedsmgitem,
		@repaircode, @initprco,@mechanic, @datecreated, @datedue, @datesched, 
		@wobeginpartstatus, @wobeginstat, 'C',@inco, @invloc, @errmsg=@errmsg output
		if  @subrcode <> 0
		begin
			select @errmsg = 'Error adding Std Maint Item: ' + convert(varchar,@passedsmgitem) + ' - ' + @errmsg, @rcode = 2 
			goto vspexit
		end
	end
vspexit:
	select @errmsg = isnull(@errmsg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspEMWOInitbySMGItem] TO [public]
GO
