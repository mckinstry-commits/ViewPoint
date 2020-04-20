SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMCompanyAPCoVal    Script Date: 12/09/2005 ******/
CREATE  proc [dbo].[vspPMCompanyAPCoVal]
/**************************************
 * Created By:	GF 12/09/2005
 * Modified By:
 *
 *
 * validates PM APCo to HQCo and returns vendor group.
 *
 * PARAMS IN:
 * APCo		PM AP Company
 *
 * PARAMS OUT:
 * Vendor Group		HQ Vendor Group for APCo
 *
 * pass in Company#
 * returns Company name
 **************************************/
(@apco bCompany = null, @vendorgroup bGroup = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @apco is null
  	begin
  	select @msg = 'Missing PM AP Company!', @rcode = 1
  	goto bspexit
  	end

-- -- -- validate to HQCo and return name and vendor group
select @msg=Name, @vendorgroup=VendorGroup
from bHQCO with (nolock) where HQCo=@apco
if @@rowcount = 0
	begin
  	select @msg = 'Not a valid HQ Company!', @rcode = 1
  	end





bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCompanyAPCoVal] TO [public]
GO
