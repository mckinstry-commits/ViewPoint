SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vspRPReportSecurity]
/********************************************************
 * Created: GG 07/11/03
 * Modified:  GG 01/21/05 - allow all Company entries (Co=-1) 
 *
 * Used to determine report security level for a specific 
 * report and user.
 *
 * Inputs:
 *	@co				Active Company#
 *	@reportid		Report ID#
 *	
 * Outputs:
 *	@access		Access level 0 = full, 2 = denied, null = missing
 *	@errmsg		Message
 *
 * Return Code:
 *	@rcode		0 = success, 1 = error
 *
 *********************************************************/

	(@co smallint = null, @reportid int = null, @access tinyint output, @errmsg varchar(512) output)
as
BEGIN

set nocount on

declare @rcode int, @user bVPUserName

if @co is null or @reportid is null 
	begin
	select @errmsg = 'Missing required input parameter(s): Company # and/or Report ID#!', @rcode = 1
	goto vspexit
	end

-- initialize return params
select @rcode = 0, @access = 0
select @user = suser_sname()	-- current user name 

-- make sure report exists
if not exists(select 1 from dbo.RPRTShared where ReportID =  @reportid)
	begin
	select @errmsg = 'Invalid Report ID#!', @rcode = 1
	goto vspexit
	end

if @user = 'viewpointcs' goto vspexit	-- Viewpoint login has full access
	
-- 1st check: Report security for user and active company, Security Group -1
select @access = Access
from dbo.vRPRS (nolock)
where Co = @co and ReportID = @reportid and SecurityGroup = -1 and VPUserName = @user
if @@rowcount = 1
	begin
	if @access = 0 goto vspexit		-- full access
	if @access = 2	-- access denied
		begin
		select @errmsg = @user + ' has been denied access to Report #' + convert(varchar,@reportid)
		goto vspexit
		end
	select @errmsg = 'Invalid access value assigned to Report #' + convert(varchar,@reportid) + ' for ' + @user, @rcode = 1
	goto vspexit
	end
-- 2nd check: Report security for user across all companies, Security Group -1 and Company = -1
select @access = Access
from dbo.vRPRS (nolock)
where Co = -1 and ReportID = @reportid and SecurityGroup = -1 and VPUserName = @user
if @@rowcount = 1
	begin
	if @access = 0 goto vspexit		-- full access
	if @access = 2	-- access denied
		begin
		select @errmsg = @user + ' has been denied access to Report #' + convert(varchar,@reportid)
		goto vspexit
		end
	select @errmsg = 'Invalid access value assigned to Report #' + convert(varchar,@reportid) + ' for ' + @user, @rcode = 1
	goto vspexit
	end
-- 3rd check: Report security for groups that user is a member of within active company
select @access = null
select @access = min(Access)	-- get least restrictive access level
from dbo.vRPRS r (nolock)
join dbo.vDDSU s (nolock) on s.SecurityGroup = r.SecurityGroup 
where r.Co = @co and r.ReportID = @reportid and s.VPUserName = @user
if @access = 0 goto vspexit		-- full access
if @access = 2	-- access denied
	begin
	select @errmsg = @user + ' has been denied access to Report #' + convert(varchar,@reportid)
	goto vspexit
	end
if @access is not null
	begin
	select @errmsg = 'Invalid access value assigned to Report #' + convert(varchar,@reportid) + ' for ' + @user, @rcode = 1
	goto vspexit
	end
-- 4th check: Report security for groups that user is a member of across all companies, Company = -1
select @access = min(Access)	-- get least restrictive access level
from dbo.vRPRS r (nolock)
join dbo.vDDSU s (nolock) on s.SecurityGroup = r.SecurityGroup 
where r.Co = -1 and r.ReportID = @reportid and s.VPUserName = @user
if @access is null		-- no entries for user in any security group
	begin
	select @errmsg = @user + ' has not been setup with access to Report #' + convert(varchar,@reportid)
	goto vspexit
	end
if @access = 0 goto vspexit		-- full access
if @access = 2	-- access denied
	begin
	select @errmsg = @user + ' has been denied access to Report #' + convert(varchar,@reportid)
	goto vspexit
	end
select @errmsg = 'Invalid access value assigned to Report #' + convert(varchar,@reportid) + ' for ' + @user, @rcode = 1
goto vspexit
	
	
vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspRPReportSecurity]'
	return @rcode

END
GO
GRANT EXECUTE ON  [dbo].[vspRPReportSecurity] TO [public]
GO
