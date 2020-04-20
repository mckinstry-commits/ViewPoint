SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      procedure [dbo].[vspEMWOInitItems]
    /*******************************************************************
    * CREATED: 04/09/08 TRL
    * LAST MODIFIED: 06/23/08 TRL Modified for Issue 127255 fix
	*				08/01/08 TRL Issue 129273 changed alias when checking 
	*				for STd Maint Items on Open Work ORders
	*				03/17/09 TRL Issue 132697 add parameter
	*				GF 10/02/2010 issue #141031 changed to use date only function
	*
    * USAGE: Called by EMWOItemInit form to initalize a Work Order with
    *		items/parts from a source Std Maint Group. Calls
    *		bspEMWOInitItem to initialize the items/parts.
    *
	*
    * INPUT PARAMS:
    *	@emco		Controlling EM Company
    *	@workorder	EMWH.WorkOrder for which Items/Parts are to be
    *			copied into EMWI/EMWP
    *	@equipment	EMWH.Equipment for which Items/Parts are to be
    *			copied into EMWI/EMWP
    *	@stdmaintgroup	EMSH.StdMaintGroup whose items and parts
    *			in EMSI/EMSP are to be copied into EMWI/EMWP
    *	@defmechanic
    *	@defdatedue
    *	@defdatesched
    *	@componenttypecode
    *	@component
    *	@repaircode
    *
    * OUTPUT PARAMS:
    *	@itemstobeinitialized
    *	@itemstobeinitialized
    *	@groupstoinitialize
	*   @groupstoinitialized
    *	@rcode		Return code; 0 = success, 1 = failure
    *	@errmsg		Error message; # copied if success,
    *			error message if failure
    ********************************************************************/
(@emco bCompany = null,
@workorder bWO = null,
@equipment bEquip = null,
@stdmaintgroup varchar(10) = null,
@includelinkedmaintgroups varchar(1)=null,/*132697*/
@defprco bCompany = null,/*27172*/
@defmechanic bEmployee = null,
@defdatedue bDate = null,
@defdatesched bDate = null,
@componenttypecode varchar(10) = null,
@component bEquip = null,
@repaircode varchar(10) = null,
@groupsinitialized smallint = 0 output,
@itemsinitialized smallint = 0 output,
@errmsg varchar(255) output)
   
as
   
set nocount on
   
/* declare locals */
declare @rcode int,
@fixeddate smalldatetime,
@datecreated bDate,
@groupinitializedYN varchar(1),

/*EMCO*/
@emgroup bGroup,@wobeginpartstatus varchar(10),@wobeginstat varchar(10),
/*EMEM*/
@hourreading numeric(10,2),@replacedhourreading numeric(10,2),@odoreading numeric(10,2),
@replacedodoreading numeric(10,2),@fuelused numeric(12,3),@equiptype char(1),
/*EMSH*/
@intervaldays smallint,@fixeddatemonth varchar(2),@fixeddateday varchar(2),
@basis char(1),@interval int,@variance int,
/*Group*/
@opencursorgroup tinyint,@gEMCo bCompany,@gEquipment bEquip,@gStdMaintGroup varchar(10),
@prevStdMaintGroup varchar(10),
/*Item*/
@opencursoritem tinyint,@iEMCo bCompany,@iEquipment bEquip,@iStdMaintGroup varchar(10),
@iStdMaintItem int,@ilastdonedate smalldatetime,@ilastgallons numeric(12,3),@ilasthourmeter numeric(10,2),
@ilastodometer numeric(10,2)

select @rcode = 0,@groupinitializedYN = 'N',
@groupsinitialized = 0,@itemsinitialized = 0, @opencursorgroup = 0, @opencursoritem=0

----#141031
SET @datecreated = dbo.vfDateOnly() 

/* verify parameters passed */
if @emco is null
begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
    goto vspexit
end
if @workorder is null
begin
	select @errmsg = 'Missing Work Order!', @rcode = 1
    goto vspexit
end
if @equipment is null
begin
	select @errmsg = 'Missing Equipment!', @rcode = 1
	goto vspexit
end
if @stdmaintgroup is null
begin
	select @errmsg = 'Missing Std Maint Group!', @rcode = 1
 	goto vspexit
end
   
/* Get WOBeginStatus and WOBeginPartStatus from bEMCO */
/* Get EMGroup from bHQCO. */
select @wobeginstat = e.WOBeginStat,@wobeginpartstatus = e.WOBeginPartStatus, 
 @emgroup = h.EMGroup
