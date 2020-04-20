SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMEquipValForCompXfer    Script Date: 2/25/2002 4:05:26 PM ******/
   
   /****** Object:  Stored Procedure dbo.bspEMEquipValForCompXfer    Script Date: 2/8/2002 3:36:31 PM ******/
   
   CREATE          procedure [dbo].[bspEMEquipValForCompXfer]
   /***********************************************************
    * CREATED BY: JM 1-2-02 - For revised form design.
    * MODIFIED By : kb 11/4/2 - issue #10135 changed to not use the Seq unless it is numeric
    *				TV 02/11/04 - 23061 added isnulls	
	*				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
    * USAGE:
    *	Validates Component's new MasterEquip vs bEMEM and returns meter info.
    *
    * INPUT PARAMETERS
    *	@EMCo			EM Company to be validated against
    *	@Equip		Equipment to be validated
    *
    * OUTPUT PARAMETERS with Return values to form inputs
    *
    *	@Tot_Fuel -- bEMEM.FuelUsed
    *	@Tot_Hours -- @Hour_Reading + @Repl_Hour_Reading
    *	@Tot_Odo -- @Odo_Reading + @Repl_Odo_Reading
    *	@msg -- Error or Description of Equipment
    *
    * RETURN VALUE
    *	0 success
    *	1 error
    *	
    ***********************************************************/
   
   (@EMCo bCompany = null,
   @Equip bEquip = null,
   @Component bEquip = null,
   @Seq varchar(20) = null,
   @Tot_Hours bHrs = 0 output,
   @Tot_Odo bHrs = 0 output,
   @Tot_Fuel bUnits = 0 output,
   @StatusMsg varchar(50) = null output,
   @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int,
   	@Type char(1),
   	@Hour_Reading bHrs,
   	@Odo_Reading bHrs,
   	@Fuel_Used bUnits, 
   	@Repl_Hour_Reading bHrs,
   	@Repl_Odo_Reading bHrs,
   	@Curr_Equip bEquip,
   	@status char(1),
   	@numrows int
   
   select @rcode = 0
   
   if @EMCo is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   if @Equip is null
   	begin
   	select @msg = 'Missing Equipment!', @rcode = 1
   	goto bspexit
   	end
   if @Component is null
   	begin
   	select @msg = 'Missing Component!', @rcode = 1
   	goto bspexit
   	end
   if @Seq is null
   	begin
   	select @msg = 'Missing Seq!', @rcode = 1
   	goto bspexit
   	end
   
   /* Make sure user isn't changing ComponentOfEquip for an existing record. */
   if isnumeric(@Seq)=1
   	begin
   	select @Curr_Equip = ComponentOfEquip from bEMHC where EMCo = @EMCo and Component = @Component and Seq = @Seq
   	if @Curr_Equip is not null
   		begin
   		if @Equip <> @Curr_Equip
   			begin
   			select @msg = 'Cannot change ' + '''' + 'Transfer To Equip' + '''' + ' for and existing record!', @rcode = 1
   			goto bspexit
   			end
   		end
   	end
   
	--Return if Equipment Change in progress for New Equipment Code
	exec @rcode = vspEMEquipChangeInProgressVal @EMCo, @Equip, @msg output
	If @rcode = 1
	begin
		  goto bspexit
	end

   /* Validae Equipment vs EMEM - allow inactive status but give warning. */
   select  @msg=Description, @status = Status
   from bEMEM
   where EMCo = @EMCo and Equipment = @Equip
   select @numrows = @@rowcount
   if @numrows = 0
   	begin
   	select @msg = 'Equipment invalid!', @rcode = 1
   	goto bspexit
   	end
   if @status = 'I'
   	select @StatusMsg = 'Warning: Status = Inactive!'
   else
   	select @StatusMsg = null
   

   /* See if it is a component by EMEM.Type='C'; also, read Desc and meter info. */
   select  @msg = Description, 
   	@Type = Type, 
   	@Hour_Reading = HourReading,
   	@Odo_Reading = OdoReading,
   	@Fuel_Used = FuelUsed,
   	@Repl_Hour_Reading = ReplacedHourReading,
   	@Repl_Odo_Reading = ReplacedOdoReading
   from bEMEM where EMCo = @EMCo and Equipment = @Equip
   
   /* Reject if a Component. */
   if @Type = 'C'
   	begin
   	select @msg = 'Equip cannot be a Component!', @rcode = 1
   	goto bspexit
   	end
   
   /* Calc totals for return to form */
   select  @Tot_Hours = @Hour_Reading + @Repl_Hour_Reading,
   	@Tot_Odo = @Odo_Reading + @Repl_Odo_Reading,
   	@Tot_Fuel = @Fuel_Used
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMEquipValForCompXfer]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValForCompXfer] TO [public]
GO
