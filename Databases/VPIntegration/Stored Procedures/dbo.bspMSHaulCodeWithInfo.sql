SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE proc [dbo].[bspMSHaulCodeWithInfo]
/*************************************
* Created By:   GF 03/14/2000
* Modified By:  GF 01/15/2001
*				RM 05/31/01 Return whether RevBased Haul Code
*				GF 03/19/2004 - issue #24038 - haul rates by phase
*
*
* validates MS Haul Code and returns info
*
* Pass:
*	MSCo,HaulCode,LocGroup,FromLoc,MatlGroup,
*   Category,Material,TruckType,UM
*
* Success returns:
*   HaulBasis from bMSHC
*   HaulRate, MinAmt from bMSHR
*	0 and Description from bMSHC
*
* Error returns:
*	1 and error message
**************************************/
(@msco bCompany = null, @haulcode bHaulCode = null, @locgroup bGroup = null,
 @fromloc bLoc = null, @matlgroup bGroup = null, @category varchar(10) = null,
 @material bMatl = null, @trucktype varchar(10) = null, @um bUM = null,
 @haulbasis tinyint output, @haulrate bUnitCost output, @minamt bDollar output,
 @revbased bYN output, @msg varchar(255) output)
as
set nocount on
   
   declare @rcode int, @retcode int, @quote varchar(10), @zone varchar(10), @tmpmsg varchar(255)
   
   select @rcode=0, @quote = null, @zone = null, @haulrate=0, @minamt=0
   
   if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if @haulcode is null
   	begin
   	select @msg = 'Missing MS Haul Code', @rcode = 1
   	goto bspexit
   	end
   
   if @locgroup is null
       begin
       select @msg = 'Missing Location Group', @rcode = 1
       goto bspexit
       end
   
   if @matlgroup is null
       begin
       select @msg = 'Missing Material Group', @rcode = 1
       goto bspexit
       end
   
   select @msg=Description, @haulbasis=HaulBasis,@revbased = RevBased
       from bMSHC where MSCo=@msco and HaulCode=@haulcode
       if @@rowcount = 0
           begin
   		select @msg = 'Not a valid MS Haul Code', @rcode = 1
           goto bspexit
   		end
   
   
   -- get haul code values
   exec @retcode = bspMSTicHaulRateGet @msco, @haulcode, @matlgroup, @material, @category, @locgroup,
                   @fromloc, @trucktype, @um, @quote, @zone, @haulbasis, null, null, null,
   				@haulrate output, @minamt output, @tmpmsg output
   
   if @haulrate is null select @haulrate = 0
   if @minamt is null select @minamt = 0
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHaulCodeWithInfo] TO [public]
GO
