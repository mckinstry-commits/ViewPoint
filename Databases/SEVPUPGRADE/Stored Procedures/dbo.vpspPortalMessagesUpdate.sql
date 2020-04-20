SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalMessagesUpdate
(
	@MessageText varchar(50),
	@Original_MessageID int,
	@Original_MessageText varchar(50),
	@MessageID int
)
AS
	SET NOCOUNT OFF;
UPDATE pPortalMessages SET MessageText = @MessageText WHERE (MessageID = @Original_MessageID) AND (MessageText = @Original_MessageText);
	SELECT MessageID, MessageText FROM pPortalMessages WHERE (MessageID = @MessageID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalMessagesUpdate] TO [VCSPortal]
GO
