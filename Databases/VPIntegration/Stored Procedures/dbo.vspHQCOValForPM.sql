SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspHQCOValForPM    Script Date: 04/18/2005 ******/
CREATE proc [dbo].[vspHQCOValForPM]
/****************************************
 * Created By:	GF 04/18/2005
 * Modified By:
 *
 * validates PMCo to HQCO. Used in PMCompany Form
 *
 * pass in PM Company
 *
 * returns
 * Vendor Group
 * Phase Group
 * Company Name or error message
 ***************************************/
(@pmco bCompany = 0, @vendorgroup bGroup output, @phasegroup bGroup output,
 @modlevel tinyint output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @modlevel = 1

if @pmco = 0
	begin
  	select @msg = 'Missing PM Company!', @rcode = 1
  	goto bspexit
  	end

---- get HQCO info
select @vendorgroup=VendorGroup, @phasegroup=PhaseGroup, @msg=Name
from bHQCO with (nolock) where HQCo=@pmco
if @@rowcount = 0
	begin
	select @msg = 'Not a valid HQ Company!', @rcode = 1
	goto bspexit
	end

---- get PM module level (1 or 2)
select @modlevel=LicLevel from vDDMO where Mod='PM'
if @@rowcount = 0 select @modlevel = 1



bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'') + char(13) + char(10) + '[vspHQCOValForPM]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQCOValForPM] TO [public]
GO
