SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMRevCodeValEquip    Script Date: 8/28/99 9:36:14 AM ******/
 CREATE     proc [dbo].[bspEMRevCodeValEquip]
 
 /******************************************************
  * Created By:  bc  10/12/98
  * Modified By: bc  07/10/00 - added two output params and now read the UpdateHr Flag
  *                             from EMRR instead of EMRC
  *               kb 6/16/01 - issue #13502 - added code so that an equip# is required
  *				TV 02/11/04 - 23061 added isnulls
  *				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
  *				LS	09/13/2010 - Added Check for EMGroup
  *
  * Usage:
  * Validates Revenue code from EMRC.
  * and returns flag and default rate information from EMRR and EMRC
  *
  *
  * Input Parameters
  *	EMCo		Need company to retreive Allow posting override flag
  * 	EMGroup		EM group for this company
  *	Equipment	Used to check the equipments category in EMEM
  *	RevCode		Revenue code to validate
  *
  * Output Parameters
  *	bYN         3 override flags
  *	basis       RevCode UM basis
  *  stdrate     EMRR rate
  *	@msg	The RevCode description.  Error message when appropriate.
  * Return Value
  *  0	success
  *  1	failure
  ***************************************************/
 
 (@emco bCompany, @EMGroup bGroup, @equip bEquip, @RevCode bRevCode,
  @update_hr_meter bYN output, @UseRateOride bYN output, @basis char(1) output,
  @stdrate bDollar output, @alloworide bYN output, @postworkunits bYN output, @um bUM output, @msg varchar(255) output)
 
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
 
 if @equip is null
  	begin
  	select @msg= 'Missing equipment.', @rcode = 1
  	goto bspexit
  	end
 
 IF @EMGroup is null
 BEGIN
	SELECT @msg = 'Missing EM Group.', @rcode = 1
	RETURN @rcode
 END
 
 
 if @RevCode is null
  	begin
  	select @msg= 'Missing Revenue code', @rcode = 1
  	goto bspexit
  	end
 
 
	--Return if Equipment Change in progress for New Equipment Code - 126196
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
	If @rcode = 1
	begin
		  goto bspexit
	end

 /* Check the Revenue Category table and make sure that the rev code exists for this piece of equipment */
 select @stdrate = r.Rate, @update_hr_meter = r.UpdtHrMeter,
        @postworkunits = r.PostWorkUnits, @um = r.WorkUM,
        @alloworide = r.AllowPostOride, @msg = c.Description
 from bEMRR r
 join bEMEM m on m.EMCo = r.EMCo and m.Category = r.Category and m.Equipment = @equip
 join bEMRC c on c.EMGroup = @EMGroup and c.RevCode = @RevCode
 where r.EMCo = @emco and r.EMGroup = @EMGroup and r.RevCode = @RevCode
 
 if @@rowcount = 0
  	begin
  	select @msg = 'Revenue code not set up by Category.', @rcode = 1
  	goto bspexit
  	end
 
 
 /* get the basis */
 select @basis = Basis
 from bEMRC
 where EMGroup = @EMGroup and RevCode = @RevCode
 
 /* Get the allow posting flag from the company table */
 select @UseRateOride = UseRateOride
 from bEMCO
 where EMCo = @emco
 
 
 bspexit:
 	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(13) + '[bspEMRevCodeValEquip]'
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMRevCodeValEquip] TO [public]
GO
