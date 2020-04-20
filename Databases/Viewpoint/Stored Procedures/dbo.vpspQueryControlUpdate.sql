SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspQueryControlUpdate
(
	@PageSiteControlID int,
	@StoredProcedureID int,
	@Original_PageSiteControlID int,
	@Original_StoredProcedureID int
)
AS
	SET NOCOUNT OFF;
UPDATE pQueryControl SET PageSiteControlID = @PageSiteControlID, StoredProcedureID = @StoredProcedureID WHERE (PageSiteControlID = @Original_PageSiteControlID) AND (StoredProcedureID = @Original_StoredProcedureID);
	SELECT PageSiteControlID, StoredProcedureID FROM pQueryControl WHERE (PageSiteControlID = @PageSiteControlID)


GO
GRANT EXECUTE ON  [dbo].[vpspQueryControlUpdate] TO [VCSPortal]
GO
