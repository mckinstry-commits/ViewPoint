SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Chris Gall
-- Create date: 11/03/2011
-- Description: Determines whether a PortalControl is a 
--		detail control.  If false, its a grid control.
-- =============================================
CREATE PROCEDURE [dbo].[vpspIsDetailControl] 
	@PortalConrolID int,
	@IsDetail bit output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @IsDetail = 0
    
	SELECT @IsDetail = 1 FROM pPortalHTMLTables
	WHERE DetailsID IS NOT NULL AND
		(HTMLTableID IN (
		SELECT TopLeftTableID FROM pPortalControlLayout WHERE
			PortalControlID = @PortalConrolID
			)
		OR HTMLTableID IN (
		SELECT TopCenterTableID FROM pPortalControlLayout WHERE
			PortalControlID = @PortalConrolID
			)
		OR HTMLTableID IN (
		SELECT TopRightTableID FROM pPortalControlLayout WHERE
			PortalControlID = @PortalConrolID
			)
		OR HTMLTableID IN (
		SELECT CenterLeftTableID FROM pPortalControlLayout WHERE
			PortalControlID = @PortalConrolID
			)
		OR HTMLTableID IN (
		SELECT CenterCenterTableID FROM pPortalControlLayout WHERE
			PortalControlID = @PortalConrolID
			)
		OR HTMLTableID IN (
		SELECT CenterRightTableID FROM pPortalControlLayout WHERE
			PortalControlID = @PortalConrolID
			)	
		OR HTMLTableID IN (
		SELECT BottomLeftTableID FROM pPortalControlLayout WHERE
			PortalControlID = @PortalConrolID
			)		
		OR HTMLTableID IN (
		SELECT BottomCenterTableID FROM pPortalControlLayout WHERE
			PortalControlID = @PortalConrolID
			)		
		OR HTMLTableID IN (
		SELECT BottomRightTableID FROM pPortalControlLayout WHERE
			PortalControlID = @PortalConrolID
			)
		)
END


GO
GRANT EXECUTE ON  [dbo].[vpspIsDetailControl] TO [VCSPortal]
GO
