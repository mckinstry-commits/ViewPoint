SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE             procedure [dbo].[bspEMComponentValForCompXfer]
   /***********************************************************
    * CREATED BY: JM 12/19/01
    * MODIFIED By : JM 1-2-02 - For revised form design.
    *		JM 4-29-02 - Ref Issue 17115 - Don't allow Component to be transferred if it exists on an open WOItem.
    *		TV 02/11/04 - 23061 added isnulls
    * USAGE:
    *	Validates Component vs bEMEM and returns Desc or err msg
    *	plus meter info for Component.
    *
    * INPUT PARAMETERS
    *	@EMCo			EM Company to be validated against
    *	@Component		Component to be validated
    *
    * RETURN VALUE
    *	0 success
    *	1 error
    *	
    ***********************************************************/
   (@EMCo bCompany = null,
   @Component bEquip = null, --0
   @Seq int = null output, --260
   @Comp_Tot_Hours bHrs = 0 output, --210
   @Comp_Tot_Odo bHrs = 0 output, --220
   @Comp_Tot_Fuel bHrs = 0 output, --230
   @Prior_Master_Equip bEquip = null output, --240
   @Prior_Master_Equip_Desc bDesc = null output, --250
   @Prior_Master_Equip_Tot_Odo bHrs = 0 output, --270
   @Prior_Master_Equip_Tot_Hours bHrs = 0 output, --280
   @Prior_Master_Equip_Tot_Fuel bUnits = 0 output, --290
   @Transfer_To_Equip bEquip = null output,
   @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @EMGroup bGroup,
   	@rcode int,
   	@Type char(1),
   	@numrows int,
   	@Comp_Hours bHrs,
   	@Comp_Repl_Hours bHrs,
   	@Comp_Odo bHrs,
   	@Comp_Repl_Odo bHrs,
   	@Comp_Fuel bUnits,
   	@Prior_Master_Equip_Odo bHrs,
   	@Prior_Master_Equip_Repl_Odo bHrs,
   	@Prior_Master_Equip_Hours bHrs,
   	@Prior_Master_Equip_Repl_Hours bHrs,
   	@Prior_Master_Equip_Fuel bUnits,
   	@Prior_Seq int
   
   select @rcode = 0,
   	@Comp_Hours = 0,
   	@Comp_Repl_Hours = 0,
   	@Comp_Odo = 0,
   	@Comp_Repl_Odo = 0,
   	@Comp_Fuel = 0
   
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
   
   /* Basic validation of Component vs EMEM. */
   exec @rcode = bspEMEquipVal @EMCo, @Component, @msg = @msg output
   if @rcode = 1
   	goto bspexit
   
   /* Ref Issue 17115 - Don't allow Component to be transferred if it exists on an open WOItem. */
   if exists (select * from bEMWI where EMCo = @EMCo and Equipment = @Component 
   	and StatusCode not in (select StatusCode from bEMWS where EMGroup = (select EMGroup from bHQCO where HQCo = @EMCo)  and StatusType = 'F'))
   	begin
   	select @msg = 'Component exists on an open WO Item!', @rcode = 1
   	goto bspexit
   	end
   
   /* See if it is a component by EMEM.Type='C'; also, read Desc, ComponentOfEquip (MasterEquip) and 
   meter readings for Component. */
   select  @msg = Description, @Type = Type from bEMEM where EMCo = @EMCo and Equipment = @Component
   
   /* Reject if not a Component. */
   if @Type <> 'C'
   	begin
   	select @msg = 'Not a Component in EMEM!', @rcode = 1
   	goto bspexit
   	end
   
   /* Get Component's current meter readings */
   select @Comp_Odo = OdoReading, 
   	@Comp_Repl_Odo = ReplacedOdoReading,
   	@Comp_Hours = HourReading,
   	@Comp_Repl_Hours = ReplacedHourReading,
   	@Comp_Fuel = FuelUsed
   from bEMEM where EMCo = @EMCo and Equipment = @Component
   
   /* Calc total hours and miles for Component */
   select @Comp_Tot_Odo = @Comp_Repl_Odo + @Comp_Odo,
   	@Comp_Tot_Hours = @Comp_Repl_Hours + @Comp_Hours,
   	@Comp_Tot_Fuel = @Comp_Fuel
   
   /* If this is first entry in EMHC, default Seq = 1 and send back Prior_Master_Equip info from EMEM */
   if not exists(select * from bEMHC where EMCo = @EMCo and Component = @Component)
   	begin
   	select @Seq = 1
   	select @Prior_Master_Equip = CompOfEquip from bEMEM where EMCo = @EMCo and Equipment = @Component
   	--select @Prior_Master_Equip_Desc = Description from bEMEM where EMCo = @EMCo and Equipment = @Prior_Master_Equip
   	/* Now set Transfer to Equip to Prior Master Equip and null out Prior Master Equip */
   	select @Transfer_To_Equip = @Prior_Master_Equip, @Prior_Master_Equip = null,@Prior_Master_Equip_Desc = null
   
   /*	select @Prior_Master_Equip_Tot_Odo = @Prior_Master_Equip_Repl_Odo + @Prior_Master_Equip_Odo,
   		@Prior_Master_Equip_Tot_Hours = @Prior_Master_Equip_Repl_Hours + @Prior_Master_Equip_Hours,
   		@Prior_Master_Equip_Tot_Fuel = @Prior_Master_Equip_Fuel*/
   	end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMComponentValForCompXfer]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMComponentValForCompXfer] TO [public]
GO
