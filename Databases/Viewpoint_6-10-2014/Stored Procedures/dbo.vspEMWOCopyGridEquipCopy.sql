SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vspEMWOCopyGridEquipCopy]
/*************************************************************************
* Created by:  TRL 05/21/08 Issue 128499,Issue 129313,
* Modified by:	TRL 11/14/08 Issue 131082 added vspEMWOGetNextAvailable (Gets next Available WO and foramts WO)
*					TRL 08/03/09 Issue 133975 Add prameters to valid Shop and WO
*				GF 09/09/2010 - issue #141031 changed to use function vfDateOnly
*
*
* USAGE:  Copies a WO to a range of Equipment, an equipment Category or an Equip Series (Yr/Make/Model).
*
* INPUT PARAMS:
*	@emco				Form EMCo
*	@copyfromwo			WO to copy
*	@CopyToOption			'C' for Category of Equip, 'E' for Equipment Range or 'S' for Equip Series
*	@shopoption			W for Copy From WO Shop, E for Copy To Equip Shop, S for Specified Shop
*	@Shop				From: Copy From WO Shop or Specified Shop; will be null if Copy To Equip Shop since
*					it will need to be selected in loop per CopyToEquip
*	@newwo			From: Auto seq per EMCo.WorkOrderOption or specified beginning WO
*	@WOBegStatus			EMCO.WOBeginStat
*	@WOPartsBegStatus		EMCO.WOBeginPartStatus
*	@AutoInitSessionID		Enables form's grid fill procedure to identify which WO's were created during this session
*
* OUTPUT PARAMS:
*	@rcode		Return code; 0 = success, 1 = failure
*	 @maxnewwo bWO output, 
*	@errmsg		Error message; # copied if success, error message if failure
*************************************************************************/
(@emco bCompany = null, 
@autoinitsessionid varchar(30) = null,
@autoseqopt char(1) = null,
@copyfromwo bWO = null,
@includenotes char(1),
@shopoption char(1), 
@newwo bWO = null,
@wobegstatus varchar(10) = null,
@wopartsbegstatus varchar(10) = null,
@datesched bDate,
@datedue bDate, 
@copytoequipment bEquip =Null,
@copytoshop varchar(20) = null,
@maxnewwo bWO output,
@errmsg varchar(255) output )
 
As 
 
Set nocount on 
 
-- Initialize general local variables. 
declare @rcode int, @wodatecreated bDate,@hqmatlgroup bGroup,@shopgroup bGroup, @allowautoseqYN bYN /*Issue 133975*/,
/*Copy From Work Order Variables*/
@copyfromwoEquip bEquip,
/*Variables used to calculate the next work order*/
@NumLeadingZeros tinyint,@NumLeadingSpaces tinyint,@newwoSave bWO,@x tinyint,@updatewo bWO,
--Cursor Variables WOItem cursor
@opencursoritems int,
@WOItemCopy smallint,@EMWIDescription bDesc, @EMWIEMGroup bEquip,@EMWICostCode bCostCode,
@EMWIprco bCompany/*122308*/, @EMWImechanic bEmployee,
@EMWIInHseSubFlag char(1),@EMWIEstHrs bHrs, @EMWIQuoteAmt bDollar,@EMWIRepairType varchar(10),
@EMWIRepairCode varchar(10), @EMWIPriority char(1), @EMWINotes varchar(8000), 
-- Cursor Varialbles for WOItemPart cursor
@opencursoritemparts int, @EMWPEMGroup bGroup, @EMWPMatlGroup bGroup,@EMWPSeq int,@EMWPDescription bDesc,
@EMWPMaterial bMatl,@EMWPINCo bCompany,@EMWPInvLoc bLoc,@EMWPUM bUM,@EMWPQtyNeeded bUnits,
@EMWPPSFlag char(1),@EMWPRequired bYN 

select @rcode = 0, @opencursoritems=0, @opencursoritemparts=0

