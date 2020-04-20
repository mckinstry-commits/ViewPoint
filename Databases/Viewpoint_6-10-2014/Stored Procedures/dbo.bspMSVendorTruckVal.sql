SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSVendorTruckVal]
   /*************************************
   * Created By:	GF 03/02/2000
   * Modified By:	
   *
   * validates MS Vendor Truck
   *
   * Pass:
   *	VendorGroup and Vendor and Truck to be validated
   *
   * Success returns:
   *	0 and Description from bMSVT
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@vendorgroup bGroup = null, @vendor bVendor = null, @truck bTruck = null, 
	@msg varchar(255) output)

   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @vendorgroup is null
   	begin
   	select @msg = 'Missing Vendor Group', @rcode = 1
   	goto bspexit
   	end
   
   if @vendor is null
   	begin
   	select @msg = 'Missing Vendor', @rcode = 1
   	goto bspexit
   	end
   
   if @truck is null
   	begin
   	select @msg = 'Missing Vendor Truck', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bMSVT where VendorGroup=@vendorgroup
       and Vendor=@vendor and Truck=@truck
       if @@rowcount = 0
           begin
   		select @msg = 'Not a valid Vendor Truck', @rcode = 1
           goto bspexit
   		end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSVendorTruckVal] TO [public]
GO
