SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspUserContactInfoDelete
(
	@Original_ContactTypeID int,
	@Original_UserID int,
	@Original_ContactValue varchar(50)
)
AS
	SET NOCOUNT OFF;
DELETE FROM pUserContactInfo WHERE (ContactTypeID = @Original_ContactTypeID) AND (UserID = @Original_UserID) AND (ContactValue = @Original_ContactValue)


GO
GRANT EXECUTE ON  [dbo].[vpspUserContactInfoDelete] TO [VCSPortal]
GO
