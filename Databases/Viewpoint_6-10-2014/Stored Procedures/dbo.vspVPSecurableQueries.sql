SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspVPSecurableQueries]
/*******************************************************************
* Created: CC 09/10/08
* Modified: AL 9/27/12
*			GPT 7/1/13
*
* Usage:
* Returns a resultset of VP Query Security info.  Includes all combinations of 
* report security groups and/or users with Queries filtered by module and company.
* Used by VA Query Security to display information in the grid.
*
* Inputs:
*	@co				Company # or -1 for all company access
*	@type			Return entries for Security Groups ('G') or Users ('U')
*	@group			Security Group or null for all, only used when @type = 'G'
*	@user			User or null for all, only used when @type = 'U'
*
* Outputs:
*	resultset of report security info 
*	@msg				Error message
*
* Return code:
*	0 = success, 1 = error w/messsge
*
*
*********************************************************************/
	(@co smallint, @type char(1) = null,
	 @group int = null, @user bVPUserName = null, @msg varchar(255) output)

as
   
set nocount on
declare @rcode int
set @rcode = 0

if @co is null
	begin
	select @msg = 'Missing Company#!', @rcode = 1
	goto vspexit
	end
if @type is null or @type not in ('G','U')
	begin
	select @msg = 'Invalid security option, must select by ''G'' = Security Group or ''U'' = User!', @rcode = 1
	goto vspexit
	end


if @type = 'G'	-- Report Security by Module, Co#, and Security Group 
	begin
	select distinct t.KeyID, t.QueryName, t.IsStandard, isnull(s.SecurityGroup, g.SecurityGroup) as [SecGroup], g.Name as [SecGroupDesc],
		null as [UserName], null as [FullName],
		case when s.Access is null then 1 else s.Access end as [Access]	-- return '1' for no access
	from dbo.VPGridQueries t (nolock)
	join dbo.vDDSG g (nolock) on g.SecurityGroup = isnull(@group,g.SecurityGroup) and GroupType = 2	-- Report Security Groups only
	left join dbo.VPQuerySecurity s (nolock) on t.QueryName = s.QueryName and s.SecurityGroup = g.SecurityGroup and s.Co = @co
	WHERE t.QueryType <> '3' -- Exclude Dispatch types
	order by t.QueryName
	end

if @type = 'U'	-- Report Security by Module, Co#, and User Name
	begin
	select distinct t.KeyID, t.QueryName, t.IsStandard, null as [SecGroup], null as [SecGroupDesc],
		isnull(s.VPUserName, p.VPUserName) as [UserName], p.FullName,
		case when s.Access is null then 1 else s.Access end as [Access]	
	from dbo.VPGridQueries t (nolock)
	join dbo.vDDUP p (nolock) on p.VPUserName = isnull(@user,p.VPUserName) and p.VPUserName not in ('vcspublic','viewpointcs')	-- exclude these
	left join dbo.VPQuerySecurity s (nolock) on t.QueryName = s.QueryName and s.VPUserName = p.VPUserName and s.Co = @co
	WHERE t.QueryType <> '3' -- Exclude Dispatch types
	order by t.QueryName
	end
 
vspexit:
    return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspVPSecurableQueries] TO [public]
GO
