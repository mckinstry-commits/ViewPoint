SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspMSQuoteInfoGet    Script Date: 12/5/2005 ******/
CREATE proc [dbo].[vspMSQuoteInfoGet]
/***********************************************************
 * Created By:  GF 12/05/2005
 * Modified By:
 *
 *
 *
 * USAGE:
 * Gets MS company info for use in MS Quote set up form.
 *
 * Returns success, or error
 *
 * INPUT PARAMETERS
 * msco - MS Company to use to get company info
 *
 * OUTPUT PARAMETERS
 *	@apco				AP Co#
 *	@arco				AR Co#
 *	@taxopt				Tax default option
 *	@taxgroup			Tax Group assigned in bHQCO
 *	@vendorgroup		Vendor Group assigned in bHQCO
 *	@custgroup			Customer Group assigned in bHQCO
 *	@matlgroup			Material Group assigned in bHQCO
 *	@autoquote			Automatically generating Quote #s
 *	@errmsg				Error message
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *
 *****************************************************/
(@msco bCompany = 0, @apco bCompany output, @arco bCompany output, @taxopt tinyint output,
 @taxgroup tinyint output, @vendorgroup tinyint output, @custgroup tinyint output,
 @matlgroup tinyint output, @autoquote bYN output, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- missing MS company
if @msco is null
	begin
   	select @errmsg = 'Missing MS Company!', @rcode = 1
   	goto bspexit
   	end

---- get MS Company info
select @apco=APCo, @arco=ARCo, @taxopt=TaxOpt, @autoquote=AutoQuote
from MSCO with (nolock) where MSCo=@msco
if @@rowcount = 0
	begin
	select @errmsg = 'MS Company ' + convert(varchar(3), @msco) + ' is not setup!', @rcode = 1
	goto bspexit
	end

---- get tax and material groups
select @taxgroup = TaxGroup, @matlgroup = MatlGroup
from HQCO with (nolock) where HQCo = @msco
---- get vendor group
select @vendorgroup = VendorGroup from HQCO with (nolock) where HQCo = @apco
---- get customer group
select @custgroup = CustGroup from HQCO with (nolock) where HQCo = @arco




bspexit:
	if @rcode<> 0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSQuoteInfoGet] TO [public]
GO