----#141031
set @wodatecreated = dbo.vfDateOnly()
 
-- Verify necessary parameters passed. 
if @emco is null
begin
 	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto vspexit
end
if @autoinitsessionid is null
begin
 	select @errmsg =  'Missing AutoInitSessionID!', @rcode = 1
 	goto vspexit
end 
if IsNull(@copyfromwo,'')= ''
begin
 	select @errmsg = 'Missing Copy From Work Order!', @rcode = 1
 	goto vspexit
end
if @wobegstatus is null
begin
 	select @errmsg = 'Missing WO Beg Status!', @rcode = 1
 	goto vspexit
end
if @wopartsbegstatus is null
begin
	select @errmsg = 'Missing WO Parts Beg Status!', @rcode = 1
 	goto vspexit
end
if IsNull(@copytoequipment,'')= ''
begin
 	select @errmsg = 'Missing Copy To Equipment!', @rcode = 1
 	goto vspexit
end

-- Issue 126052
If IsNull(@autoseqopt,'') = 'C'  and IsNumeric(@newwo)<> 1 and IsNull(@shopoption,'') <> 'E'
begin
	select @errmsg='Next Work Order in EM Shop cannot be alpha-numeric!',@rcode = 1
	goto vspexit
end

If IsNull(@autoseqopt,'') = 'E'  and IsNumeric(@newwo)<> 1 
begin
	select @errmsg='Next Work Order in EM Company Parameters cannot be alpha-numeric!',@rcode = 1
	goto vspexit
end

--Get HQCo Information 
/*Issue 133975 Linked EMCo to get WOSeq Option*/
select @hqmatlgroup = HQCO.MatlGroup, @shopgroup = HQCO.ShopGroup, @allowautoseqYN=isnull(EMCO.WOAutoSeq,'N')
from dbo.HQCO with(nolock) 
Inner join dbo.EMCO with(nolock)on EMCO.EMCo = HQCO.HQCo 
where HQCo = @emco

--If Auto Seq by Shop get last work from the Equipment Shop
if @autoseqopt = 'C'
begin
	If IsNull(@copytoshop,'') = ''
	begin
		select @errmsg = 'Missing Shop! No Work Order created. (Auto Seq Work Orders by Shop)',@rcode = 7
		goto vspexit
	end
	--Check for valid copy to shop
	If not exists (select top 1 1 from dbo.EMSX with(nolock) 
					where ShopGroup = @shopgroup and Shop = @copytoshop)
	begin
		select @errmsg = 'Invalid copy to Shop! No Work Order created. (Auto Seq Work Orders by Shop)',@rcode = 7
		goto vspexit
	end
	--If No LastWorkOrder No set to zero
 	select @newwo = IsNull(LastWorkOrder,0)	from dbo.EMSX with(nolock) 
	where ShopGroup = @shopgroup and Shop = @copytoshop
End

If @autoseqopt = 'M' and IsNumeric(@newwo)=0
begin
	if exists (select top 1 1 from dbo.EMWH with(nolock) where EMCo = @emco and WorkOrder = @newwo)
	begin
		select @errmsg = 'Work Order: "'+@newwo+'" already exists!', @rcode = 1
		goto vspexit
	end
	goto CreateWO
end

/*Issue 131082*/
IF IsNumeric(Replace(@newwo,' ','0'))=1
	BEGIN
		--Formats and verifies and/or gets next available Work Order number
		/*Issue 133975 Add prameters to valid Shop and WO*/
		exec @rcode = dbo.vspEMWOGetNextAvailable @emco,  @allowautoseqYN, @autoseqopt, @shopgroup, @copytoshop, @newwo output, @errmsg output
		If @rcode = 1
		begin
			goto vspexit
		end   
	end
ELSE
	BEGIN
		--Still need to format Alpha-Numeric Work Orders
		exec @rcode = dbo.vspEMFormatWO @newwo output, @errmsg output
		If @rcode = 1
		begin
			goto vspexit
		end   
	END

