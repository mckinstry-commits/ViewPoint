SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREquipValNoComponent    Script Date: 8/28/99 9:34:27 AM ******/
   CREATE    procedure [dbo].[bspPREquipValNoComponent]
   
   /***********************************************************
    * CREATED BY: EN 4/24/00
    * MODIFIED BY: EN 6/5/01 - issue #13648 - allow equipment with status of 'down'
    *				GG 01/11/02 - remove unused parameters, return Equipment description
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 2/6/03 - issue 19974  return desc in @msg to populate lbldesc for mech equip
	*				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
    *
    * USAGE:
    *	Validates Equipment for PR Mechanic Timecards 
    *
    * INPUT PARAMETERS
    *	@emco		EM Company
    *	@equip		Equipment to be validated
    *
    * OUTPUT PARAMETERS
    *	@desc		Equipment description 
    *	@msg		Description or Error msg 
    *
    * RETURN VALUE:
    * 	0 	    Success
    *	1 & message Failure
     **********************************************************/
   
   (@emco bCompany = null, @equip bEquip = null, @desc bDesc output, @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int, @equiptype char(1),@status char(1)
   select @rcode = 0
   
   -- check for required values
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

   -- validate Equipment
   select @equiptype = Type, @status = Status,	@msg = Description
   from EMEM
   where EMCo = @emco and Equipment = @equip
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid Equipment code!', @rcode = 1
   	goto bspexit
   	end
   -- make sure Equipment is not a Component
   if @equiptype = 'C'
   	begin
   	select @msg = 'Equipment is a Component!', @rcode = 1
   	goto bspexit
   	end
   -- Equipment cannot be inactive, must be 'active' or 'down' 
   if @status = 'I'
   	begin
   	select @msg = 'Equipment is inactive!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	--if @rcode <> 0 select @msg = @msg + char(13) + char(10) + '[bspPREquipValNoComponent]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREquipValNoComponent] TO [public]
GO
