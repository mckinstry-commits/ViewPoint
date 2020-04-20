SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspPortalHTMLTablesInsert
(
	@DataGridID int,
	@DetailsID int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPortalHTMLTables(DataGridID, DetailsID) VALUES (@DataGridID, @DetailsID);
	SELECT HTMLTableID, DataGridID, DetailsID FROM pPortalHTMLTables WHERE (HTMLTableID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vpspPortalHTMLTablesInsert] TO [VCSPortal]
GO
