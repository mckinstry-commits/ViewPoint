SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspPortalDetailsFieldDelete
(
	@Original_DetailsFieldID int,
	@Original_ColumnName varchar(50),
	@Original_DataFormatID int,
	@Original_DetailsFieldOrder int,
	@Original_DetailsID int,
	@Original_LabelText varchar(50),
	@Original_MaxLength int,
	@Original_Editable int,
	@Original_Required bit,
	@Original_TextMode int,
	@Original_Visible bit
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalDetailsField 
WHERE (DetailsFieldID = @Original_DetailsFieldID) AND 
(ColumnName = @Original_ColumnName OR @Original_ColumnName IS NULL AND ColumnName IS NULL) AND 
(DataFormatID = @Original_DataFormatID OR @Original_DataFormatID IS NULL AND DataFormatID IS NULL) AND 
(DetailsFieldOrder = @Original_DetailsFieldOrder) AND 
(DetailsID = @Original_DetailsID) AND 
(LabelText = @Original_LabelText OR @Original_LabelText IS NULL AND LabelText IS NULL) AND 
(MaxLength = @Original_MaxLength OR @Original_MaxLength IS NULL AND MaxLength IS NULL) AND 
(Editable = @Original_Editable) AND 
(Required = @Original_Required) AND 
(TextMode = @Original_TextMode) AND 
(Visible = @Original_Visible)



GO
GRANT EXECUTE ON  [dbo].[vpspPortalDetailsFieldDelete] TO [VCSPortal]
GO
