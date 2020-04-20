SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspINCopyMatlVal]
   /*************************************
   * Created By: GR 11/6/99
   * Modified By: RM 12/23/02 Cleanup Double Quotes
   
   * validates the material to be copied
   *
   * Pass:
   *	INCO, Location, Material
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@inco bCompany = null, @loc bLoc = null, @material bMatl = null, @msg varchar(100) output)
   as
   	set nocount on
   	declare @rcode int, @matlgroup bGroup
   	select @rcode = 0
   
   if @inco is null
       begin
       select @msg='Missing IN Company', @rcode=1
       goto bspexit
       end
   
   if @loc is null
       begin
       select @msg='Missing Location', @rcode=1
       goto bspexit
       end
   
   if @material is null goto bspexit
   
   select @matlgroup=MatlGroup from bHQCO where HQCo=@inco
   
   if @matlgroup is not null
       begin
       select * from bINMT
       where MatlGroup=@matlgroup and INCo=@inco and Loc=@loc and Material=@material
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid material for this Location', @rcode = 1
   		end
       else
           begin
           select @msg=Description from bHQMT where Material=@material and MatlGroup=@matlgroup
           end
       end
   
   bspexit:
       if @rcode<>0 select @msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINCopyMatlVal] TO [public]
GO
