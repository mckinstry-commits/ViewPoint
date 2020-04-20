SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMRIDesc    Script Date: 06/30/2005 ******/
CREATE   proc [dbo].[vspPMRIDesc]
/*************************************
 * Created By:	GF 06/30/2005
 * Modified by:
 *
 * called from PMRFI to return RFI View key description
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * RFIType		PM RFI Type
 * RFI			PM RFI
 * 
 * Returns:
 * Description
 *
 * Success returns:
 *	0 and Description from PMRI
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @rfitype bDocType, @rfi bDocument, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@rfi,'') <> ''
	begin
	select @msg = Subject
	from PMRI with (nolock) where PMCo=@pmco and Project=@project and RFIType=@rfitype and RFI=@rfi
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMRIDesc] TO [public]
GO
