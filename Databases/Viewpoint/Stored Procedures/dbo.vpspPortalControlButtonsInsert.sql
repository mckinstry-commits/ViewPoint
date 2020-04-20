SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE dbo.vpspPortalControlButtonsInsert
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
	@RoleID int
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

INSERT INTO pPortalControlButtons(PortalControlID, ButtonID, SuccessMessageID, InformationMessageID, FailureMessageID, ButtonOrder, DefaultImageName, HoverImageName, TooltipText, ConfirmMessageID, NavigationPageID, RoleID) VALUES (@PortalControlID, @ButtonID, @SuccessMessageID, @InformationMessageID, @FailureMessageID, @ButtonOrder, @DefaultImageName, @HoverImageName, @TooltipText, @ConfirmMessageID, @NavigationPageID, @RoleID);
	SELECT PortalControlID, ButtonID, SuccessMessageID, InformationMessageID, FailureMessageID, ButtonOrder, DefaultImageName, HoverImageName, TooltipText, ConfirmMessageID, NavigationPageID, RoleID FROM pPortalControlButtons WHERE (ButtonID = @ButtonID) AND (PortalControlID = @PortalControlID)



GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlButtonsInsert] TO [VCSPortal]
GO
