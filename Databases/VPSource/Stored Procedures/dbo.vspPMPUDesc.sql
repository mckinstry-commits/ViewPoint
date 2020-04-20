SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPUDesc    Script Date: 06/10/2005 ******/
CREATE proc [dbo].[vspPMPUDesc]
/*************************************
 * Created By:	GF 06/10/2005
 * Modified by:
 *
 * called from PMPunchList to return project punch list key description
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * PunchList	PM Project PunchList
 *
 * Returns:
 * Description
 *
 * Success returns:
 *	0 and Description from PMPU
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @punchlist bDocument = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@punchlist,'') <> ''
	begin
	select @msg = Description
	from PMPU with (nolock) where PMCo=@pmco and Project=@project and PunchList=@punchlist
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPUDesc] TO [public]
GO
