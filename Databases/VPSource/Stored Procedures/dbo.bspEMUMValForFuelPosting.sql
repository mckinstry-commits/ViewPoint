SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMUMValForFuelPosting    Script Date: 4/4/2002 2:44:33 PM ******/
CREATE   proc [dbo].[bspEMUMValForFuelPosting]
/**********************************************************
* CREATED BY:  JM 2/9/99
* MODIFIED BY: RH 2/12/99 - Corrected returned Price to be either (1) from HQMU if passed UM <> HQMT.SalesUM
*				or (2) HQMT.Price if passed UM = HQMT.SalesUM.
*				JM 2/24/99 - Removed rejection if @material is passed in as null since forms using this val
*				routine need to allow entry of a UM when Material has not been entered (EMCostAdj and
*				EMPartsPosting). Also added restriction to get SalesUM and Price from HQMT for the material
*				passed in only when @material is not null.
*				JM 6/5/01 - Changed method that extracts price to include inventory when INLoc specified.
*				Changed comparison in HQ section to StdUM from SalesUM per DanF.
*				JM 5/28/02 - Ref Issue 17427 - Added error condition when conversion does not exist in INMU for UM
* 				JM 12-11-02 Ref Issue 19620 - rewrote this logic to return error if conversion from HQMT.StdUM to UM being validated doesn't exist 
*				and to assure that Inventoried materials look for conversion from HQMT.StdUM in INMU.
*				GF 02/19/2003 - need to consider validate parts flag from EMCo.
*				TV 02/11/04 - 23061 added isnulls
*				TRL 04/23/09 -- Removed Valid Matl required from HQMU error.
*
* USAGE: Validates UM vs bHQUM and returns Price from bHQMU
*	for a passed MatlGroup/Material.
*
* INPUT PARAMETERS:
*	UM to be validated
*	MatlGroup and Material for select against bHQMU
*	INLoc
*
* OUTPUT PARAMETERS:
*	UnitPrice from HQ or IN for the material
*	Error message
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
**********************************************************/
(@emco bCompany = null, @um bUM = null, @matlgroup bGroup = null, @material bMatl = null,
@inco bCompany = null, @inloc bLoc = null, @priceout bUnitCost output, @msg varchar(255) output)
as
set nocount on
    
declare @rcode int, @stdum bUM, @stdunitcost bUnitCost, @equippriceopt tinyint, @emrate bRate,
	@lastcost bUnitCost, @avgcost bUnitCost, @stdprice bUnitCost, @hqumconv bUnits,
	@hqcost bUnitCost, @hqprice bUnitCost, @inumconv bUnits, @incost bUnitCost,
	@inprice bUnitCost, @matlvalid bYN, @inlastcost bUnitCost
    
select @rcode = 0

if @um is null
begin
	select @msg = 'Missing Unit of Measure.', @rcode = 1
	goto bspexit
end

if @matlgroup is null
begin
	select @msg = 'Missing Material Group.', @rcode = 1
	goto bspexit
end
    
-- Run base validation of UM against bHQUM.
select @msg = Description from dbo.HQUM with (nolock) where UM = @um
if @@rowcount = 0
begin
	select @msg = 'Not a valid Unit of Measure.', @rcode = 1
	goto bspexit
end
   
-- get Material Valid flag from EMCo
select @matlvalid = IsNull(MatlValid,'N') from dbo.EMCO with (nolock) where EMCo = @emco

If exists (select top 1 1 from dbo.HQMT with (nolock) where MatlGroup = @matlgroup and Material = @material) or @matlvalid = 'Y'
begin
	-- JM 12-11-02 Ref Issue 19620 - rewrote this logic to return error if conversion from HQMT.StdUM to UM being
	-- validated doesn't exist and to assure that Inventoried materials look for conversion from HQMT.StdUM in INMU.
	if IsNull(@material,'')<>'' and IsNull(@inloc,'')='' --Non-inventoried material so compare HQMT to HQMU
	begin
		select @stdum = StdUM, @priceout = Price from dbo.HQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
		If @stdum <> @um
		begin
			-- Return Price from HQMU for MatlGroup/Material.
			select @priceout = Price from dbo.HQMU with (nolock) where MatlGroup = @matlgroup and Material = @material and UM = @um
			if @@rowcount = 0 
			begin
				-- Issue 127133
				--if @matlvalid = 'N' goto bspexit --not validating parts, no error
	 			select @msg = 'Conversion does not exist in HQMU for UM: ' + isnull(@um,'') + ' !', @rcode = 1
	 			goto bspexit
 			end
		end
	end
   
	-- Overwrite value from HQ with value from IN if user specified INLoc
	if IsNUll(@material,'')<>'' and IsNull(@inloc,'')<>'' --Inventoried material so compare HQMT to INMU
	begin
		select @stdum = StdUM from dbo.HQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
		select @lastcost=LastCost, @avgcost=AvgCost, @stdunitcost=StdCost, @stdprice=StdPrice, @emrate=EquipRate
		from dbo.INMT with (nolock) where INCo= @inco and Loc=@inloc and Material=@material and MatlGroup=@matlgroup
		if @um <> @stdum
		begin
			select @inumconv = Conversion, @incost = StdCost, @inprice = Price, @inlastcost = LastCost
			from dbo.INMU with (nolock) where INCo = @inco and Material=@material and MatlGroup=@matlgroup and Loc = @inloc and UM = @um
			if @inumconv is null
				begin
					select @hqumconv = Conversion, @hqcost = Cost,	@hqprice = Price 
					from dbo.HQMU with (nolock) where Material=@material and MatlGroup=@matlgroup and UM = @um
					if @@rowcount = 0
						begin
							select @msg = 'Conversion does not exist in INMU or HQMU for UM ' + isnull(@um,'') + '!', @rcode = 1
	 						goto bspexit
		 				end
					else
						begin
							-- Conversion based on HQMU
							select @avgcost = @avgcost * @hqumconv, 
							@stdunitcost = @hqcost, @stdprice = @hqprice,
							@lastcost = @lastcost * @hqumconv
						end
				end
			else
				begin
					-- Conversion based on INMU
					select @avgcost = @avgcost * @inumconv, 
					@stdunitcost = @incost, @stdprice = @inprice,
					@lastcost = @lastcost * @inumconv
					-- @lastcost= case when @inlastcost = 0 then @lastcost * @inumconv else @inlastcost end
				end
		end
   
		-- Get Price Option to determine correct UnitPrice
		select @equippriceopt=EquipPriceOpt from dbo.INCO with (nolock) where INCo=@inco
		select  @priceout = case @equippriceopt
		when 1 then @avgcost+(@avgcost*@emrate)
   		when 2 then @lastcost+(@lastcost*@emrate)
   		when 3 then @stdunitcost+(@stdunitcost*@emrate)
   		when 4 then @stdprice-(@stdprice*@emrate) end
	end
end

bspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspEMUMValForFuelPosting] TO [public]
GO
