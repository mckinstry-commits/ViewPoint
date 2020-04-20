SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    PROCEDURE dbo.vpspPortalDetailsFieldInsert
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
	@DataFormatID int
)
AS
	SET NOCOUNT OFF;

IF @DataFormatID = -1 
	BEGIN
	SELECT @DataFormatID = NULL
	END

INSERT INTO pPortalDetailsField(DetailsID, LabelText, ColumnName, Editable, Required, TextMode, 
MaxLength, DetailsFieldOrder, Visible, DataFormatID) 
	VALUES (@DetailsID, @LabelText, @ColumnName, @Editable, @Required, @TextMode, @MaxLength, 
			@DetailsFieldOrder, @Visible, @DataFormatID);
	
SELECT DetailsFieldID, DetailsID, LabelText, ColumnName, Editable, Required, TextMode, MaxLength, 
	DetailsFieldOrder, Visible, DataFormatID FROM pPortalDetailsField WHERE (DetailsFieldID = SCOPE_IDENTITY())





GO
GRANT EXECUTE ON  [dbo].[vpspPortalDetailsFieldInsert] TO [VCSPortal]
GO
