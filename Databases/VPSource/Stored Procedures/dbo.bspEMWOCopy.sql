SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE           proc [dbo].[bspEMWOCopy]
 /*************************************************************************
 * Created by TV 03/25/04 issue 24150 -  Designed to combine the 3 other stored Procs into 
 *						one easy to maintain procedure. 
 * Modified by:	TV 04/12/04 23558 if the part is not valid 
 *				TV 06/30/04 24930 - no time needed on date
 *				TV 07/13/04 25057 - added Date sched and Date due.
 *				TV 10/19/04 25713 - Invalid use of null error when equipment # is a component - backed out
 *				TRL 01/17/07 126052 Stop procedure when AutoSeq by Shop or Company when New WorkOrder isnot numeric
 *			    TRL 05/13/08 122308  add EMWI.PRCo when Item is copied
 *				GF 09/05/2010 - issue #141031 use function vfDateOnly
 *
 * USAGE:  Copies a WO to a range of Equipment, an equipment Category or an Equip Series (Yr/Make/Model).
 *
 * INPUT PARAMS:
 *	@EMCo				Form EMCo
 *	@CopyFromWO			WO to copy
 *	@CopyToOption			'C' for Category of Equip, 'E' for Equipment Range or 'S' for Equip Series
 *	@CopyToCategory		EMEM.Category of Equipment that WO is to be copied to for @CopyToOption = 'C'
 *	@CopyToBegEquip		Beginning of range of EMEM.Equipment that WO is to be copied to for @CopyToOption = 'E'
 *	@CopyToEndEquip		Ending of range of EMEM.Equipment that WO is to be copied to for @CopyToOption = 'E'
 *	@CopyToEquipSeriesYear	EMEM.ModelYr that WO is to be copied to for @CopyToOption = 'S'
 *	@CopyToEquipSeriesMake	EMEM.Manufacturer that WO is to be copied to for @CopyToOption = 'S'
 *	@CopyToEquipSeriesModel	EMEM.Model that WO is to be copied to for @CopyToOption = 'S'
 *	@ShopOption			W for Copy From WO Shop, E for Copy To Equip Shop, S for Specified Shop
 *	@Shop				From: Copy From WO Shop or Specified Shop; will be null if Copy To Equip Shop since
 *					it will need to be selected in loop per CopyToEquip
 *	@NewWO			From: Auto seq per EMCo.WorkOrderOption or specified beginning WO
 *	@WOBegStatus			EMCO.WOBeginStat
 *	@WOPartsBegStatus		EMCO.WOBeginPartStatus
 *	@AutoInitSessionID		Enables form's grid fill procedure to identify which WO's were created during this session
 *
 * OUTPUT PARAMS:
 *	@rcode		Return code; 0 = success, 1 = failure
 *	@WOCreated smallint output,
 *	 @MaxNewWO bWO output, 
 *	@ErrMsg		Error message; # copied if success, error message if failure
 *************************************************************************/
 (@EMCo bCompany = null, --1
 @autoseqopt char(1) = null,--2 
 @CopyFromWO bWO = null, --3
 @CopyToOption char(1) = null, --4
 @CopyToCategory bCat = null, --5
 @CopyToBegEquip bEquip = null,--6
 @CopyToEndEquip bEquip = null,--7
 @CopyToEquipSeriesYear varchar(6) = null, --8
 @CopyToEquipSeriesMfr varchar(20) = null,--9
 @CopyToEquipSeriesModel varchar(20) = null,--10
 @ShopOption char(1), --11
 @SpecifiedShop varchar(20) = null,--12
 @NewWO bWO = null,--13
 @WOBegStatus varchar(10) = null,--14
 @WOPartsBegStatus varchar(10) = null,--15
 @IncludeNotes char(1),--16
 @AutoInitSessionID varchar(30) = null,--17
 @DateSched bDate,--18
 @DateDue bDate, --19
 @WOCreated smallint output, --20
 @MaxNewWO bWO output,--21
 @ErrMsg varchar(255) output )--22
 
 
 As 
 
 Set nocount on 
 
 -- Initialize general local variables. 
 declare @CopyFromWOEquip bEquip, @EquipCopy bEquip, @MatlGroup bGroup,	@NewWOSave bWO,	@NumLeadingSpaces tinyint,
 @NumLeadingZeros tinyint, @numrows int,	@rcode int,	@Shop varchar(10), @ShopGroup bGroup, @sp tinyint,
 @TargetEquip bEquip, /*@WOFormatOption char(1),*/ @WOItemCopy smallint,	@WOOption char(1), @WOPartCopy bMatl,
 @x tinyint, @updatewo bWO, @date bDate
 
 --Declare variables for values copied from bEMWH 
 declare @EMWHDescription bItemDesc, @EMSXInvLoc bLoc, @EMSXINCo bCompany, @EMWHPRCo bCompany, @EMWHShopGroup bGroup,
 @EMWHNotes varchar(8000), @mechanic bEmployee 
 
 -- Declare variables for values copied from bEMWI 
 declare @EMWIComponentTypeCode varchar(10), @EMWIComponent bEquip,	@EMWIEMGroup bEquip, @EMWICostCode bCostCode,
 @EMWIDescription bDesc,	@EMWIInHseSubFlag char(1), @EMWIRepairType varchar(10), @EMWIRepairCode varchar(10),
 @EMWIEstHrs bHrs, @EMWIQuoteAmt bDollar, @EMWIPriority char(1), @EMWINotes varchar(8000), 
 @EMWIprco bCompany/*122308*/, @EMWImechanic bEmployee
 
 -- Declare variables for values copied from bEMWP 
 declare @EMWPMaterial bMatl, @EMWPEMGroup bGroup, @EMWPInvLoc bLoc, @EMWPDescription bDesc, @EMWPUM bUM,
 @EMWPQtyNeeded bUnits, @EMWPPSFlag char(1),	@EMWPRequired bYN, @EMWPINCo bCompany 
 
 select @rcode = 0
 
 -- Verify necessary parameters passed. 
 if @EMCo is null
 begin
 	select @ErrMsg = 'Missing EM Company!', @rcode = 1
 	goto bspexit
 end
 
 if @CopyFromWO is null
 begin
 	select @ErrMsg = 'Missing Copy From Work Order!', @rcode = 1
 	goto bspexit
 end
 
 if @CopyToOption is null
 begin
 	select @ErrMsg = 'Missing Copy To Option!', @rcode = 1
 	goto bspexit
 end
 
 if @WOBegStatus is null
 begin
 	select @ErrMsg = 'Missing WO Beg Status!', @rcode = 1
 	goto bspexit
 end
 
 if @WOPartsBegStatus is null
 begin
 	select @ErrMsg = 'Missing WO Parts Beg Status!', @rcode = 1
 	goto bspexit
 end
 
 if @AutoInitSessionID is null
 begin
 	select @ErrMsg =  'Missing AutoInitSessionID!', @rcode = 1
 	goto bspexit
 end
 
