SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspReportSecurityUpdate]
(@ReportID int,
@RoleID int,
@Access int,
@UserID int
)

AS
SET NOCOUNT ON;

IF suser_name() = 'viewpointcs'
BEGIN
	IF EXISTS (SELECT Access FROM pReportSecurity WHERE RoleID = @RoleID AND ReportID = @ReportID)
	BEGIN
		UPDATE pReportSecurity SET 
			Access = @Access
			WHERE ReportID = @ReportID AND RoleID = @RoleID
	END
	ELSE
	BEGIN
		INSERT INTO pReportSecurity
			(ReportID, RoleID, Access) VALUES (@ReportID, @RoleID, @Access)
	END
	
	--Update the custom records too so that the get stored procedure reflects our changes
	UPDATE pReportSecurityCustom SET 
	Access = @Access
	WHERE ReportID = @ReportID AND RoleID = @RoleID
END
ELSE
BEGIN
	IF EXISTS (SELECT Access FROM pReportSecurityCustom WHERE RoleID = @RoleID AND ReportID = @ReportID)
	BEGIN
		UPDATE pReportSecurityCustom SET 
			Access = @Access
			WHERE ReportID = @ReportID AND RoleID = @RoleID
	END
	ELSE
	BEGIN
		INSERT INTO pReportSecurityCustom
			(ReportID, RoleID, Access) VALUES (@ReportID, @RoleID, @Access)
	END
END

execute vpspReportSecurityGet @ReportID, @UserID, @RoleID
GO
GRANT EXECUTE ON  [dbo].[vpspReportSecurityUpdate] TO [VCSPortal]
GO
