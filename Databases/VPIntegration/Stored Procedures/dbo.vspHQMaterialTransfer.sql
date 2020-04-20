SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHQMaterialTransfer]
   /*************************************************
   *	Created By:	TRL 05/09/2006
   *	 
   *
   *	This procedure will transfer records from HQMT and  HQMU to INMT and INMU 
   *	if  Materials that are flagged as Stocked and Active.
   *	menu item on form HQMT (frmHQMatl) calls this procedure.
   *
   *	Inputs:
   *		@matl		Material
   *		@matlgroup	Material Group
   *		@um			Alternative unit of measure 
   *
   *	Outputs:
   *		@msg		Procedure Message
   *
   *	Return Code:
   *		@rcode = 0 if successful, 1 if failure
   *
   *************************************************/
    
    (@inco tinyint = 0, @material bMatl = null, @matlgroup bGroup = null, @loc varchar(10) = null, @lastupdate smalldatetime = null,
@cost bUnitCost = '0', @cecm bECM = 'E', @price bUnitCost = 0, @pecm bECM = 'E', @conversion bUnitCost = 0, @msg varchar(256) output)
    
   as
   set nocount on
    
 declare @rcode int
    	
   select @rcode = 0

   if @inco is null
    	begin
    	select @msg = 'Missing IN Company!', @rcode = 1
    	goto vspexit
    	end 
   
   if @matlgroup is null
    	begin
    	select @msg = 'Missing Material Group!', @rcode = 1
    	goto vspexit
    	end 

   if @material is null
    	begin
    	select @msg = 'Missing Material!', @rcode = 1
    	goto vspexit
    	end
   
   
	if not exists(select 1 from bINMT where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup	and Material = @material)
      		-- add new u/m for this material and location
   			insert bINMT (INCo, Loc, MatlGroup, Material,  LastCost, LastECM, LastCostUpdate, AvgCost, AvgECM, StdCost, StdECM,  StdPrice, PriceECM, WeightConv,
				LowStock,ReOrder, CustRate, JobRate, InvRate, EquipRate, OnHand, RecvdNInvcd,Alloc,OnOrder,Booked, Active,AutoProd, GLSaleUnits, AuditYN)
   			values (@inco, @loc, @matlgroup, @material, @cost, @cecm, @lastupdate, @cost, @cecm,@cost, @cecm,@price, @pecm,@conversion,0,0,0,0,0,0,0,0,0,0,0,'Y','N','N','Y' )
  
 
   vspexit:
	   	if @rcode <> 0 select @msg = isnull(@msg,'') + char(13) + char(10) + '[bspHQMaterialTransfer]'
       	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQMaterialTransfer] TO [public]
GO
