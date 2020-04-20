SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMJCJMContractGet    Script Date: 08/12/2005 ******/
CREATE   proc [dbo].[vspPMJCJMContractGet]
/*************************************
 * Created By:	GF 08/12/2005
 * Modified By:
 *
 *
 * USAGE:
 * Called from PM Contract Master to return the JCJM.Contract for active project.
 *
 *
 * INPUT PARAMETERS
 * @pmco			PM Company
 * @project			PM Project
 *
 * Success returns:
 *	0 and Contract from JCJM
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @contract bContract

select @rcode = 0, @msg = ''

if @pmco is null or isnull(@project,'') = '' goto bspexit

-- -- -- get contract for project
select @contract=Contract
from bJCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount = 0 
	goto bspexit
else
	select @msg = @contract



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMJCJMContractGet] TO [public]
GO
