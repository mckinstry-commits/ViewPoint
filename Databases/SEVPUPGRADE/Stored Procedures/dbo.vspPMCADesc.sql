SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMCADesc    Script Date: 04/20/2005 ******/
CREATE  proc [dbo].[vspPMCADesc]
/*************************************
 * Created By:	GF 04/20/2005
 * Modified by:
 *
 * called from PMCompanyAddons to return add-on key description
 *
 * Pass:
 * PMCo			PM Company
 * AddOn		PM Company Addon
 *
 * Success returns:
 *	0 and Description from PMCA
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @addon tinyint, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@addon,0) <> 0
	begin
	select @msg = Description
	from PMCA with (nolock) where PMCo=@pmco and Addon=@addon
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCADesc] TO [public]
GO
