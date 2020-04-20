SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************/
CREATE    proc [dbo].[bspMSTicPayCodeVal]
/******************************************************
 * Created By:  GF  07/03/2000
 * Modified By: GG 01/24/01 - initialized output parameters to null
 *				GF 09/23/2003 - issue #22101 need to pass vendor as varchar then convert to bVendor (for null)
 *				Dan So 05/22/2008 - Issue #28688 - Return Minimum Pay Amount 
 *
 *
 * USAGE:   Validate MS Pay Code entered in MS TicEntry and MS HaulEntry.
 *  Will also calculate the pay basis to be used as the
 *  default in TicEntry and HaulEntry.
 *
 *
 * Input Parameters
 *  @msco               MS Company
 *	@paycode            Pay Code to validate
 *  @matlgroup          Material Group
 *  @material           Material
 *  @locgroup           Sell From Location Group
 *  @fromloc            Sell From Location
 *  @quote              Quote
 *  @trucktype          Truck Type
 *  @vendorgroup        Vendor Group
 *  @vendor             Haul Vendor #
 *  @truck              Truck
 *  @um                 Material U/M
 *  @zone               Zone
 *
 * Output Parameters
 *  @rate               Default Pay Code Rate
 *  @basis              Pay Basis Type
 *	@basistooltip       Pay Basis info
 *  @totaltooltip       Pay Rate info
 *  @payminamt			Pay Minimum Amount
 *	@msg                Pay Code description or error message
 *
 * Return Value
 *  0	success
 *  1	failure
 ***************************************************/
(@msco bCompany = null, @paycode bPayCode = null, @matlgroup bGroup = null, @material bMatl = null,
 @locgroup bGroup = null, @fromloc bLoc = null, @quote varchar(10) = null, @trucktype varchar(10) = null,
 @vendorgroup bGroup = null, @vendor bVendor = null, @truck varchar(10) = null, @um bUM = null,
 @zone varchar(10) = null, @rate bUnitCost  = null output, @basis tinyint = null output,
 @basistooltip varchar(255) = null output, @totaltooltip varchar(255) = null output,
 @payminamt bDollar = null output, @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @retcode int, @category varchar(10), @tmpmsg varchar(255)

select @rcode = 0

if @msco is null
    	begin
    	select @msg = 'Missing MS company.', @rcode = 1
    	goto bspexit
    	end

if @paycode is null
    	begin
    	select @msg = 'Missing Pay code', @rcode = 1
    	goto bspexit
    	end

---- get material info
if @matlgroup is not null and @material is not null
	begin
	select @category=Category
	from HQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
	if @@rowcount = 0 select @category = null
	end
else
	begin
	select @category = null
	end

---- validate Pay Code
select @msg= Description, @basis=PayBasis
from MSPC with (nolock) where MSCo=@msco and PayCode=@paycode
if @@rowcount = 0
	begin
	select @msg = 'Pay code not set up.', @rcode = 1
	goto bspexit
	end

---- get Pay Rate
exec @retcode = dbo.bspMSTicPayCodeRateGet @msco,@paycode,@matlgroup,@material,@category,
					@locgroup,@fromloc,@quote,@trucktype,@vendorgroup,@vendor,@truck,@um,
					@zone,@basis,@rate output, @payminamt output, @tmpmsg output

if @rate is null select @rate = 0

---- set tool tips description
select @totaltooltip = 'Pay Rate is ' + convert(varchar(20),@rate)

if @basis = 1 select @basistooltip = 'Pay Basis is Per Unit'
if @basis = 2 select @basistooltip = 'Pay Basis is Per Hour'
if @basis = 3 select @basistooltip = 'Pay Basis is Per Load'
if @basis = 4 select @basistooltip = 'Pay Basis is Units Per Mile'
if @basis = 5 select @basistooltip = 'Pay Basis is Units Per Hour'
if @basis = 6 select @basistooltip = 'Pay Basis is Percent of Haul Charge'


bspexit:
	if @rcode <> 0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicPayCodeVal] TO [public]
GO
