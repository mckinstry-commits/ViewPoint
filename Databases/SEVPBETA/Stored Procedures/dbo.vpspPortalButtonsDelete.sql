SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalButtonsDelete
(
	@Original_ButtonName varchar(50),
	@Original_ButtonID int,
	@Original_ConfirmMessageID int,
	@Original_DefaultImageName varchar(50),
	@Original_HoverImageName varchar(50),
	@Original_TooltipText varchar(50)
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalButtons WHERE (ButtonName = @Original_ButtonName) AND (ButtonID = @Original_ButtonID) AND (ConfirmMessageID = @Original_ConfirmMessageID OR @Original_ConfirmMessageID IS NULL AND ConfirmMessageID IS NULL) AND (DefaultImageName = @Original_DefaultImageName) AND (HoverImageName = @Original_HoverImageName) AND (TooltipText = @Original_TooltipText)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalButtonsDelete] TO [VCSPortal]
GO