-- Issue 126052
If IsNull(@autoseqopt,'') = 'C'  and IsNumeric(@NewWO)<> 1 
begin
	select @ErrMsg='Next Work Order in EM Shop cannot be alpha-numeric!',@rcode = 1
end

If IsNull(@autoseqopt,'') = 'E'  and IsNumeric(@NewWO)<> 1 
begin
	select @ErrMsg='Next Work Order in EM Company Parameters cannot be alpha-numeric!',@rcode = 1
end

 -- Create list of Equipment to copy WO to. 
 CREATE TABLE #TargetEquip (Equipment varchar(10) NOT NULL)
 
 -- Get Equipment for CopyFromWO so that it can be excluded from any range 
 select @CopyFromWOEquip = Equipment from dbo.EMWH with(nolock) where EMCo = @EMCo and WorkOrder = @CopyFromWO
 
 -- Fill #TargetEquip depending on @CopyToOption 
if @CopyToOption = 'C' --Category
begin
 	insert into #TargetEquip (Equipment)
 	select Equipment from dbo.EMEM with(nolock)
 	where EMCo = @EMCo 
 	and Category = @CopyToCategory 
 	and Equipment <> @CopyFromWOEquip
 	and Status <> 'I' 
 	and Type <> 'C' 
 	order by Equipment
end
 
if @CopyToOption = 'E' --Range of Equipment
begin
 	insert into #TargetEquip (Equipment)
 	select Equipment from dbo.EMEM with(nolock)
 	where EMCo = @EMCo 
 	and  Equipment >= @CopyToBegEquip 
 	and Equipment <= @CopyToEndEquip
 	and Equipment <> @CopyFromWOEquip
 	and Status <> 'I' 
 	and Type <> 'C' -- backed out
 	order by Equipment
