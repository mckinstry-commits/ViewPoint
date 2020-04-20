SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspPortalDataFormatInsert
(
	@Name varchar(50),
	@DataFormatString varchar(50)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPortalDataFormat(Name, DataFormatString) VALUES (@Name, @DataFormatString);
	SELECT DataFormatID, Name, DataFormatString FROM pPortalDataFormat WHERE (DataFormatID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vpspPortalDataFormatInsert] TO [VCSPortal]
GO
