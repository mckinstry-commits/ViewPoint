SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspMSVendorVal]
   /***********************************************************
    * Created By:  GF 03/03/2000
    * Modified By:
    *
    * Usage: Used within MS to validate the entry by either Sort Name or number.
    *
    * Input params:
    *	@vendgroup	Vendor Group
    *	@vendor		Vendor sort name or number
    *
    * Output params:
    *	@vendorout	Vendor number
    *	@msg		Vendor Name or error message
    *
    * Return code:
    *	0 = success, 1 = failure
    *****************************************************/
   (@vendorgroup bGroup = null, @vendor varchar(15) = null,
    @vendorout bVendor=null output, @msg varchar(255) output)
   
    as
    set nocount on
    declare @rcode int, @type char(1), @active bYN
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
   
   -- If @vendor is numeric then try to find Vendor number
   if isnumeric(@vendor) = 1
      select @vendorout=Vendor, @msg=Name
      from APVM where VendorGroup=@vendorgroup and Vendor=convert(int,convert(float, @vendor))
      -- if not numeric or not found try to find as Sort Name
      if @@rowcount = 0
   	  begin
         select @vendorout=Vendor, @msg=Name
   	  from APVM where VendorGroup=@vendorgroup and SortName=@vendor
   	  -- if not found, try to find closest
      	  if @@rowcount = 0
          	 begin
            set rowcount 1
            select @vendorout=Vendor, @msg=Name
   		 from APVM
   		 where VendorGroup=@vendorgroup and SortName like @vendor + '%'
   		 if @@rowcount = 0
    	  		begin
   	    	select @msg = 'Not a valid Vendor', @rcode = 1
   			goto bspexit
   	   		end
   		 end
   	  end
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSVendorVal] TO [public]
GO