end
 
if @CopyToOption = 'S' --Equipment Series
Begin
 	-- Convert @CopyToEquipSeriesMfr and @CopyToEquipSeriesModel to lower case to match any cases in table 
 	select @CopyToEquipSeriesMfr = lower(@CopyToEquipSeriesMfr), 
		@CopyToEquipSeriesModel= lower(@CopyToEquipSeriesModel)
 	
 	-- Year, Mfr and Model 
	--if @CopyToEquipSeriesYear is not null and @CopyToEquipSeriesMfr is not null and @CopyToEquipSeriesModel is not null
 	if IsNull(@CopyToEquipSeriesYear,'')<>'' and IsNull(@CopyToEquipSeriesMfr,'')<>'' and IsNull(@CopyToEquipSeriesModel,'')<>''
	begin
 		insert into #TargetEquip (Equipment)
 		select Equipment from dbo.EMEM with (nolock)
 		where EMCo = @EMCo 
 		and ModelYr = @CopyToEquipSeriesYear 
 		and lower(Manufacturer) = @CopyToEquipSeriesMfr 
 		and lower(Model) = @CopyToEquipSeriesModel
 		and Equipment <> @CopyFromWOEquip
 		and Status <> 'I' 
 		and Type <> 'C' 
 		order by Equipment
 		goto proceed
 	end
 	
 	-- Year only 
	--if @CopyToEquipSeriesYear is not null and @CopyToEquipSeriesMfr is null and @CopyToEquipSeriesModel is null
 	if IsNull(@CopyToEquipSeriesYear,'')<>'' and IsNull(@CopyToEquipSeriesMfr,'')='' and IsNull(@CopyToEquipSeriesModel,'')=''
 	begin
 		insert into #TargetEquip (Equipment)
 		select Equipment from dbo.EMEM  with (nolock)
 		where EMCo = @EMCo 
 		and ModelYr = @CopyToEquipSeriesYear 
 		and Equipment <> @CopyFromWOEquip
 		and Status <> 'I' 
 		and Type <> 'C' 
 		order by Equipment
 		goto proceed
 	end
 	
 	-- Mfr only 
	--if @CopyToEquipSeriesYear is null and @CopyToEquipSeriesMfr is not null and @CopyToEquipSeriesModel is null
 	if IsNull(@CopyToEquipSeriesYear,'')=''and IsNull(@CopyToEquipSeriesMfr,'')<>'' and  IsNull(@CopyToEquipSeriesModel,'')=''
 	begin
 		insert into #TargetEquip (Equipment)
 		select Equipment from dbo.EMEM  with (nolock)
 		where EMCo = @EMCo 
 		and lower(Manufacturer) = @CopyToEquipSeriesMfr 
 		and Equipment <> @CopyFromWOEquip
 		and Status <> 'I' 
 		and Type <> 'C' 
 		order by Equipment
 		goto proceed
 	end
 	
 	-- Model only 
	--if @CopyToEquipSeriesYear is null and @CopyToEquipSeriesMfr is null and @CopyToEquipSeriesModel is not null
 	if IsNull(@CopyToEquipSeriesYear,'')='' and IsNull(@CopyToEquipSeriesMfr,'')='' and IsNull(@CopyToEquipSeriesModel,'')<> ''
 	begin
 		insert into #TargetEquip (Equipment)
 		select Equipment from dbo.EMEM  with (nolock)
 		where EMCo = @EMCo 
 		and lower(Model) = @CopyToEquipSeriesModel
 		and Equipment <> @CopyFromWOEquip
 		and Status <> 'I' 
 		and Type <> 'C' 
 		order by Equipment
 		goto proceed
 	end
 	
 	-- Year and Mfr 
	--if @CopyToEquipSeriesYear is not null and @CopyToEquipSeriesMfr is not null and @CopyToEquipSeriesModel is null
 	if IsNull(@CopyToEquipSeriesYear,'')<>''and IsNull(@CopyToEquipSeriesMfr,'')<>'' and  IsNull(@CopyToEquipSeriesModel,'')=''
 	begin
 		insert into #TargetEquip (Equipment)
 		select Equipment from dbo.EMEM  with (nolock)
 		where EMCo = @EMCo 
 		and ModelYr = @CopyToEquipSeriesYear 
 		and lower(Manufacturer) = @CopyToEquipSeriesMfr 
 		and Equipment <> @CopyFromWOEquip
 		and Status <> 'I' 
 		and Type <> 'C' 
 		order by Equipment
 		goto proceed
 	end
 	
 	-- Year and Model
	--if @CopyToEquipSeriesYear is not null and @CopyToEquipSeriesMfr is null and @CopyToEquipSeriesModel is not null 
 	if IsNull(@CopyToEquipSeriesYear,'')<>'' and IsNull(@CopyToEquipSeriesMfr,'')='' and IsNull(@CopyToEquipSeriesModel,'')<>''
 	begin
 		insert into #TargetEquip (Equipment)
 		select Equipment from dbo.EMEM  with (nolock)
 		where EMCo = @EMCo 
 		and ModelYr = @CopyToEquipSeriesYear 
 		and lower(Model) = @CopyToEquipSeriesModel
 		and Equipment <> @CopyFromWOEquip
 		and Status <> 'I' 
 		and Type <> 'C' 
 		order by Equipment
 		goto proceed
 	end
 	
 	-- Mfr and Model 
	--if @CopyToEquipSeriesYear is null and @CopyToEquipSeriesMfr is not null and @CopyToEquipSeriesModel is not null
 	if IsNull(@CopyToEquipSeriesYear,'')='' and IsNull(@CopyToEquipSeriesMfr,'')<>'' and  IsNull(@CopyToEquipSeriesModel,'')<>''
	begin
 		insert into #TargetEquip (Equipment)
 		select Equipment from dbo.EMEM  with (nolock)
 		where EMCo = @EMCo 
 		and lower(Manufacturer) = @CopyToEquipSeriesMfr 
 		and lower(Model) = @CopyToEquipSeriesModel
 		and Equipment <> @CopyFromWOEquip
 		and Status <> 'I' 
 		and Type <> 'C' 
 		order by Equipment
		goto proceed	
 	end
