SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspUserContactInfoGet
AS
	SET NOCOUNT ON;
SELECT UserID, ContactTypeID, ContactValue FROM pUserContactInfo


GO
GRANT EXECUTE ON  [dbo].[vpspUserContactInfoGet] TO [VCSPortal]
GO
