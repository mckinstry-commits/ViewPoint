SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspPMPMValForDist]
   /*************************************
   * Created By:   GF 03/09/2001
   * Modified By:
   *
   *   Validates PM Firm contact for distribution forms.
   *
   * Pass:
   *	VendorGroup
   *	Firm        Firm to validate contact in
   *   ContactSort Contact or contact sort name to validate
   *
   * Returns:
   *   ContactOut  Validated contact number
   *   PrefMethod  Contact preferred method of contact
   *   Email       Contact email address
   *   Fax         Contact fax number
   *
   * Success returns:
   *   Contact First Name and Last Name in message
   *
   * Error returns:
   
   *	1 and error message
   **************************************/
   (@vendorgroup bGroup, @firm bFirm, @contactsort bSortName, @contactout bEmployee=null output,
    @prefmethod varchar(1) output, @email varchar(60) output, @fax varchar(20) output, @msg varchar(255) output)
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
   
   -- If @contact is numeric then try to find contact number
   if isnumeric(@contactsort) = 1
       select @contactout=ContactCode, @prefmethod=PrefMethod, @email=EMail, @fax=Fax, @msg=FirstName + ' ' + LastName
   	from PMPM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@firm and ContactCode=convert(int,convert(float, @contactsort))
   
   -- if not numeric or not found try to find as Sort Name
   if @@rowcount = 0
       begin
       select @contactout=ContactCode, @prefmethod=PrefMethod, @email=EMail, @fax=Fax, @msg=FirstName + ' ' + LastName
       from PMPM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@firm and SortName=@contactsort
       -- if not found,  try to find closest
       if @@rowcount = 0
           begin
           set rowcount 1
   	    select @contactout=ContactCode, @prefmethod=PrefMethod, @email=EMail, @fax=Fax, @msg=FirstName + ' ' + LastName
   		from PMPM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@firm and SortName like @contactsort + '%'
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
GRANT EXECUTE ON  [dbo].[bspPMPMValForDist] TO [public]
GO
