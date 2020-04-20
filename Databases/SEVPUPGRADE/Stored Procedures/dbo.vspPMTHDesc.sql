SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMTHDesc    Script Date: 04/26/2005 ******/
CREATE  proc [dbo].[vspPMTHDesc]
/*************************************
 * Created By:	GF 04/26/2005
 * Modified by:
 *
 * called from PMTemplatePhases to return template key description
 *
 * Pass:
 * PMCo			PM Company
 * Template		PM Template
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
(@pmco bCompany, @template varchar(10), @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@template,'') <> ''
	begin
	select @msg = Description
	from PMTH with (nolock) where PMCo=@pmco and Template=@template
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMTHDesc] TO [public]
GO
