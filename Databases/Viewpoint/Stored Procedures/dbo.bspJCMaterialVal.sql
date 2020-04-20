SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspJCMaterialVal]
/*****************************************************************************
* Created By: danf 02/27/2000
*				TV - 23061 added isnulls
*
* validates Material
*
* Pass:
*	Material, MaterialGroup, INCO, Loc
*
* Success returns:
*	Material Description
*
* Error returns:
*	1 and error message
*******************************************************************************/
   	(@material bMatl = null, @matlgrp bGroup = null, @inco bCompany = null, @loc bLoc = null, @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int, @stocked bYN, @active bYN

   	select @rcode = 0
   
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
   
   --check whether material exists in HQMT
     select @msg=Description
     from bHQMT
     where Material=@material and MatlGroup=@matlgrp
     if @@rowcount = 0
       begin
       select @msg='Not set up in HQ Material', @rcode=1
       goto bspexit
       end
 
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCMaterialVal] TO [public]
GO
