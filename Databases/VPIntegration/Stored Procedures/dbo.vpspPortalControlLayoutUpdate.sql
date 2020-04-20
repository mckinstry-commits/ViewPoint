SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPortalControlLayoutUpdate]
(
	@PortalControlID int,
	@TopLeftTableID int,
	@TopCenterTableID int,
	@TopRightTableID int,
	@CenterLeftTableID int,
	@CenterCenterTableID int,
	@CenterRightTableID int,
	@BottomLeftTableID int,
	@BottomCenterTableID int,
	@BottomRightTableID int,
	@Original_PortalControlID int,
	@Original_BottomCenterTableID int,
	@Original_BottomLeftTableID int,
	@Original_BottomRightTableID int,
	@Original_CenterCenterTableID int,
	@Original_CenterLeftTableID int,
	@Original_CenterRightTableID int,
	@Original_TopCenterTableID int,
	@Original_TopLeftTableID int,
	@Original_TopRightTableID int
)
AS
	SET NOCOUNT OFF;
	IF @TopLeftTableID = -1 SET @TopLeftTableID = NULL
	IF @TopCenterTableID = -1 SET @TopCenterTableID = NULL
	IF @TopRightTableID = -1 SET @TopRightTableID = NULL
	IF @CenterLeftTableID = -1 SET @CenterLeftTableID = NULL
	IF @CenterCenterTableID = -1 SET @CenterCenterTableID = NULL
	IF @CenterRightTableID = -1 SET @CenterRightTableID = NULL
	IF @BottomLeftTableID = -1 SET @BottomLeftTableID = NULL
	IF @BottomCenterTableID = -1 SET @BottomCenterTableID = NULL
	IF @BottomRightTableID = -1 SET @BottomRightTableID = NULL
UPDATE pPortalControlLayout SET PortalControlID = @PortalControlID, TopLeftTableID = @TopLeftTableID, TopCenterTableID = @TopCenterTableID, TopRightTableID = @TopRightTableID, CenterLeftTableID = @CenterLeftTableID, CenterCenterTableID = @CenterCenterTableID, CenterRightTableID = @CenterRightTableID, BottomLeftTableID = @BottomLeftTableID, BottomCenterTableID = @BottomCenterTableID, BottomRightTableID = @BottomRightTableID WHERE PortalControlID = @Original_PortalControlID
	SELECT PortalControlID, TopLeftTableID, TopCenterTableID, TopRightTableID, CenterLeftTableID, CenterCenterTableID, CenterRightTableID, BottomLeftTableID, BottomCenterTableID, BottomRightTableID FROM pPortalControlLayout WHERE (PortalControlID = @PortalControlID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlLayoutUpdate] TO [VCSPortal]
GO
