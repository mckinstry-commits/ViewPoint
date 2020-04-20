SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspMSPayCodeWithInfo]
   /*************************************
   * Created By:   GF 03/14/2000
   * Modified By:  GG 01/15/01	- removed Truck Type validation
   *               GF 01/15/2001 - use bspMSTicPayCodeRateGet
   *			   DAN SO 05/22/2008 - Issue# 28688 - added @payminamt to bspMSTicPayCodeRateGet call
   *
   * validates MS Pay Code and returns info
   *
   * Pass:
   *	MSCo,PayCode,LocGroup,FromLoc,MatlGroup,Category
   *   Material,TruckType,VendorGroup,Vendor,Truck,UM
   *
   * Success returns:
   *   PayBasis from bMSPC
   *   PayRate from bMSPR
   *	0 and Description from bMSPC
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @paycode bPayCode = null, @locgroup bGroup = null,
    @fromloc bLoc = null, @matlgroup bGroup = null, @category varchar(10) = null,
    @material bMatl = null, @trucktype varchar(10) = null, @vendorgroup bGroup = null,
    @vendor bVendor = null, @truck bTruck = null, @um bUM = null,
    @paybasis tinyint output, @payrate bUnitCost output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @retcode int, @quote varchar(10), @zone varchar(10), @tmpmsg varchar(255),
		   @payminamt bDollar
   
   select @rcode=0, @retcode = 0, @quote = null, @zone = null, @payrate=0
   
   if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if @paycode is null
   	begin
   	select @msg = 'Missing MS Pay Code', @rcode = 1
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
   
   if @vendorgroup is null
       begin
       select @msg = 'Missing Vendor Group', @rcode = 1
       goto bspexit
       end
   
   select @msg=Description, @paybasis=PayBasis
       from bMSPC where MSCo=@msco and PayCode=@paycode
       if @@rowcount = 0
           begin
   		select @msg = 'Not a valid MS Pay Code', @rcode = 1
           goto bspexit
   		end
   
   -- get Pay Rate
   exec @retcode = dbo.bspMSTicPayCodeRateGet @msco,@paycode,@matlgroup,@material,@category,@locgroup,
                   @fromloc,@quote,@trucktype,@vendorgroup,@vendor,@truck,@um,@zone,@paybasis,
                   @payrate output, @payminamt output, @tmpmsg output
   
   if @payrate is null select @payrate = 0
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPayCodeWithInfo] TO [public]
GO
