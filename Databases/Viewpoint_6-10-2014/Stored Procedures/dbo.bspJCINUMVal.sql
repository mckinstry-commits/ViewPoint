SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspJCINUMVal]
   /*************************************
   * Created By:   DANF 02/27/2000
   * Modified By: TV - 23061 added isnulls
   *
   * validates Unit of measure to HQUM.UM and HQMT.STDUM and HQMU.UM
   *
   * Pass:
   *	HQ MatlGroup
   *	HQ Material
   *   HQ UM
   *
   * Success returns:
   *
   *	0 and Description from bHQMT
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@matlgroup bGroup = null, @material bMatl = null, @um bUM = null,  @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @validcnt int, @stdum bUM, @unitprice bUnitCost, @umconv bUnitCost
   select @rcode = 0, @unitprice = 0
   
   if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @um is null
       begin
       select @msg = 'Missing Unit of measure!', @rcode=1
       goto bspexit
       end
   
   select @msg=Description from bHQUM where UM=@um
       if @@rowcount=0
           begin
           select @msg = 'Invalid Unit of measure!', @rcode = 1
           goto bspexit
           end
   
   exec @rcode = bspHQStdUMGet @matlgroup, @material, @um, @umconv output, @stdum output, @msg output
   if @rcode <> 0 goto bspexit
   
   if rtrim(@material)='' GOTO bspexit
   
   select @unitprice=isnull(Price,0)
       from bHQMU where MatlGroup=@matlgroup and Material=@material and UM=@um
       if @@rowcount=0
          begin
            select @stdum=StdUM
            from bHQMT where MatlGroup=@matlgroup and Material=@material
            if @@rowcount=0
               begin
               goto bspexit
               end
            if @stdum<>@um
               begin
               select @msg = 'Unit of measure is not set up for this material.', @rcode=1
               goto bspexit
               end
          end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCINUMVal] TO [public]
GO
