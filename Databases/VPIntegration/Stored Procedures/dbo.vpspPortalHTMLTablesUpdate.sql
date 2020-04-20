SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPortalHTMLTablesUpdate]
(
	@DataGridID int,
	@DetailsID int,
	@Original_HTMLTableID int,
	@Original_DataGridID int,
	@Original_DetailsID int,
	@HTMLTableID int
)
AS
	SET NOCOUNT OFF;
	
IF @DataGridID = -1 SET @DataGridID = NULL
IF @DetailsID = -1 SET @DetailsID = NULL
	
UPDATE pPortalHTMLTables SET DataGridID = @DataGridID, DetailsID = @DetailsID WHERE HTMLTableID = @Original_HTMLTableID;
	SELECT HTMLTableID, DataGridID, DetailsID FROM pPortalHTMLTables WHERE (HTMLTableID = @HTMLTableID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalHTMLTablesUpdate] TO [VCSPortal]
GO
