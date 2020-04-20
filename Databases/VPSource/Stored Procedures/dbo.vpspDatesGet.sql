SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspDatesGet]

AS
	
SET NOCOUNT ON;

SELECT DateID, [Name], TableName, DateColumn, [Description], [Type], Filter
	FROM pDates with (nolock)
	



GO
GRANT EXECUTE ON  [dbo].[vpspDatesGet] TO [VCSPortal]
GO
