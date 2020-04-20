SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE       PROCEDURE [dbo].[vpspLookupColumnsGet]
AS
	SET NOCOUNT ON;
SELECT LookupColumnID, ColumnOrder, LookupID, Name, Filter, Text, 
Visible, ISNULL(ColumnWidth, 200) As ColumnWidth, CopyToCache FROM pLookupColumns with (nolock)





GO
GRANT EXECUTE ON  [dbo].[vpspLookupColumnsGet] TO [VCSPortal]
GO
