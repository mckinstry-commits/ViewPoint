SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspPortalControlButtonsDelete]
(
	@Original_ButtonID int,
	@Original_PortalControlID int,
	@Original_ButtonOrder int,
	@Original_ConfirmMessageID int,
	@Original_DefaultImageName varchar(50),
	@Original_FailureMessageID int,
	@Original_HoverImageName varchar(50),
	@Original_InformationMessageID int,
	@Original_NavigationPageID int,
	@Original_RoleID int,
	@Original_SuccessMessageID int,
	@Original_TooltipText varchar(50)
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalControlButtons 
WHERE (ButtonID = @Original_ButtonID) 
AND (PortalControlID = @Original_PortalControlID) 



GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlButtonsDelete] TO [VCSPortal]
GO
