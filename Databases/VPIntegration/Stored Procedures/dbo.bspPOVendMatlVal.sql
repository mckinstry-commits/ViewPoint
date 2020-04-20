SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOVendMatlVal    Script Date: 8/28/99 9:33:10 AM ******/
   CREATE  proc [dbo].[bspPOVendMatlVal]
   /***********************************************************
    * CREATED BY: kb 11/3/99
    * MODIFIED By : kb 1/23/00 added return of the POVM description and um
    *              kb 4/10/2 - issue #16911
    *
    * USAGE:
    * validates PO Vendor Material and if exists returns the corresponding
    * unit price and HQMT material
    *
    * INPUT PARAMETERS
    *   Vendor Vendor to validate
    *   VendorMatl Vendor Material to validate
    * OUTPUT PARAMETERS
    *   @hqmtmatl
    *   @unitprice
    *   @msg      error message if error occurs otherwise Description of EarnCode
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   	(@vendorgroup bGroup, @vendor bVendor, @matlgroup bGroup, @vendmatl varchar(30),
        @hqmtmatl bMatl output,  @matldesc varchar(60) output, @um bUM output,
        @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @errmsg varchar(60)
   
   select @rcode = 0
   
   if @vendorgroup is null
   	begin
   	select @msg = 'Missing Vendor Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @vendmatl is null
       begin
       select @msg = 'Missing Vendor Material #', @rcode = 1
       goto bspexit
       end
   
   select @um = min(UM) from POVM where MatlGroup = @matlgroup and
       VendorGroup = @vendorgroup and Vendor = @vendor and VendMatId = @vendmatl
   if @um is null
       begin
       select @um = min(UM) from POSM where MatlGroup = @matlgroup and
         VendorGroup = @vendorgroup and Vendor = @vendor and VendMatId = @vendmatl
       if @um is not null
           begin
           select @hqmtmatl=Material, @msg = Description
             from POSM where MatlGroup = @matlgroup and
             VendorGroup = @vendorgroup and Vendor = @vendor
             and VendMatId = @vendmatl and UM=@um
           end
       end
   
   
   select @hqmtmatl=Material, @msg = Description
       from POVM where MatlGroup = @matlgroup and
       VendorGroup = @vendorgroup and Vendor = @vendor and VendMatId = @vendmatl and UM=@um
   select @matldesc = @msg
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOVendMatlVal] TO [public]
GO
