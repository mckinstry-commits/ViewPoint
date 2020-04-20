SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vpspRequestedAccountsInsert]
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
	@Date datetime
)
AS
	SET NOCOUNT OFF;
	
INSERT INTO pRequestedAccounts(UserName, FirstName, MiddleName, LastName, 
EmailAddress, PhoneNumber, Company, Role, Description, Date) VALUES (@UserName, @FirstName, @MiddleName, @LastName, @EmailAddress, @PhoneNumber, @Company, @Role, @Description, @Date);
	SELECT RequestedAccountID, UserName, FirstName, MiddleName, LastName,
 EmailAddress, PhoneNumber, Company, Role, Description, Date FROM pRequestedAccounts 
WHERE (RequestedAccountID = SCOPE_IDENTITY())





GO
GRANT EXECUTE ON  [dbo].[vpspRequestedAccountsInsert] TO [VCSPortal]
GO
