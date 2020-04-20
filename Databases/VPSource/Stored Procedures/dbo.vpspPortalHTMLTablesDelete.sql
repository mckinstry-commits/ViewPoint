SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalHTMLTablesDelete
(
	@Original_HTMLTableID int,
	@Original_DataGridID int,
	@Original_DetailsID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalHTMLTables WHERE (HTMLTableID = @Original_HTMLTableID) AND (DataGridID = @Original_DataGridID OR @Original_DataGridID IS NULL AND DataGridID IS NULL) AND (DetailsID = @Original_DetailsID OR @Original_DetailsID IS NULL AND DetailsID IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalHTMLTablesDelete] TO [VCSPortal]
GO
