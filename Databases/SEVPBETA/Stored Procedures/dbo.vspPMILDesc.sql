SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMILDesc    Script Date: 08/01/2005 ******/
CREATE proc [dbo].[vspPMILDesc]
/*************************************
 * Created By:	GF 08/01/2005
 * Modified by:
 *
 * called from PMInspectionLogs to return Inspection Log View key description
 *
 * Pass:
 * PMCo					PM Company
 * Project				PM Project
 * InspectionType		PM Inspection Type
 * InspectionCode		PM Inspection Log
 * 
 * Returns:
 * Description
 *
 * Success returns:
 *	0 and Description from PMIL
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @inspectiontype bDocType, @inspectioncode bDocument, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@inspectioncode,'') <> ''
	begin
	select @msg = Description
	from PMIL with (nolock) where PMCo=@pmco and Project=@project and InspectionType=@inspectiontype and InspectionCode=@inspectioncode
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMILDesc] TO [public]
GO
