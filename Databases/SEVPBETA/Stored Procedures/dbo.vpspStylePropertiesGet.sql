SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspStylePropertiesGet
AS
	SET NOCOUNT ON;
SELECT StyleID, Name FROM pStyleProperties


GO
GRANT EXECUTE ON  [dbo].[vpspStylePropertiesGet] TO [VCSPortal]
GO