END
proceed:
 
select @MatlGroup = MatlGroup, @ShopGroup = ShopGroup from dbo.HQCO with(nolock) where HQCo = @EMCo
 
select @EMWHDescription = Description, @EMWHPRCo = PRCo, @EMWHShopGroup = ShopGroup,
@EMWHNotes = case when @IncludeNotes = 'Y' then Notes else null end, @mechanic = Mechanic
from dbo.EMWH with (nolock) where EMCo = @EMCo and WorkOrder = @CopyFromWO
 
-- Establish Shop based on @ShopOption for @ShopOption 'S' and 'W' ('E' is selected within loop.) 
if @ShopOption = 'S' 
	select @Shop = @SpecifiedShop

if @ShopOption = 'W' 
	select @Shop = Shop from dbo.EMWH with(nolock) where EMCo = @EMCo and WorkOrder = @CopyFromWO

--if @ShopOption = 'E' - must be done in the Equip loop
 
--TV 06/30/04 24930 - no time needed on date
----#141031
set @date = dbo.vfDateOnly()
 
select @WOCreated = 0

/*Get Count of Equipment that could be copied*/ 
--declare @targetequiprecords int
--Select @targetequiprecords = Count(*) From #TargetEquip
--Select @ErrMsg = 'Records: '+ convert(varchar(20),IsNull(@targetequiprecords,0))+' in Target Equipment.',@rcode = 1
--goto bspexit

