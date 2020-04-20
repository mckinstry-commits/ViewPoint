SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMTLDesc    Script Date: 07/29/2005 ******/
CREATE proc [dbo].[vspPMTLDesc]
/*************************************
 * Created By:	GF 07/29/2005
 * Modified by:
 *
 * called from PMTestLogs to return Test Log View key description
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * TestType		PM Test Type
 * TestCode		PM Test Log
 * 
 * Returns:
 * Description
 *
 * Success returns:
 *	0 and Description from PMTL
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @testtype bDocType, @testcode bDocument, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@testcode,'') <> ''
	begin
	select @msg = Description
	from PMTL with (nolock) where PMCo=@pmco and Project=@project and TestType=@testtype and TestCode=@testcode
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMTLDesc] TO [public]
GO
