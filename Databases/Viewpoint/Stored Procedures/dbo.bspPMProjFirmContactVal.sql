SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPMProjFirmContactVal]
   /*************************************
   * Created By:   GF 04/10/2001
   * Modified By:  RT 05/05/2003 - Added return column 'PMPM.ExcludeYN' for Issue #20657.
   *
   * validates PM Firm Contact called from PM Project Firms
   *
   * Pass:
   *   VendorGroup
   *   Firm            Firm to validate contact in
   *	ContactSort     Contact code or sortname to validate
   *
   * Returns:
   *	ContactOut      The contact number validated
   *   Contact Phone
   *   Contact EMail
   *   Contact FAx
   *
   * Success returns:
   *   Contact Name
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@vendorgroup bGroup, @firm bFirm, @contactsort bSortName, @contactout bEmployee = null output,
    @phone bPhone = null output, @title bDesc = null output, @email varchar(60) = null output,
    @fax bPhone = null output, @exclude bYN = null output, @msg varchar(255) output)
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
   
   exec @rcode = dbo.bspPMFirmContactVal @vendorgroup, @firm, @contactsort, 
   		@contactout output, @msg output
   if @rcode = 0
       begin
       select @phone=Phone, @title=Title, @email=EMail, @fax=Fax, @exclude = ExcludeYN
       from bPMPM with (nolock) where VendorGroup=@vendorgroup and FirmNumber=@firm and ContactCode=@contactout
       end
   
   
   
   bspexit:
       if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjFirmContactVal] TO [public]
GO
