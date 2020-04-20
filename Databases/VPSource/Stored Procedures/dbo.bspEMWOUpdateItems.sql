SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWOUpdateItems    Script Date: 9/17/2001 3:58:57 PM ******/
CREATE proc [dbo].[bspEMWOUpdateItems]
/****************************************************************************
* CREATED BY: 	JM 11/1/98
* MODIFIED BY:	JM 12/7/98 - Changed '= null' to 'is null'.
*		JM 8/25/99 - Added loop on WOItem to update LastDone info to bEMSI.
*		MH 9/14/99 - Modified to allow updating of components.  Also commented out DateCompl check (notes below)
*				Meter readings may be null...for example if status type is changed from final to non-final
*				change the readings to null
*		JM 9/17/01 - Changed creation method for temp tables from 'select * into' to discrete declaration
*				of specific fields. Also changed inserts into temp tables to discrete declaration of fields. 
*				Ref Issue 14227.
*		TV 12/27/02 - Cleanup and Not set Meter readings to Zero when status is other than final #18779     
*		TV 1/23/02 - Issue 19880 Last done field not updating correctly
*		TV 02/11/04 - 23061 added isnulls 
*		TRL 03/20/08 - 126198 Added PRCo parameter to update EMWI.PRCo
*		TRL 03/11/09 - 132360 Changed what PR Co and Mechanic are updated
*		TRL 04/27/10 - 138984 current hour and odo readings now update EMSI, instead of current meter + replaced meter
*		JVH 10/21/10 - 141030 should check to see if component is an empty string too
*		JVH	6/9/11 - TK-05982 Removed the update to EMSI since the update trigger in EMWI should do the update to EMSI
*
* USAGE:
* 	Updates all items on a Work Order per input parameters.
*
* INPUT PARAMETERS:
*	EM Company - Controlling EMCo in EMWH.
*	WorkOrder - Controlling WorkOrder in EMWH.
*	Mechanic - New Mechanic - optional
*	StatusCode - New StatusCode - optional
*	RepairType - New RepairType - optional
*	DateCompl - New DateCompl - optional
*	CurrentOdometer - New Odometer - optional
*	TotalOdometer - New CurrentOdometer + ReplacedOdometer
*	CurrentHourMeter - New HourMeter - optional
*	TotalHourMeter - New CurrentHourMenter + ReplacedHourMeter
*
* OUTPUT PARAMETERS:
*	Error message if applicable.
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*****************************************************************************/
   
(@emco bCompany = null, @workorder bWO = null, @prco bCompany = null/*126198*/, @mechanic bEmployee = null, @statuscode varchar(10) = null, 
	@repairtype varchar (10) = null, @datecompl bDate = null, @currentodometer bHrs = null, @totalodometer bHrs = null,
	@currenthourmeter bHrs = null, @totalhourmeter bHrs = null, @errmsg varchar(255) output)

as

set nocount on

declare @equipment bEquip,@stdmaintgroup varchar(10), @stdmaintitem bItem, @woitem smallint, @update_currodo bHrs,
@update_totalodo bHrs, @update_currhr bHrs, @update_totalhr bHrs, @update_fuel bUnits, @component bEquip,
@statustype char(1), @rcode integer

select @rcode = 0
   
--Verify required parameters passed. 
if @emco is null
begin
   select @errmsg = 'Missing EM Company!', @rcode = 1
   goto bspexit
end

if @workorder is null
begin
	select @errmsg = 'Missing Work Order!', @rcode = 1
	goto bspexit
end

select @statustype = StatusType from EMWS 
where EMGroup = (select EMGroup from HQCO where HQCo = @emco)and StatusCode = @statuscode

