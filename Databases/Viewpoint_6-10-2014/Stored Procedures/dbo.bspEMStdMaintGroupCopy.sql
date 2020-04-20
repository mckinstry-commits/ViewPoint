SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE                procedure [dbo].[bspEMStdMaintGroupCopy]
   /*******************************************************************
    * CREATED: 9/15/98 JM
    * LAST MODIFIED: JM 9/15/98 - Added delete statements against target tables;
    *			Added code to copy dependent records from EMSI (Items)
    *			and EMSP (Parts) for each StdMaintGroup copied from EMSH.
    *		JM 12/7/98 - Changed '= null' to 'is null'.
    *      JM 9/1/99 - Made major revisions to logic to install loops within
    *          each dependency rather than copying sets directly. Also added
    *          option to update or replace target SMG Items/Parts with
    *          SaveLastDone option on Item to save meter data when replacing.
    *          Added copy of linked SMG in bEMSL.
    *      JM 11/5/99 - Added revisions to replication of links to bEMSL.
    *      JM 3/15/01 - Temporarily disabled section involving update or replacement of existing 
    *	items/parts to get working version that correctly copies to new SMG to Parsons.
    * 	Made several corrections to looping logic.
    *       JM 7/11/01 - Added delete statements applying to bEMSL
    *	JM 8/6/01 - Ref Issue 14227 - Added error return if @copyfromequip has inactive status.
    *		Added skip of copy to any equipment with inactvie status in range between 
    *		@copytobegequip and @copytoendequip.
    *	09/17/01 JM - Changed creation method for temp tables from 'select * into' to discrete declaration
    *	of specific fields. Also changed inserts into temp tables to discrete declaration of fields. 
    *	Ref Issue 14227.
    *	TV 02/11/04 - 23061 added isnulls
	*		DAN SO 06/18/09 - Issue: #132538 - Added ExpLifeTimeFrame
			AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
    *		JVH 6/9/11 - TK-05982 - Added sql to retrieve the replaceodometerreading and replacehourmeterreading when creating the SMI
	*		GF 01/17/2013 TK-20837 options to copy ud columns for EMSH, EMSI, and EMSP
	*		GF 04/26/2013 TFS-48552 EMSH/EMSI description expanded
	*
	*
    *
    * USAGE:  Called by EMStdMaintCopy form to copy a Std Maint Group (or set)
    *          to either a range of Equipment or an equipment Category. Replicates
    *          links in bEMSL from source to target Equipment.
    *
    * INPUT PARAMS:
    *	@emco				EMSH.EMCo
    *	@copyfromequip		EMSH.Equipment whose StdMaintGroup(s) are to be copied from
    *	@copyfrombegsmg	    	Beginning of range of EMSH.StdMaintGroups to be copied from
    *	@copyfromendsmg	    	Ending of range of EMSH.StdMaintGroups to be copied from
    *	@copytooption			Either 'C' for Category or 'E' for range of Equipment
    *	@copytocategory		EMEM.Category of Equipment that StdMaintGroups are to be copied to
    *	@copytobegequip		Beginning of range of EMSH.Equipment that StdMaintGroups are to be copied to
    *	@copytoendequip		Ending of range of EMSH.Equipment that StdMaintGroups are to be copied to
    *  	@updateoption       		Either 'A' for 'Add New Items/Parts Only' or 'R' for 'Replace Existing Items/Parts'
    *  	@savelastdone       		'Save 'Last Done' Meter Data' at Item level:
    *						if @updateoption = 'R' for 'Replace Existing Items/Parts' - can be either 'Y' or 'N'
    *						if @updateoption = 'A' for 'Add New Items/Parts Only' - not appl so will = 'N'
    *
    * OUTPUT PARAMS:
    *	@rcode		Return code; 0 = success, 1 = failure
    *	@errmsg		Error message; # copied if success, error message if failure
    ********************************************************************/
   (@emco bCompany = null,
   @copyfromequip bEquip = null,
   @copyfrombegsmg varchar(10) = null,
   @copyfromendsmg varchar(10) = null,
   @copytooption char(1) = null,
   @copytocategory varchar(10) = null,
   @copytobegequip bEquip = null,
   @copytoendequip bEquip = null,
   @updateoption char(1),
   @savelastdone char(1),
   ----TK-20837
   @CopyEMSHCustom CHAR(1) = 'N',
   @CopyEMSICustom CHAR(1) = 'N',
   @CopyEMSPCustom CHAR(1) = 'N',
   @errmsg varchar(255) output)
   
   as
   
   set nocount on
   
   /* Initialize general local variables. */
   declare @autodelete bYN,
       @basis char(1),
       @directsmg varchar(10),
       @equipment bEquip,
       @fixeddate bDate,
       @interval int,
       @intervaldays smallint,
       @linkcopy varchar(10),
       @linkedsmg varchar(10),
       @lasthourmeter bHrs,
       @lastodometer bHrs,
       @lastgallons bHrs,
       @lastdonedate bDate,
       @numgrpscopied smallint,
       @rcode int,
       @smgcopy varchar(10),
       @smicopy bItem,
       @smisave bItem,
       @smpcopy bMatl,
       @targetequip bEquip,
       @variance INT,
	----TK-20837     
	@EMSHud_flag bYN,
	@EMSIud_flag bYN,
	@EMSPud_flag bYN,
	@Joins varchar(max),
	@Where varchar(max)


   select @rcode = 0

