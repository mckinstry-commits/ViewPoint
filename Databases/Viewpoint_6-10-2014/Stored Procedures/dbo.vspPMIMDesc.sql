SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMIMDesc    Script Date: 04/30/2005 ******/
CREATE   proc [dbo].[vspPMIMDesc]
/*************************************
 * Created By:	GF 04/30/2005
 * Modified by:
 *
 * called from PMProjectIssues to return project issue key description
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * Issue		PM Project Issue
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
(@pmco bCompany, @project bJob, @issue bIssue, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@issue,0) <> 0
	begin
	select @msg = Description
	from PMIM with (nolock) where PMCo=@pmco and Project=@project and Issue=@issue
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMIMDesc] TO [public]
GO
