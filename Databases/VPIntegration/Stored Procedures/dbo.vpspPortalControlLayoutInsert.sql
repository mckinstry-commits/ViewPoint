SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalControlLayoutInsert
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
	@BottomRightTableID int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPortalControlLayout(PortalControlID, TopLeftTableID, TopCenterTableID, TopRightTableID, CenterLeftTableID, CenterCenterTableID, CenterRightTableID, BottomLeftTableID, BottomCenterTableID, BottomRightTableID) VALUES (@PortalControlID, @TopLeftTableID, @TopCenterTableID, @TopRightTableID, @CenterLeftTableID, @CenterCenterTableID, @CenterRightTableID, @BottomLeftTableID, @BottomCenterTableID, @BottomRightTableID);
	SELECT PortalControlID, TopLeftTableID, TopCenterTableID, TopRightTableID, CenterLeftTableID, CenterCenterTableID, CenterRightTableID, BottomLeftTableID, BottomCenterTableID, BottomRightTableID FROM pPortalControlLayout WHERE (PortalControlID = @PortalControlID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlLayoutInsert] TO [VCSPortal]
GO