CreateWO:
-- Create new bEMWH record. Note that Mechanic, DateDue, DateSched, Notes and
-- AutoInitSessionID will be set to null by being excluded from insert statement. 
insert into dbo.EMWH (EMCo, WorkOrder,Description,AutoInitSessionID,Equipment,
ShopGroup,Shop,PRCo,Mechanic,INCo,InvLoc,DateCreated,DateDue,DateSched,Notes)
Select EMCo,@newwo,Description,@autoinitsessionid,@copytoequipment,
@shopgroup,@copytoshop,PRCo,Mechanic,INCo,InvLoc,@wodatecreated,@datedue,@datesched,
EMWHNotes = case when @includenotes = 'Y' then Notes else null end
from dbo.EMWH with(nolock)
where EMCo = @emco and WorkOrder = @copyfromwo
If @@rowcount = 0
begin
	select @errmsg = 'No Work Order found to copy!',@rcode = 1
	goto vspexit
end

-- Start loop on WOItems. Note that StdMaintGroup, StdMaintItem, Mechanic, PartCode, 
--SerialNo, DateDue, DateSched, DateCompl and Notes will be set to null by being 
--excluded from insert statement. 
--Declare and open cursor, run through SMGItemsToInitialize
declare vcsWOItems cursor local fast_forward for
select WOItem,Equipment,Description,EMGroup,CostCode,PRCo,Mechanic,
InHseSubFlag,EstHrs,QuoteAmt,RepairType,RepairCode,Priority,
EMWINotes = case when @includenotes = 'Y' then Notes else null end 
From dbo.EMWI with(nolock)
Where EMCo = @emco and WorkOrder = @copyfromwo

--Open Cursor
open vcsWOItems
select @opencursoritems = 1
	
goto NextWOItem
NextWOItem:
Fetch next from vcsWOItems into @WOItemCopy,@copyfromwoEquip, @EMWIDescription,@EMWIEMGroup,@EMWICostCode,@EMWIprco,@EMWImechanic,
@EMWIInHseSubFlag,@EMWIEstHrs,@EMWIQuoteAmt,@EMWIRepairType,@EMWIRepairCode,@EMWIPriority,@EMWINotes

If (@@fetch_status <> 0)
begin
	goto EndNextWOItem
