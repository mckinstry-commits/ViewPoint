SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE proc [dbo].[vspMSCommonInfoGetForMassEdit]
/********************************************************
 * Created By:	GF 09/07/2007 6.x
 * Modified By:	
 *               
 *
 * USAGE:
 * Retrieves common MS information for use in MS Mass Edit form
 *
 * INPUT PARAMETERS:
 * MS Company
 *
 * OUTPUT PARAMETERS:
 * APCO
 * MatlGroup
 * VendorGroup
 * ARCO
 * CustGroup
 * TaxGroup
 * PhaseGroup			Phase Group for MS Company
 * EMGroup				EM Group for MS Company
 *	
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@msco bCompany=0, @apco bCompany = null output, @matlgroup bGroup = null output,
 @vendorgroup bGroup = null output, @arco bCompany = null output, @custgroup bGroup = null output,
 @taxgroup bGroup = null output, @phasegroup bGroup = null output, @emgroup bGroup = null output,
 @errmsg varchar(255) output) 
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
select @apco=isnull(APCo,0), @arco=isnull(ARCo,0)
from MSCO with (nolock) where MSCo=@msco
if @@rowcount = 0
	begin
	select @errmsg = 'MS Company ' + convert(varchar(3), @msco) + ' is not setup!', @rcode = 1
	goto bspexit
	end

---- get vendor group from HQCO for AP company
select @vendorgroup = VendorGroup
from HQCO with (nolock) where HQCo = @apco

---- get material, tax, phase group from HQCO for MS company
select @matlgroup = MatlGroup, @taxgroup = TaxGroup,
		@phasegroup=PhaseGroup, @emgroup=EMGroup
from HQCO with (nolock) where HQCo = @msco

---- get customer group fro HQCO for AR Company
select @custgroup = CustGroup
from HQCO with (nolock) where HQCo = @arco




bspexit:
	if @rcode<> 0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSCommonInfoGetForMassEdit] TO [public]
GO
