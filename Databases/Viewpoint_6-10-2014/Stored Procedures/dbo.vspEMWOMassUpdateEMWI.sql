SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMWOMassUpdateEMWI]
/****************************************************************************
* CREATED BY: 	TRL 02/03/09 Issue 129069 New form EM Work Order Mass Update
* MODIFIED BY:   TRL 08/19/09 Issue 135097 added code to prevent incorrect total hours or odometer update
*
* USAGE: EM Work Order Mass Update, Returns data for Work Order Header Grid
* @statuscodetype could come from form but chose procedure
* INPUT PARAMETERS:
* @emco 
* @emgroup
* @equipment 
* @wo 
* @woitem 
* @prco
* @mechanic
* @statuscode
* @completedate
* @repairtype
* @hours
* @odometer
* @fueluse
* @woitemnotes
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*****************************************************************************/
(@emco bCompany = null,
@emgroup bGroup = null, 
@equipment bEquip = null,
@component bEquip = null,
@wo bWO = null,
@woitem bWO = null,
@prco bCompany = null, 
@mechanic bEmployee = null,
@statuscode varchar (10) = null,
@completedate smalldatetime = null,
@repairtype varchar(10) = null,
@hours bHrs = null, 
@totalhours bHrs = null,
@odometer bHrs = null, 
@totalodo bHrs = null,
@fueluse bHrs = null, 
@woitemnotes varchar(max) = null,
@errmsg varchar(255) output)
    
as
 
set nocount on

declare @rcode int, @changeinprogress bYN, @statuscodetype varchar(1),@EquipOrComp varchar(11)


select @rcode = 0, @changeinprogress = 'N'

--Verify EM Company
If @emco is null
begin
	select @errmsg = 'Missing EM Company',@rcode =1 
	goto vspexit
end
--Verify EM Group
If @emgroup is null
begin
	select @errmsg = 'Missing EM Group',@rcode =1 
	goto vspexit
end
--Verify WorkOrder
If IsNull(@wo,'') = ''
begin
	select @errmsg = 'Missing Work Order',@rcode=1
	goto vspexit
end
If not exists (Select WorkOrder from dbo.EMWH with(nolock)Where EMCo=@emco and WorkOrder = @wo and Equipment=@equipment)
begin
	select @errmsg = 'Missing or Invalid Work Order',@rcode=1
	goto vspexit
end
--Verify Work Order Item
If @woitem is null
begin
	select @errmsg = 'Missing Work Order Item',@rcode=1
	goto vspexit
end    
If not exists (Select WOItem from dbo.EMWI with(nolock) Where EMCo=@emco and WorkOrder = @wo and WOItem=@woitem and  Equipment=@equipment)
begin
	select @errmsg = 'Missing or Invalid Work Order Item',@rcode=1
	goto vspexit
end
--Verify Equipment
--1st check to see if Equipment code in the middle of being changed
If exists(select LastUsedEquipmentCode from dbo.EMEM with(nolock) Where EMCo=@emco and LastUsedEquipmentCode= @equipment and IsNull(ChangeInProgress,'N') = 'Y' )
begin
	select @errmsg = 'Equipment Code change in progress, all records are currently being changed to a different new code',@rcode=1
	goto vspexit
end
If exists(select Equipment from dbo.EMEM with(nolock) Where EMCo=@emco and Equipment= @equipment and IsNull(ChangeInProgress,'N') = 'Y' )
begin
	select @errmsg = 'Equipment Code change in progress, database update is not complete for new Equipment Code',@rcode=1
	goto vspexit
end
--Check to see if Equipment exists
If not exists (select Equipment from dbo.EMEM with(nolock) where EMCo=@emco and Equipment=@equipment and IsNull(ChangeInProgress,'N') = 'N')
begin
	select @errmsg = 'Invalid Equipment code',@rcode=1
	goto vspexit
end

--Validate Repair Type
if IsNull(@repairtype,'')<>''
begin
	If not exists (select RepType from dbo.EMRX with(nolock) Where EMGroup=@emgroup and RepType=@repairtype )
	begin
		select @errmsg = 'Invalid RepairType',@rcode=1
   		goto vspexit
	end
