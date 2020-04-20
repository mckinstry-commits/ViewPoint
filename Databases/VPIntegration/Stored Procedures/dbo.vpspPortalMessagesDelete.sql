SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalMessagesDelete
(
	@Original_MessageID int,
	@Original_MessageText varchar(50)
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalMessages WHERE (MessageID = @Original_MessageID) AND (MessageText = @Original_MessageText)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalMessagesDelete] TO [VCSPortal]
GO
