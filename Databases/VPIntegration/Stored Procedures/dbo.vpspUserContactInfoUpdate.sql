SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspUserContactInfoUpdate
(
	@UserID int,
	@ContactTypeID int,
	@ContactValue varchar(50),
	@Original_ContactTypeID int,
	@Original_UserID int,
	@Original_ContactValue varchar(50)
)
AS
	SET NOCOUNT OFF;
UPDATE pUserContactInfo SET UserID = @UserID, ContactTypeID = @ContactTypeID, ContactValue = @ContactValue WHERE (ContactTypeID = @Original_ContactTypeID) AND (UserID = @Original_UserID) AND (ContactValue = @Original_ContactValue);
	SELECT UserID, ContactTypeID, ContactValue FROM pUserContactInfo WHERE (ContactTypeID = @ContactTypeID) AND (UserID = @UserID)


GO
GRANT EXECUTE ON  [dbo].[vpspUserContactInfoUpdate] TO [VCSPortal]
GO
