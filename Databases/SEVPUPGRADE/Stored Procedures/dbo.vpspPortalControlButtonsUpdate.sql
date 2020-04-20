SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE    PROCEDURE dbo.vpspPortalControlButtonsUpdate
(
	@PortalControlID int,
	@ButtonID int,
	@SuccessMessageID int,
	@InformationMessageID int,
	@FailureMessageID int,
	@ButtonOrder int,
	@DefaultImageName varchar(50),
	@HoverImageName varchar(50),
	@TooltipText varchar(50),
	@ConfirmMessageID int,
	@NavigationPageID int,
	@RoleID int,
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

IF @SuccessMessageID = -1 
	BEGIN
	SELECT @SuccessMessageID = NULL
	END

IF @InformationMessageID = -1 
	BEGIN
	SELECT @InformationMessageID = NULL
	END

IF @FailureMessageID = -1 
	BEGIN
	SELECT @FailureMessageID = NULL
	END

IF @ConfirmMessageID = -1 
	BEGIN
	SELECT @ConfirmMessageID = NULL
	END

IF @NavigationPageID = -1 
	BEGIN
	SELECT @NavigationPageID = NULL
	END


UPDATE pPortalControlButtons SET PortalControlID = @PortalControlID, ButtonID = @ButtonID, 
SuccessMessageID = @SuccessMessageID, InformationMessageID = @InformationMessageID, 
FailureMessageID = @FailureMessageID, ButtonOrder = @ButtonOrder, DefaultImageName = @DefaultImageName, 
HoverImageName = @HoverImageName, TooltipText = @TooltipText, ConfirmMessageID = @ConfirmMessageID, 
NavigationPageID = @NavigationPageID, RoleID = @RoleID WHERE (ButtonID = @Original_ButtonID) AND 
(PortalControlID = @Original_PortalControlID) ;
	SELECT PortalControlID, ButtonID, SuccessMessageID, InformationMessageID, FailureMessageID, ButtonOrder, DefaultImageName, HoverImageName, TooltipText, ConfirmMessageID, NavigationPageID, RoleID FROM pPortalControlButtons WHERE (ButtonID = @ButtonID) AND (PortalControlID = @PortalControlID)



GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlButtonsUpdate] TO [VCSPortal]
GO
