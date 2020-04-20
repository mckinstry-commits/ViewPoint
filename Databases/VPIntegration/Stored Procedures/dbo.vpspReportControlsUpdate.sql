SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspReportControlsUpdate]
(@ReportID int,
@PortalControlID int,
@Access int,
@UserID int
)

AS
SET NOCOUNT ON;

IF suser_name() = 'viewpointcs'
BEGIN
	IF EXISTS (SELECT Access FROM pReportControls WHERE PortalControlID = @PortalControlID AND ReportID = @ReportID)
	BEGIN
		UPDATE pReportControls SET 
			Access = @Access
			WHERE ReportID = @ReportID AND PortalControlID = @PortalControlID
	END
	ELSE
	BEGIN
		INSERT INTO pReportControls
			(ReportID, PortalControlID, Access) VALUES (@ReportID, @PortalControlID, @Access)
	END
	
	--Update the custom records to so that we have a view that displays our changes
	UPDATE pReportControlsCustom SET 
	Access = @Access
	WHERE ReportID = @ReportID AND PortalControlID = @PortalControlID
END
ELSE
BEGIN
	IF EXISTS (SELECT Access FROM pReportControlsCustom WHERE PortalControlID = @PortalControlID AND ReportID = @ReportID)
	BEGIN
		UPDATE pReportControlsCustom SET 
			Access = @Access
			WHERE ReportID = @ReportID AND PortalControlID = @PortalControlID
	END
	ELSE
	BEGIN
		INSERT INTO pReportControlsCustom
			(ReportID, PortalControlID, Access) VALUES (@ReportID, @PortalControlID, @Access)
	END
END


execute vpspReportControlsGet @ReportID, @UserID, @PortalControlID
GO
GRANT EXECUTE ON  [dbo].[vpspReportControlsUpdate] TO [VCSPortal]
GO