--Mechanic cannot be updated without a PR Company
If @prco is not null
begin
	If @mechanic is not null
	begin
		--1. Update All WO Items where PRCo and Mechanic have no values
		update dbo.EMWI 
		set PRCo = @prco, Mechanic = @mechanic
		where EMCo = @emco and WorkOrder = @workorder
	end

	If @mechanic is null
	begin
		--2. Update Update PRCo when WO Items have no Mechanic
		update dbo.EMWI
		set PRCo = IsNull(@prco,PRCo)
		where EMCo = @emco and WorkOrder = @workorder and Mechanic is null

		--3 Will Update PRCo when existing WO Item Mechanic is valid for @proc
		update dbo.EMWI 
		set PRCo = @prco
		From EMWI i
		inner join PREH h with(nolock)on h.PRCo=i.PRCo and h.Employee=i.Mechanic
		where i.EMCo = @emco and i.WorkOrder = @workorder and i.Mechanic is not null
		and i.PRCo=@prco
	end
end

--Update each field in bEMWI if optional param is not null.
update dbo.EMWI
set StatusCode =  isnull(@statuscode,StatusCode),
	RepairType =  isnull(@repairtype,RepairType),
	DateCompl = @datecompl
where EMCo = @emco and WorkOrder = @workorder

/* Remove for Issue 132360
--Update each field in bEMWI if optional param is not null.
update dbo.EMWI
set PRCo = IsNull(@prco,PRCo),/*126198*/
	Mechanic =  isnull(@mechanic,Mechanic),
	StatusCode =  isnull(@statuscode,StatusCode),
	RepairType =  isnull(@repairtype,RepairType),
	DateCompl = @datecompl
where EMCo = @emco and WorkOrder = @workorder*/
   
--Cross-update the LastDone info bEMSI. 
--Echanged TempTable and Psuedo cursor for regular cursor 1/10/03 TV
Declare bcWOItemsCursor cursor for

select WOItem,Equipment,Component,StdMaintGroup,StdMaintItem,DateCompl
from dbo.EMWI with(nolock) where EMCo = @emco and WorkOrder = @workorder

open bcWOItemsCursor

fetch_next:
fetch next from bcWOItemsCursor into 
	@woitem,@equipment,@component,@stdmaintgroup,@stdmaintitem,@datecompl
if @@fetch_status <> 0 goto fetch_end
 
if @statustype = 'F'
begin
	--issue 141030 - should check to see if component is an empty string too
	if @component is null or @component = ''
		begin
			select @update_currodo = isnull(@currentodometer,OdoReading),
			@update_totalodo = isnull(@totalodometer,ReplacedOdoReading + OdoReading),
			@update_currhr = isnull(@currenthourmeter,HourReading),
			@update_totalhr = isnull(@totalhourmeter,ReplacedHourReading + HourReading),
			@update_fuel = FuelUsed
			from dbo.EMEM with(nolock) 
			where EMCo = @emco and Equipment = @equipment
		end
   else
		begin
			select @update_currodo = OdoReading,@update_totalodo = ReplacedOdoReading + OdoReading,
			@update_currhr = HourReading,@update_totalhr = ReplacedHourReading + HourReading,
			@update_fuel = FuelUsed
			from dbo.EMEM with(nolock)
			where EMCo = @emco and Equipment = @component
		end
end
   
--9/15/99 addition.  also combined following EMWI and EMSI set statements.  Mark
--01/10/03 If the status is not final then we do not change a the meter reading to 0 TV

update dbo.EMWI
set FuelUse = isnull(@update_fuel, FuelUse), 
CurrentOdometer = isnull(@update_currodo, CurrentOdometer),
TotalOdometer = isnull(@update_totalodo, TotalOdometer), 
CurrentHourMeter = isnull(@update_currhr, CurrentHourMeter),
TotalHourMeter = isnull(@update_totalhr, TotalHourMeter)
where EMCo = @emco and WorkOrder = @workorder and WOItem = @woitem
   
goto fetch_next
fetch_end:
close bcWOItemsCursor
deallocate bcWOItemsCursor

bspexit:
if @rcode<>0 select @errmsg=isnull(@errmsg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOUpdateItems] TO [public]
GO
