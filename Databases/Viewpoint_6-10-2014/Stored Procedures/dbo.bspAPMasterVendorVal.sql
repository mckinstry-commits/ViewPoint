SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPMasterVendorVal   ******/
   CREATE       proc [dbo].[bspAPMasterVendorVal]
   
   /***********************************************************
    * CREATED BY: MV 07/30/02
    * MODIFIED By : kb 10/28/2 - issue #18878 - fix double quotes
    *		ES 03/11/04 - #23061 isnull wrapping
    *		MV 05/31/06 - #26388 6X - convert mastervendor to uppercase
    *
    * Usage:
    *	Used by APVM to validate the master vendor entry by either Sort Name or number.
    *	Ignores validation for new vendor numbers.
    *
    * Input params:
    *	@vendgroup	Vendor Group
    *	@vendormaster	Vendor sort name or number
    *
    * Output params:
    *	@vendorout	Vendor number
    *	@msg		Vendor Name or error message
    *
    * Return code:
    *	0 = success, 1 = failure
    *****************************************************/
   (@vendgroup bGroup = null,@vendor bVendor = null, @mastervendor varchar(15) = null, 
   	@mastervendorout bVendor=null output,@msg varchar(60)=null output)
   as
   set nocount on
   declare @rcode int, @active bYN
   select @rcode = 0
   /* check required input params */
   if @vendgroup is null
   	begin
   	select @msg = 'Missing Vendor Group.', @rcode = 1
   	goto bspexit
   	end
   
   if @mastervendor is null
   	begin
   	select @msg = 'Missing Master Vendor.', @rcode = 1
   	goto bspexit
   	end
   
   /* If @mastervendor is numeric then try to find Vendor number */
   if isnumeric(@mastervendor) = 1
   	select @mastervendorout = Vendor, @msg = Name
   	from APVM
   	where VendorGroup = @vendgroup and Vendor = convert(int,convert(float, @mastervendor))
   /* if not numeric or not found try to find as Sort Name */
   if @@rowcount = 0
   	begin
       	 select @mastervendorout = Vendor, @msg = Name
   	 from APVM
   	 where VendorGroup = @vendgroup and SortName = upper(@mastervendor)
   	 /* if not found,  try to find closest */
      	 if @@rowcount = 0
          	begin
           		set rowcount 1
           		select @mastervendorout = Vendor,@msg = Name
   			 from APVM
   			 where VendorGroup = @vendgroup and SortName like upper(@mastervendor) + '%'
   			 if @@rowcount = 0
   	 	  	 begin
   		            select @msg = 'Master Vendor ' + isnull(Convert(varchar(6), @mastervendor), '') + ' is not on file.'   --#23061
   		            /*if isnumeric(@mastervendor) <> 0
   		                select @mastervendorout = @mastervendor
   			    	  else
   		                select @mastervendorout = null*/
   				  select @rcode=1
   		            goto bspexit
   		   	 end
   		end
   	end
   
   --make sure the vendor is not already a master vendor
   select * from bAPVM where VendorGroup=@vendgroup and MasterVendor= @vendor
   	if @@rowcount <> 0
   	begin
   	select @msg = 'Vendor ' + isnull(Convert(varchar(6), @vendor), '') + ' is a master vendor and cannot be a sub vendor.'  --#23061
   	select @rcode=1
   	goto bspexit
   	end
   	
   -- make sure the master vendor is not already a sub vendor
   select * from bAPVM where VendorGroup=@vendgroup and Vendor=@mastervendorout and MasterVendor is not null
   	if @@rowcount <> 0
   	begin
   	select @msg = 'Vendor ' + isnull(Convert(varchar(6), @mastervendor), '') + ' is a sub vendor and cannot be a master vendor.'  --#23061
   	select @rcode=1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPMasterVendorVal] TO [public]
GO
