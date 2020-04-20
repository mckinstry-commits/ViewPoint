SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************/
CREATE proc [dbo].[bspMSTicTruckTypeVal]
/*************************************
 * Created By:   GF 06/30/2000
 * Modified By:	 GF 01/14/2013 TK-17005 MS Haul Entry: Haul code does not default from HQ Materials
 *
 * USAGE:   Validate Truck Type entered in MS TicEntry and MS HaulEntry.
 *
 *
 * INPUT PARAMETERS
 *  MS Company, TruckType, Quote, LocGroup, FromLoc, MatlGroup, Material,
 *  UM, VendorGroup, Vendor, Truck, HaulType
 *
 * OUTPUT PARAMETERS
 *  Quote Haul Code
 *  Quote Pay Code
 *  @msg      error message if error occurs, otherwise description from MSTT
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 **************************************/
(@msco bCompany = null, @trucktype varchar(10) = null, @quote varchar(10) = null,
 @locgroup bGroup = null, @fromloc bLoc = null, @matlgroup bGroup = null,
 @material bMatl = null, @um bUM = null, @vendorgroup bGroup = null,
 @vendor bVendor = null, @truck varchar(10) = null, @haultype char(1) = 'N',
 @haulcode bHaulCode output, @paycode bPayCode output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @category varchar(10), @tmpmsg varchar(255)

----TK-17005
DECLARE @TmpHaulCode VARCHAR(10)

select @rcode = 0

if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end

if @trucktype is null
   	begin
   	select @msg = 'Missing MS Truck Type', @rcode = 1
   	goto bspexit
   	end

select @msg = Description from MSTT with (nolock) where MSCo=@msco and TruckType = @trucktype
if @@rowcount = 0
	begin
	select @msg = 'Not a valid MS Truck Type', @rcode = 1
	goto bspexit
	end

---- get material haul code
select @category=Category,
		----TK-17005
		@TmpHaulCode = HaulCode
from HQMT with (nolock) where MatlGroup=@matlgroup and Material=@material

---- skip to exit if haultype is 'N'
if @haultype = 'N' goto bspexit

-- get default haul code for quote
if @quote is not null
	BEGIN
	exec @retcode = dbo.bspMSTicQuoteHaulCodeGet @msco,@matlgroup,@material,@category,
            @locgroup,@fromloc,@um,@quote,@trucktype,@haulcode output,@tmpmsg OUTPUT
	END

---- TK-17005
IF @haulcode IS NULL SET @haulcode = @TmpHaulCode

---- get default pay code for quote
if @quote is not null and @haultype='H'
	BEGIN
	exec @retcode = dbo.bspMSTicQuotePayCodeGet @msco,@matlgroup,@material,@category,
            @locgroup,@fromloc,@um,@quote,@vendorgroup,@vendor,@truck,@trucktype,
            @paycode output,@tmpmsg output
	END



bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicTruckTypeVal] TO [public]
GO
