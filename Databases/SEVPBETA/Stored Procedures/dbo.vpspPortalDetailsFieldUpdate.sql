SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE dbo.vpspPortalDetailsFieldUpdate
(
	@DetailsID int,
	@LabelText varchar(50),
	@ColumnName varchar(50),
	@Editable int,
	@Required bit,
	@TextMode int,
	@MaxLength int,
	@DetailsFieldOrder int,
	@Visible bit,
	@DataFormatID int,
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
	@Original_Visible bit,
	@DetailsFieldID int
)
AS
	SET NOCOUNT OFF;

IF @DataFormatID = -1 
	BEGIN
	SELECT @DataFormatID = NULL
	END

UPDATE pPortalDetailsField SET DetailsID = @DetailsID, LabelText = @LabelText, ColumnName = @ColumnName, 
	Editable = @Editable, Required = @Required, TextMode = @TextMode, MaxLength = @MaxLength, 
	DetailsFieldOrder = @DetailsFieldOrder, Visible = @Visible, DataFormatID = @DataFormatID 
	WHERE (DetailsFieldID = @Original_DetailsFieldID) AND 
	(ColumnName = @Original_ColumnName OR @Original_ColumnName IS NULL AND ColumnName IS NULL) AND 
	(DataFormatID = @Original_DataFormatID OR @Original_DataFormatID IS NULL AND DataFormatID IS NULL) AND 
	(DetailsFieldOrder = @Original_DetailsFieldOrder) AND (DetailsID = @Original_DetailsID) AND 
	(LabelText = @Original_LabelText OR @Original_LabelText IS NULL AND LabelText IS NULL) AND 
	(MaxLength = @Original_MaxLength OR @Original_MaxLength IS NULL AND MaxLength IS NULL) AND 
	(Editable = @Original_Editable) AND 
	(Required = @Original_Required OR @Original_Required IS NULL AND Required IS NULL) AND 
	(TextMode = @Original_TextMode OR @Original_TextMode IS NULL AND TextMode IS NULL) AND 
	(Visible = @Original_Visible OR @Original_Visible IS NULL AND Visible IS NULL);
	SELECT DetailsFieldID, DetailsID, LabelText, ColumnName, Editable, Required, TextMode, MaxLength, 
	DetailsFieldOrder, Visible, DataFormatID FROM pPortalDetailsField WHERE (DetailsFieldID = @DetailsFieldID)




GO
GRANT EXECUTE ON  [dbo].[vpspPortalDetailsFieldUpdate] TO [VCSPortal]
GO
