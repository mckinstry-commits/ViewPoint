SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspQueryControlDelete
(
	@Original_PageSiteControlID int,
	@Original_StoredProcedureID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pQueryControl WHERE (PageSiteControlID = @Original_PageSiteControlID) AND (StoredProcedureID = @Original_StoredProcedureID)


GO
GRANT EXECUTE ON  [dbo].[vpspQueryControlDelete] TO [VCSPortal]
GO
