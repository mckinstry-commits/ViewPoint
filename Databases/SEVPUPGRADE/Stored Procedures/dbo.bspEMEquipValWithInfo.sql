SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMEquipValWithInfo    Script Date: 8/28/99 9:32:41 AM ******/
   CREATE   procedure [dbo].[bspEMEquipValWithInfo]
   
   /***********************************************************
    * CREATED BY: JM 8/13/98
    * MODIFIED By : JM 5/9/00 - Added restriction on validation to Status A or D.
    *				TV 02/11/04 - 23061 added isnulls	]
	*				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
    * USAGE:
    *	Validates EMEM.Equipment
    *
    * INPUT PARAMETERS
    *	@emco		EM Company
    *	@equip		Equipment to be validated
    *
    * OUTPUT PARAMETERS
    *	ret val		EMEM column
    *	-------		-----------
    *	@loc		Location
    *	@type		Type
    *	@dept		Department
    *	@category	Category
    *	@status		Status
    *	@odoreading 	OdoReading
    *	@ododate 	OdoDate
    *	@hrreading 	HourReading
    *	@hrdate 	HourDate
    *	@fuelmatlcode 	FuelMatlCode
    *	@fuelused	FuelUsed
    *	@fuelcostcode 	FuelCostCode
    *	@fuelcosttype 	FuelCostType
    *	@lastfueldate 	LastFuelDate
    *	@attachtoequip 	AttachToEquip
    *	@jcco 		JCCo
    *	@job 		Job
    *	@phasegrp 	PhaseGrp
    *	@usgcosttype	UsageCostType
    *	@shop 		Shop
    *	@compofequip	CompOfEquip
    *	@postcosttocomp PostCostToComp
    *	@msg		Description or Error msg if error
     **********************************************************/
   
   
   (@emco bCompany = null,
   @equip bEquip = null,
   @loc bLoc = null output,
   @type char(1) = null output,
   @dept bDept = null output,
   @category char(10)= null output,
   @status char(1) = null output,
   @odoreading bHrs = null output,
   @ododate bDate = null output,
   @hrreading bHrs = null output,
   @hrdate bDate = null output,
   @fuelmatlcode char(20) = null output,
   @fuelused int = null output,
   @fuelcostcode bCostCode = null output,
   @fuelcosttype bEMCType = null output,
   @lastfueldate bDate = null output,
   @attachtoequip bEquip = null output,
   @jcco bCompany = null output,
   @job bJob = null output,
   @phasegrp bGroup = null output,
   @usgcosttype bJCCType = null output,
   @shop char(20) = null output,
   @compofequip bEquip = null output,
   @postcosttocomp bYN = null output,
   @msg varchar(255) output)
   
   as
   
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @emco is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @equip is null
   	begin
   	select @msg = 'Missing Equipment!', @rcode = 1
   	goto bspexit
   	end
   
	--Return if Equipment Change in progress for New Equipment Code - 126196
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
	If @rcode = 1
	begin
		  goto bspexit
	end

   select @loc=Location, @type=Type, @dept=Department, @category=Category,
   	@msg=Description, @status=Status, @odoreading=OdoReading, @ododate=OdoDate,
   	@hrreading=HourReading, @hrdate=HourDate, @fuelmatlcode=FuelMatlCode,
   	@fuelused=FuelUsed, @fuelcostcode=FuelCostCode, @fuelcosttype=FuelCostType,
   	@lastfueldate=LastFuelDate, @attachtoequip=AttachToEquip, @jcco=JCCo,
   	@job=Job, @phasegrp=PhaseGrp, @usgcosttype=UsageCostType, @shop=Shop,
   	@compofequip=CompOfEquip, @postcosttocomp = PostCostToComp
   from bEMEM
   where EMCo = @emco and Equipment = @equip
   	if @@rowcount = 0
   		begin
   		select @msg = 'Equipment invalid!', @rcode = 1
   		end
   
   /* Reject if Status inactive. */
   if @status = 'I'
      begin
      select @msg = 'Equipment Status = Inactive!', @rcode = 1
      goto bspexit
      end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMEquipValWithInfo]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValWithInfo] TO [public]
GO
