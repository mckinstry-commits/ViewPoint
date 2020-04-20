SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMDescEquipment    Script Date:  ******/
CREATE PROC [dbo].[vspEMDescEquipment]
/***********************************************************
* CREATED BY:  TJL 03/07/07 - Issue #27815:  6x Rewrite
* MODIFIED By : TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
*
* USAGE:
* 	Returns Equipment Description
*
* INPUT PARAMETERS
*   EM Company
*   Equipment to validate
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@emco bCompany = null, @equipment bEquip = null,  @msg varchar(255) output)
as
set nocount on

declare @rcode int;

set @rcode = 0

if @emco is null
	begin
	goto vspexit
	end
if @equipment is null
	begin
	goto vspexit
	end
Else
   	begin

	--Return if Equipment Change in progress for New Equipment Code - 126196
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equipment, @msg output
	If @rcode = 1
	begin
		  goto vspexit
	end

	--Return if Equipment Change in progress for New Equipment Code - 126196
	exec @rcode = vspEMEquipChangeEMEHVal @emco, @equipment, @msg output
	If @rcode = 1
	begin
		  goto vspexit
	end

 	select @msg = Description from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment
   	end

vspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMDescEquipment] TO [public]
GO
