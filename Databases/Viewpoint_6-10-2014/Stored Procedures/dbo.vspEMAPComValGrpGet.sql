SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  Procedure [dbo].[vspEMAPComValGrpGet]
/***********************************************************
* CREATED BY: TV 7/31/06
*
* USAGE:
* validates AP Company number and returns Vendor Group
* 
* INPUT PARAMETERS
*   APCo   AP Co to Validate  
*
*
* OUTPUT PARAMETERS
*	@APVendor
*   @msg If Error, error message, otherwise description of Company
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/ 
(@apco bCompany = 0, @APVendorGrp tinyint output, @msg varchar(60)=null output)
as

set nocount on


declare @rcode int
select @rcode = 0


if not exists(select * from APCO with (nolock) where APCo = @apco)
	begin
	select @msg = 'Not a valid AP Company', @rcode = 1
	goto bspexit
	end

select @msg = Name, @APVendorGrp = VendorGroup
from bHQCO with (nolock)
where HQCo = @apco

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMAPComValGrpGet] TO [public]
GO
