SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPDeleteGridQueryLinkParameters]
/***********************************************************
* CREATED BY:   HH 5/24/2012
* MODIFIED BY:  
*
* Usage: Delete VPGridQueryLinkParameters
*	
*
* Input params:
*	@QueryName
*	@RelatedQueryName
*
* Output params:
*	
*
* Return code:
*
*	
************************************************************/

@QueryName VARCHAR(50) = NULL		
,@RelatedQueryName VARCHAR(50) = NULL		
,@msg VARCHAR(100) OUTPUT
,@ReturnCode INT OUTPUT  	
AS

SET NOCOUNT ON

BEGIN TRY
    DELETE 
	FROM VPGridQueryLinkParameters 
	WHERE QueryName = @QueryName
		AND RelatedQueryName = @RelatedQueryName;

	SELECT	@msg = 'VPGridQueryLinkParameters deleted.',@ReturnCode = 0
	RETURN @ReturnCode;

END TRY
BEGIN CATCH
    SELECT	@msg = 'VPGridQueryLinkParameters delete failed.',@ReturnCode = -1
	RETURN @ReturnCode
END CATCH;
GO
GRANT EXECUTE ON  [dbo].[vspVPDeleteGridQueryLinkParameters] TO [public]
GO
