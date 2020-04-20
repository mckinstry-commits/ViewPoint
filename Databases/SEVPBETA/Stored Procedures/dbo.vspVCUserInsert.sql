SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[vspVCUserInsert]
/*************************************
* Created By:	SDE 7/7/2008
*
*	Inserts the correct enteries into the pUserContactInfo and 
*	pUserSites tables for a newly added Portal User.
*	
* Pass:
*	UserID, SiteID, EmailAddress
*
* Success returns:
*	0
*
* Error returns:
*	1 and error message
**************************************/
(@userID int = null, @siteID int = null, @emailAddress varchar(255) = '', @message varchar(255) = '' output)
	as 
	set nocount on

declare @returnCode int
select @returnCode = 0

if isnull(@userID, -1) = -1
	begin
		select @message = 'Missing User Name.', @returnCode = 1
		goto vsp_exit
	end

if isnull(@siteID, -1) = -1
	begin
		select @message = 'Missing SiteID.', @returnCode = 1
		goto vsp_exit
	end

if isnull(@emailAddress, '') = ''
	begin
		select @message = 'Missing Email Address.', @returnCode = 1
		goto vsp_exit
	end

-- Insert this users Email Address into UserContactInfo
declare @emailAddressTypeID int
set @emailAddressTypeID = 6

insert into VCUserContactInfo (UserID, ContactTypeID, ContactValue) 
	values (@userID, @emailAddressTypeID, @emailAddress)

-- Insert this user into the UserSites for the site provided
declare @defaultRoleID int
set @defaultRoleID = 3

insert into VCUserSites (UserID, SiteID, RoleID) 
	values (@userID, @siteID, @defaultRoleID)

vsp_exit:
	return @returnCode




GO
GRANT EXECUTE ON  [dbo].[vspVCUserInsert] TO [public]
GO
