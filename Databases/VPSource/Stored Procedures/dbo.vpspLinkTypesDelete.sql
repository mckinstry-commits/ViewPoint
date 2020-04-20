SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspLinkTypesDelete
(
	@Original_LinkTypeID int,
	@Original_Description varchar(255),
	@Original_Name varchar(50)
)
AS
	SET NOCOUNT OFF;
DELETE FROM pLinkTypes WHERE (LinkTypeID = @Original_LinkTypeID) AND (Description = @Original_Description) AND (Name = @Original_Name)


GO
GRANT EXECUTE ON  [dbo].[vpspLinkTypesDelete] TO [VCSPortal]
GO
