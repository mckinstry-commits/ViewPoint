SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMEquipValForRevRatesEQ]
   
/***********************************************************
* CREATED BY:  TJL 10/20/06 - Issue #27929, 6x Recode.  Added Error on EMEM.Type <> 'E'
* MODIFIED By :	TRL 08/13/2008 - 126196 check to see Equipment code is being Changed 
*				TRL 04/01/2009 - 131254 Add output parameter for category
*
* USAGE:
*	Validates EMEM.Equipment.	(Modeled after bspEMEquipVal w/special requirements
*	Special Requirements for Forms:
*		EM Revenue Rates By Equipment
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
   
(@emco bCompany = null,	@equip bEquip = null, @category bCat output, @msg varchar(255) output)
   
as

set nocount on
declare @rcode int, @status char(1), @equiptype char(1)
select @rcode = 0
   
if @emco is null
begin
	select @msg = 'Missing EM Company.', @rcode = 1
	goto vspexit
end
   
if @equip is null
begin
	select @msg = 'Missing Equipment.', @rcode = 1
	goto vspexit
end
	  
-- Return if Equipment Change in progress for New Equipment Code, 126196.
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
If @rcode = 1
begin
	  goto vspexit
end
 
select  @msg=Description, @status = Status, @equiptype = Type,
@category=Category /*Issue 131254*/
from EMEM with (nolock)
where EMCo = @emco and Equipment = @equip
if @@rowcount = 0
	begin
	select @msg = 'Equipment invalid.', @rcode = 1
	goto vspexit
	end

/* Reject if Equipment Type is not "E" */
if @equiptype <> 'E'
begin
	select @msg = 'Equipment Type must be "E" type.', @rcode = 1
	goto vspexit
end
	   
/* Reject if Status inactive. */
if @status = 'I'
begin
	select @msg = 'Equipment Status = Inactive.', @rcode = 1
	goto vspexit
end

vspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipValForRevRatesEQ] TO [public]
GO
