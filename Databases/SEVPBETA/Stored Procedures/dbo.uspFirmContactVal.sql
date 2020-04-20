SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspFirmContactVal] /** User Defined Validation Procedure **/


   (@vendorgroup bGroup, @firm bFirm, @contactsort bSortName, @contactout bEmployee=null output, @msg varchar(255) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @firm is null
   	begin
   	select @msg = 'Missing Firm!', @rcode = 1
   	goto spexit
   	end
   
   if @contactsort is null
   	begin
   	select @msg = 'Missing Contact!', @rcode = 1
   	goto spexit
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
   		   goto spexit
   	   	   end
   		end
       end
   
   
   spexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspFirmContactVal] TO [public]
GO
