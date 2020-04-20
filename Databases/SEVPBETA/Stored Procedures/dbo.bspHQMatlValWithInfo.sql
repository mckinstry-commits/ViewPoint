SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatlValWithInfo    Script Date: 8/28/99 9:36:18 AM ******/
   CREATE  proc [dbo].[bspHQMatlValWithInfo]
   /********************************************************
   * CREATED BY: 	cjw 6/3/97
   * MODIFIED BY:	cjw 6/3/97
   *
   * USAGE:
   * 	Retrieves the Standard Price, StandardUM, ECM,for a Material from bHQMT
   *
   * INPUT PARAMETERS:
   *	HQ Material Group
   *	HQ Material
   *	
   * OUTPUT PARAMETERS:
   *	Unit price from HQMT 
   *	PriceUM, PriceECM
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   	(@matlgroup bGroup=0, @material bMatl=null, @price bUnitCost output, @stdum bUM output, 
   	@PriceECM bECM=null output,  @cost bUnitCost output, @purchaseUM bUM output, @phase bPhase output, 
   	@ct bJCCType output, @msg varchar(60) output)
   
   as
   	set nocount on
   	declare @rcode int
   	select @rcode=0
   	declare @stdcost bUnitCost	
   
   if @matlgroup= 0 
   	begin
   	select @msg='Missing HQ Material Group', @rcode=1
   	goto bspexit
   	end
   if @material is null
   	begin
   	select @msg='Missing HQ Material#', @rcode=1
   	goto bspexit
   	end
   
   /*Need to first validate Material using other stored procedure */
   exec @rcode=bspHQMatlVal @matlgroup, @material, @msg=@msg output
   if @rcode=1 goto bspexit
   
   select @price=isNull(Price,0), @PriceECM=PriceECM, @stdum=StdUM, @cost=isNull(Cost,0), 
   		@purchaseUM=PurchaseUM, @ct=MatlJCCostType, @phase=MatlPhase from bHQMT
   where MatlGroup=@matlgroup and Material=@material
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQMatlValWithInfo] TO [public]
GO
