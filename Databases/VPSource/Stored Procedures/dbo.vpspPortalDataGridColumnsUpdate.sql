SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    PROCEDURE [dbo].[vpspPortalDataGridColumnsUpdate]
(
	@DataGridID int,
	@ColumnName varchar(50),
	@HeaderText varchar(50),
	@Visible bit,
	@ColumnOrder int,
	@DataFormatID int,
	@Original_DataGridColumnID int,
	@Original_ColumnName varchar(50),
	@Original_ColumnOrder int,
	@Original_DataFormatID int,
	@Original_DataGridID int,
	@Original_HeaderText varchar(50),
	@Original_Visible bit,
	@DataGridColumnID int,
	@ColumnWidth int,
	@MaxLength int,
	@ChangesAllowedOnAdd bit,
	@ChangesAllowedOnUpdate bit,
	@IsRequired bit
)
AS
	SET NOCOUNT OFF;

IF @DataFormatID = -1 
	BEGIN
	SELECT @DataFormatID = NULL
	END

IF @Original_DataFormatID = -1
	BEGIN
	SET @Original_DataFormatID = NULL
	END

IF @ColumnWidth = -1
	BEGIN
	SET @ColumnWidth = NULL
	END


UPDATE pPortalDataGridColumns SET DataGridID = @DataGridID, ColumnName = @ColumnName, HeaderText = @HeaderText, Visible = @Visible, ColumnOrder = @ColumnOrder, DataFormatID = @DataFormatID, ColumnWidth = @ColumnWidth, MaxLength = @MaxLength, ChangesAllowedOnAdd = @ChangesAllowedOnAdd, ChangesAllowedOnUpdate = @ChangesAllowedOnUpdate, IsRequired = @IsRequired WHERE (DataGridColumnID = @Original_DataGridColumnID) AND (ColumnName = @Original_ColumnName) AND (ColumnOrder = @Original_ColumnOrder) AND (DataFormatID = @Original_DataFormatID OR @Original_DataFormatID IS NULL AND DataFormatID IS NULL) AND (DataGridID = @Original_DataGridID) AND (HeaderText = @Original_HeaderText) AND (Visible = @Original_Visible);
	SELECT DataGridColumnID, DataGridID, ColumnName, HeaderText, Visible, ColumnOrder, DataFormatID, ColumnWidth, MaxLength, ChangesAllowedOnAdd, ChangesAllowedOnUpdate FROM pPortalDataGridColumns WHERE (DataGridColumnID = @DataGridColumnID)





GO
GRANT EXECUTE ON  [dbo].[vpspPortalDataGridColumnsUpdate] TO [VCSPortal]
GO
