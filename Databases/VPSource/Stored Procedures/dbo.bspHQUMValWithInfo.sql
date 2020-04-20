SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQUMValWithInfo    Script Date: 8/28/99 9:34:56 AM ******/
   CREATE   proc [dbo].[bspHQUMValWithInfo]
   /**********************************************************
    * CREATED BY:  JM 2/9/99
    * MODIFIED BY: 	RH 2/12/99 - Corrected returned Price to be either (1) from HQMU if passed UM <> HQMT.SalesUM
    *			or (2) HQMT.Price if passed UM = HQMT.SalesUM.
    *		JM 2/24/99 - Removed rejection if @material is passed in as null since forms using this val
    *			routine need to allow entry of a UM when Material has not been entered (EMCostAdj and
    *			EMPartsPosting). Also added restriction to get SalesUM and Price from HQMT for the material
    *			passed in only when @material is not null.
    *		JM 6/5/01 - Changed method that extracts price to include inventory when INLoc specified.
    *			Changed comparison in HQ section to StdUM from SalesUM per DanF.
    *		JM 5/28/02 - Ref Issue 17427 - Added error condition when conversion does not exist in INMU for UM
    * 		JM 12-11-02 Ref Issue 19620 - rewrote this logic to return error if conversion from HQMT.StdUM to UM being validated doesn't exist 
    *		and to assure that Inventoried materials look for conversion from HQMT.StdUM in INMU.
   			RM 03/26/04 - Issue# 23061 - Added IsNulls
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
    (@um bUM = null,
    @matlgroup bGroup = null,
    @material bMatl = null,
    @inco bCompany = null,
    @inloc bLoc = null,
    @price bUnitCost output,
    @msg varchar(60) output)
    
    as
    set nocount on
    
    declare @rcode int,
    	@stdum bUM,
    	@stdunitcost bUnitCost,
    	@equippriceopt as tinyint,
    	@emrate as bRate,
    	@lastcost bUnitCost,
    	@avgcost bUnitCost,
    	@stdprice bUnitCost,
    	@hqumconv bUnits,
    	@hqcost bUnitCost,
    	@hqprice bUnitCost,
    	@inumconv bUnits,
    	@incost bUnitCost,
    	@inprice bUnitCost
    
    select @rcode = 0
    
    if @um is null
    	begin
    	select @msg = 'Missing Unit of Measure!', @rcode = 1
    	goto bspexit
    	end
    if @matlgroup is null
    	begin
    	select @msg = 'Missing Material Group!', @rcode = 1
    	goto bspexit
    	end
    
    /* Run base validation of UM against bHQUM. */
    select @msg = Description
    from bHQUM
    where UM = @um
    if @@rowcount = 0
    	begin
    	select @msg = 'Not a valid Unit of Measure', @rcode = 1
    	goto bspexit
    	end
    
    /* JM - Following replaced 6/5/01 to include inventory option for extracting price. */
    /* Get SalesUM and Price from HQMT for this material. */
    /*if @material is not null
    	begin
    	select @salesum = SalesUM, @price = Price
    	from bHQMT
    	where MatlGroup = @matlgroup	and Material = @material
    	If @salesum <> @um
    		-- Return Price from HQMU for MatlGroup/Material.
    		select @price = Price
    		from bHQMU
    		where MatlGroup = @matlgroup	and Material = @material and UM = @um
    	end*/
   
   /* Replaced with: */
   /* JM 12-11-02 Ref Issue 19620 - rewrote this logic to return error if conversion from HQMT.StdUM to UM being validated doesn't exist 
   and to assure that Inventoried materials look for conversion from HQMT.StdUM in INMU. */
   if @material is not null and @inloc is null --Non-inventoried material so compare HQMT and HQUM
    	begin
    	select @stdum = StdUM, @price = Price from bHQMT where MatlGroup = @matlgroup and Material = @material
    	If @stdum <> @um
   		begin
   		-- Return Price from HQMU for MatlGroup/Material.
    		select @price = Price from bHQMU where MatlGroup = @matlgroup and Material = @material and UM = @um
   		/* JM 12-11-02 Ref Issue 19620 - Return error if conversion from HQMT.StdUM to UM being validated doesn't exist */
   		if @@rowcount = 0
   		 	begin
   		 	select @msg = 'Conversion does not exist in HQMU for UM ' + isnull(@um,'') + '!', @rcode = 1
   		 	goto bspexit
   		 	end
   		end
    	end
   
   /* Overwrite value from HQ with value from IN if user specified INLoc */
   if @material is not null and  @inloc is not null --Inventoried material so compare HQMT and INMU
   	begin
    	select @stdum = StdUM from bHQMT where MatlGroup = @matlgroup and Material = @material
   	select @lastcost=LastCost, @avgcost=AvgCost, @stdunitcost=StdCost,@stdprice=StdPrice, @emrate=EquipRate
   	from bINMT where INCo= @inco and Loc=@inloc and Material=@material and MatlGroup=@matlgroup
   	if @um <> @stdum
   		begin
   		select @inumconv = Conversion, @incost = StdCost, @inprice = Price from INMU where INCo = @inco and Material=@material and MatlGroup=@matlgroup and Loc = @inloc and UM = @um
   		if @inumconv is null
   			begin
   			select @hqumconv = Conversion, @hqcost = Cost,	@hqprice = Price from HQMU where Material=@material and MatlGroup=@matlgroup and UM = @um
   			if @@rowcount = 0
   		 		begin
   			 	select @msg = 'Conversion does not exist in INMU or HQMU for UM ' + isnull(@um,'') + '!', @rcode = 1
   		 		goto bspexit
   			 	end
   			else
   				select @avgcost = @avgcost * @hqumconv, @lastcost = @lastcost * @hqumconv, @stdunitcost = @hqcost, @stdprice = @hqprice
   			end
   		else
   			select @avgcost = @avgcost * @inumconv, @lastcost = @lastcost * @inumconv, @stdunitcost = @incost, @stdprice = @inprice
   		end
   
   	select @equippriceopt=EquipPriceOpt from bINCO where INCo=@inco
   	select  @price =
   		case @equippriceopt
   		when 1 then @avgcost+(@avgcost*@emrate)
   		when 2 then @lastcost+(@lastcost*@emrate)
   		when 3 then @stdunitcost+(@stdunitcost*@emrate)
   		when 4 then @stdprice-(@stdprice*@emrate)
   		end
   	end
   
   
   
   
   
   
    
   bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQUMValWithInfo] TO [public]
GO
