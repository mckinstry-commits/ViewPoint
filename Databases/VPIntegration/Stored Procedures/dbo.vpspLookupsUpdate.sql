SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE PROCEDURE [dbo].[vpspLookupsUpdate]
(
	@Original_LookupID int,
    @Name varchar(50),
    @DefaultSortID int,
    @FromClause varchar(255),
    @WhereClause varchar(255),
    @ReturnColumnID int,
    @DisplayColumnID int 
)
AS

SET NOCOUNT OFF;

IF @DefaultSortID = -1 SET @DefaultSortID = NULL
IF @ReturnColumnID = -1 SET @ReturnColumnID = NULL
IF @DisplayColumnID = -1 SET @DisplayColumnID = NULL

UPDATE pLookups
SET
Name = @Name,
DefaultSortID = @DefaultSortID,
FromClause = @FromClause,
WhereClause= @WhereClause,
ReturnColumnID = @ReturnColumnID,
DisplayColumnID = @DisplayColumnID
WHERE LookupID = @Original_LookupID;	





GO
GRANT EXECUTE ON  [dbo].[vpspLookupsUpdate] TO [VCSPortal]
GO
