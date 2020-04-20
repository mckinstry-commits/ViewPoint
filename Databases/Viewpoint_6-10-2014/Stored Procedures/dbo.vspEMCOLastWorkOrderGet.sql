SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspEMCOLastWorkOrderGet]
/**************************************************************************
* 
*Created:	TRL 6-11-07 - Used to get last work order for frm EM Work Order Copy
*Modified:	TRL 11/14/08 Issue 131082 changed WO formatting to vspEMFormatWO from bfJustifyStringToDatatype 
*
*USAGE:
* returns next available Work Order number to frm EMWO Copy
*
*   Inputs:
*	EMCO
* 
*   Outputs:
*	Work Order number
*	error message, if there is one
*
*   RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
***************************************************************************/
(@emco bCompany, @lastworkorder varchar(10) =null output, @msg varchar(255) output)
as
   
set nocount on
   
declare @rcode int 
   
select @rcode = 0

If Isnull(@emco,0) = 0   
begin
	select @msg = 'Missing EM Company!', @rcode =1 
	goto vspexit
end

If (select top 1 EMCo from dbo.EMCO Where EMCo=@emco) = 0 
begin 
	select @msg = 'Invalid EM Company!', @rcode = 1 
	goto vspexit
end

/* Issue 122308 */
select @lastworkorder = IsNull(LastWorkOrder,'0')
from dbo.EMCO with (nolock)
where EMCo=@emco
	
/* Issue 131082*/
exec @rcode = dbo.vspEMFormatWO @lastworkorder output, @msg output   	
If @rcode = 1
begin
	goto vspexit
end 
   
vspexit:
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCOLastWorkOrderGet] TO [public]
GO
