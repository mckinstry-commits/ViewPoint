SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


AS
	SET NOCOUNT ON;
SELECT RequestedAccountID, UserName, FirstName, MiddleName, LastName, 
EmailAddress, PhoneNumber, Company, Role, Description, Date FROM pRequestedAccounts


GO
GRANT EXECUTE ON  [dbo].[vpspRequestedAccountsGet] TO [VCSPortal]
GO