SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     PROCEDURE [dbo].[vpspLookupColumnsUpdate]
(
	@Original_LookupColumnID int,
    @Original_LookupID int,
    @ColumnOrder int,
    @Name varchar(255),
    @Filter varchar(255),
    @Text varchar(255),
    @Visible bit,
    @ColumnWidth int
)
AS

SET NOCOUNT OFF;

UPDATE pLookupColumns
SET
ColumnOrder = @ColumnOrder,
Name = @Name,
Filter = @Filter,
Text = @Text,
Visible = @Visible,
ColumnWidth = @ColumnWidth 
WHERE LookupColumnID = @Original_LookupColumnID AND LookupID = @Original_LookupID;	




GO
GRANT EXECUTE ON  [dbo].[vpspLookupColumnsUpdate] TO [VCSPortal]
GO
