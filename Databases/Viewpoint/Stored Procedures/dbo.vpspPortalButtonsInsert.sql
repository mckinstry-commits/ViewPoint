SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalButtonsInsert
(
	@ButtonName varchar(50),
	@DefaultImageName varchar(50),
	@HoverImageName varchar(50),
	@TooltipText varchar(50),
	@ConfirmMessageID int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPortalButtons(ButtonName, DefaultImageName, HoverImageName, TooltipText, ConfirmMessageID) VALUES (@ButtonName, @DefaultImageName, @HoverImageName, @TooltipText, @ConfirmMessageID);
	SELECT ButtonID, ButtonName, DefaultImageName, HoverImageName, TooltipText, ConfirmMessageID FROM pPortalButtons WHERE (ButtonName = @ButtonName)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalButtonsInsert] TO [VCSPortal]
GO
