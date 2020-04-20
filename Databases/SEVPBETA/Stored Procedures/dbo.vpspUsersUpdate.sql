SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE          PROCEDURE [dbo].[vpspUsersUpdate]
/************************************************************
* CREATED:      2006/02/01 SDE
* MODIFIED:     2009/07/06 JB		Added DDUP Reference - PRCo, PREmployee, HRCo, HRRef now come from DDUP
*               2011/09/19 TEJ      Added Administer Portal Column to pUsers
*
* USAGE:
*	Updates a Users and returns the user with the associated 
*	Lookups
*	
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@UserName varchar(50),
	@PID varchar(255),
	@SID varchar(255),
	@LastPIDChange datetime,
	@FirstName varchar(50),
	@MiddleName varchar(50),
	@LastName varchar(50),
	@LastLogin datetime,
	@VPUserName bVPUserName,
	@VendorGroup int,
	@Vendor int,
	@CustGroup int,
	@Customer int,
	@FirmNumber int,
	@Contact int,
	@DefaultSiteID int,
	@Original_UserID int,
	@UserID int,
	@AdministerPortal bit
)
AS
	SET NOCOUNT ON
-- Set Null fields
if @VendorGroup = -1 set @VendorGroup = Null
if @Vendor = -1 set @Vendor = Null
if @CustGroup = -1 set @CustGroup = Null
if @Customer = -1 set @Customer = Null
if @FirmNumber = -1 set @FirmNumber = Null
if @Contact = -1 set @Contact = Null
if @LastLogin = 'Jan  1 1901 12:00:00:000AM' set @LastLogin = Null
if @LastPIDChange = 'Jan  1 1901 12:00:00:000AM' set @LastPIDChange = Null

UPDATE pUsers SET UserName = @UserName, 
	PID = @PID, 
	SID = @SID, 
	LastPIDChange = @LastPIDChange, 
	FirstName = @FirstName, 
	MiddleName = @MiddleName, 
	LastName = @LastName, 
	LastLogin = @LastLogin, 
	VPUserName = @VPUserName,
	VendorGroup = @VendorGroup, 
	Vendor = @Vendor, 
	CustGroup = @CustGroup, 
	Customer = @Customer, 
	FirmNumber = @FirmNumber, 
	Contact = @Contact, 
	DefaultSiteID = @DefaultSiteID ,
	AdministerPortal = @AdministerPortal
	WHERE (UserID = @Original_UserID)
	
execute vpspUsersGet @UserID
GO
GRANT EXECUTE ON  [dbo].[vpspUsersUpdate] TO [VCSPortal]
GO
