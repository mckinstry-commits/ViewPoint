SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMDZGetKeyId ******/
CREATE proc [dbo].[vspPMDZGetKeyId]
/*************************************
 * Created By:	12/5/2007
 * Modified By:
 *
 *
 * Used to get the next PMDZ Key Id for the current record in PM Document Create and Send.
 *
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * DocCategory	PM Document Category
 * UserName		VP User Name
 * VendorGroup	PM Firm Vendor Group
 * Sequence		PMDZ Sequence
 *
 * Success returns:
 *	0 on Success, 1 on ERROR
 * @pmdzkeyid		PMDZ key id
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany = null, @project bJob = null, @doccategory varchar(10) = null,
 @username bVPUserName = null, @vendorgroup bGroup = null, @sequence int = null,
 @pmdzkeyid bigint = null output, @msg varchar(255) = null output)
as
set nocount on
 
declare @rcode int

select @rcode = 0

------ get PMDZ.KeyId
select @pmdzkeyid=KeyID
from PMDZ with (nolock) where PMCo=@pmco and Project=@project and DocCategory=@doccategory
and UserName=@username and VendorGroup=@vendorgroup and Sequence=@sequence
if @@rowcount = 0
	begin
	select @msg = 'Error has occurred retrieving Key Id for firm and contact.', @rcode = 1
	goto bspexit
	end
if @pmdzkeyid is null or @pmdzkeyid = 0
	begin
	select @msg = 'Missing Identity key for firm and contact.', @rcode = 1
	goto bspexit
	end




bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDZGetKeyId] TO [public]
GO
