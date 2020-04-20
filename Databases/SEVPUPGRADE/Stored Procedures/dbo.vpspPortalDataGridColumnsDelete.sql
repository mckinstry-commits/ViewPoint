SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspPortalDataGridColumnsDelete
(
	@Original_DataGridColumnID int,
	@Original_ColumnName varchar(50),
	@Original_ColumnOrder int,
	@Original_DataFormatID int,
	@Original_DataGridID int,
	@Original_HeaderText varchar(50),
	@Original_Visible bit
)
AS

SET NOCOUNT OFF;

IF @Original_DataFormatID = -1
	BEGIN
	SET @Original_DataFormatID = NULL
	END

DELETE FROM pPortalDataGridColumns WHERE (DataGridColumnID = @Original_DataGridColumnID) AND (ColumnName = @Original_ColumnName) AND (ColumnOrder = @Original_ColumnOrder) AND (DataFormatID = @Original_DataFormatID OR @Original_DataFormatID IS NULL AND DataFormatID IS NULL) AND (DataGridID = @Original_DataGridID) AND (HeaderText = @Original_HeaderText) AND (Visible = @Original_Visible)



GO
GRANT EXECUTE ON  [dbo].[vpspPortalDataGridColumnsDelete] TO [VCSPortal]
GO
