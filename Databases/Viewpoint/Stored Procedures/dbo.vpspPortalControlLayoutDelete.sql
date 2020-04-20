SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalControlLayoutDelete
(
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
DELETE FROM pPortalControlLayout WHERE (PortalControlID = @Original_PortalControlID) AND (BottomCenterTableID = @Original_BottomCenterTableID OR @Original_BottomCenterTableID IS NULL AND BottomCenterTableID IS NULL) AND (BottomLeftTableID = @Original_BottomLeftTableID OR @Original_BottomLeftTableID IS NULL AND BottomLeftTableID IS NULL) AND (BottomRightTableID = @Original_BottomRightTableID OR @Original_BottomRightTableID IS NULL AND BottomRightTableID IS NULL) AND (CenterCenterTableID = @Original_CenterCenterTableID OR @Original_CenterCenterTableID IS NULL AND CenterCenterTableID IS NULL) AND (CenterLeftTableID = @Original_CenterLeftTableID OR @Original_CenterLeftTableID IS NULL AND CenterLeftTableID IS NULL) AND (CenterRightTableID = @Original_CenterRightTableID OR @Original_CenterRightTableID IS NULL AND CenterRightTableID IS NULL) AND (TopCenterTableID = @Original_TopCenterTableID OR @Original_TopCenterTableID IS NULL AND TopCenterTableID IS NULL) AND (TopLeftTableID = @Original_TopLeftTableID OR @Original_TopLeftTableID IS NULL AND TopLeftTableID IS NULL) AND (TopRightTableID = @Original_TopRightTableID OR @Original_TopRightTableID IS NULL AND TopRightTableID IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlLayoutDelete] TO [VCSPortal]
GO