end
--Verify PR Co
If @prco is not null
begin
	If not exists (select PRCo from dbo.PRCO with(nolock)Where PRCo=@prco)
	begin
   		select @errmsg = 'Invalid PR Co: ' + convert(varchar(3),@prco),@rcode=1
   		goto vspexit
	end	
end
--Verify Mechanic
If @mechanic is not null
begin
	If not exists (select PRCo from dbo.PRCO with(nolock) Where PRCo=@prco)
	begin
   		select @errmsg = 'Invalid PR Co: ' + convert(varchar(3),@prco),@rcode=1
   		goto vspexit
   	end	
	--select @prco = PRCo from bEMCO e, inserted i where e.EMCo = i.EMCo
   	If not exists (select Employee from dbo.PREH with(nolock) Where PRCo=@prco and Employee=@mechanic)
	begin
   		select @errmsg = 'PR Company: ' + convert(varchar(3),@prco) + 'has an invalid Mechanic: ' + convert(varchar(10),@mechanic),@rcode =1
   		goto vspexit
   	end	
end
--Verify Status code and get status type
If IsNull(@statuscode,'')<>''
begin
	If not exists (select StatusCode from dbo.EMWS with(nolock) where EMGroup = @emgroup and StatusCode = @statuscode)
   	begin
   		select @errmsg = 'Invalid Status Code',@rcode =1
  		goto vspexit
	end
	--Issue 135097
	select @statuscodetype = StatusType  from dbo.EMWS with(nolock) where EMGroup = @emgroup and StatusCode = @statuscode
end


--Issue 135097
if isnull(@statuscodetype,'') ='F'
begin
	select @EquipOrComp = case when isnull(@component,'') = '' then 'Equipment' else 'Component' end
	if isnull(@hours,0) > isnull(@totalhours,0)
	begin
		select @errmsg='Hour meter entered exceeds the Last Hours reading on file for ' + @EquipOrComp + ', update current Hours in EM Meter Readings',@rcode=1
		goto vspexit
		
	END
	if isnull(@odometer,0) > isnull(@totalodo,0)
	BEGIN
		select @errmsg='Odometer entered exceeds the Last Odometer reading on file for ' + @EquipOrComp + ', update current  odometer in EM Meter Readings',@rcode=1
		goto vspexit
	END
end

begin try
	Begin Transaction;
	
	Update EMWI
	Set Component=@component,PRCo=@prco,Mechanic=@mechanic,
	StatusCode=@statuscode,RepairType=@repairtype,DateCompl=@completedate,
	CurrentHourMeter=@hours,
	TotalHourMeter=@totalhours,
	CurrentOdometer=@odometer,
	TotalOdometer=@totalodo,
	FuelUse=@fueluse, Notes = @woitemnotes
	from dbo.EMWI i with(nolock) 
	Inner join dbo.EMWH h with(nolock)on h.EMCo = i.EMCo and h.WorkOrder = i.WorkOrder and h.Equipment = i.Equipment
	where i.EMCo=@emco and i.WorkOrder = @wo and i.WOItem = @woitem and i.Equipment = @equipment;

	Commit transaction;
	
end try
begin catch
	
    -- Test XACT_STATE for 1 or -1.
    -- XACT_STATE = 0 means there is no transaction and
    -- a COMMIT or ROLLBACK would generate an error.

    -- Test if the transaction is uncommittable.
    -- The transaction is in an uncommittable state.  Rolling back transaction.
    IF (XACT_STATE()) = -1 or (XACT_STATE()) = 0
    BEGIN
		select @errmsg = convert(varchar(50),ERROR_NUMBER()) + ' - '+ IsNull(ERROR_MESSAGE(),''),@rcode=1
        ROLLBACK TRANSACTION;
    END;

    -- Test if the transaction is active and valid.
    -- The transaction is committable. Committing transaction.
    IF (XACT_STATE()) = 1
    BEGIN
                COMMIT TRANSACTION;   
    END;

end catch

vspexit:
    
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOMassUpdateEMWI] TO [public]
GO
