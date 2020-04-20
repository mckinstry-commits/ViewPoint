SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspRequestedAccountsUpdate]
(
	@UserName varchar(50),
	@FirstName varchar(50),
	@MiddleName varchar(50),
	@LastName varchar(50),
	@EmailAddress varchar(50),
	@PhoneNumber varchar(50),
	@Company varchar(255),
	@Role varchar(50),
	@Description varchar(3000),
	@Date datetime,
	@Original_RequestedAccountID int,
	@Original_Company varchar(255),
	@Original_Date datetime,
	@Original_EmailAddress varchar(50),
	@Original_PhoneNumber varchar(50),
	@Original_FirstName varchar(50),
	@Original_LastName varchar(50),
	@Original_MiddleName varchar(50),
	@Original_Role varchar(50),
	@Original_UserName varchar(50),
	@Original_Description varchar(3000),
	@RequestedAccountID int
)
AS
	SET NOCOUNT OFF;
UPDATE pRequestedAccounts SET UserName = @UserName, FirstName = @FirstName,
 MiddleName = @MiddleName, LastName = @LastName, EmailAddress = @EmailAddress, PhoneNumber = @PhoneNumber, Company = @Company, Role = @Role, Description = @Description, Date = @Date WHERE (RequestedAccountID = @Original_RequestedAccountID) AND (Company = @Original_Company) AND (Date = @Original_Date) AND (EmailAddress = @Original_EmailAddress) AND (PhoneNumber = @Original_PhoneNumber) AND (FirstName = @Original_FirstName) AND (LastName = @Original_LastName) AND (MiddleName = @Original_MiddleName) AND (Role = @Original_Role OR @Original_Role IS NULL AND Role IS NULL) AND (UserName = @Original_UserName) AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL);
	SELECT RequestedAccountID, UserName, FirstName, MiddleName, LastName, 
EmailAddress, PhoneNumber, Company, Role, Description, 
Date FROM pRequestedAccounts WHERE (RequestedAccountID = @RequestedAccountID)



GO
GRANT EXECUTE ON  [dbo].[vpspRequestedAccountsUpdate] TO [VCSPortal]
GO
