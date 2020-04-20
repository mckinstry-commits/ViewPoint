SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRGroupValforBatchAdd    Script Date: ******/

CREATE proc [dbo].[vspPRGroupValforBatchAdd]
/***********************************************************
* CREATED BY: TJL 02/03/10 - Issue #137806, Don't allow batch creation when not a member of Group Security
* MODIFIED By:  TJL 03/19/10 - Issue #138462, Don't allow batch creation when not a member of Group Security, unless Group Security is EMPTY
*				
*
* USAGE:
*	validates PR Group from PRGR
*	validates VPUserName is a member of PR Group
*
* INPUT PARAMETERS
*   PRCo   PR Co to validate agains 
*   Group  PR Group to validate
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of PR Group
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
   
(@prco bCompany = 0, @group bGroup = null, @msg varchar(60) output)
as

set nocount on

declare @rcode int, @empldtsecure bYN

select @rcode = 0, @empldtsecure = 'N'
   
if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto vspexit
   	end
   
if @group is null
   	begin
   	select @msg = 'Missing PR Group!', @rcode = 1
   	goto vspexit
   	end

/* Validate a Valid PR Group */  
select @msg = Description
from bPRGR with (nolock)
where PRCo = @prco and PRGroup=@group 
if @@rowcount = 0
   	begin
   	select @msg = 'PR Group not on file!', @rcode = 1
   	goto vspexit
   	end

/* Validate that current User is member if PR Group */
--Perform the check only when UserName is NOT 'viewpointcs' and bEmployee Datatype security is turned ON and
--when there is at least one record in the PR Group Security (PRGS) table otherwise skip.
select @empldtsecure = Secure
from dbo.DDDTShared (nolock)
where Datatype = 'bEmployee'
if (suser_sname() <> 'viewpointcs' and @empldtsecure = 'Y')
	and exists(select top 1 1 from bPRGS with (nolock) where PRCo = @prco and PRGroup = @group)
	begin
	if not exists(select top 1 1 from bPRGS with (nolock) where PRCo = @prco and PRGroup = @group and VPUserName = suser_sname())
   		begin
   		select @msg = 'User ' + suser_sname() + ' is not a member of group security for PR Group #' + convert(varchar(3), @group) + '!', @rcode = 1
   		goto vspexit
   		end
	end
	   
vspexit:
return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPRGroupValforBatchAdd] TO [public]
GO
