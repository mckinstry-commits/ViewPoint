SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspHQDRGetBeginStatus]
/********************************************************
* CREATED BY: 	RT 12/8/05
* MODIFIED BY:	TJL  10/13/06 - Issue #28081, 6x Recode.  Pass in HQCo
*
* USAGE:
* 	Returns the status from HQDS that is set as the beginning status
*		(default status for new records).
*
* RETURN VALUE:
* 	0 			- Success
*	    1 & message - Failure
*
**********************************************************/
  
(@hqco bCompany, @statusCode bStatus output)
as 
set nocount on
declare @rcode int
select @rcode = 1

select @statusCode = Status 
from bHQDS with (nolock)
where YNBeginStatus = 'Y'

select @rcode = 0

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQDRGetBeginStatus] TO [public]
GO
