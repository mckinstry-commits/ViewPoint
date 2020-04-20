SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspPortalMessagesInsert
(
	@MessageText varchar(50)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPortalMessages(MessageText) VALUES (@MessageText);
	SELECT MessageID, MessageText FROM pPortalMessages WHERE (MessageID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vpspPortalMessagesInsert] TO [VCSPortal]
GO
