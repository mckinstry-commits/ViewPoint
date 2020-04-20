SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                  procedure [dbo].[bspEMSeqValForCompXfer]
   /***********************************************************
    * CREATED BY: JM 2-07-02 - For revised form design.
    * MODIFIED By : kb 11/4/2 - issue #10135 changed to not send CurrentSeq
    * and to generate the PriorSeq
    *				TV 02/11/04 - 23061 added isnulls
    *				GF 09/09/2010 - issue #141031 changed to use function vfDateOnly
    * USAGE:
    *	Returns:
    *		Next avail Seq
    *		Current Date to DateOn and DateOff
    *		Current Component TotHrs, TotMiles Fuel from bEMEM to Date On line inputs
    *		Current Component TotHrs, TotMiles Fuel from bEMEM to Date Off line inputs
    *		Prior Master Equipment and Desc from bEMEM to Prior Master Equip  labels
    *		Current Prior Master Equip TotHrs, TotMiles, Fuel to Date Off inputs
    *
    * INPUT PARAMETERS
    *	@EMCo		EM Company to be validated against
    *	@Component	Component associated with the Seq
    *
    * OUTPUT PARAMETERS with Return values to form inputs
    *
    *	@CurrDate
    *	@ComponentTotHourReading
    *	@ComponentTotOdoReading
    *	@ComponentFuelUsed
    *	@PriorEquip
    *	@PriorEquipDesc
    *	@PriorEquipTotHourReading
    *	@PriorEquipTotOdoReading
    *	@PriorEquipFuelUsed
    *
     * RETURN VALUE
    *	0 success
    *	1 error
    *	
    ***********************************************************/
   
   (@EMCo bCompany = null,
   @Component bEquip = null,
   @CurrentSeq varchar(20) = null, --issue #10135
   @NextAvailSeq int = null output,
   @CurrDate bDate output,
   @ComponentTotHourReading bHrs output,
   @ComponentTotOdoReading bHrs output,
   @ComponentFuelUsed bUnits output,
   @PriorEquip bEquip output,
   @PriorEquipDesc bDesc output,
   @PriorEquipTotHourReading bHrs output,
   @PriorEquipTotOdoReading bHrs output,
   @PriorEquipFuelUsed bUnits output,
   @CompOfEquipTotHourReading bHrs output,
   @CompOfEquipTotOdoReading bHrs output,
   @CompOfEquipFuelUsed bUnits output,
   @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare 	@rcode int,
   	@CompOfEquip bEquip,
   	@ComponentHourReading bHrs,
   	@ComponentOdoReading bHrs,
   	@ComponentReplacedHourReading bHrs,
   	@ComponentReplacedOdoReading bHrs,
   	@PriorEquipHourReading bHrs,
   	@PriorEquipOdoReading bHrs,
   	@PriorEquipReplacedHourReading bHrs,
   	@PriorEquipReplacedOdoReading bHrs,
   	@CompOfEquipHourReading bHrs,
   	@CompOfEquipOdoReading bHrs,
   	@CompOfEquipReplacedHourReading bHrs,
   	@CompOfEquipReplacedOdoReading bHrs,
   	@PriorSeq int
   
   select @rcode = 0
   
   if @EMCo is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   if @Component is null
   	begin
   	select @msg = 'Missing Component!', @rcode = 1
   	goto bspexit
   	end
   /*if @CurrentSeq is null
   	begin
   	select @msg = 'Missing Seqt!', @rcode = 1
   	goto bspexit
   	end*/
   
   /* Ref Issue 17115 - Don't allow Component to be transferred if it exists on an open WOItem. */
   if exists (select * from bEMWI where EMCo = @EMCo and Equipment = @Component 
   	and StatusCode not in (select StatusCode from bEMWS where EMGroup = (select EMGroup from bHQCO where HQCo = @EMCo)  and StatusType = 'F'))
   	begin
   	select @msg = 'Component exists on an open WOItem!', @rcode = 1
   	goto bspexit
   	end
   
   /* Get next Seq */
   select @NextAvailSeq = isnull(Max(Seq),0) + 1 from bEMHC where EMCo = @EMCo and Component = @Component
   
   /* Get Current Date */
   ----#141031
   select @CurrDate = dbo.vfDateOnly()
   
   /* Get info from bEMEM for Component and calc totals for hours and odo */
   select  @CompOfEquip = CompOfEquip,
   	@ComponentHourReading = HourReading,
   	@ComponentOdoReading = OdoReading,
   	@ComponentFuelUsed = FuelUsed,
   	@ComponentReplacedHourReading = ReplacedHourReading,
   	@ComponentReplacedOdoReading = ReplacedOdoReading
   from bEMEM where EMCo = @EMCo and Equipment = @Component
   select @ComponentTotHourReading = @ComponentHourReading + @ComponentReplacedHourReading,
   	@ComponentTotOdoReading = @ComponentOdoReading + @ComponentReplacedOdoReading
   
   if @NextAvailSeq = 1
   	begin
   	/* Get Transfer To Equip meter info */
   	select @CompOfEquipHourReading = HourReading,
   		@CompOfEquipOdoReading = OdoReading,
   		@CompOfEquipFuelUsed = FuelUsed,
   		@CompOfEquipReplacedHourReading = ReplacedHourReading,
   		@CompOfEquipReplacedOdoReading = ReplacedOdoReading
   	from bEMEM where EMCo = @EMCo and Equipment = @CompOfEquip
   	select @CompOfEquipTotHourReading = @CompOfEquipHourReading + @CompOfEquipReplacedHourReading,
   		@CompOfEquipTotOdoReading = @CompOfEquipOdoReading + @CompOfEquipReplacedOdoReading
   	/* Set all prior info to null */
   	select  @PriorEquip = Equipment, @PriorEquipDesc = Description from bEMEM where EMCo = @EMCo and Equipment = @CompOfEquip
   	select @PriorEquipTotHourReading = null, @PriorEquipTotOdoReading = null, @PriorEquipFuelUsed = null
   	end
   else
   	begin
   	/* Get PriorEquip for this Component's ComponentOfEquip in bEMHC for last sequence */
   if isnumeric(@CurrentSeq) = 1 
   	begin
   	select @PriorEquip = ComponentOfEquip from bEMHC where EMCo = @EMCo and Component = @Component
   		and Seq = @CurrentSeq -1
   	end
   else
   	begin
   	select @PriorSeq = isnull(max(Seq),1) from bEMHC where EMCo = @EMCo and Component = @Component
   	select @PriorEquip = ComponentOfEquip from bEMHC where EMCo = @EMCo and Component = @Component
   		and Seq = @PriorSeq 
   	end
   
   	/* Get info from bEMEM for PriorEquip and calc totals for hours and odo */
   	select  @PriorEquipDesc = Description,
   		@PriorEquipHourReading = HourReading,
   		@PriorEquipOdoReading = OdoReading,
   		@PriorEquipFuelUsed = FuelUsed,
   		@PriorEquipReplacedHourReading = ReplacedHourReading,
   		@PriorEquipReplacedOdoReading = ReplacedOdoReading
   	from bEMEM where EMCo = @EMCo and Equipment = @PriorEquip
   	select @PriorEquipTotHourReading = @PriorEquipHourReading + @PriorEquipReplacedHourReading,
   		@PriorEquipTotOdoReading = @PriorEquipOdoReading + @PriorEquipReplacedOdoReading
   	end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMSeqValForCompXfer]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMSeqValForCompXfer] TO [public]
GO
