SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspQueryControlInsert
(
	@PageSiteControlID int,
	@StoredProcedureID int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pQueryControl(PageSiteControlID, StoredProcedureID) VALUES (@PageSiteControlID, @StoredProcedureID);
	SELECT PageSiteControlID, StoredProcedureID FROM pQueryControl WHERE (PageSiteControlID = @PageSiteControlID)


GO
GRANT EXECUTE ON  [dbo].[vpspQueryControlInsert] TO [VCSPortal]
GO
