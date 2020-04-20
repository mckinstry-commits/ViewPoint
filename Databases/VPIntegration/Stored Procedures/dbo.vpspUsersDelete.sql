SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROCEDURE [dbo].[vpspUsersDelete]
/************************************************************
* CREATED:		UNKOWN
* MODIFIED:		2011/09/19 TEJ      Added Administer Portal Column to pUsers
*
* USAGE:
*	Deletes specified user from the database
*	
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*  UserID 
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(
	@Original_UserID int,
	@Original_Contact int,
	@Original_CustGroup int,
	@Original_Customer int,
	@Original_DefaultSiteID int,
	@Original_FirmNumber int,
	@Original_FirstName varchar(50),
	@Original_HRCo int,
	@Original_HRRef int,
	@Original_LastLogin datetime,
	@Original_LastName varchar(50),
	@Original_LastPIDChange datetime,
	@Original_MiddleName varchar(50),
	@Original_PID varchar(255),
	@Original_PRCo int,
	@Original_PREmployee int,
	@Original_SID varchar(255),
	@Original_UserName varchar(50),
	@Original_Vendor int,
	@Original_VendorGroup int,
	@Original_AdministerPortal bit
)
AS
	SET NOCOUNT OFF;

-- Set Null fields
if @Original_HRCo = -1 set @Original_HRCo = Null
if @Original_HRRef = -1 set @Original_HRRef = Null
if @Original_PRCo = -1 set @Original_PRCo = Null
if @Original_VendorGroup = -1 set @Original_VendorGroup = Null
if @Original_Vendor = -1 set @Original_Vendor = Null
if @Original_CustGroup = -1 set @Original_CustGroup = Null
if @Original_Customer = -1 set @Original_Customer = Null
if @Original_FirmNumber = -1 set @Original_FirmNumber = Null
if @Original_Contact = -1 set @Original_Contact = Null
if @Original_PREmployee = -1 set @Original_PREmployee = Null
if @Original_LastLogin = 'Jan  1 1901 12:00:00:000AM' set @Original_LastLogin = Null
if @Original_LastPIDChange = 'Jan  1 1901 12:00:00:000AM' set @Original_LastPIDChange = Null

DELETE FROM pUsers WHERE (UserID = @Original_UserID) AND (Contact = @Original_Contact OR @Original_Contact IS NULL AND Contact IS NULL) AND (CustGroup = @Original_CustGroup OR @Original_CustGroup IS NULL AND CustGroup IS NULL) AND (Customer = @Original_Customer OR @Original_Customer IS NULL AND Customer IS NULL) AND (DefaultSiteID = @Original_DefaultSiteID) AND (FirmNumber = @Original_FirmNumber OR @Original_FirmNumber IS NULL AND FirmNumber IS NULL) AND (FirstName = @Original_FirstName) AND (HRCo = @Original_HRCo OR @Original_HRCo IS NULL AND HRCo IS NULL) AND (HRRef = @Original_HRRef OR @Original_HRRef IS NULL AND HRRef IS NULL) AND (LastLogin = @Original_LastLogin OR @Original_LastLogin IS NULL AND LastLogin IS NULL) AND (LastName = @Original_LastName) AND (LastPIDChange = @Original_LastPIDChange OR @Original_LastPIDChange IS NULL AND LastPIDChange IS NULL) AND (MiddleName = @Original_MiddleName) AND (PID = @Original_PID) AND (PRCo = @Original_PRCo OR @Original_PRCo IS NULL AND PRCo IS NULL) AND (PREmployee = @Original_PREmployee OR @Original_PREmployee IS NULL AND PREmployee IS NULL) AND (SID = @Original_SID) AND (UserName = @Original_UserName) AND (Vendor = @Original_Vendor OR @Original_Vendor IS NULL AND Vendor IS NULL) AND (VendorGroup = @Original_VendorGroup OR @Original_VendorGroup IS NULL AND VendorGroup IS NULL)
GO
GRANT EXECUTE ON  [dbo].[vpspUsersDelete] TO [VCSPortal]
GO
