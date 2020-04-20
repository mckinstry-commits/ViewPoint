SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPDeleteGridQueryLinkParametersByName]
/***********************************************************
* CREATED BY:   HH 5/25/2012
* MODIFIED BY:  
*
* Usage: Delete VPGridQueryLinkParameters by RelatedQueryName and ParameterName
*	
*
* Input params:
*	@QueryName
*	@ParameterName
*
* Output params:
*	
*
* Return code:
*
*	
************************************************************/

@QueryName VARCHAR(50) = NULL		
,@ParameterName VARCHAR(50) = NULL		
,@msg VARCHAR(100) OUTPUT
,@ReturnCode INT OUTPUT  	
AS

SET NOCOUNT ON

BEGIN TRY
	
	DECLARE @CursorQueryName varchar(50)
	
	DELETE 
	FROM VPGridQueryLinkParameters 
	WHERE ParameterName = @ParameterName
		AND RelatedQueryName = @QueryName;
	
	
	-- Cursor for affected Queries
	-- and execute vspVPGridQueryLinksConfigured to update LinksConfiguredFlag
	DECLARE CursorQueries CURSOR FAST_FORWARD FOR 
		SELECT DISTINCT QueryName
		FROM VPGridQueryLinks
		WHERE RelatedQueryName = @QueryName;

	OPEN CursorQueries 
	FETCH NEXT FROM CursorQueries INTO @CursorQueryName 
	WHILE @@FETCH_STATUS = 0 
	  BEGIN 
		  	EXEC vspVPGridQueryLinksConfigured @CursorQueryName, @QueryName, '', 0
			
			FETCH NEXT FROM CursorQueries INTO @CursorQueryName 
	  END 
	CLOSE CursorQueries 
	DEALLOCATE CursorQueries 

	SELECT	@msg = 'VPGridQueryLinkParameters deleted.',@ReturnCode = 0
	RETURN @ReturnCode;

END TRY
BEGIN CATCH
    SELECT	@msg = 'VPGridQueryLinkParameters delete failed.',@ReturnCode = -1
	RETURN @ReturnCode
END CATCH; 
GO
GRANT EXECUTE ON  [dbo].[vspVPDeleteGridQueryLinkParametersByName] TO [public]
GO
