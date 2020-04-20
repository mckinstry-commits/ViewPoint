SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspINGetDefaultUnitPrice]
   /******************************************
   	Created: 04/05/02 RM
   	Modified: 07/24/02 RM - Changed to use Job Pricing Option instead of Inv. Pricing Option
   
   	Usage: Used to get the default unit price for Material Orders
   
   	
   ******************************************/
   (@inco bCompany = null, @location bLoc = null, @material bMatl = null, @matlgrp bGroup = null,
       @unitprice bUnitCost = null output, @msg varchar(100) = null output)
   as
   	set nocount on
   	declare @rcode int, @active bYN, @locgroup bGroup, @validcnt int,
           @stocked bYN, @category varchar(10), @jobpriceopt int
   	select @rcode = 0
   
   if @inco is null
       begin
       select @msg='Missing IN Company', @rcode=1
       goto bspexit
       end
   
   if @location is null or @location = ''
       begin
       select @msg='Missing Location', @rcode=1
       goto bspexit
       end
   
   if @material is null
       begin
       select @msg='Missing Material', @rcode=1
       goto bspexit
       end
   
   if @matlgrp is null
       begin
       select @msg='Missing Material Group', @rcode=1
       goto bspexit
       end
   
   --get Job sales price option from IN Company
   select @jobpriceopt=JobPriceOpt from bINCO where INCo=@inco
   
   --get category and material description
   select @stocked = Stocked
   from bHQMT
   where Material=@material and MatlGroup=@matlgrp
   if @@rowcount = 0
       begin
       select @msg='Material not set up in HQ Materials', @rcode=1
       goto bspexit
       end
   
   if @stocked = 'N'
       begin
       select @msg = 'Must be a Stocked Material.', @rcode = 1
       goto bspexit
       end
   
   
   
   --validate material in INMT
   select @unitprice=case @jobpriceopt when 1 then i.AvgCost + (i.AvgCost * i.JobRate)
                when 2 then i.LastCost + (i.LastCost * i.JobRate)
                when 3 then i.StdCost + (i.StdCost * i.JobRate)
                when 4 then i.StdPrice - (i.StdPrice * i.JobRate) end
   from bINMT i
   where i.INCo = @inco and i.Loc = @location and i.Material=@material and i.MatlGroup=@matlgrp
   if @@rowcount = 0
       begin
       select @msg='Material not set up in IN Location Materials', @rcode=1
       goto bspexit
       end
   
   
   
   
   
   bspexit:
    --   if @rcode<>0 select @msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINGetDefaultUnitPrice] TO [public]
GO
