SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE      PROCEDURE [dbo].[vpspLookupsGet]
AS
	SET NOCOUNT ON;
SELECT LookupID, 
	Name, 
	IsNull(DefaultSortID, -1) as 'DefaultSortID', 
	FromClause, 
	WhereClause, 
	IsNull(ReturnColumnID, -1) as 'ReturnColumnID', 
	IsNull(DisplayColumnID, -1) as 'DisplayColumnID'
	FROM pLookups with (nolock)
GO
GRANT EXECUTE ON  [dbo].[vpspLookupsGet] TO [VCSPortal]
GO