from dbo.EMCO e with(nolock)
Inner Join dbo.HQCO h with(nolock)on h.HQCo=e.EMCo
where EMCo = @emco
if @wobeginstat is null --cannot be null in bEMWI
begin
	select @errmsg = 'Missing WO Begin Status in EM Company file!', @rcode = 1
    goto vspexit
end
if @wobeginpartstatus is null --cannot be null in bEMWP
begin
	select @errmsg = 'Missing WO Begin Parts Status in EM Company file!', @rcode = 1
	goto vspexit
end
if @emgroup is null --needed as param in several other calls
begin
	select @errmsg = 'Missing EM Group in EM Company file!', @rcode = 1
    goto vspexit
end
--127340
select @equiptype = EMEM.Type from dbo.EMEM with(nolock) where EMCo = @emco and Equipment = @equipment
if IsNull(@equiptype,'')=''
begin
	select @errmsg = 'Missing Equipment Type in bEMEM!', @rcode = 1
    goto vspexit
end

--Create a local table for the StdMaintGroups to be copied - to hold the final set of SMG
--consisting of the one passed in if it isnt already initialized plus any non-open linked
--SMG. This will include the bEMSI.StdMaintGroup for the passed WorkOrder/Equipment plus
--any StdMaintGroups linked to that StdMaintGroup in bEMSL. 
--select EMCo, Equipment, StdMaintGroup, Description, Basis, Interval, IntervalDays, Variance, FixedDateMonth,
--FixedDateDay, AutoDelete, Notes
--into #GroupsToInit from dbo.EMSH where 1=2
CREATE TABLE #GroupsToInit
(EMCo tinyint NOT NULL ,Equipment varchar(10) NULL,StdMaintGroup varchar (10),Description varchar (30) NULL,
Basis char (1),Interval int NULL, IntervalDays smallint NULL ,Variance int NULL,
FixedDateMonth tinyint NULL, FixedDateDay tinyint NULL, AutoDelete char(1) NULL, Notes text) 
 
--Also create a local table for Items to be copied from bEMSI
--to bEMWI. Use select into so we can retrieve the Notes
--column and any User Memo columns. 
select EMCo, Equipment, StdMaintGroup, StdMaintItem, EMGroup, CostCode, RepairType, InOutFlag,
Description, EstHrs, EstCost, LastHourMeter, LastOdometer, LastGallons, LastDoneDate, Notes
into #ItemsToInit from dbo.EMSI where 1=2

--Get Std Maint Groups to be initialized  
/*Add records to #GroupsToCopy table. First add the passed in StdMaintGroup.*/
insert into #GroupsToInit (EMCo, Equipment, StdMaintGroup, Description, Basis, Interval,
IntervalDays, Variance, FixedDateMonth, FixedDateDay, AutoDelete, Notes)
select EMCo, Equip = case when IsNull(@component,'') = '' then @equipment else @component end,
StdMaintGroup, Description, Basis, Interval,IntervalDays,Variance, 
FixedDateMonth, FixedDateDay, AutoDelete, Notes
from dbo.EMSH with(nolock)where EMCo = @emco and StdMaintGroup = @stdmaintgroup
and Equipment = case  when IsNull(@component,'') = '' then @equipment else @component end

/*132697*/
If IsNull(@includelinkedmaintgroups,'N') = 'Y'
begin
	--Add Linked StdMaintGroups form the StdMaintGroup passed in. 
	insert into #GroupsToInit (EMCo, Equipment, StdMaintGroup, Description, Basis, Interval,
	IntervalDays, Variance, FixedDateMonth, FixedDateDay, AutoDelete, Notes)
	select h.EMCo, Equip = case when IsNull(@component,'') = '' then @equipment else @component end,
	h.StdMaintGroup, h.Description, h.Basis,h.Interval, h.IntervalDays, h.Variance,
	h.FixedDateMonth,h.FixedDateDay, h.AutoDelete, h.Notes
	from dbo.EMSH h with(nolock)
	Inner Join dbo.EMSL l with(nolock) on h.EMCo=l.EMCo and h.Equipment=l.Equipment and h.StdMaintGroup=l.LinkedMaintGrp
	where l.EMCo=@emco and l.StdMaintGroup = @stdmaintgroup
	and l.Equipment = case  when IsNull(@component,'') = '' then @equipment else @component end
End

