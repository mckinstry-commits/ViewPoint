SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalDataFormatDelete
(
	@Original_DataFormatID int,
	@Original_DataFormatString varchar(50),
	@Original_Name varchar(50)
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalDataFormat WHERE (DataFormatID = @Original_DataFormatID) AND (DataFormatString = @Original_DataFormatString) AND (Name = @Original_Name)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalDataFormatDelete] TO [VCSPortal]
GO
