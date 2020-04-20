SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMSCDesc    Script Date: 04/13/2005 ******/
CREATE  proc [dbo].[vspPMSCDesc]
/*************************************
 * Created By:	GF 04/26/2005
 * Modified by:
 *
 * called from PMStatusCodes to return status code key description
 *
 * Pass:
 * PM Status Code
 *
 * Returns:
 * Description
 *
 * Success returns:
 *	0 and Description from PMSC
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@statuscode  bStatus, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@statuscode,'') <> ''
	begin
	select @msg = Description
	from PMSC with (nolock) where Status=@statuscode
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSCDesc] TO [public]
GO
