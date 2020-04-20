SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspQueryControlParameterValuesDelete
(
	@Original_QueryControlParameterID int,
	@Original_PageSiteControlID int,
	@Original_ParameterID int,
	@Original_ParameterValue varchar(50),
	@Original_RoleID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pQueryControlParameterValues WHERE (QueryControlParameterID = @Original_QueryControlParameterID) AND (PageSiteControlID = @Original_PageSiteControlID) AND (ParameterID = @Original_ParameterID) AND (ParameterValue = @Original_ParameterValue OR @Original_ParameterValue IS NULL AND ParameterValue IS NULL) AND (RoleID = @Original_RoleID)


GO
GRANT EXECUTE ON  [dbo].[vpspQueryControlParameterValuesDelete] TO [VCSPortal]
GO
