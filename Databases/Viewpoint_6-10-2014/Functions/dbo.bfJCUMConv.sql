SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    function [dbo].[bfJCUMConv]
  (@matlgroup bGroup, @material bMatl,@pstum bUM, @jcum bUM)
      returns bUnitCost
   /***********************************************************
    * CREATED BY	: DANF 04/11/2004
    * MODIFIED BY	
    *
    * USAGE:
    * Used to return the JC Unit of measure conversion
    *
    * INPUT PARAMETERS
    * 	@matlgroup bGroup
    * 	@material bMatl
    * 	@pstum bUM
    *	@jcum bUM
    *
    * OUTPUT PARAMETERS
    *  @jcumconv      jcconvserion factor
    *
    *****************************************************/
      as
      begin
  
 		declare @hqmatl bYN, @stdum bUM, @umconv bUnitCost, @jcumconv bUnitCost, @rcode int, @errmsg varchar(255)
 
         -- init material defaults
         select @hqmatl = 'N', @stdum = null, @umconv = 0, @jcumconv = 0
 
 		if @pstum = @jcum 
 			begin
 			select  @jcumconv = 1
 			goto exitfunction
 			end
 
 
         -- check for Material in HQ
         select @stdum = StdUM
         from dbo.bHQMT WITH (NOLOCK)
         where MatlGroup = @matlgroup and Material = @material
         if @@rowcount = 1
              begin
              select @hqmatl = 'Y'    -- setup in HQ Materials
              if @stdum = @pstum select @umconv = 1
              end
          -- validate Unit of Measure
          if not exists(select 1 from dbo.bHQUM WITH (NOLOCK) where UM = @pstum)
              begin
              goto exitfunction
              End
              -- if HQ Material, validate UM and get unit of measure conversion
          if @hqmatl = 'Y' and @pstum <> @stdum
        		 begin
              select @umconv = Conversion
              from dbo.bHQMU WITH (NOLOCK)
              where MatlGroup = @matlgroup and Material = @material and UM = @pstum
              if @@rowcount=0
                  begin
                  goto exitfunction
                  End
        		 End
 
          if @hqmatl = 'Y' and isnull(@jcum,'') <> @pstum
              begin
 				if isnull(@stdum,'') = @jcum
 					begin
 					select @jcumconv = 1   -- conversion factor = 1
 					goto setconversion
 					end
 				-- check for non standard UM for this material
 				select @jcumconv = isnull(Conversion,0)   -- conversion will remain 0.00 if not found in bHQMU
 				from dbo.bHQMU with (nolock)
 				where MatlGroup = @matlgroup and Material = @material and UM = @jcum
 	             if @@rowcount=0
 	                 begin
 	                 goto exitfunction
 	                 End
 				setconversion:
   				if @jcumconv <> 0 select @jcumconv = @umconv / @jcumconv
             End
   
 
  	exitfunction:
  			
  	return @jcumconv
      end

GO
GRANT EXECUTE ON  [dbo].[bfJCUMConv] TO [public]
GO
