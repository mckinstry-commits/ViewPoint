SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
   CREATE   proc [dbo].[bspPMFirmVendorVal]
   /*********************************************
    * CREATED BY:	 GF 01/18/2002
    * LAST MODIFIED: GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
    *					GF 06/08/2004 - issue #24761 - arithmetic overflow error
    *
    * validates PM Firm and checks Vendor Match. Used in PMSLSend.
    *
    * Pass:
    *	VendorGroup		PM Vendor Group
    *	PM FirmSort		Firm or sortname of firm, will validate either
    *	SL Vendor		Vendor for subcontract
    *
    * Returns:
    *	FirmNumber
    *   Firm Contact
    *
    * Success returns:
    *      FirmNumber and Firm Name
    *
    * Error returns:
    
    *	1 and error message
    **************************************/
    (@vendorgroup bGroup, @firmsort varchar(15), @vendor bVendor, @firmout bFirm = null output,
     @contact varchar(30) output, @msg varchar(255) output)
    as
    set nocount on
    
    declare @rcode int, @firmvendor bVendor
    
    select @rcode = 0
    
    if @firmsort is null
    	begin
    	select @msg = 'Missing Firm!', @rcode = 1
    	goto bspexit
    	end
    
    if @vendor is null
    	begin
    	select @msg = 'Missing Vendor', @rcode = 1
    	goto bspexit
    	end
   
   -- if firm is not numeric then assume a SortName
   if dbo.bfIsInteger(@firmsort) = 1
   -- -- -- if isnumeric((@firm))<>0
   	begin
   	if len(@firmsort) < 7
   		begin
   		-- validate firm to make sure it is valid to use
   		select @firmout = FirmNumber, @contact=ContactName, @msg=FirmName, @firmvendor=Vendor
   		from PMFM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=convert(int,convert(float, @firmsort))
   		end
   	else
   		begin
   		select @msg = 'Invalid firm number, length must be 6 digits or less.', @rcode = 1
   		goto bspexit
   		end
   	end
   
   -- -- --  -- If @firm is numeric then try to find firm number
   -- -- --  if isnumeric(@firmsort) = 1
   -- -- --  	select @firmout = FirmNumber, @contact=ContactName, @msg=FirmName, @firmvendor=Vendor
   -- -- --  	from PMFM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=convert(int,convert(float, @firmsort))
    
    -- if not numeric or not found try to find as Sort Name
    if @@rowcount = 0
    	begin
    	select @firmout = FirmNumber, @contact=ContactName, @msg = FirmName, @firmvendor=Vendor
    	from PMFM with (nolock) where VendorGroup=@vendorgroup and SortName=@firmsort
    	-- if not found,  try to find closest
    	if @@rowcount = 0
    		begin
    		select @firmout=FirmNumber, @contact=ContactName, @msg=FirmName, @firmvendor=Vendor
    		from PMFM with (nolock) where VendorGroup=@vendorgroup and SortName like @firmsort + '%'
    		if @@rowcount = 0
     	  		begin
    		 	select @msg = 'PM Firm ' + convert(varchar(15),isnull(@firmsort,'')) + ' not on file!', @rcode = 1
   			goto bspexit
   			end
   -- -- --  			if isnumeric(@firmsort) <> 0
   -- -- --  				select @firmout = convert(int,@firmsort)
   -- -- --  			else
   -- -- --  				select @firmout = null
   -- -- --  				goto bspexit
   -- -- --  	   		end
    		end
    	end
   
   
   
   
   if @firmvendor <> @vendor
    	begin
    	select @msg = 'PM Firm: ' + convert(varchar(15),isnull(@firmsort,'')) + ' is not assigned to SL Vendor: ' + convert(varchar(8),@vendor) + ' !', @rcode = 1
    	goto bspexit
    	end
   
   
   
   
   bspexit:
   	if @rcode<>0 select @msg = isnull(@msg,'')
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMFirmVendorVal] TO [public]
GO
