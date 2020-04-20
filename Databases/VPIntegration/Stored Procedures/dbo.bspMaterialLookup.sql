SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspMaterialLookup]
   /*****************************************************************************
   * Created By: danf 07/17/00
   * Modified by:
   *
   * Material List based on Inventory Items or Non Stocked Items
   *
   * Pass:
   * MaterialGroup, Inventory Company, Inventory Location
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   *******************************************************************************/
   	(@matlgrp bGroup = null, @inco bCompany = null, @loc bLoc = null)
   as
   	set nocount on
   	declare @rcode int, @msg varchar(60)
   	select @rcode = 0
   
   
   --check whether material exists in HQMT
   if @loc is null or @inco is null
    begin
      select Material, Description
      from bHQMT
      where MatlGroup=@matlgrp
     end
    else
     begin
      select a.Material, b.Description
      from bINMT a
      JOIN bHQMT b on a.MatlGroup=b.MatlGroup and a.Material=b.Material
      where a.INCo = @inco and a.Loc = @loc
     end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMaterialLookup] TO [public]
GO
