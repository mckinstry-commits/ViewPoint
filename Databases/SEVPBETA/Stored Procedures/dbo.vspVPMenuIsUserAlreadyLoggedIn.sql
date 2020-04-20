SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE        PROCEDURE [dbo].[vspVPMenuIsUserAlreadyLoggedIn]
/**************************************************
* Created: JRK 09/12/03
* Modified: JRK 06/27/06 Removed DISTINCT to return count of all connections by a user.
*
* Used by VPMenu to determine if a user is already logged in from the same workstation.
*
* Inputs:
*	@userid		Login id of the user trying to log in.
*	@workstn	Name of PC the user is logging in from.
*
* Output:
*	@rcode		result code:  -1=error.
*	@errmsg		Error message
*
*
* Return code:
*	@rcode	0 = success, -1 = failure
*
****************************************************/
	(@userid bVPUserName, @workstn varchar(128),
	 @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0

if @userid = null or @workstn = null
	begin
	select @errmsg = 'Missing required input parameter: userid or workstn', @rcode = -1
	goto vspexit
	end

return_results:		
	select @rcode = count (loginame) from master.dbo.sysprocesses
	where program_name = 'ViewpointClient' and loginame = @userid and hostname=@workstn


vspexit:

	if @rcode < 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuIsUserAlreadyLoggedIn]'
	return @rcode
















GO
GRANT EXECUTE ON  [dbo].[vspVPMenuIsUserAlreadyLoggedIn] TO [public]
GO
