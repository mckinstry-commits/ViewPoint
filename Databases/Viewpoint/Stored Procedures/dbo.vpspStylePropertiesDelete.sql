SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspStylePropertiesDelete
(
	@Original_StyleID int,
	@Original_Name varchar(50)
)
AS
	SET NOCOUNT OFF;
DELETE FROM pStyleProperties WHERE (StyleID = @Original_StyleID) AND (Name = @Original_Name)


GO
GRANT EXECUTE ON  [dbo].[vpspStylePropertiesDelete] TO [VCSPortal]
GO
