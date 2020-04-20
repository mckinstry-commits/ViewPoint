SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSMatlUMVal]
   /*************************************
   * Created By:   GF 03/01/2000
   * Modified By:
   *
   * validates Unit of measure to HQUM.UM and HQMT.STDUM and HQMU.UM
   *
   * Pass:
   *	HQ MatlGroup
   *	HQ Material
   *   HQ UM
   *
   * Success returns:
   *   Payment Discount Rate
   *	0 and Description from bHQUM
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@matlgroup bGroup = null, @material bMatl = null, @um bUM = null,
    @paydiscrate bUnitCost output, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @validcnt int, @stdum bUM
   select @rcode = 0, @paydiscrate=0
   
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
   
   if @material is null GOTO bspexit
   
   select @paydiscrate=isnull(PayDiscRate,0)
       from bHQMU where MatlGroup=@matlgroup and Material=@material and UM=@um
       if @@rowcount=0
          begin
            select @stdum=StdUM, @paydiscrate=isnull(PayDiscRate,0)
            from bHQMT where MatlGroup=@matlgroup and Material=@material
            if @@rowcount=0
               begin
               select @msg = 'Invalid material!', @rcode=1
               goto bspexit
               end
            if @stdum<>@um
               begin
               select @msg = 'Invalid unit of measure, not standard or in HQMU!', @rcode=1
               goto bspexit
               end
          end
   
   bspexit:
       if @rcode<>0 select @msg= isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSMatlUMVal] TO [public]
GO