end
	--Format WorkOrder
	/*Issue 131082*/
 	exec @rcode = dbo.vspEMFormatWO @newwo output, @errmsg output
	If @rcode = 1
	begin
		goto vspexit
	end   

 	-- Create new bEMWI record. 
 	insert into dbo.EMWI (EMCo, WorkOrder, WOItem,Description, Equipment,
 	EMGroup, CostCode,PRCo,Mechanic,InHseSubFlag,EstHrs, QuoteAmt,
 	RepairType, RepairCode,  Priority, DateCreated,DateDue,DateSched,Notes, 
 	CurrentHourMeter, TotalHourMeter, CurrentOdometer, TotalOdometer,FuelUse,StatusCode)
 	values (@emco, @newwo, @WOItemCopy,@EMWIDescription,@copytoequipment,
 	@EMWIEMGroup, @EMWICostCode,@EMWIprco, @EMWImechanic,@EMWIInHseSubFlag,@EMWIEstHrs, @EMWIQuoteAmt,
 	@EMWIRepairType, @EMWIRepairCode,@EMWIPriority, @wodatecreated,@datedue, @datesched,@EMWINotes,
 	0, 0, 0, 0,0,@wobegstatus)

	--Issue 129251 Added (Fixed) EMWP.Seq column to be copied
	--Declare and open cursor, run through SMGItemsToInitialize
	declare vcsWOItemParts cursor local fast_forward for
	select EMGroup,MatlGroup,Material,INCo,InvLoc,Description,UM,QtyNeeded,PSFlag,Required,Seq
	From dbo.EMWP with(nolock)
	Where EMCo = @emco and WorkOrder = @copyfromwo and WOItem=@WOItemCopy and Equipment = @copyfromwoEquip
	
	--Open Cursor
	open vcsWOItemParts
	select @opencursoritemparts = 1
	
	goto NextWOItemPart
	NextWOItemPart:
	Fetch next from vcsWOItemParts into @EMWPEMGroup,@EMWPMatlGroup,@EMWPMaterial,@EMWPINCo,@EMWPInvLoc,@EMWPDescription,
 												@EMWPUM,@EMWPQtyNeeded,@EMWPPSFlag,@EMWPRequired,@EMWPSeq
	If (@@fetch_status <> 0)
	begin
		goto EndNextWOItemPart
	end
		--Is material or partcode stocked or purchased
		if @EMWPINCo is not null and IsNull(@EMWPInvLoc,'')<>''
		begin
 			select  @EMWPPSFlag = 'P'
		end	
		--Does Material exist
 		if exists(select top 1 1 from dbo.INMT with(nolock) where INCo = @EMWPINCo and Loc = @EMWPInvLoc 
 					and MatlGroup = @EMWPMatlGroup and Material = @EMWPMaterial)
			begin
				select @EMWPPSFlag = 'S'
			end
 		else
			begin
 				select @EMWPPSFlag = 'P'
			end
 		
		-- Create new bEMWP record. 
 		insert into dbo.EMWP (EMCo,WorkOrder,WOItem,Description,Equipment,EMGroup,MatlGroup,Material, 
 		INCo,InvLoc,PartsStatusCode,UM,QtyNeeded,PSFlag,Required,Seq)
 		values (@emco,@newwo,@WOItemCopy,@EMWPDescription,@copytoequipment,@EMWPEMGroup,@EMWPMatlGroup,@EMWPMaterial,
		@EMWPINCo,@EMWPInvLoc,@wopartsbegstatus,@EMWPUM,@EMWPQtyNeeded,@EMWPPSFlag,@EMWPRequired,@EMWPSeq)
 		
		goto NextWOItemPart

		EndNextWOItemPart:
		If @opencursoritemparts = 1
		begin
			close vcsWOItemParts
			deallocate vcsWOItemParts
			select @opencursoritemparts = 0
		End
		
		goto NextWOItem

EndNextWOItem:
If @opencursoritems = 1
begin
	close vcsWOItems
	deallocate vcsWOItems
	select @opencursoritems = 0
End

vspexit:

--Close cursors if open
If @opencursoritemparts = 1
begin
	close vcsWOItemParts
	deallocate vcsWOItemParts
End
If @opencursoritems = 1
begin
	close vcsWOItems
	deallocate vcsWOItems
End

IF (@autoseqopt = 'C' or @autoseqopt = 'E' or @autoseqopt = 'M') and IsNull(@newwo,'') <> '' and IsNumeric(@newwo)=1
BEGIN
	--Update LastWorkOrder for the Shop when Auto Sequencing by Shop
	if @autoseqopt = 'C' 
	begin
		update dbo.EMSX set LastWorkOrder = @newwo where ShopGroup = @shopgroup and Shop = @copytoshop
	end
	
	/*update LastWorkOrder in EM Company Parameters when Auto Sequencing by Company*/
	--Return Max Work Order Number in from EMWH and update EM Company Parameters?
	if @autoseqopt = 'E'
	begin	
		update dbo.EMCO set LastWorkOrder = @newwo where EMCo = @emco
	end

	/*Issue 133975 Add prameters to valid Shop and WO*/
	exec @rcode = dbo.vspEMWOGetNextAvailable @emco, @allowautoseqYN, @autoseqopt, @shopgroup, @copytoshop, @newwo output, @errmsg output
END

Select @maxnewwo = @newwo
if @autoseqopt = 'M' and IsNumeric(@newwo)=0
begin
	Select @maxnewwo = @newwo
End

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOCopyGridEquipCopy] TO [public]
GO
