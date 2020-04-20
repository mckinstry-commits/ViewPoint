SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspEMEquipValForMeterReadingsChangedDeleted]
   
   /***********************************************************
    * CREATED BY: JM 10/24/00
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls	
	*				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
    *
    * USAGE:
    *	Validates EMEM.Equipment for batch validation procedure
    *  bspEMVal_Meters_ChangedDeleted.
    *
    * INPUT PARAMETERS
    *	@emco		EM Company
    *	@equip		Equipment to be validated
    *
    * OUTPUT PARAMETERS
    *	ret val					EMEM column
    *	-------					-----------
    *	@msg					Description or Error msg if error
     **********************************************************/
   
   (@emco bCompany = null,
   @equip bEquip = null,
   @msg varchar(255) output)
   
   as
   
   set nocount on
   declare @rcode int, @status char(1), @numrows smallint
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
   
   /* Get all info from bEMEM, assuming that @emtrans is null
   and Hour/Odo info will come from bEMEM. */
   select @msg=Description, @status=Status
   from bEMEM
   where EMCo = @emco and Equipment = @equip
   select @numrows = @@rowcount
   if @numrows = 0
   	begin
   	select @msg = 'Equipment invalid!', @rcode = 1
      goto bspexit
   	end
   
   
   /* Reject if Status inactive. */
   if @status = 'I'
      begin
      select @msg = 'Equipment Status = Inactive!', @rcode = 1
      goto bspexit
      end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMEquipValForMeterReadingsChangedDeleted]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValForMeterReadingsChangedDeleted] TO [public]
GO