--Exit procedure if No Std Maintn Groups are found.
if (select count(*) from #GroupsToInit) = 0 
begin
	select @errmsg = 'No Std Maint Groups to initialize',@rcode = 1
	goto vspexit
end

/* Get Std Maint Items that are not on open Work Orders
Link with #GroupsToInit, no need to link back to EMSI or EMSH with parameters
Select Std MaintItems that are not on Open Works
NOTE: TO FIND WHETHER AN SMG IS ALREADY INITIALIZED YOU NEED TO CHECK WHETHER THERE ARE ANY
RECORDS IN bEMWI WITH A STATUSCODE DEFINED AS 'FINAL' IN bEMWS.*/
--1. Equipment on EMWI Equipment to EMSI Equipment
--2. Component on EMWI Component to EMSI Equipment
If IsNull(@component,'') = ''
	begin
		insert into #ItemsToInit (EMCo, Equipment, StdMaintGroup, StdMaintItem, EMGroup,
		CostCode, RepairType, InOutFlag, Description, EstHrs, EstCost, LastHourMeter,
		LastOdometer, LastGallons, LastDoneDate, Notes)
		select i.EMCo, i.Equipment, i.StdMaintGroup, i.StdMaintItem, i.EMGroup,
		i.CostCode, i.RepairType, i.InOutFlag, i.Description, i.EstHrs, i.EstCost, i.LastHourMeter,
		i.LastOdometer, i.LastGallons, i.LastDoneDate, i.Notes
		from dbo.EMSI i with(nolock)
		/*132697*/	
		Inner Join #GroupsToInit w on w.EMCo=i.EMCo and w.Equipment=i.Equipment and w.StdMaintGroup=i.StdMaintGroup
		--Left Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Equipment=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
		--Left Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
		--where i.EMCo=@emco and i.StdMaintGroup = @stdmaintgroup and i.Equipment = @equipment
	end
else
	begin
		insert into #ItemsToInit (EMCo, Equipment, StdMaintGroup, StdMaintItem, EMGroup,
		CostCode, RepairType, InOutFlag, Description, EstHrs, EstCost, LastHourMeter,
		LastOdometer, LastGallons, LastDoneDate, Notes)
		select i.EMCo, i.Equipment, i.StdMaintGroup, i.StdMaintItem, i.EMGroup,
		i.CostCode, i.RepairType, i.InOutFlag, i.Description, i.EstHrs, i.EstCost, i.LastHourMeter,
		i.LastOdometer, i.LastGallons, i.LastDoneDate, i.Notes
		from dbo.EMSI i with(nolock)
		/*132697*/
		Inner Join #GroupsToInit w on w.EMCo=i.EMCo and w.Component=i.Equipment and w.StdMaintGroup=i.StdMaintGroup
		/*Left Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Component=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
		Left Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
		where   i.EMCo=@emco and i.StdMaintGroup = @stdmaintgroup  and i.Equipment = @component*/
	end

