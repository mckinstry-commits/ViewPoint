SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMRevCodeValWithInfo    Script Date: 8/28/99 9:32:43 AM ******/
   CREATE    proc [dbo].[bspEMRevCodeValWithInfo]
   
   /******************************************************
    * Created By:  bc  08/25/98
    * Modified By: bc  07/19/00
    *				TV 02/11/04 - 23061 added isnulls
    * Usage:
    * A standard validation for a revenue code from EMRC.
    * and returns flag and default information
    *
    *
    * Input Parameters
    *	EMCo		Need company to retreive Allow posting override flag
    * 	EMGroup		EM group for this company
    *	RevCode		Revenue code to validate
    *
    * Output Parameters
    *	@msg		The RevCode description.  Error message when appropriate.
    *	Basis		Whether the rev code is based on Time or Work units.
    *
    * Return Value
    *  0	success
    *  1	failure
    ***************************************************/
   
   (@emco bCompany, @EMGroup bGroup, @RevCode bRevCode,
    @update_hr_meter bYN output, @UseRateOride bYN output, @basis char(1) output,
    @time_um bUM output, @msg varchar(60) output)
   
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   select @update_hr_meter = 'Y', @UseRateOride = 'Y'
   
   if @emco is null
    	begin
    	select @msg= 'Missing company.', @rcode = 1
    	goto bspexit
    	end
   
   if @RevCode is null
    	begin
    	select @msg= 'Missing Revenue code', @rcode = 1
    	goto bspexit
    	end
   
    /* Get the update hour meter flag */
   select @msg= Description, @update_hr_meter = UpdateHourMeter, @basis = Basis, @time_um = TimeUM
   from bEMRC
   where EMGroup = @EMGroup and RevCode = @RevCode
   
   if @@rowcount = 0
    	begin
    	select @msg = 'Revenue code not set up.', @rcode = 1
    	goto bspexit
    	end
   
   /* Get the allow posting flag from the company table */
   select @UseRateOride = UseRateOride
   from bEMCO
   where EMCo = @emco
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMRevCodeValWithInfo]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMRevCodeValWithInfo] TO [public]
GO
