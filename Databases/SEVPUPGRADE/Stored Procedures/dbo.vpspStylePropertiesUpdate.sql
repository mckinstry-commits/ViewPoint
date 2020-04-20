SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspStylePropertiesUpdate
(
	@Name varchar(50),
	@Original_StyleID int,
	@Original_Name varchar(50),
	@StyleID int
)
AS
	SET NOCOUNT OFF;
UPDATE pStyleProperties SET Name = @Name WHERE (StyleID = @Original_StyleID) AND (Name = @Original_Name);
	SELECT StyleID, Name FROM pStyleProperties WHERE (StyleID = @StyleID)


GO
GRANT EXECUTE ON  [dbo].[vpspStylePropertiesUpdate] TO [VCSPortal]
GO
