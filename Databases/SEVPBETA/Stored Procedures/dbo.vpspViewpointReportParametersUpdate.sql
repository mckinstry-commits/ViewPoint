SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspViewpointReportParametersUpdate]
(@ReportID int,
@ParameterName varchar(30),
@PortalParameterDefault varchar(60),
@PortalAccess int,
@UserID int
)

AS
SET NOCOUNT ON;

UPDATE RPRPShared SET 
	PortalParameterDefault = @PortalParameterDefault,
	PortalAccess = @PortalAccess
	WHERE ReportID = @ReportID AND ParameterName = @ParameterName

--Update the custom table as well if the logged in User is viewpointcs so that the view
--will be guaranteed to have the changes
IF suser_name() = 'viewpointcs'
BEGIN
	UPDATE RPRPc SET 
		PortalParameterDefault = @PortalParameterDefault,
		PortalAccess = @PortalAccess
		WHERE ReportID = @ReportID AND ParameterName = @ParameterName
END



execute vpspViewpointReportParametersGet @ReportID, @UserID, @ParameterName
GO
GRANT EXECUTE ON  [dbo].[vpspViewpointReportParametersUpdate] TO [VCSPortal]
GO