-- Start loop on Equipment. 
select @EquipCopy = min(Equipment)
from #TargetEquip
while isnull(@EquipCopy,'') <> '' 
begin
	if @ShopOption = 'E'
 	begin
 		select @Shop = Shop from dbo.EMEM where EMCo = @EMCo and Equipment = @EquipCopy
 		-- Make sure there is a Shop for this Equip Backed out 10/19/04 TV
 		/*if (select Type from dbo.EMEM where EMCo = @EMCo and Equipment = @EquipCopy) = 'E'
 			begin 
 			select @Shop = Shop from dbo.EMEM where EMCo = @EMCo and Equipment = @EquipCopy
 			end 
 		else
 			begin
 			select @Shop = Shop from dbo.EMEM where EMCo = @EMCo and 
 			Equipment = (select CompOfEquip From dbo.EMEM m where EMCo = @EMCo and Equipment = @EquipCopy)
 			end*/
 
 		if IsNull(@Shop,'')=''
			goto skipcopy
 		
 		if @autoseqopt = 'C'
 		begin
 			select @NewWO = Max (IsNull(LastWorkOrder,0)) 
			from dbo.EMSX with(nolock) 
			where ShopGroup = @ShopGroup and Shop = @Shop 
			Group by ShopGroup,Shop
 		end
 		
 		-- If no LastWorkOrder found, skip this Equip 
 		if IsNull(@NewWO,'')=''
			goto skipcopy
 	end
 	
 	-- Store the number of leading zeros in @NewWO since incrementing process in loop will wipe them out
   	--and they need to be added back to the front of the string after the increment. 
   	-- Strip out any leading spaces from R justification. 
   	select @NumLeadingZeros = 0, @NumLeadingSpaces = 0
   	while substring(@NewWO,@NumLeadingSpaces+1,1) = ' '
   		select @NumLeadingSpaces = @NumLeadingSpaces + 1	

	   	select @NewWOSave = @NewWO, @NewWO = substring(@NewWO,@NumLeadingSpaces+1,len(@NewWO))
   		while substring(@NewWO,@NumLeadingZeros+1,1) = '0'
   		select @NumLeadingZeros = @NumLeadingZeros + 1	

   	select @NewWO = @NewWOSave

tryagain: 
 	--TV 1/16/04 23410 - verfy Formatting
 	select @NewWO = dbo.bfJustifyStringToDatatype(@NewWO,'bWO')

	if exists (select * from dbo.EMWH with(nolock) where EMCo = @EMCo and WorkOrder = @NewWO)
 	begin
 		select @NewWO = @NewWO + 1	
 		-- Before formatting for 'R' justification add back any leading zeros that were lost in
 	   	--the incrementing process. 
 	   	select @x = @NumLeadingZeros
 	   	while @x > 0
 		begin
 	   		select @NewWO = '0' + @NewWO
 	   		select @x = @x - 1
 	   	end

		/* Issue 122308 */
		If Len(@NewWO) = 2 and substring(@NewWO,1,1) = '0'
		begin
			select @NewWO =  substring(@NewWO,2,1) 
		end


