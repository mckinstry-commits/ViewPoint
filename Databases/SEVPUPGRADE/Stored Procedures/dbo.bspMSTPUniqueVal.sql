SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSTPUniqueVal]
   /*************************************
   * Created By:   GF 03/02/2000
   * Modified By:  GF 10/10/2000
   *
   * validates MSCo,PriceTemplate,LocGroup,FromLoc,MatlGroup,Material,UM
   * to MSTP for uniqueness.
   *
   * Pass:
   *   MSCo,PriceTemplate,LocGroup,FromLoc,MatlGroup,Category,Material,UM,Seq
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany, @pricetemplate smallint, @locgroup bGroup, @fromloc bLoc,
    @matlgroup bGroup, @category varchar(10), @material bMatl, @um bUM,
    @seq int = null, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0, @msg=''
   
   if @msco is null
       begin
       select @msg = 'Missing MS Company!', @rcode=1
       goto bspexit
       end
   
   if @pricetemplate is null
       begin
       select @msg = 'Missing Price Template!', @rcode=1
       goto bspexit
       end
   
   if @locgroup is null
       begin
       select @msg = 'Missing Location Group!', @rcode=1
       goto bspexit
       end
   
   if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group!', @rcode=1
   	goto bspexit
   	end
   
   if @category is null
       begin
       select @msg = 'Missing Material Category!', @rcode=1
       goto bspexit
       end
   
   if @um is null
       begin
       select @msg = 'Missing Unit of measure!', @rcode=1
       goto bspexit
       end
   
   if @seq is null
       begin
       select @validcnt = Count(*) from bMSTP
       where MSCo=@msco and PriceTemplate=@pricetemplate and LocGroup=@locgroup
       and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
       and Material=@material and UM=@um
       if @validcnt >0
          begin
          select @msg = 'Duplicate record, cannot insert!', @rcode=1
          goto bspexit
          end
       end
   else
       begin
       select @validcnt = Count(*) from bMSTP
       where MSCo=@msco and PriceTemplate=@pricetemplate and LocGroup=@locgroup
       and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
       and Material=@material and UM=@um and Seq<>@seq
       if @validcnt >0
          begin
          select @msg = 'Duplicate record, cannot insert!', @rcode=1
          goto bspexit
          end
       end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTPUniqueVal] TO [public]
GO
