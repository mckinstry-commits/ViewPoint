SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE proc [dbo].[vspMSCommonInfoGetForMSMH]
/********************************************************
 * Created By:	GF 07/15/2008 - issue #128458 international tax
 * Modified By:	
 *               
 *
 * USAGE:
 * Retrieves common MS information for use in MS Material Vendor Worksheets
 * form's DDFH LoadProc field 
 *
 * INPUT PARAMETERS:
 * MS Company
 *
 * OUTPUT PARAMETERS:
 * From MSCO
 * APCO
 * ARCO
 * From HQCO
 * VendorGroup
 * CustGroup
 * GLCo
 * TaxGroup
 * @cmco				CM Co# assigned to AR Company
 * @cmacct				CM Account assigned to AR Company
 * @country				HQ Country Code
 *	
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@msco bCompany=0, @apco bCompany = null output, @vendorgroup bGroup = null output,
 @arco bCompany = null output, @custgroup bGroup = null output, @glco bCompany = null output,
 @taxgroup bGroup = null output, @cmco bCompany output, @cmacct bCMAcct output,
 @country varchar(2) = null output, @errmsg varchar(255) output) 
as 
set nocount on

declare @rcode int, @errortext varchar(255)

select @rcode = 0

---- missing MS company
if @msco is null
	begin
   	select @errmsg = 'Missing MS Company!', @rcode = 1
   	goto bspexit
   	end

---- Get info from MSCO
select @apco=isnull(APCo,0), @arco=isnull(ARCo,0), @glco=isnull(GLCo,0)
from MSCO with (nolock) where MSCo=@msco
if @@rowcount = 0
	begin
	select @errmsg = 'MS Company ' + convert(varchar(3), @msco) + ' is not setup!', @rcode = 1
	goto bspexit
	end


---- get vendor group from HQCO for AP company
select @vendorgroup = VendorGroup
from HQCO with (nolock) where HQCo = @apco

---- get material group from HQCO for MS company
select @taxgroup = TaxGroup, @country = DefaultCountry
from HQCO with (nolock) where HQCo = @msco

---- get customer group fro HQCO for AR Company
select @custgroup = CustGroup
from HQCO with (nolock) where HQCo = @arco

---- get AR company information
select @cmco = CMCo, @cmacct = CMAcct
from ARCO with (nolock) where ARCo=@arco



bspexit:
	if @rcode<> 0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSCommonInfoGetForMSMH] TO [public]
GO
