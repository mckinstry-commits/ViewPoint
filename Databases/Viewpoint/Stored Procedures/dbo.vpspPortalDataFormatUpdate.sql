SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalDataFormatUpdate
(
	@Name varchar(50),
	@DataFormatString varchar(50),
	@Original_DataFormatID int,
	@Original_DataFormatString varchar(50),
	@Original_Name varchar(50),
	@DataFormatID int
)
AS
	SET NOCOUNT OFF;
UPDATE pPortalDataFormat SET Name = @Name, DataFormatString = @DataFormatString WHERE (DataFormatID = @Original_DataFormatID) AND (DataFormatString = @Original_DataFormatString) AND (Name = @Original_Name);
	SELECT DataFormatID, Name, DataFormatString FROM pPortalDataFormat WHERE (DataFormatID = @DataFormatID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalDataFormatUpdate] TO [VCSPortal]
GO
