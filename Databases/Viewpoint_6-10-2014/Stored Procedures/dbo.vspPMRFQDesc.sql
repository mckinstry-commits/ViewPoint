SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMRFQDesc    Script Date: 02/22/2006 ******/
CREATE proc [dbo].[vspPMRFQDesc]
/*************************************
 * Created By:	GF 02/22/2006
 * Modified by:
 *
 * called from PMRFQ to return RFQ key description
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
(@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO, @rfq bDocument, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@rfq,'') <> ''
	begin
	select @msg = Description
	from PMRQ with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and RFQ=@rfq
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMRFQDesc] TO [public]
GO
