SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         function [dbo].[bfINUMConv]
  (@matlgroup bGroup, @material bMatl, @inco bCompany, @loc bLoc, @pstum bUM)
      returns bUnitCost
   /***********************************************************
    * CREATED BY	: DANF 04/11/2004
    * MODIFIED BY	
    *
    * USAGE:
    * Used to return the IN Unit of measure conversion
    *
    * INPUT PARAMETERS
    * 	@matlgroup bGroup
    * 	@material bMatl
    * 	@inco bCompany
    *	@loc bLoc
    * 	@pstum bUM
    *
    * OUTPUT PARAMETERS
    *  @umconv      in convserion factor
    *
    *****************************************************/
      as
      begin
  
 		declare @hqmatl bYN, @stdum bUM, @umconv bUnitCost, @rcode int, @msg varchar(255)
 
         -- init material defaults
         select @hqmatl = 'N', @stdum = null, @umconv = 0
 
 		-- get material's standard unit of measure
 		select @stdum = StdUM
 		from dbo.bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
 		if @@rowcount = 0 goto exitfunction  -- no conversion available
 		if @stdum = @pstum
 			begin
 			select @umconv = 1   -- conversion factor = 1
 			goto exitfunction
 			end
 
 		-- check for non standard UM for this material
 		select @umconv = Conversion   -- conversion will remain 0.00 if not found in bHQMU
 		from dbo.bHQMU with (nolock)
 		where MatlGroup = @matlgroup and Material = @material and UM = @pstum
 
 		-- get conversion factor from bINMU if exists, overrides bHQMU
 		if @stdum <> @pstum
 			  begin
 			  select @umconv = Conversion
 			  from dbo.bINMU with (nolock)
 			  where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup
 			      and Material = @material and UM = @pstum
 			  end
   
 
  	exitfunction:
  			
  	return @umconv
     end

GO
GRANT EXECUTE ON  [dbo].[bfINUMConv] TO [public]
GO
