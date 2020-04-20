SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


(
	@UserID int,
	@ContactTypeID int,
	@ContactValue varchar(50)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pUserContactInfo(UserID, ContactTypeID, ContactValue) VALUES (@UserID, @ContactTypeID, @ContactValue);
	SELECT UserID, ContactTypeID, ContactValue FROM pUserContactInfo WHERE (ContactTypeID = @ContactTypeID) AND (UserID = @UserID)


GO
GRANT EXECUTE ON  [dbo].[vpspUserContactInfoInsert] TO [VCSPortal]
GO