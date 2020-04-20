SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMODDesc    Script Date: 08/12/2005 ******/
CREATE proc [dbo].[vspPMODDesc]
/*************************************
 * Created By:	GF 08/12/2005
 * Modified by:
 *
 * called from PMOtherDocs to return Other Docs View key description
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * DocType		PM Other Doc Type
 * Document		PM Other Document
 * 
 * Returns:
 * Description
 *
 * Success returns:
 *	0 and Description from PMOD
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @otherdoctype bDocType, @otherdoc bDocument, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@otherdoc,'') <> ''
	begin
	select @msg = Description
	from PMOD with (nolock) where PMCo=@pmco and Project=@project and DocType=@otherdoctype and Document=@otherdoc
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMODDesc] TO [public]
GO
