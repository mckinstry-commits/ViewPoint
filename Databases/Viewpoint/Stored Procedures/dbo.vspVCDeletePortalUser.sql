SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Create Procedure
CREATE PROCEDURE [dbo].[vspVCDeletePortalUser]
/*************************************
* Created By:	SDE 7/1/2008
* Modified By:  TEJ 01/29/2010 - Added License Type deletion
*	Deletes a Portal User
*	
* Usage:
*      Pass: UserID
*      Returns: Success = 0; 
*	            Error = 1 and error message;
**************************************/
(@userID int = null, @message varchar(255) = '' output)
	as 
	set nocount on

declare @returnCode int
select @returnCode = 0

if @userID <= 1
begin
	select @message = 'Cannot delete UserID: ' + cast(@userID as varchar(255)), @returnCode = 1
	goto vsp_exit
end
-- Delete User Contact Information
delete VCUserContactInfo where UserID = @userID  
-- Delete User Sites
delete VCUserSites where UserID = @userID  
-- Delete License Assignments
delete pUserLicenseType where UserID = @userID 
-- Delete the User
delete VCUsers where UserID = @userID  

vsp_exit:
	return @returnCode

GO
GRANT EXECUTE ON  [dbo].[vspVCDeletePortalUser] TO [public]
GO