-- 	   	if @WOFormatOption = 'R'
-- 	   	begin
-- 	   		select @sp = 10 - len(@NewWO)
-- 	   		while @sp > 0
-- 	   		begin
-- 	   			select @NewWO = ' ' + @NewWO
-- 	   			select @sp = @sp - 1		
-- 	   		end
-- 	   	end
 		goto tryagain
 	end
 		
 	-- Get InvLoc and INCo from bEMSX for @Shop. 
 	select @EMSXInvLoc = InvLoc, @EMSXINCo  = INCo from dbo.EMSX with(nolock)
	
 	where ShopGroup = @ShopGroup and Shop = @Shop
 	
 	-- Create new bEMWH record. Note that Mechanic, DateDue, DateSched, Notes and
 	-- AutoInitSessionID will be set to null by being excluded from insert statement. 
 	insert into dbo.EMWH (EMCo, WorkOrder, Equipment, Shop, Description, InvLoc, 
 	DateCreated, INCo, PRCo, ShopGroup, AutoInitSessionID, Notes, Mechanic, DateDue, DateSched)--TV 07/13/04 25057 - added Date sched and Date due.
 	values (@EMCo, @NewWO, @EquipCopy, @Shop, @EMWHDescription, @EMSXInvLoc, 
 	@date, @EMSXINCo, @EMWHPRCo, @EMWHShopGroup, @AutoInitSessionID, @EMWHNotes, @mechanic, @DateDue, @DateSched)
 	
 	select @WOCreated = @WOCreated + 1
 	-- Start loop on WOItems. Note that StdMaintGroup, StdMaintItem, Mechanic, PartCode, 
 	--SerialNo, DateDue, DateSched, DateCompl and Notes will be set to null by being 
 	--excluded from insert statement. 
 	select @WOItemCopy = min(WOItem) 
 	from dbo.EMWI with(nolock)
 	where EMCo = @EMCo and WorkOrder = @CopyFromWO
 	while @WOItemCopy is not null
 	begin	
 		--  Get values from bEMWI to be copied to new WOItem and all Parts for this WOItem. 
 		select @EMWIComponentTypeCode = ComponentTypeCode, @EMWIComponent  = Component,
 			@EMWIEMGroup = EMGroup, @EMWICostCode = CostCode, @EMWIDescription = Description,
 			@EMWIInHseSubFlag = InHseSubFlag, @EMWIRepairType = RepairType, 
 			@EMWIRepairCode = RepairCode, @EMWIEstHrs = EstHrs, @EMWIQuoteAmt = QuoteAmt,
 			@EMWIPriority = Priority,@EMWIprco = PRCo/*122308*/, @EMWImechanic = Mechanic,
 			@EMWINotes = case when @IncludeNotes = 'Y' then Notes else null end 
 		from dbo.EMWI with(nolock) where EMCo = @EMCo and WorkOrder = @CopyFromWO and WOItem = @WOItemCopy
 		
 		--TV 1/16/04 23410 - verfy Formatting
 		select @NewWO = dbo.bfJustifyStringToDatatype(@NewWO,'bWO')
 		
 		-- Create new bEMWI record. 
 		insert into dbo.EMWI (EMCo, WorkOrder, WOItem, Equipment, ComponentTypeCode,
 			Component, EMGroup, CostCode, Description, InHseSubFlag, StatusCode,
 			RepairType, RepairCode, EstHrs, QuoteAmt, Priority, DateCreated, 
 			CurrentHourMeter, TotalHourMeter, CurrentOdometer, TotalOdometer,
 			FuelUse, Notes, PRCo/*122308*/,Mechanic, DateDue, DateSched)--TV 07/13/04 25057 - added Date sched and Date due.
 		values (@EMCo, @NewWO, @WOItemCopy, @EquipCopy, @EMWIComponentTypeCode,
 			@EMWIComponent, @EMWIEMGroup, @EMWICostCode, @EMWIDescription,
 			@EMWIInHseSubFlag, @WOBegStatus, @EMWIRepairType, @EMWIRepairCode,
 			@EMWIEstHrs, @EMWIQuoteAmt, @EMWIPriority, @date, 0, 0, 0, 0, 
 			0, @EMWINotes, @EMWIprco/*122308*/, @EMWImechanic, @DateDue, @DateSched)
 				
 		-- Start loop on WOParts - use cursor since Material can be alpha numeric. 
 		-- Declare cursor on EMWP. 
 		declare bcWOParts cursor for 
 		select Material, EMGroup, Description, UM, QtyNeeded, PSFlag, Required
 		from dbo.EMWP with(nolock) where EMCo = @EMCo 
 		and WorkOrder = @CopyFromWO 
 		and WOItem = @WOItemCopy 
 		and MatlGroup = @MatlGroup
 		open bcWOParts
 		
 		WOPartsLoop:
 		fetch next from bcWOParts into @EMWPMaterial, @EMWPEMGroup, @EMWPDescription,
 		@EMWPUM, @EMWPQtyNeeded, @EMWPPSFlag, @EMWPRequired
 		while @@fetch_status = 0
 		begin
 			if @EMSXINCo is null
 				select @EMWPInvLoc = null, @EMWPPSFlag = 'P', @EMWPINCo = null 
				
 			
 			--if @EMSXINCo is not null and @EMSXInvLoc is null
			if @EMSXINCo is not null and IsNull(@EMSXInvLoc,'')=''
 				select @EMWPInvLoc = null, @EMWPPSFlag = 'P', @EMWPINCo = @EMSXINCo 
 			
 			--if @EMSXINCo is not null and @EMSXInvLoc is not null
			if @EMSXINCo is not null and IsNull(@EMSXInvLoc,'')<>''
 			begin
 				select @EMWPInvLoc = @EMSXInvLoc, @EMWPINCo = @EMSXINCo
 				if exists (select Material from dbo.INMT with(nolock) where INCo = @EMSXINCo and Loc = @EMSXInvLoc 
 				and MatlGroup = @MatlGroup and Material = @EMWPMaterial)
					 				select @EMWPPSFlag = 'S'
 				else
 					select @EMWPPSFlag = 'P', @EMWPInvLoc = null--TV 04/12/04 23558 if the part is not valid 
 			end
				
			If @EMWPINCo is not null
				--Last chance to get INCo Matl Group
				select @MatlGroup = MatlGroup from dbo.HQCO with(nolock) Where HQCO.HQCo=@EMWPINCo 			
			else
				--If no INCo Company, use HQ Matl Group
				select @MatlGroup = MatlGroup from dbo.HQCO with(nolock) Where HQCO.HQCo=@EMCo 			

 			--TV 1/16/04 23410 - verfy Formatting
 			select @NewWO = dbo.bfJustifyStringToDatatype(@NewWO,'bWO')
 			
 			-- Create new bEMWP record. 
 			insert into dbo.EMWP (EMCo, WorkOrder, WOItem, MatlGroup, Material, Equipment, 
 			EMGroup, PartsStatusCode, InvLoc, Description, UM, QtyNeeded, PSFlag,
 			Required, INCo)
 			values (@EMCo, @NewWO, @WOItemCopy, @MatlGroup, @EMWPMaterial, @EquipCopy,
 			@EMWPEMGroup, @WOPartsBegStatus, @EMWPInvLoc, @EMWPDescription, 
 			@EMWPUM, @EMWPQtyNeeded, @EMWPPSFlag, @EMWPRequired, @EMWPINCo)
 		
 			goto WOPartsLoop
 			
 		end --End WOPartsLoop While
 		
 		-- Close and deallocate cursor 
 		close bcWOParts
 		deallocate bcWOParts
 		
 		select  @WOItemCopy = min(WOItem) 
 		from dbo.EMWI with(nolock)
 		where EMCo = @EMCo and WorkOrder = @CopyFromWO and WOItem > @WOItemCopy
 	end -- End Item Copy
 	
 	
 	-- Keep incrementing until the next available WO is found in EMWH for this EMCo 
