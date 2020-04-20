SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspEMEquipmentPartDesc]
/***********************************************************
* CREATED BY: DANF 01/04/2007
* MODIFIED By : TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
*				TRL 02/19/2008 - 127133 add 2 parameters IsPartNoHQMatl (Y/N) and HQ Matl StdUM
*				Used when adding a EM Part Code that exists in HQ Matl
*				TRL 05/28/2009 - Issue 133497- added code to reset @msg
*				JVH 1/18/2010 - Simplified sql
*				
* USAGE:
* Used in EM EquipmentPart Master to return the a description to the key field.
*
* INPUT PARAMETERS
*   EMCo   			EM Co
*   Equipment	    Equipment
*   EquipmentPart 	EquipmentPart
*
* OUTPUT PARAMETERS
*   @msg      Description of EquipmentPart if found.
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@emco bCompany, @equipment bEquip, @equipmentpart varchar(30),
@ispartnohqmatl bYN output,@hqmatlum bUM output,
@msg varchar(255) output)

as

set nocount on

declare @rcode int, @matlgroup bGroup

select @rcode = 0,@ispartnohqmatl = 'N'

Select @matlgroup=MatlGroup from dbo.HQCO where HQCo=@emco 
  
--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equipment, @msg output
If @rcode = 1
begin
	goto vspexit
end

select @msg = ''

--Sets the Material Description which may get overwritten in the next select statement
select @ispartnohqmatl = 'Y',@hqmatlum=StdUM, @msg = Description
from dbo.HQMT with(nolock) Where MatlGroup=@matlgroup and Material=@equipmentpart

--If validation is loading for an existing EMEP record then we overwrite the msg variable to display in the
--description box
select @msg = Description from dbo.EMEP with (nolock)
where EMCo = @emco and Equipment = @equipment and PartNo = @equipmentpart


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipmentPartDesc] TO [public]
GO
