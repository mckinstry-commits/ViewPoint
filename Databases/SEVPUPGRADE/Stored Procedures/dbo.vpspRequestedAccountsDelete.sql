SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vpspRequestedAccountsDelete]
(
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
	@Original_Description varchar(3000)
)
AS
	SET NOCOUNT OFF;
DELETE FROM pRequestedAccounts WHERE (RequestedAccountID = @Original_RequestedAccountID) AND (Company = @Original_Company) AND (Date = @Original_Date) AND (EmailAddress = @Original_EmailAddress) AND (PhoneNumber = @Original_PhoneNumber) AND (FirstName = @Original_FirstName) AND (LastName = @Original_LastName) AND (MiddleName = @Original_MiddleName) AND (Role = @Original_Role OR @Original_Role IS NULL AND Role IS NULL) AND (UserName = @Original_UserName) AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL)




GO
GRANT EXECUTE ON  [dbo].[vpspRequestedAccountsDelete] TO [VCSPortal]
GO
