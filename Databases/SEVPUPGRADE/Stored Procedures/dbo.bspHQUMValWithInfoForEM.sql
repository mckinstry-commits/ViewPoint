SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQUMValWithInfoForEM   Script Date: 8/28/99 9:34:56 AM ******/
CREATE     proc [dbo].[bspHQUMValWithInfoForEM]
/**********************************************************
* CREATED BY:  JM 2/9/99
* MODIFIED BY: 	RH 2/12/99 - Corrected returned Price to be either (1) from HQMU if passed UM <> HQMT.SalesUM
*		or (2) HQMT.Price if passed UM = HQMT.SalesUM.
*		JM 2/24/99 - Removed rejection if @material is passed in as null since forms using this val
*		routine need to allow entry of a UM when Material has not been entered (EMCostAdj and
*		EMPartsPosting). Also added restriction to get SalesUM and Price from HQMT for the material
*		passed in only when @material is not null.
*		JM 6/5/01 - Changed method that extracts price to include inventory when INLoc specified.
*		Changed comparison in HQ section to StdUM from SalesUM per DanF.
*		JM 5/28/02 - Ref Issue 17427 - Added error condition when conversion does not exist in INMU for UM
* 		JM 12-11-02 Ref Issue 19620 - rewrote this logic to return error if conversion from HQMT.StdUM to UM being validated doesn't exist 
*		and to assure that Inventoried materials look for conversion from HQMT.StdUM in INMU.
*		GF 02/19/2003 - copy of bspHQUMValWithInfo for EM. Consider parts
*		RM 03/26/04 - Issue# 23061 - Added IsNulls
*		TV 09/01/05 29697 - Unit Price is not calculated correctly, Price/100, when ECM C is used.
*		GF 01/24/2008 - issue #126872 - EM Type = 'Depn' only validate UM to HQUM when not null, otherwise do not care.
*		TRL 02/17/2008 - Issue 127133, added isnulls and begin/ends, changed value for HQ UM validation
*		GF 03/16/2010 - issue #138535 - hqum and inmu conversion factors should be bUnitCost
*		GF 04/02/2010 - rejection fix for issue #127133 no error when @@rowcount = 0
*
*
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
(@emco bCompany = null, @emtype varchar(10) = null, @um bUM = null, @matlgroup bGroup = null,
@material bMatl = null, @inco bCompany = null, @inloc bLoc = null, @price bUnitCost output,
@msg varchar(255) output)

as

set nocount on

declare @rcode int, @stdum bUM, @stdunitcost bUnitCost, @equippriceopt tinyint, @emrate bRate,
		@lastcost bUnitCost, @avgcost bUnitCost, @stdprice bUnitCost, @hqcost bUnitCost, 
		@hqprice bUnitCost, @incost bUnitCost,@inprice bUnitCost, @matlvalid bYN, 
		@inlastcost bUnitCost,@PerECM bECM, @AvgECM bECM, @LastECM bECM, @StdECM bECM,
		----#138535
		@hqumconv bUnitCost, @inumconv bUnitCost

select @rcode = 0

if @emco is null
begin
	select @msg = 'Missing EM Company!', @rcode = 1
	goto bspexit
end

---- if EM Type = 'DEPN' then validate to HQUM only
if @um is not null and @emtype = 'Depn'
begin
	---- Run base validation of UM against bHQUM.
	select @msg = Description from dbo.HQUM with (nolock) where UM = @um
	if @@rowcount = 0
	begin
		select @msg = 'Not a valid Unit of Measure', @rcode = 1
		goto bspexit
	end
end

if @emtype = 'Depn' 
begin
	goto bspexit
end

if IsNull(@um,'') = ''
begin
   	select @msg = 'Missing Unit of Measure!', @rcode = 1
   	goto bspexit
end
   
if @matlgroup is null
begin
	select @msg = 'Missing Material Group!', @rcode = 1
    goto bspexit
end
    
-- Run base validation of UM against bHQUM.
select @msg = Description from dbo.HQUM with (nolock) where UM = @um
if @@rowcount = 0
begin
	select @msg = 'Not a valid Unit of Measure', @rcode = 1
    goto bspexit
end
   
-- get Material Valid flag from EMCo
select @matlvalid = IsNull(MatlValid,'N') from dbo.EMCO with (nolock) where EMCo = @emco
--if @@rowcount = 0 
--begin
--	select @matlvalid = 'Y'
--end

if isnull(@emtype,'') = '' 
begin
	select @emtype = 'Equip'
end

-- remmed out next line - did not do anything whether exist or not. 
--If exists (select top 1 1 from dbo.HQMU with (nolock) where MatlGroup = @matlgroup and Material = @material) or @matlvalid = 'Y'    
-- JM 12-11-02 Ref Issue 19620 - rewrote this logic to return error if conversion from HQMT.StdUM
-- to UM being validated doesn't exist and to assure that Inventoried materials look for conversion
-- from HQMT.StdUM in INMU.
IF IsNull(@material,'')<> '' and IsNull(@inloc,'')='' --Non-inventoried material so compare HQMT and HQUM
BEGIN
	select @stdum = StdUM, @price = Price, @PerECM = PriceECM 
   	from dbo.HQMT with (nolock) 
   	where MatlGroup = @matlgroup and Material = @material
    If @stdum <> @um
   	Begin
   		-- Return Price from HQMU for MatlGroup/Material.
    	select @price = Price, @PerECM = PriceECM
   		from dbo.HQMU with (nolock) 
   		where MatlGroup = @matlgroup and Material = @material and UM = @um
   		---- #127133 GF
   		if @@rowcount = 0
			begin
	 		select @msg = 'Conversion does not exist in  HQ Matl Addl UMs (HQMU) for UM: ' + isnull(@um,'') + ' !', @rcode = 1
	 		goto bspexit
			end
			
		/*Start Issue #127133*/
   		if @@rowcount = 1 
   		begin
   			if @matlvalid = 'N' and @emtype in ('WO','Parts','Equip','Fuel') 
   			begin
   				select @price = (@price / case @PerECM when 'C' then 100 when 'M' then 1000 else 1 end)--TV 09/01/05 29697
    			goto bspexit --not validating parts, no error
   			end
		else
			begin
   		 		select @msg = 'Conversion does not exist in  HQ Matl Addl UMs (HQMU) for UM: ' + isnull(@um,'') + ' !', @rcode = 1
   		 		goto bspexit
			end
   	 	end
		/*End Issue #127133*/
		
   	End
	select @price = (@price / case @PerECM when 'C' then 100 when 'M' then 1000 else 1 end) --TV 09/01/05 29697
	
