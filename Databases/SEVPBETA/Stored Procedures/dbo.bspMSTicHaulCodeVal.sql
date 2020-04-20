SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************/
CREATE  proc [dbo].[bspMSTicHaulCodeVal]
/*************************************
 * Created By:  GF 07/05/2000
 * Modified By: GG 01/24/01 - initialized output parameters to null
 *				RM 03/26/01 - Added validation and input params to base on RevCode
 *				GF 03/19/2004 - issue #24038 - rates by phase
 *
 *
 * USAGE:   Validate haul code entered in MS TicEntry and MS HaulEntry
 *
 *
 * INPUT PARAMETERS
 *  @msco           MS Company
 *  @haulcode       HaulCode
 *  @matlgroup      Material Group
 *  @material       Material
 *  @locgroup       Sell From Location Group
 *  @fromloc        Sell From Location
 *  @quote          Quote
 *  @um             Material U/M - posted
 *  @trucktype      Truck Type
 *  @zone           Zone
 *
 * OUTPUT PARAMETERS
 *  @basis          Haul Basis Type
 *  @taxable        Haul Taxable flag
 *  @rate           Default Haul Rate
 *  @minamt         Haul Minimum Amount
 *	@basistooltip   Haul basis info
 *  @ratetooltip    Haul rate info
 *  @totaltooltip   Haul code info including minimum amount
 *  @msg            Haul code description or error message
 *   
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 *
 **************************************/
(@msco bCompany = null, @haulcode bHaulCode, @matlgroup bGroup = null, @material bMatl = null,
 @locgroup bGroup = null, @fromloc bLoc = null, @quote varchar(10) = null, @um bUM = null,
 @trucktype varchar(10) = null, @zone varchar(10) = null, @basis tinyint = null output,
 @taxable bYN = null output, @rate bUnitCost = null output, @minamt bDollar = null output,
 @basistooltip varchar(255) = null output, @ratetooltip varchar(255) = null output,
 @totaltooltip varchar(255) = null output, @emgroup bGroup = null, @revcode bRevCode = null,
 @revbased bYN = null output, @haulum bUM = null,@paycode bPayCode = null, 
 @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @retcode int, @category varchar(10), @tmpmsg varchar(255), @haulbased bYN,
   		@revbasis char(1), @revum bUM, @paybasis char(1)

select @rcode = 0, @retcode = 0

if @msco is null
	begin
	select @msg = 'Missing MS Company', @rcode = 1
	goto bspexit
	end

if @matlgroup is null
	begin
   	select @msg = 'Missing Material Group', @rcode = 1
   	goto bspexit
   	end

if @locgroup is null
	begin
	select @msg = 'Missing IN Location Group', @rcode = 1
	goto bspexit
	end

if @fromloc is null
   	begin
   	select @msg = 'Missing IN From Location', @rcode = 1
   	goto bspexit
   	end

if @haulcode is null
	begin
	select @msg = 'Missing Haul Code', @rcode = 1
	goto bspexit
	end

select @msg=Description, @basis=HaulBasis, @taxable=Taxable,@revbased = RevBased
from MSHC with (nolock) where MSCo=@msco and HaulCode=@haulcode
if @@rowcount = 0
	begin
	select @msg = 'Invalid Haul Code', @rcode = 1
	goto bspexit
	end


select @category=Category
from HQMT with (nolock) where MatlGroup=@matlgroup and Material=@material

---- get haul code values
exec @retcode = dbo.bspMSTicHaulRateGet @msco, @haulcode, @matlgroup, @material, @category, @locgroup,
					@fromloc, @trucktype, @um, @quote, @zone, @basis, null, null, null,
					@rate output, @minamt output, @tmpmsg output

if @revcode is not null
	begin
	select @haulbased = HaulBased,@revbasis = Basis,@revum = WorkUM
	from EMRC with (nolock) where EMGroup = @emgroup and RevCode = @revcode

	if @revbased = 'Y'
   		begin
			if @haulbased = 'Y'
			begin
   			select @rcode = 1,@msg = 'Cannot Use Haul Code based on Rev Code while Rev Code is based on Haul Code.'
   			goto bspexit
			end

		if @basis <> 1
			begin
   			select @haulum = UM from MSHC with (nolock) where MSCo=@msco and HaulCode=@haulcode
			end

		if ((@basis in (1,3,4,5) and @revbasis <> 'U') or (@basis= 2 and @revbasis <> 'H')) and @revbasis is not null
   			begin
   			select @rcode = 1,@msg = 'When using a Haul Code that is based on the Rev Code, the basis must be the same.'
   			goto bspexit
   			end

		if @basis <> 2 and isnull(@revum,@haulum) <> @haulum
			begin
   			select @rcode = 1,@msg = 'When using a Haul Code that is based on the Rev Code, the UM must be the same.'
   			goto bspexit
			end
		end
	end
else
	begin
	select @paybasis = PayBasis from MSPC with (nolock) where MSCo = @msco and PayCode = @paycode
	if @revbased = 'Y'
		begin
   		if  ((@basis in (1,4,5) and @paybasis not in (1,4,5)) or (@basis= 2 and @paybasis <> 2) or (@basis= 3 and @paybasis <> 3)) and @paybasis is not null
   			begin
   			select @rcode = 1,@msg = 'When using a Haul Code that is based on the Pay Code, the basis must be the same.' 
   			goto bspexit
   			end

		if @paybasis = 6
   			begin
   			select @rcode = 1,@msg = 'When using a Haul Code that is based on the Pay Code, the Pay Basis cannot be 6.'
   			goto bspexit
   			end
		end
	end


if @rate is null select @rate = 0

if @minamt is null select @minamt = 0

---- set tool tips description
select @ratetooltip = 'Default Haul Rate is ' + convert(varchar(12),@rate)
select @totaltooltip = 'Haul Rate Minimum Amount is ' + convert(varchar(12),@minamt)

if @basis = 1 select @basistooltip = 'Haul Basis is Per Unit'
if @basis = 2 select @basistooltip = 'Haul Basis is Per Hour'
if @basis = 3 select @basistooltip = 'Haul Basis is Per Load'
if @basis = 4 select @basistooltip = 'Haul Basis is Units Per Mile'
if @basis = 5 select @basistooltip = 'Haul Basis is Units Per Hour'

if @taxable = 'Y'
	select @basistooltip = @basistooltip + ': Haul Code is taxable'
else
	select @basistooltip = @basistooltip + ': Haul Code is not taxable'



bspexit:
	if @rcode <> 0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicHaulCodeVal] TO [public]
GO
