SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPLDesc    Script Date: 04/26/2005 ******/
CREATE   proc [dbo].[vspPMPLDesc]
/*************************************
 * Created By:	GF 04/26/2005
 * Modified by:
 *
 * called from PMProjectLoc to return project location key description
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * Location		PM Project Location
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
(@pmco bCompany, @project bJob, @location bLoc, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@location,'') <> ''
	begin
	select @msg = Description
	from PMPL with (nolock) where PMCo=@pmco and Project=@project and Location=@location
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPLDesc] TO [public]
GO