IncrementAgain:
	select @updatewo = @NewWO
 	select @NewWO = @NewWO + 1	
    -- Before formatting for 'R' justification add back any leading zeros that were lost in
    --the incrementing process. 
    select @x = @NumLeadingZeros
    while @x > 0
    begin
		select @NewWO = '0' + @NewWO
    	select @x = @x - 1
    end

	/* Issue 122308 */
	If Len(@NewWO) = 2 and substring(@NewWO,1,1) = '0'
	begin
		select @NewWO =  substring(@NewWO,2,1) 
	end

--    if @WOFormatOption = 'R'
--    begin
--    	select @sp = 10 - len(@NewWO)
--    	while @sp > 0
--    		begin
--    		select @NewWO = ' ' + @NewWO
--    		select @sp = @sp - 1		
--    	end
--    end
    
 	--TV 1/16/04 23410 - verfy Formatting
 	select @NewWO = dbo.bfJustifyStringToDatatype(@NewWO,'bWO')
 	if exists (select * from dbo.EMWH with(nolock) where EMCo = @EMCo and WorkOrder = @NewWO) 
 	goto IncrementAgain
 
 	
skipcopy:
 	select @EquipCopy = min(Equipment)
 	from #TargetEquip
 	where Equipment > @EquipCopy
END


--update shop when auot Seq by Shop 
if @autoseqopt = 'C'
begin
 	select @updatewo = dbo.bfJustifyStringToDatatype(@updatewo,'bWO')
	If IsNull(@updatewo,'') <> ''
		update dbo.EMSX set LastWorkOrder = @updatewo where ShopGroup = @ShopGroup and Shop = @Shop
	--else
		--select @ErrMsg = 'Shop: '+ @Shop + ' Last Work Order is null!', @rcode = 1
		--goto bspexit 
end
 
if @autoseqopt = 'E'
begin	
 	select @updatewo = dbo.bfJustifyStringToDatatype(@updatewo,'bWO') 
	If IsNull(@updatewo,'') <> ''
		update dbo.EMCO set LastWorkOrder = @updatewo where EMCo = @EMCo
	--else
		--select @ErrMsg = 'EM Company ' + Convert(varchar(3),@EMCo) +' Last Work Order is null' + IsNull(@updatewo,'??'), @rcode = 1
		--goto bspexit 
end 

 -- return @MaxNewWO 
 select @MaxNewWO = Max(WorkOrder) from dbo.EMWH with(nolock) where AutoInitSessionID = @AutoInitSessionID
 select @MaxNewWO = dbo.bfJustifyStringToDatatype(@MaxNewWO,'bWO')
 

 bspexit:
 
 return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOCopy] TO [public]
GO
