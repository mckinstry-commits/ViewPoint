SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    PROCEDURE [dbo].[vpspPortalDataGridColumnsInsert]
(
	@DataGridID int,
	@ColumnName varchar(50),
	@HeaderText varchar(50),
	@Visible bit,
	@ColumnOrder int,
	@DataFormatID int,
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

IF @ColumnWidth = -1
	BEGIN
	SELECT @ColumnWidth = NULL
	END

INSERT INTO pPortalDataGridColumns(DataGridID, ColumnName, HeaderText, Visible, ColumnOrder, DataFormatID, ColumnWidth, MaxLength, ChangesAllowedOnAdd, ChangesAllowedOnUpdate, IsRequired) VALUES (@DataGridID, @ColumnName, @HeaderText, @Visible, @ColumnOrder, @DataFormatID, @ColumnWidth, @MaxLength, @ChangesAllowedOnAdd,@ChangesAllowedOnUpdate,@IsRequired);
	SELECT DataGridColumnID, DataGridID, ColumnName, HeaderText, Visible, ColumnOrder, DataFormatID, ColumnWidth, MaxLength, ChangesAllowedOnAdd, ChangesAllowedOnUpdate, IsRequired FROM pPortalDataGridColumns WHERE (DataGridColumnID = SCOPE_IDENTITY())





GO
GRANT EXECUTE ON  [dbo].[vpspPortalDataGridColumnsInsert] TO [VCSPortal]
GO
