SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspINMatlUMVal]
   /***************************************************************************
   * Created By: GR 11/04/99
   * Modified: RM 03/08/02 - Look in HQMT for UM before in HQMU, or else it gives
   						  error if you use std UM
   *
   * validates Unit of Measure
   *
   * Pass:
   *	Material, Material Group, Unit of Measure
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   *****************************************************************************/
   	(@material bMatl = null, @matlgroup bGroup = null, @um bUM = null,
        @conv bUnitCost output, @cost bUnitCost output,  @costecm bECM output,
        @price bUnitCost output, @priceecm bECM output, @msg varchar(255) output)
   as
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   
   if @material is null
       begin
       select @msg='Missing Material', @rcode=1
       goto bspexit
       end
   
   if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group', @rcode = 1
   	goto bspexit
   	end
   
   select @cost=Cost,@costecm=CostECM,@price=Price,@priceecm=PriceECM,@conv=1 from HQMT
   where Material=@material and MatlGroup=@matlgroup and StdUM=@um
   if @@rowcount=0
   begin
   
   	select @conv=Conversion, @cost=Cost, @costecm=CostECM,
   	@price=Price, @priceecm=PriceECM
   	from bHQMU
   	where Material=@material and MatlGroup=@matlgroup and UM=@um
   		if @@rowcount = 0
   			begin
   			select @msg = 'Not a valid Unit of Measure for this material in HQ Materials/ Additional UM', @rcode = 1
   			goto bspexit
   			end
   end
   
   select @msg = Description from HQUM where UM=@um
   
   
   bspexit:
      -- if @rcode<>0 select @msg=@msg + ' [bspINMatlUMVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMatlUMVal] TO [public]
GO
