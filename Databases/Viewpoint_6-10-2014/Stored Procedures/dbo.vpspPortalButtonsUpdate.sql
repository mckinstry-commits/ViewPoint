SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalButtonsUpdate
(
	@ButtonName varchar(50),
	@DefaultImageName varchar(50),
	@HoverImageName varchar(50),
	@TooltipText varchar(50),
	@ConfirmMessageID int,
	@Original_ButtonName varchar(50),
	@Original_ConfirmMessageID int,
	@Original_DefaultImageName varchar(50),
	@Original_HoverImageName varchar(50),
	@Original_TooltipText varchar(50)
)
AS
	SET NOCOUNT OFF;
UPDATE pPortalButtons SET ButtonName = @ButtonName, DefaultImageName = @DefaultImageName, HoverImageName = @HoverImageName, TooltipText = @TooltipText, ConfirmMessageID = @ConfirmMessageID WHERE (ButtonName = @Original_ButtonName) AND (ConfirmMessageID = @Original_ConfirmMessageID OR @Original_ConfirmMessageID IS NULL AND ConfirmMessageID IS NULL) AND (DefaultImageName = @Original_DefaultImageName) AND (HoverImageName = @Original_HoverImageName) AND (TooltipText = @Original_TooltipText);
	SELECT ButtonID, ButtonName, DefaultImageName, HoverImageName, TooltipText, ConfirmMessageID FROM pPortalButtons WHERE (ButtonName = @ButtonName)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalButtonsUpdate] TO [VCSPortal]
GO
