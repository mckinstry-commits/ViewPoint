SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspQueryControlParameterValuesUpdate
(
	@QueryControlParameterID int,
	@ParameterID int,
	@PageSiteControlID int,
	@RoleID int,
	@ParameterValue varchar(50),
	@Original_QueryControlParameterID int,
	@Original_PageSiteControlID int,
	@Original_ParameterID int,
	@Original_ParameterValue varchar(50),
	@Original_RoleID int
)
AS
	SET NOCOUNT OFF;
UPDATE pQueryControlParameterValues SET QueryControlParameterID = @QueryControlParameterID, ParameterID = @ParameterID, PageSiteControlID = @PageSiteControlID, RoleID = @RoleID, ParameterValue = @ParameterValue WHERE (QueryControlParameterID = @Original_QueryControlParameterID) AND (PageSiteControlID = @Original_PageSiteControlID) AND (ParameterID = @Original_ParameterID) AND (ParameterValue = @Original_ParameterValue OR @Original_ParameterValue IS NULL AND ParameterValue IS NULL) AND (RoleID = @Original_RoleID);
	SELECT QueryControlParameterID, ParameterID, PageSiteControlID, RoleID, ParameterValue FROM pQueryControlParameterValues WHERE (QueryControlParameterID = @QueryControlParameterID)


GO
GRANT EXECUTE ON  [dbo].[vpspQueryControlParameterValuesUpdate] TO [VCSPortal]
GO