----TK-20837
SET @EMSHud_flag = 'N'
SET @EMSIud_flag = 'N'
SET @EMSPud_flag = 'N'

---- set the user memo flags for the tables that have user memos
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bEMSH'))
  	SET @EMSHud_flag = 'Y'
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bEMSI'))
  	SET @EMSIud_flag = 'Y'
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bEMSP'))
  	SET @EMSPud_flag = 'Y'



   /* Verify necessary parameters passed. */
   if @emco is null
   	begin
   	select @errmsg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   if @copyfromequip is null
   	begin
   	select @errmsg = 'Missing Copy From Equipment!', @rcode = 1
   	goto bspexit
   	end
   if @copyfrombegsmg is null
   	begin
   	select @errmsg = 'Missing Copy From Beg Maint Group!', @rcode = 1
   	goto bspexit
   	end
   if @copyfromendsmg is null
   	begin
   	select @errmsg = 'Missing Copy From End Maint Group!', @rcode = 1
   	goto bspexit
   	end
   if @copytooption is null
   	begin
   	select @errmsg = 'Missing Copy To Option!', @rcode = 1
   	goto bspexit
   	end
   if @copytocategory is null and @copytooption = 'C'
   	begin
   	select @errmsg = 'Missing Copy To Category!', @rcode = 1
   	goto bspexit
   	end
   if @copytobegequip is null and @copytooption = 'E'
   	begin
   	select @errmsg = 'Missing Copy To Beg Equip!', @rcode = 1
   	goto bspexit
   	end
   if @copytoendequip is null and @copytooption = 'E'
   	begin
   	select @errmsg = 'Missing Copy To End Equip!', @rcode = 1
   	goto bspexit
   	end
   
   /* Make sure @copyfromequip is not inactive. */
   /* Removed 10/17/01per comment from CM in issue 14227 - allow copying from an inactive equip.. 
   if (select Status from  bEMEM where EMCo = @emco and Equipment = @copyfromequip) = 'I'
   	begin
   	select @errmsg = 'Copy from Equipment has Inactive Status!', @rcode = 1
   	goto bspexit
   	end*/
   
   /* Create temp tables for SMG, SMItems, SMParts to be copied, and Linked SMG's. */
   select EMCo, Equipment, Location, Type, Department, Category, Manufacturer, Model, ModelYr, VINNumber, 
   	Description, Status, OdoReading, OdoDate, ReplacedOdoReading, ReplacedOdoDate, HourReading, HourDate, 
   	ReplacedHourReading, ReplacedHourDate, MatlGroup, FuelMatlCode, FuelCapacity, FuelCapUM, FuelUsed, 
   	EMGroup, FuelCostCode, FuelCostType, LastFuelDate, AttachToEquip, AttachPostRevenue, JCCo, Job, 
   	PhaseGrp, UsageCostType, WeightUM, WeightCapacity, VolumeUM, VolumeCapacity, Capitalized, LicensePlateNo, 
   	LicensePlateState, LicensePlateExpDate, IRPFleet, CompOfEquip, ComponentTypeCode, CompUpdateHrs, 
   	CompUpdateMiles, CompUpdateFuel, PostCostToComp, PRCo, Operator, Shop, GrossVehicleWeight, TareWeight, 
   	Height, Wheelbase, NoAxles, Width, OverallLength, HorsePower, TireSize, OwnershipStatus, InServiceDate, ExpLife, ExpLifeTimeFrame,
   	ReplCost, CurrentAppraisal, SoldDate, SalePrice, PurchasedFrom, PurchasePrice, PurchDate, APCo, VendorGroup, 
   	LeasedFrom, LeaseStartDate, LeaseEndDate, LeasePayment, LeaseResidualValue, ARCo, CustGroup, Customer, 
   	CustEquipNo, MSTruckType, RevenueCode, Notes, MechanicNotes, JobDate, FuelType, UpdateYN 
   	into #TargetEquip from bEMEM where 1=2
   
   select EMCo, Equipment, StdMaintGroup, Description, Basis, Interval, IntervalDays, Variance, FixedDateMonth, 
   	FixedDateDay, AutoDelete, Notes  
   	into #GroupsToCopy from bEMSH where 1=2
   
   select EMCo, Equipment, StdMaintGroup, Description, Basis, Interval, IntervalDays, Variance, FixedDateMonth, 
   	FixedDateDay, AutoDelete, Notes 
   	 into #GroupsToCopy1 from bEMSH where 1=2
   
   select EMCo, Equipment, StdMaintGroup, StdMaintItem, EMGroup, CostCode, RepairType, InOutFlag, Description, 
   	EstHrs, EstCost, LastHourMeter, LastOdometer, LastGallons, LastDoneDate, Notes 
   	into #ItemsToCopy from bEMSI where 1=2
   
   select EMCo, Equipment, StdMaintGroup, StdMaintItem, MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required 
   	into #PartsToCopy from bEMSP where 1=2
   
   select EMCo, Equipment, StdMaintGroup, LinkedMaintGrp 
   	into #LinkedSMG1 from bEMSL where 1=2
   
   select EMCo, Equipment, StdMaintGroup, LinkedMaintGrp
   	 into #LinkedSMG2 from bEMSL where 1=2
   
   select EMCo, Equipment, StdMaintGroup, LinkedMaintGrp
   	into #LinksToCopy from bEMSL where 1=2
   
   create table #SaveLastDone (StdMaintItem smallint, LastHourMeter float,
       LastOdometer float, LastGallons float, LastDoneDate smalldatetime)
   
   /* Populate #TargetEquip table from bEMEM - by Category or between the range. */
   if @copytooption = 'C'
       insert into #TargetEquip (EMCo, Equipment, Location, Type, Department, Category, Manufacturer, Model, ModelYr, 
   	VINNumber, Description, Status, OdoReading, OdoDate, ReplacedOdoReading, ReplacedOdoDate,
   	 HourReading, HourDate, ReplacedHourReading, ReplacedHourDate, MatlGroup, FuelMatlCode, FuelCapacity,
   	FuelCapUM, FuelUsed, EMGroup, FuelCostCode, FuelCostType, LastFuelDate, AttachToEquip, AttachPostRevenue, 
   	JCCo, Job, PhaseGrp, UsageCostType, WeightUM, WeightCapacity, VolumeUM, VolumeCapacity, Capitalized, LicensePlateNo, 
   	LicensePlateState, LicensePlateExpDate, IRPFleet, CompOfEquip, ComponentTypeCode, CompUpdateHrs, CompUpdateMiles, 
   	CompUpdateFuel, PostCostToComp, PRCo, Operator, Shop, GrossVehicleWeight, TareWeight, Height, Wheelbase, NoAxles, 
   	Width, OverallLength, HorsePower, TireSize, OwnershipStatus, InServiceDate, ExpLife, ExpLifeTimeFrame, ReplCost, CurrentAppraisal, SoldDate, 
   	SalePrice, PurchasedFrom, PurchasePrice, PurchDate, APCo, VendorGroup, LeasedFrom, LeaseStartDate, LeaseEndDate, 
   	LeasePayment, LeaseResidualValue, ARCo, CustGroup, Customer, CustEquipNo, MSTruckType, RevenueCode, Notes, 
   	MechanicNotes, JobDate, FuelType, UpdateYN)
       select EMCo, Equipment, Location, Type, Department, Category, Manufacturer, Model, ModelYr, VINNumber, Description, 
   	Status, OdoReading, OdoDate, ReplacedOdoReading, ReplacedOdoDate, HourReading, HourDate, ReplacedHourReading, 
   	ReplacedHourDate, MatlGroup, FuelMatlCode, FuelCapacity, FuelCapUM, FuelUsed, EMGroup, FuelCostCode, FuelCostType, 
   	LastFuelDate, AttachToEquip, AttachPostRevenue, JCCo, Job, PhaseGrp, UsageCostType, WeightUM, WeightCapacity, 
   	VolumeUM, VolumeCapacity, Capitalized, LicensePlateNo, LicensePlateState, LicensePlateExpDate, IRPFleet, CompOfEquip, 
   	ComponentTypeCode, CompUpdateHrs, CompUpdateMiles, CompUpdateFuel, PostCostToComp, PRCo, Operator, Shop, 
   	GrossVehicleWeight, TareWeight, Height, Wheelbase, NoAxles, Width, OverallLength, HorsePower, TireSize, OwnershipStatus, 
   	InServiceDate, ExpLife, ExpLifeTimeFrame, ReplCost, CurrentAppraisal, SoldDate, SalePrice, PurchasedFrom, PurchasePrice, PurchDate, APCo, 
   	VendorGroup, LeasedFrom, LeaseStartDate, LeaseEndDate, LeasePayment, LeaseResidualValue, ARCo, CustGroup, Customer, 
   	CustEquipNo, MSTruckType, RevenueCode, Notes, MechanicNotes, JobDate, FuelType, UpdateYN
    from bEMEM
       where EMCo = @emco and Category = @copytocategory
   else
       insert into #TargetEquip (EMCo, Equipment, Location, Type, Department, Category, Manufacturer, Model, ModelYr, 
   	VINNumber,  Description, Status, OdoReading, OdoDate, ReplacedOdoReading, ReplacedOdoDate,
   	 HourReading, HourDate, ReplacedHourReading, ReplacedHourDate, MatlGroup, FuelMatlCode, FuelCapacity,
   	FuelCapUM, FuelUsed, EMGroup, FuelCostCode, FuelCostType, LastFuelDate, AttachToEquip, AttachPostRevenue, 
   	JCCo, Job, PhaseGrp, UsageCostType, WeightUM, WeightCapacity, VolumeUM, VolumeCapacity, Capitalized, LicensePlateNo, 
   	LicensePlateState, LicensePlateExpDate, IRPFleet, CompOfEquip, ComponentTypeCode, CompUpdateHrs, CompUpdateMiles, 
   	CompUpdateFuel, PostCostToComp, PRCo, Operator, Shop, GrossVehicleWeight, TareWeight, Height, Wheelbase, NoAxles, 
   	Width, OverallLength, HorsePower, TireSize, OwnershipStatus, InServiceDate, ExpLife, ExpLifeTimeFrame, ReplCost, CurrentAppraisal, SoldDate, 
   	SalePrice, PurchasedFrom, PurchasePrice, PurchDate, APCo, VendorGroup, LeasedFrom, LeaseStartDate, LeaseEndDate, 
   	LeasePayment, LeaseResidualValue, ARCo, CustGroup, Customer, CustEquipNo, MSTruckType, RevenueCode, Notes, 
   	MechanicNotes, JobDate, FuelType, UpdateYN)

       select EMCo, Equipment, Location, Type, Department, Category, Manufacturer, Model, ModelYr, VINNumber,  Description, 
   	Status, OdoReading, OdoDate, ReplacedOdoReading, ReplacedOdoDate, HourReading, HourDate, ReplacedHourReading, 
   	ReplacedHourDate, MatlGroup, FuelMatlCode, FuelCapacity, FuelCapUM, FuelUsed, EMGroup, FuelCostCode, FuelCostType, 
   	LastFuelDate, AttachToEquip, AttachPostRevenue, JCCo, Job, PhaseGrp, UsageCostType, WeightUM, WeightCapacity, 
   	VolumeUM, VolumeCapacity, Capitalized, LicensePlateNo, LicensePlateState, LicensePlateExpDate, IRPFleet, CompOfEquip, 
   	ComponentTypeCode, CompUpdateHrs, CompUpdateMiles, CompUpdateFuel, PostCostToComp, PRCo, Operator, Shop, 
   	GrossVehicleWeight, TareWeight, Height, Wheelbase, NoAxles, Width, OverallLength, HorsePower, TireSize, OwnershipStatus, 
   	InServiceDate, ExpLife, ExpLifeTimeFrame, ReplCost, CurrentAppraisal, SoldDate, SalePrice, PurchasedFrom, PurchasePrice, PurchDate, APCo, 
   	VendorGroup, LeasedFrom, LeaseStartDate, LeaseEndDate, LeasePayment, LeaseResidualValue, ARCo, CustGroup, Customer, 
   	CustEquipNo, MSTruckType, RevenueCode, Notes, MechanicNotes, JobDate, FuelType, UpdateYN
       from bEMEM
       where EMCo = @emco
           and Equipment >= @copytobegequip and Equipment <= @copytoendequip
   /* Clear any records in #TargetEquip with inactive Status. */
   /* Note: Per CM comment in issue 14227, do not allow copy to an inactive equip. */
   delete #TargetEquip where Status = 'I'
   
   /* Populate #GroupsToCopy1 table from bEMSH within the range.*/
   insert into #GroupsToCopy1(EMCo, Equipment, StdMaintGroup, Description, Basis, Interval, IntervalDays, Variance, FixedDateMonth, 
   	FixedDateDay, AutoDelete, Notes)
   select EMCo, Equipment, StdMaintGroup, Description, Basis, Interval, IntervalDays, Variance, FixedDateMonth, FixedDateDay, AutoDelete, Notes
   from bEMSH
   where EMCo = @emco
       and Equipment = @copyfromequip
       and StdMaintGroup >= @copyfrombegsmg and StdMaintGroup <= @copyfromendsmg
   
   /* Add any SMGs linked to the SMG in the range. */
   /* First get all the base SMG from bEMSL for the EMCo/Equipment. */
   insert into #LinkedSMG1(EMCo, Equipment, StdMaintGroup, LinkedMaintGrp)
       select distinct @emco, @copyfromequip, StdMaintGroup, LinkedMaintGrp
       from bEMSL
       where EMCo = @emco
           and Equipment = @copyfromequip
           and StdMaintGroup >= @copyfrombegsmg and StdMaintGroup <= @copyfromendsmg
   
   /* Add all the Linked SMG from bEMSL for the EMCo/Equipment. */
   --#142278
   INSERT   INTO #LinkedSMG1
            ( EMCo,
              Equipment,
              StdMaintGroup,
              LinkedMaintGrp
            )
            SELECT DISTINCT
                    @emco,
                    @copyfromequip,
                    T.StdMaintGroup,
                    T.LinkedMaintGrp
            FROM    dbo.bEMSL L
                    JOIN #LinkedSMG1 T ON L.EMCo = T.EMCo
										AND L.Equipment = T.Equipment
										AND L.StdMaintGroup = T.LinkedMaintGrp
   
   /* Eliminate any duplicates by copying a distinct select into
   another temp table. */
   insert into #LinkedSMG2 (EMCo, Equipment, StdMaintGroup, LinkedMaintGrp)
   	select distinct EMCo, Equipment, StdMaintGroup, LinkedMaintGrp 
   	from #LinkedSMG1 
   	order by LinkedMaintGrp
   
   /* Loop thru Linked SMG's and add any to #GroupsToCopy1 that
   aren't there yet. */
   select @linkedsmg=min(LinkedMaintGrp) from #LinkedSMG2
   while @linkedsmg is not null
       begin
       if not exists (select * from #GroupsToCopy1 where StdMaintGroup = @linkedsmg)
           insert into #GroupsToCopy1(EMCo, Equipment, StdMaintGroup, Description, Basis, Interval, 
   	IntervalDays, Variance, FixedDateMonth, FixedDateDay, AutoDelete, Notes)
           select EMCo, Equipment, StdMaintGroup, Description, Basis, Interval, IntervalDays, Variance, 
   	FixedDateMonth, FixedDateDay, AutoDelete, Notes 
           from bEMSH
           where EMCo = @emco
               and Equipment = @copyfromequip
               and StdMaintGroup = @linkedsmg
       /* Get the next LinkedMaintGrp to copy from #LinkedSMG2. */
       select @linkedsmg=min(LinkedMaintGrp)
       from #LinkedSMG2
       where LinkedMaintGrp > @linkedsmg
       end
   
   /* Create final sorted list by selecting against #GroupsToCopy1 with an order by clause. */
   insert into #GroupsToCopy (EMCo, Equipment, StdMaintGroup, Description, Basis, Interval, 
   	IntervalDays, Variance, FixedDateMonth, FixedDateDay, AutoDelete, Notes)
   	select EMCo, Equipment, StdMaintGroup, Description, Basis, Interval, IntervalDays, Variance, 
   		FixedDateMonth, FixedDateDay, AutoDelete, Notes
   	 from #GroupsToCopy1 
   	order by StdMaintGroup
   
   /* Now that we have a complete list of SMG to copy, start the loops. */
   /* Loop thru SMG to copy. */
   select @smgcopy=min(StdMaintGroup) from #GroupsToCopy
   while @smgcopy is not null
       begin
   	/* Loop thru target Equipment. */
   	select @targetequip=min(Equipment) from #TargetEquip
   	while @targetequip is not null
   	begin
   	
   		/* If the SMG already exists, run subroutine to add new items/parts or replace entirely. Otherwise create new SMG. */
   		if exists(select * from bEMSH where EMCo = @emco and Equipment = @targetequip and StdMaintGroup = @smgcopy)
   			BEGIN
			----TK-20837          
   			exec @rcode =  bspEMStdMaintGroupCopyPreexisting @emco, @copyfromequip, @targetequip, @smgcopy,
							@updateoption, @savelastdone, @EMSIud_flag, @EMSPud_flag, @CopyEMSICustom,
							@CopyEMSPCustom, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = 'Std Maint Group Process failed-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		else
   			begin
   				/* Insert into bEMSH for EMCo, target Equipment and SMG copy. */
   				insert into bEMSH (EMCo, Equipment, StdMaintGroup, Description, Basis, Interval, IntervalDays, 
   					Variance, FixedDateMonth, FixedDateDay, AutoDelete, Notes)
   				select @emco, @targetequip, @smgcopy, Description, Basis, Interval, IntervalDays, Variance,
   					 FixedDateMonth, FixedDateDay, AutoDelete, Notes
   				from #GroupsToCopy
   				where EMCo = @emco and Equipment = @copyfromequip and StdMaintGroup = @smgcopy
   				----TK-20837
				IF @@ROWCOUNT <> 0 and @EMSHud_flag = 'Y' AND @CopyEMSHCustom = 'Y'
					BEGIN
  					-- build joins and where clause
  					select @Joins = ' from EMSH join EMSH z with (nolock) on z.EMCo = ' + convert(varchar(3),@emco) 
  									+ ' and z.Equipment = ' + CHAR(39) + @copyfromequip + CHAR(39) 
  									+ ' and z.StdMaintGroup = ' + CHAR(39) + @smgcopy + CHAR(39)
  					select @Where = ' where EMSH.EMCo = ' + convert(varchar(3),@emco) 
  									+ ' and EMSH.Equipment = ' + CHAR(39) + @targetequip + CHAR(39) 
  									+ ' and EMSH.StdMaintGroup = ' + CHAR(39) + @smgcopy + CHAR(39)
  					-- execute user memo update
  					exec @rcode = bspPMProjectCopyUserMemos 'EMSH', @Joins, @Where, @errmsg output
  					END

   				/* Insert into bEMSI for EMCo, target Equipment and SMG copy;
   				set LastDone columns to 0 since this is a brand new SMG. */
   				insert into bEMSI (EMCo, Equipment, StdMaintGroup, StdMaintItem, EMGroup, CostCode, RepairType, InOutFlag, Description, EstHrs, EstCost, 
   					LastHourMeter, LastReplacedHourMeter, LastOdometer, LastReplacedOdometer, LastGallons, LastDoneDate, Notes)
   				select @emco, @targetequip, @smgcopy, StdMaintItem, bEMSI.EMGroup, CostCode, RepairType, InOutFlag, bEMSI.[Description], EstHrs, EstCost, 0, bEMEM.ReplacedHourReading, 0, bEMEM.ReplacedOdoReading, 0, null, bEMSI.Notes
   				from bEMSI
   				LEFT JOIN bEMEM ON bEMEM.EMCo = @emco AND bEMEM.Equipment = @targetequip
   				where bEMSI.EMCo = @emco and bEMSI.Equipment = @copyfromequip and StdMaintGroup = @smgcopy
   				----TK-20837
				IF @@ROWCOUNT <> 0 and @EMSIud_flag = 'Y' AND @CopyEMSICustom = 'Y'
					BEGIN
  					-- build joins and where clause
  					select @Joins = ' from EMSI join EMSI z with (nolock) on z.EMCo = ' + convert(varchar(3),@emco) 
  									+ ' and z.Equipment = ' + CHAR(39) + @copyfromequip + CHAR(39) 
  									+ ' and z.StdMaintGroup = ' + CHAR(39) + @smgcopy + CHAR(39)
									+ ' AND z.StdMaintItem = EMSI.StdMaintItem'
  					select @Where = ' where EMSI.EMCo = ' + convert(varchar(3),@emco) 
  									+ ' and EMSI.Equipment = ' + CHAR(39) + @targetequip + CHAR(39) 
  									+ ' and EMSI.StdMaintGroup = ' + CHAR(39) + @smgcopy + CHAR(39)
  					-- execute user memo update
  					exec @rcode = bspPMProjectCopyUserMemos 'EMSI', @Joins, @Where, @errmsg output
  					END



   				/* Insert into bEMSP for EMCo, target Equipment and SMG copy. */
   				insert into bEMSP (EMCo, Equipment, StdMaintGroup, StdMaintItem, MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required)
   				select @emco, @targetequip, @smgcopy, StdMaintItem, MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required
   				from bEMSP
   				where EMCo = @emco and Equipment = @copyfromequip and StdMaintGroup = @smgcopy
   				----TK-20837
				IF @@ROWCOUNT <> 0 and @EMSPud_flag = 'Y' AND @CopyEMSPCustom = 'Y'
					BEGIN
  					-- build joins and where clause
  					select @Joins = ' from EMSP join EMSP z with (nolock) on z.EMCo = ' + convert(varchar(3),@emco) 
  									+ ' and z.Equipment = ' + CHAR(39) + @copyfromequip + CHAR(39) 
  									+ ' and z.StdMaintGroup = ' + CHAR(39) + @smgcopy + CHAR(39)
									+ ' AND z.StdMaintItem = EMSP.StdMaintItem'
									+ ' AND z.MatlGroup = EMSP.MatlGroup'
									+ ' AND z.Material = EMSP.Material'
  					select @Where = ' where EMSP.EMCo = ' + convert(varchar(3),@emco) 
  									+ ' and EMSP.Equipment = ' + CHAR(39) + @targetequip + CHAR(39) 
  									+ ' and EMSP.StdMaintGroup = ' + CHAR(39) + @smgcopy + CHAR(39)
  					-- execute user memo update
  					exec @rcode = bspPMProjectCopyUserMemos 'EMSP', @Joins, @Where, @errmsg output
  					END
   			end
   		
   	/* Get the next target Equipment. */
   	select @targetequip=min(Equipment)
   	from #TargetEquip
   	where Equipment > @targetequip
   	end
   
   /* Get the next StdMaintGroup to copy from #GroupsToCopy. */
   select @smgcopy=min(StdMaintGroup)
   from #GroupsToCopy
   where StdMaintGroup > @smgcopy
   end
   
   /* Now that the SMG's exist for the target equip, copy the links so triggers won't block operation.  */
   select @smgcopy=min(StdMaintGroup) from #GroupsToCopy
   select @smgcopy as '@smgcopy'
   while @smgcopy is not null
   	begin
   
   	select @targetequip=min(Equipment) from #TargetEquip
   	select @targetequip as '@targetequip'
   	while @targetequip is not null
   		begin
   
   		/* Add records to bEMSL for the @targetequip/@smgcopy. */
   		/* Clear any records in #LinksToCopy. */
   		delete #LinksToCopy
   		
   		/* Fill #LinksToCopy with Links for bEMSL.LinkedMaintGrp = source SMG. */
   		insert into #LinksToCopy (EMCo, Equipment, StdMaintGroup, LinkedMaintGrp)
   		select EMCo, Equipment, StdMaintGroup, LinkedMaintGrp 
   		from bEMSL
   		where EMCo = @emco and Equipment = @copyfromequip and StdMaintGroup = @smgcopy
   		select * from #LinksToCopy
   		
   		/* Loop thru #LinksToCopy adding any links to the target
   		equipment that arent already there. */
   		select @linkcopy=min(LinkedMaintGrp) from #LinksToCopy
   		select @linkcopy as '@linkcopy'
   		while @linkcopy is not null
   			begin
   			if exists(select * from bEMSH where EMCo = @emco and Equipment = @targetequip and StdMaintGroup = @linkcopy)
   				begin
   				select 'SMG ' + isnull(convert(varchar(3),@linkcopy),'') + ' exists in bEMSH for @targetequip ' + isnull(@targetequip,'') + ' so ok to insert in bEMSL'
   				if not exists (select * from bEMSL where EMCo = @emco and Equipment = @targetequip and StdMaintGroup = @smgcopy and LinkedMaintGrp = @linkcopy)
   					insert bEMSL (EMCo, Equipment, StdMaintGroup, LinkedMaintGrp)
   					values (@emco, @targetequip, @smgcopy, @linkcopy)
   				end
   			else
   				select 'SMG ' + isnull(convert(varchar(3),@linkcopy),'') + ' does not exist in bEMSH for @targetequip ' + isnull(@targetequip,'') + ' so dont insert in bEMSL'
   			
   			/* Get the next Link to copy from #LinksToCopy. */
   			select @linkcopy=min(LinkedMaintGrp)
   			from #LinksToCopy
   			where LinkedMaintGrp > @linkcopy
   			end
   		select * from bEMSL
   
   		select @targetequip=min(Equipment)
   		from #TargetEquip
   		where Equipment > @targetequip
   		end
   
   	select @smgcopy=min(StdMaintGroup)
   	from #GroupsToCopy
   	where StdMaintGroup > @smgcopy
   	end
   
   bspexit:
   
   if @rcode<>0 select @errmsg=isnull(@errmsg,'')
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMStdMaintGroupCopy] TO [public]
GO
