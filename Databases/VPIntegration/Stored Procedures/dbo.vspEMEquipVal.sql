SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[vspEMEquipVal]
  
/***********************************************************
* CREATED BY: JM 8/13/98
* MODIFIED By : JM 5/9/00 - Added restriction on validation to Status A or D.
*				TV 02/11/04 - 23061 added isnulls	
*				TV 09/12/05 - moved to .NET
* USAGE:
*	Validates EMEM.Equipment
*
* INPUT PARAMETERS
*	@emco		EM Company
*	@equip		Equipment to be validated
*
* OUTPUT PARAMETERS
*	@msg 		error or Description
*
* RETURN VALUE
*	0 success
*	1 error
***********************************************************/
(@emco bCompany = null,@equip bEquip = null,@msg varchar(255) output)
  
as
  
set nocount on
 
declare @rcode int, @status char(1), @numrows int
select @rcode = 0
 
if @emco is null
begin
  	select @msg = 'Missing EM Company!', @rcode = 1
  	goto vspexit
end
  
if @equip is null
begin
  	select @msg = 'Missing Equipment!', @rcode = 1
  	goto vspexit
end

 


select  @msg=Description, @status = Status
from dbo.EMEM with(nolock)
where EMCo = @emco and Equipment = @equip 
if @@rowcount = 0 
begin
	--Return if Equipment Change in progress for Old Equipment Code
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
	If @rcode = 1
	begin
		goto vspexit
	end
   
	select @msg = 'Invalid Equipment!', @rcode = 1
	goto vspexit
end
--Return if Equipment Change in progress for New Equipment Code
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
If @rcode = 1
begin
	goto vspexit
end

/* Reject if Status inactive. */
if @status = 'I'
begin
	select @msg = 'Equipment Status = Inactive!', @rcode = 1
	goto vspexit
end
  
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipVal] TO [public]
GO
