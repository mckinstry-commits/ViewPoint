SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPResetQueryLinkParameterMatchingColumn]
/***********************************************************
* CREATED BY:   HH 5/30/2012
* MODIFIED BY:  
*
* Usage: Reset VPGridQueryLinkParameters.MatchingColumn afer a Column 
* from the starting query has been deleted if it is a MatchingColumn 
*	
*
* Input params:
*	@QueryName
*	@ColumnName
*
* Output params:
*	
*
* Return code:
*
*	
************************************************************/

@QueryName VARCHAR(50) = NULL		
,@ColumnName VARCHAR(50) = NULL		
,@msg VARCHAR(100) OUTPUT
,@ReturnCode INT OUTPUT  	
AS

SET NOCOUNT ON

BEGIN TRY
	DECLARE @RelatedQueryName VARCHAR(50)
	
	-- Get all related queries affected by the MatchingColum impact
	-- and set the LinkConfiguration to 'N'
	DECLARE CursorRelatedQueries CURSOR FAST_FORWARD FOR 
		SELECT DISTINCT RelatedQueryName 
		FROM VPGridQueryLinkParameters
		WHERE QueryName = @QueryName
			AND MatchingColumn = @ColumnName
			AND UseDefault = 'N';

	OPEN CursorRelatedQueries 
	FETCH NEXT FROM CursorRelatedQueries INTO @RelatedQueryName 
	WHILE @@FETCH_STATUS = 0 
	  BEGIN 
		  	UPDATE VPGridQueryLinks 
		  	SET LinksConfigured = 'N'
		  	WHERE QueryName = @QueryName
		  		AND RelatedQueryName = @RelatedQueryName
			
		  FETCH NEXT FROM CursorRelatedQueries INTO @RelatedQueryName 
	  END 
	CLOSE CursorRelatedQueries 
	DEALLOCATE CursorRelatedQueries 

	--Reset the MatchingColumn to null
	UPDATE VPGridQueryLinkParameters
	SET MatchingColumn = null
	WHERE QueryName = @QueryName
		AND MatchingColumn = @ColumnName;

	SELECT	@msg = 'Reset VPGridQueryLinkParameters.MatchingColumn succeeded.',@ReturnCode = 0
	RETURN @ReturnCode;

END TRY
BEGIN CATCH
    SELECT	@msg = 'Reset VPGridQueryLinkParameters.MatchingColumn failed.',@ReturnCode = 1
	RETURN @ReturnCode
END CATCH;

GO
GRANT EXECUTE ON  [dbo].[vspVPResetQueryLinkParameterMatchingColumn] TO [public]
GO
