SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMFTDesc    Script Date: 04/13/2005 ******/
CREATE  proc [dbo].[vspPMFTDesc]
/*************************************
 * Created By:	GF 04/13/2005
 * Modified By:
 *
 *
 * used in PMFirmTypes to return firm type description for key label display
 *
 * Pass:
 *	PM Company
 *	PM Firm Type
 *
 * Returns:
 *
 * Success returns:
 *	0 and Description from FirmType
 *
 * Error returns:
 *  
 *	1 and error message
 **************************************/
(@firmtype bFirmType = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@firmtype,'') <> ''
	begin
	select @msg = Description from PMFT with (nolock) where FirmType = @firmtype
  	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMFTDesc] TO [public]
GO
