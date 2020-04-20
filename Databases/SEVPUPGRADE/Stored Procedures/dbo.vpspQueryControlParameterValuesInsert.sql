SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspQueryControlParameterValuesInsert
(
	@QueryControlParameterID int,
	@ParameterID int,
	@PageSiteControlID int,
	@RoleID int,
	@ParameterValue varchar(50)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pQueryControlParameterValues(QueryControlParameterID, ParameterID, PageSiteControlID, RoleID, ParameterValue) VALUES (@QueryControlParameterID, @ParameterID, @PageSiteControlID, @RoleID, @ParameterValue);
	SELECT QueryControlParameterID, ParameterID, PageSiteControlID, RoleID, ParameterValue FROM pQueryControlParameterValues WHERE (QueryControlParameterID = @QueryControlParameterID)


GO
GRANT EXECUTE ON  [dbo].[vpspQueryControlParameterValuesInsert] TO [VCSPortal]
GO
