SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


AS
	SET NOCOUNT ON;
SELECT QueryControlParameterID, ParameterID, PageSiteControlID, RoleID, ParameterValue FROM pQueryControlParameterValues


GO
GRANT EXECUTE ON  [dbo].[vpspQueryControlParameterValuesGet] TO [VCSPortal]
GO