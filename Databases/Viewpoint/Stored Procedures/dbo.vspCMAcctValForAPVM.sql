SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspCMAcctValForAPVM    Script Date: ******/
CREATE proc [dbo].[vspCMAcctValForAPVM]
/***********************************************************
* CREATED BY:	TJL 02/04/09 - Issue #124739, Add CMAcct in APVM as default 
* MODIFIED By :
*				
*
* USAGE:
* validates CM Account.  Errors only if CMAcct does not exist in any CMCo
*
* INPUT PARAMETERS
*   CMAcct Account to validate
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of CMAcct
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
   
(@vendorgroup bGroup = null, @cmacct bCMAcct = null, @msg varchar(100) output)
as

set nocount on

declare @rcode int

select @rcode = 0

if @vendorgroup is null
   	begin
   	select @msg = 'Missing Vendor Group.', @rcode = 1
   	goto vspexit
   	end   
if @cmacct is null
   	begin
   	select @msg = 'Missing CM Account.', @rcode = 1
   	goto vspexit
   	end
   
--select @msg = Description 
--from CMAC with (nolock)
--where CMAcct = @cmacct

select @msg = CMAC.Description
from CMAC with (nolock)
join APCO (nolock) on APCO.CMCo = CMAC.CMCo
join HQCO (nolock) on HQCO.HQCo = APCO.APCo
where HQCO.VendorGroup = @vendorgroup and CMAC.CMAcct = @cmacct
Group By CMAC.CMAcct, CMAC.Description, CMAC.CMCo

if @@rowcount = 0
   	begin
   	select @msg = 'Invalid CM Account - CM Account not on file in any AP Company that shares this Vendor Group.', @rcode = 1
   	goto vspexit
   	end
   
vspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspCMAcctValForAPVM] TO [public]
GO
