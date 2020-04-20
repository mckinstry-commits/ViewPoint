SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspVAAttachmentTypeSecurityList]
/*******************************************************************
* Created: JonathanP 04/24/08
* Modified: RickM 10/28/09 - Restrict dataset to only secured attachment types.
*			AL 9/28/12 - Changed Security group to int
*
* Usage:
* Returns a resultset of Attachment Type Security info.  Includes all combinations of 
* attachment type security groups and/or users with attachment types filtered by attachment
* type and company.
* Used by VA Attachment Type Security to display information in the grid.
*
* Inputs:
*	@attachmentTypeID	Attachment type ID used to filter type, null for all
*	@company			Company # or -1 for all company access
*	@securityType		Return entries for Security Groups ('G') or Users ('U')
*	@group				Security Group or null for all, only used when @securityType = 'G'
*	@user				User or null for all, only used when @securityType = 'U'
*
* Outputs:
*	resultset of attachment type security info .
*	@errorMessage		Error message
*
* Return code:
*	0 = success, 1 = error w/messsge
*
*
*********************************************************************/
	(@attachmentTypeID int = null, @company smallint = null, @securityType char(1) = null,
	 @group int = null, @user bVPUserName = null, @errorMessage varchar(255) output)

as
   
set nocount on

declare @returnCode int
set @returnCode = 0

if @company is null
	begin
	select @errorMessage = 'Missing Company number!', @returnCode = 1
	goto vspexit
	end
	
if @securityType is null or @securityType not in ('G','U')
	begin
	select @errorMessage = 'Invalid security option, must select by ''G'' = Security Group or ''U'' = User!', @returnCode = 1
	goto vspexit
	end

if @securityType = 'G'	-- Attachment Type Security by attachment type, Company number, and Security Group 
	begin
	select distinct t.AttachmentTypeID, t.Name, isnull(s.SecurityGroup, g.SecurityGroup) as [SecGroup], 
		g.Name as [SecGroupDesc],
		null as [UserName], null as [FullName],
		case when s.Access is null then 1 else s.Access end as [Access]	-- return '1' for no access
	from dbo.DMAttachmentTypesShared t (nolock)	
	join dbo.vDDSG g (nolock) on g.SecurityGroup = isnull(@group,g.SecurityGroup) and GroupType = 3	-- Attachment Type Security Groups only
	left join dbo.vVAAttachmentTypeSecurity s (nolock) on s.AttachmentTypeID = t.AttachmentTypeID and s.SecurityGroup = g.SecurityGroup and s.Co = @company
	where t.AttachmentTypeID = ISNULL(@attachmentTypeID, t.AttachmentTypeID) and t.Secured = 'Y'
	order by t.Name
	end

if @securityType = 'U'	-- Attachment Type Security by attachment type, Company number, and user name.
	begin
	select distinct t.AttachmentTypeID, t.Name, null as [SecGroup], null as [SecGroupDesc],
		isnull(s.VPUserName, p.VPUserName) as [UserName], p.FullName,
		case when s.Access is null then 1 else s.Access end as [Access]	
	from dbo.DMAttachmentTypesShared t (nolock)	
	join dbo.vDDUP p (nolock) on p.VPUserName = isnull(@user,p.VPUserName) and p.VPUserName not in ('vcspublic','viewpointcs')	-- exclude these
	left join dbo.vVAAttachmentTypeSecurity s (nolock) on s.AttachmentTypeID = t.AttachmentTypeID and s.VPUserName = p.VPUserName and s.Co = @company
	where t.AttachmentTypeID = ISNULL(@attachmentTypeID, t.AttachmentTypeID) and t.Secured = 'Y'
	order by t.Name
	end
 
vspexit:
    return @returnCode





GO
GRANT EXECUTE ON  [dbo].[vspVAAttachmentTypeSecurityList] TO [public]
GO
