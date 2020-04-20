SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE             PROCEDURE [dbo].[vspVPMenuTestLongProcess]
/**************************************************
* Created: JRK 10/27/04
* Modified: 
*
* Used by to test a long running process
*
* Inputs:
*	@sleepSeconds	
*
* Output:
*	resultset of user info
*	@errmsg		Error message
*
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@sleepSeconds int, 
	 @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0

if @sleepSeconds is null
	begin
	select @errmsg = 'Missing required input parameter(s): @sleepSeconds!', @rcode = 1
	goto vspexit
	end

if @sleepSeconds < 0
	begin
	select @errmsg = '@sleepSeconds cannot be negative: nbrSeconds and/or nbrMinutes!', @rcode = 1
	goto vspexit
	end

-- Convert total seconds into minutes and seconds.
declare @delaySeconds int, @delayMinutes int
select @delayMinutes = ROUND(@sleepSeconds  / 60, 0, 1)
select @delaySeconds = @sleepSeconds % 20

	-- Force a delay --
	declare @delayTime as varchar(8)
	select @delayTime = '00:'

	if @delayMinutes < 10
		select @delayTime = @delayTime + '0' + cast(@delayMinutes as char(1)) + ':'
	else
		select @delayTime = @delayTime +cast(@delayMinutes as char(2)) + ':'

	if @delaySeconds < 10
		select @delayTime = @delayTime + '0' + cast(@delaySeconds as char(1))
	else
		select @delayTime = @delayTime +cast(@delaySeconds as char(2))

	waitfor delay @delayTime  -- HH:MM:SS

	-- After the delay get a list of Viewpoint users.
	SELECT count(m.loginame) as 'Count'
	FROM master.dbo.sysprocesses m
	left outer JOIN vDDUP u ON m.loginame = u.VPUserName
	WHERE program_name = 'ViewpointClient'
		and loginame <> 'viewpointcs'	-- exclude viewpoint system login

vspexit:

	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspVPMenuTestLongProcess]'
	return @rcode






GO
GRANT EXECUTE ON  [dbo].[vspVPMenuTestLongProcess] TO [public]
GO