--Exit if No Std Maint Items are selected
If (select IsNull(count(*),0) from #ItemsToInit) = 0
begin
	select @errmsg = 'No Std Maint Items to initialize',@rcode = 1
	goto vspexit
end

--Declare and open cursor to run through Groups To Initialize
declare cGroupsToInit cursor local fast_forward for
select EMCo,Equipment,StdMaintGroup from #GroupsToInit
--open cursor
open cGroupsToInit
select @opencursorgroup = 1

goto NextStdMaintGroup
NextStdMaintGroup:
	fetch next from cGroupsToInit into @gEMCo,@gEquipment,@gStdMaintGroup
	if (@@fetch_status <> 0)
	begin
		goto EndNextStdMaintGroup
	end
	
	select  @groupinitializedYN = 'N'	
	
	/* Get equipment info needed for selection comparisons. */
    select @hourreading = isnull(HourReading,0),@replacedhourreading = isnull(ReplacedHourReading,0),
    @odoreading = isnull(OdoReading,0), @replacedodoreading = isnull(ReplacedOdoReading,0), @fuelused = isnull(FuelUsed,0),
	@equiptype = EMEM.Type, @componenttypecode = IsNull(ComponentTypeCode,'')
	from dbo.EMEM with(nolock) 
	where EMCo = @gEMCo and Equipment =  @gEquipment 

	/* Get Std MaintGroup info needed for selection comparisons from #GroupsToInit. */
    select @intervaldays = IntervalDays, @fixeddatemonth = convert(varchar(2),FixedDateMonth), 
	@fixeddateday = convert(varchar(2),FixedDateDay),
	@basis = Basis, @interval = Interval, @variance = isnull(Variance,0)
    from #GroupsToInit 
	where EMCo = @gEMCo and StdMaintGroup = @gStdMaintGroup and  Equipment = @gEquipment

	--Declare and open cursor to rund through Items to Initialize
	declare cItemsToInit cursor local fast_forward for

	select EMCo,Equipment,StdMaintGroup,StdMaintItem,LastDoneDate,LastGallons,LastHourMeter,LastOdometer 
	from #ItemsToInit
	Where EMCo = @gEMCo and StdMaintGroup = @gStdMaintGroup and  Equipment = @gEquipment

	--open cursor
	open cItemsToInit
	select @opencursoritem = 1

	goto NextStdMaintItem
	NextStdMaintItem:
		fetch next from cItemsToInit into @iEMCo,@iEquipment,@iStdMaintGroup,@iStdMaintItem,
		@ilastdonedate,@ilastgallons,@ilasthourmeter,@ilastodometer

		if (@@fetch_status <> 0)
		begin
			 goto EndNextStdMaintItem
		end
		--Issue 127255 06/23/08 
		--If on an equipment std maintenance item on open work order, skip item 
		If @equiptype = 'E'
		begin
			--Issue 129273
			If exists (select top 1 1 from dbo.EMSI i with(nolock)  
				Inner Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Equipment=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
				Inner Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
				where i.EMCo = @iEMCo and i.StdMaintGroup = @iStdMaintGroup  and i.StdMaintItem=@iStdMaintItem 
				and i.Equipment = @iEquipment and IsNull(s.StatusType,'') <> 'F')
			begin
				goto NextStdMaintItem
			end
		end
		--If on an component std maintenance item on open work order, skip item 
		If @equiptype = 'C'
		begin
			--Issue 129273
			If exists (select top 1 1 from dbo.EMSI i with(nolock)  
				Inner Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Component=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
				Inner Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
				where w.EMCo = @iEMCo and w.StdMaintGroup = @iStdMaintGroup and w.StdMaintItem=@iStdMaintItem  
				and w.Equipment = @iEquipment and w.Component = @iEquipment	and w.Equipment = @equipment	
				and IsNull(s.StatusType,'') <> 'F')
			begin
				goto NextStdMaintItem
			end
		end
			
		If IsNull(@component,'')=''
			begin
				--Run bspEMWOInitItem to add WOItem WO. 
				exec @rcode = dbo.bspEMWOInitItem @iEMCo, @workorder, @iEquipment,null,null,
				@emgroup, @iStdMaintGroup,@iStdMaintItem, @repaircode, @defprco /*27172*/, @defmechanic, @datecreated,
				@defdatedue, @defdatesched, @wobeginpartstatus, @wobeginstat,
     			@equiptype, @errmsg=@errmsg output
				--If error in bsp, return errmsg and let user know that some WO were
				--not created. 
    			if @rcode <> 0
					begin
						select @rcode = 1, @errmsg = 'Error during initialization - ' + isnull(@errmsg,'')
    					goto vspexit
    				end	
				else
					select @itemsinitialized = @itemsinitialized + 1,@groupinitializedYN = 'Y'
					goto NextStdMaintItem
			end
		else
			--Run bspEMWOInitItem to add WOItem WO. 
			exec @rcode = dbo.bspEMWOInitItem @emco, @workorder, @equipment,@componenttypecode,@iEquipment,
			@emgroup,  @iStdMaintGroup,@iStdMaintItem, @repaircode, @defprco /*27172*/, @defmechanic, @datecreated,
			@defdatedue, @defdatesched, @wobeginpartstatus, @wobeginstat,
     		@equiptype, @errmsg=@errmsg output
			--If error in bsp, return errmsg and let user know that some WO were
			--not created. 
    		if @rcode <> 0
				begin
					select @rcode = 1, @errmsg = 'Error during initialization - ' + isnull(@errmsg,'')
					goto vspexit
    			end	
			else
				select @itemsinitialized = @itemsinitialized + 1,@groupinitializedYN = 'Y'
				goto NextStdMaintItem


	EndNextStdMaintItem:

	If @opencursoritem = 1
	begin
		close cItemsToInit
		deallocate cItemsToInit
		select @opencursoritem =0
	End

	If @groupinitializedYN = 'Y'
	begin
		select	@groupsinitialized  = @groupsinitialized  +1
	end
	goto NextStdMaintGroup

EndNextStdMaintGroup:
If @opencursorgroup = 1
begin
	close cGroupsToInit
	deallocate cGroupsToInit
	select @opencursorgroup =0
End

vspexit:
If @opencursoritem = 1
begin
	close cItemsToInit
	deallocate cItemsToInit
End

If @opencursorgroup =1
begin
	close cGroupsToInit
	deallocate cGroupsToInit
End
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOInitItems] TO [public]
GO
