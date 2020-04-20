SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMEquipValForStdMaintGroups    Script Date: 11/2/2001 11:20:08 AM ******/
   CREATE   procedure [dbo].[bspEMEquipValForStdMaintGroups]
   
    /***********************************************************
     * CREATED BY: JM 11/2/01
     * MODIFIED By : TV 02/11/04 - 23061 added isnulls	
	 *				 TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
     *
     * USAGE: Validates EMEM.Equipment and returns Equip info for form display
     *
     * INPUT PARAMETERS
     *	@emco		EM Company
     *	@equip		Equipment to be validated
     *
     * OUTPUT PARAMETERS
     *	ret val			EMEM column
     *	-------			-----------
     *	@status		Status
     *	@odoreading 		OdoReading
     *	@ododate 		OdoDate
     *	@replodoreading 	ReplacedOdoReading
     *	@replododate 		ReplacedOdoDate
     *	@hourreading 		HourReading
     *	@hourdate 		HourDate
     *	@replhourreading 	ReplacedHourReading
     *	@replhourdate 		ReplacedHourDate
     *	@fuelused		FuelUsed
     *	@lastfueldate 		LastFuelDate
     *	@shop 			Shop
     *	@purchdate		PurchDate
     *	@loc			Location
     *	@dept			Department
     *	@category		Category
     *	@msg		Description or Error msg if error
      **********************************************************/
   
   
    (@emco bCompany = null,
    @equip bEquip = null,
    @status char(1) = null output,
    @odoreading bHrs = null output,
    @ododate bDate = null output,
    @replodoreading bHrs = null output,
    @replododate bDate = null output,
    @hourreading bHrs = null output,
    @hourdate bDate = null output,
    @replhourreading bHrs = null output,
    @replhourdate bDate = null output,
    @fuelused int = null output,
    @lastfueldate bDate = null output,
    @shop char(20) = null output,
    @purchdate bDate = null output,
    @loc bLoc = null output,
    @dept bDept = null output,
    @category char(10)= null output,
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

    select @msg=Description, @status=Status,
   	@odoreading=OdoReading, @ododate=OdoDate,
   	@replodoreading=ReplacedOdoReading, @replododate=ReplacedOdoDate,
    	@hourreading=HourReading, @hourdate=HourDate,
    	@replhourreading=ReplacedHourReading, @replhourdate=ReplacedHourDate,
   	@fuelused=FuelUsed, @lastfueldate=LastFuelDate,
    	@shop=Shop, @purchdate=PurchDate,
   	@loc=Location, @dept=Department, @category=Category
    from bEMEM
    where EMCo = @emco and Equipment = @equip
   
    if @@rowcount = 0 select @msg = 'Equipment invalid!', @rcode = 1
   
    /* Reject if Status inactive. */
    if @status = 'I'
       begin
       select @msg = 'Equipment Status = Inactive!', @rcode = 1
       goto bspexit
       end
   
    bspexit:
    	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) +'[bspEMEquipValForStdMaintGroups]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValForStdMaintGroups] TO [public]
GO