END
   
-- Overwrite value from HQ with value from IN if user specified INLoc
IF IsNull(@material,'')<>'' and  IsNull(@inloc,'')<>'' --Inventoried material so compare HQMT and INMU
BEGIN
	--TV 09/01/05 29697 - Unit Price is not calculated correctly, Price/100, when ECM C is used.
	select @stdum = StdUM from dbo.HQMT with (nolock) 
   	where MatlGroup = @matlgroup and Material = @material

   	select @lastcost=LastCost, @LastECM = LastECM, @avgcost=AvgCost, @AvgECM = AvgECM, @stdunitcost=StdCost, @StdECM = StdECM,
   	@stdprice=StdPrice, @PerECM = PriceECM, @emrate=EquipRate
   	from dbo.INMT with (nolock) 
   	where INCo= @inco and Loc=@inloc and Material=@material and MatlGroup=@matlgroup
   	If @um <> @stdum
   	Begin
   		select @inumconv = Conversion, @incost = StdCost, @inprice = Price, @inlastcost = LastCost
   		from dbo.INMU with (nolock) 
   		where INCo = @inco and Material=@material and MatlGroup=@matlgroup and Loc = @inloc and UM = @um
   		if @inumconv is null
   			begin
   				select @hqumconv = Conversion, @hqcost = Cost,	@hqprice = Price 
   				from dbo.HQMU with (nolock) 
   				where Material=@material and MatlGroup=@matlgroup and UM = @um
				if @@rowcount = 0
   	 				begin
   					 	select @msg = 'Conversion does not exist in INMU or HQMU for UM: ' + isnull(@um,'') + ' !', @rcode = 1
   						goto bspexit
   					end
   				else
					begin
   						select @avgcost = @avgcost * @hqumconv, @lastcost = @lastcost * @hqumconv,
   						@stdunitcost = @hqcost, @stdprice = @hqprice
					end
   	   		end
   		else
   			begin
   				select @avgcost = @avgcost * @inumconv,  @stdunitcost = @incost, @stdprice = @inprice,
   				@lastcost = @lastcost * @inumconv
   				-- @lastcost= case when @inlastcost = 0 then @lastcost * @inumconv else @inlastcost end
   			end
   		end
   
		--TV 09/01/05 29697 - Unit Price is not calculated correctly, Price/100, when ECM C is used.
   		select 	@lastcost = (@lastcost/case @LastECM when 'C' then 100 when 'M' then 1000 else 1 end),
    	@avgcost = (@avgcost/case @AvgECM when 'C' then 100 when 'M' then 1000 else 1 end),
    	@stdunitcost = (@stdunitcost/case @StdECM when 'C' then 100 when 'M' then 1000 else 1 end),
    	@stdprice = (@stdprice/case @PerECM when 'C' then 100 when 'M' then 1000 else 1 end)
   
   	   	select @equippriceopt=EquipPriceOpt from bINCO with (nolock) where INCo=@inco
   		select  @price = case @equippriceopt
   				when 1 then @avgcost+(@avgcost*@emrate)
   				when 2 then @lastcost+(@lastcost*@emrate)
   				when 3 then @stdunitcost+(@stdunitcost*@emrate)
   				when 4 then @stdprice-(@stdprice*@emrate)
   	End
END
    
bspexit:
   	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspHQUMValWithInfoForEM] TO [public]
GO
