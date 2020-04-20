SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMFirmContactVal    Script Date: 8/28/99 9:33:03 AM ******/
   CREATE proc [dbo].[bspPMFirmContactVal]
   /*************************************
   * CREATED BY    : SAE  12/1/97
   * LAST MODIFIED : SAE  12/3/97
   * validates PM Firm
   *
   * Pass:
   *	VendorGroup
   *	Firm    Firm to validate contact in
   *       ContactSort  Contact or contact sort name to validate
   * Returns:
   *       ContactOut   the contact number validated
   * Success returns:
   *      ContactNumber and Contact Name
   *
   * Error returns:
   
   *	1 and error message
   **************************************/
   (@vendorgroup bGroup, @firm bFirm, @contactsort bSortName,
    @contactout bEmployee=null output, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @firm is null
   	begin
   	select @msg = 'Missing Firm!', @rcode = 1
   	goto bspexit
   	end
   
   if @contactsort is null
   	begin
   	select @msg = 'Missing Contact!', @rcode = 1
   	goto bspexit
   	end
   
   /* If @contact is numeric then try to find contact number */
   if isnumeric(@contactsort) = 1
   	select @contactout = ContactCode, @msg=FirstName + ' ' + LastName
   	from PMPM with (nolock) 
   	where VendorGroup = @vendorgroup and FirmNumber=@firm
   	and ContactCode = convert(int,convert(float, @contactsort))
   
   -- if not numeric or not found try to find as Sort Name
   if @@rowcount = 0
       begin
        select @contactout=ContactCode, @msg=FirstName + ' ' + LastName
   	 from PMPM with (nolock) 
   	 where VendorGroup = @vendorgroup and FirmNumber=@firm and SortName = @contactsort
   
   	 -- if not found,  try to find closest
        if @@rowcount = 0
           begin
           set rowcount 1
   	    select @contactout=ContactCode, @msg=FirstName + ' ' + LastName
   		from PMPM with (nolock) 
   		where VendorGroup = @vendorgroup and FirmNumber=@firm and SortName like @contactsort + '%'
   		if @@rowcount = 0
    	  	   begin
              select @msg = 'PM Contact ' + convert(varchar(15),isnull(@contactsort,'')) + ' not on file!', @rcode = 1
   		   goto bspexit
   	   	   end
   		end
       end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMFirmContactVal] TO [public]
GO
