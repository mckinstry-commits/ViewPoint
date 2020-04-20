SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMCompanyVal]
/********************************************************
* CREATED BY: TV 06/01/06
* USAGE:	TJL  10/23/06 - Issue #27929:  Make this into more of a CommonInfoGet LoadProc
*
* 	Retrieves Information commonly used by EM.
*		To retrieve only EMGroup or EMGroup & GLCo info use:  vspEMGroupGet or vspEMGroupGetAlloc
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
*	EMGroup from bHQCO
*	GLCO from EMCO
*	
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/

(@emco bCompany, @emgroup tinyint output, @msg varchar(60) output) 
as 
set nocount on

declare @rcode int
select @rcode = 0

select @emgroup = h.EMGroup, @msg = h.Name
from HQCO h with (nolock) 
where h.HQCo = @emco
if @@rowcount = 0
	begin
	select @msg = 'Not a valid EM company ', @rcode = 1
	goto vspexit
	end

if @emgroup is Null 
	begin
	select @msg = 'EM Group not setup for EM Co ' + isnull(convert(varchar(3),@emco),'') + ' in HQ.', @rcode=1
	goto vspexit
	end

vspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCompanyVal] TO [public]
GO
