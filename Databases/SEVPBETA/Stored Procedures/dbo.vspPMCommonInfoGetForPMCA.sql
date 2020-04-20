SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE  proc [dbo].[vspPMCommonInfoGetForPMCA]
/********************************************************
 * Created By:	GF 07/19/2007 6.x 
 * Modified By:	
 *               
 *
 * USAGE:
 * Retrieves common info from PMCO for use in PM company addons
 * form's DDFH LoadProc field. Form is only accessed from PM Company form
 * Needed special SP so that we will not check if PMCo exists
 *
 * INPUT PARAMETERS:
 *	PM Company
 *
 * OUTPUT PARAMETERS:
 * PhaseGroup
 *	
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@pmco bCompany=0, @phasegroup bGroup = null output)
as 
set nocount on

declare @rcode int, @errortext varchar(255)

select @rcode = 0

---- get phase group from HQCO for JC company
select @phasegroup = PhaseGroup
from HQCO with (nolock) where HQCo=@pmco




bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCommonInfoGetForPMCA] TO [public]
GO
