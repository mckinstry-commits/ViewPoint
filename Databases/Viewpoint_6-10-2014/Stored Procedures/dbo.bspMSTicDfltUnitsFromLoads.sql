SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************************/
CREATE   procedure [dbo].[bspMSTicDfltUnitsFromLoads]
/***********************************************************
    * Created By:  GG 03/19/2001
    * Modified By: GF 10/31/2002 - Issue #18755 allow zero for conversion factor
    *
    * USAGE:
    *	Used by MS Ticket Entry to default material units sold based on vehicle capacity and loads.
    *
    * INPUT PARAMETERS
    *  @msco           MS Company
    *  @fromloc        Sold From Location
    *  @matlgroup      Material Group
    *  @material       Material
    *  @matlum         Posted material u/m
    *  @haulertype     Hauler Type (E = Equipment, H = Haul Vendor)
    *  @emco           EM Co#
    *  @equip          Equipment
    *  @vendorgroup    Vendor Group
    *  @haulvendor     Haul Vendor
    *  @truck          Truck
    *  @loads          Loads
    *
    * OUTPUT PARAMETERS
    *  @matlunits      Material units sold
    *	@msg 		    Message
    *
    * RETURN VALUE
    *	0 success
    *	1 error
    ***********************************************************/
(@msco bCompany = null, @fromloc bLoc = null, @matlgroup bGroup = null, @material bMatl = null,
 @matlum bUM = null, @haulertype char(1) = null, @emco bCompany = null, @equip bEquip = null,
 @vendorgroup bGroup = null, @haulvendor bVendor = null, @truck bTruck = null, @loads smallint = null,
 @matlunits bUnits output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @stdum bUM, @wghtconv bUnits, @umconv bUnits, @wghtum bUM, @wghtcap bHrs,
		@volumeum bUM, @volumecap bHrs, @capum bUM, @capacity bUnits, @capunits bUnits,
		@capconv bUnits, @factor float

select @rcode = 0, @matlunits = 0

if @loads = 0 or @haulertype = 'N' goto bspexit ---- skip if no loads or hauler

if @material is null or @matlum is null goto bspexit ---- skip if material or u/m is missing

---- get std material info
select @stdum = StdUM, @wghtconv = WeightConv
from HQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
if @@rowcount = 0 goto bspexit  -- skip if invalid material
---- get alternative u/m conversion info
select @umconv = 1
if @matlum <> @stdum
	begin
	select @umconv = Conversion from HQMU with (nolock) 
	where MatlGroup = @matlgroup and Material = @material and UM = @matlum
	if @@rowcount = 0 goto bspexit  ---- skip if u/m is invalid for the material
	end

---- get weight and u/m conversion factors based on sales location
select @wghtconv = WeightConv   -- overrides HQ
from INMT with (nolock) 
where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material

---- get alternative u/m conversion based on sales location
if @matlum <> @stdum
	begin
	select @umconv = Conversion ---- overrides HQ
	from INMU with (nolock) 
	where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material and UM = @matlum
	end

if @haulertype = 'E'    ---- equipment
   	begin
   	select @wghtum = WeightUM, @wghtcap = WeightCapacity, @volumeum = VolumeUM, @volumecap = VolumeCapacity
	from EMEM with (nolock) where EMCo = @emco and Equipment = @equip
	if @@rowcount = 0 goto bspexit  ---- skip if invalid equipment

	if @wghtum = @stdum or (select count(*) from HQMU with (nolock)
					where MatlGroup=@matlgroup and Material=@material and UM = @wghtum) = 1
					or (@wghtum in ('LBS','TON','kg') and isnull(@wghtconv,0)<>0)
		begin
		select @capum = @wghtum, @capacity = @wghtcap   -- use weight capacity if u/m is valid for this material
		goto calc_units
		end
	else
		begin
		select @capum = @volumeum, @capacity = @volumecap   -- use volume capacity
		goto calc_units
		end
	end

if @haulertype = 'H'    -- haul vendor
	begin
	select @capum = WghtUM, @capacity = WghtCap
	from MSVT with (nolock) 
	where VendorGroup = @vendorgroup and Vendor = @haulvendor and Truck = @truck
	end

calc_units:
if @capum is null or isnull(@capacity,0) = 0 goto bspexit   ---- skip if invalid truck or missing capacity info
select @msg = 'Capacity:' + convert(varchar(16),isnull(@capacity,0)) + ' ' + @capum
select @capunits = @loads * @capacity    -- total units in truck capacity u/m

if @capum = @matlum
	begin
	select @matlunits = @capunits   -- use total units if truck capacity u/m matches material u/m
	goto bspexit
	end

---- try to convert capacity u/m to material std u/m
if @capum <> @stdum
	begin
	select @capconv = 0
	---- get std conversion for capacity u/m
	select @capconv = Conversion from HQMU with (nolock) 
	where MatlGroup = @matlgroup and Material = @material and UM = @capum
	---- check for IN override
	select @capconv = Conversion from INMU with (nolock) 
	where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material and UM = @capum
	---- convert to std u/m using capacity conversion factor
	select @capunits = @capunits * @capconv

	---- if capacity u/m not valid for material, try to convert using weight factors
	if @capunits = 0
		begin
		select @factor = case @capum when 'LBS' then 1 when 'TON' then 2000 when 'kg' then 2.20462262 else 0 end
		if @factor <> 0 and @wghtconv <> 0 select @capunits = (@loads * @capacity) / (@wghtconv / @factor)
		end
	end


---- convert to material posted u/m
if @capunits <> 0 and @umconv <> 0 select @matlunits = @capunits / @umconv



bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicDfltUnitsFromLoads] TO [public]
GO
