SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPDeleteGridQuery]
/***********************************************************
* CREATED BY:   HH 5/29/2012 TK-15181
* MODIFIED BY:  HH 11/13/2012 TK-18458 unassign WDJob if Query gets deleted
*
* Usage: Cascaded deletes for VPGridQueries and its related tables
*	
*
* Input params:
*	@QueryName
*
* Output params:
*	
*
* Return code:
*
*	
************************************************************/

@QueryName VARCHAR(50) = NULL		
,@msg VARCHAR(100) OUTPUT
,@ReturnCode INT OUTPUT  	
AS

SET NOCOUNT ON

BEGIN TRY
	
	DELETE 
	FROM VPGridColumns
	WHERE QueryName = @QueryName

	DELETE 
	FROM VPGridQueryParameters
	WHERE QueryName = @QueryName

	DELETE 
	FROM VPGridQueryAssociation
	WHERE QueryName = @QueryName

    DELETE 
	FROM VPGridQueryLinks
	WHERE QueryName = @QueryName
	
	DELETE 
	FROM VPGridQueryLinks
	WHERE RelatedQueryName = @QueryName
	
	DELETE 
	FROM VPGridQueryLinkParameters
	WHERE QueryName = @QueryName
	
	DELETE 
	FROM VPGridQueryLinkParameters
	WHERE RelatedQueryName = @QueryName
	
	UPDATE WDJob SET QueryName = ''
	WHERE QueryName = @QueryName AND QueryType = 1

	SELECT	@msg = '[vspVPDeleteGridQueryLink succeeded.',@ReturnCode = 0
	RETURN @ReturnCode;

END TRY
BEGIN CATCH
    SELECT	@msg = 'vspVPDeleteGridQueryLink failed.',@ReturnCode = 1
	RETURN @ReturnCode
END CATCH;
GO
GRANT EXECUTE ON  [dbo].[vspVPDeleteGridQuery] TO [public]
GO
