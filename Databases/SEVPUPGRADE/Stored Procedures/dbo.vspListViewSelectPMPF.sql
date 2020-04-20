SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspListViewSelectPMPF]
   /***********************************************************
    * Created By:	GP	02/25/2011
    * Modified By:	
    *
    *****************************************************/
   (@VendorGroup bGroup, @msg varchar(255) output)
   as
   set nocount on
   
declare @rcode int, @SLCo bCompany 
select @rcode = 0

--------------
--VALIDATION--
--------------
if @VendorGroup is null
begin
	select @msg = 'Missing Vendor Group.', @rcode = 1
	goto vspexit
end


------------   
--GET DATA--
------------
select FirmNumber as [Firm], FirmName as [Name], Vendor, ContactName as [Contact], EMail, KeyID
from dbo.PMFM 
where VendorGroup = @VendorGroup


   
vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspListViewSelectPMPF] TO [public]
GO
