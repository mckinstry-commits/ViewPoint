SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPUpdateGridQueryLinkParametersByName]
/***********************************************************
* CREATED BY:   HH 5/25/2012
* MODIFIED BY:  
*
* Usage: Update VPGridQueryLinkParameters 
*	
*
* Input params:
*	@QueryName
*	@Seq
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
,@Seq INT
,@NewParameterName VARCHAR(50) = NULL		
,@msg VARCHAR(100) OUTPUT
,@ReturnCode INT OUTPUT  	
AS

SET NOCOUNT ON

BEGIN TRY

	DECLARE @OldParameterName VARCHAR(50)

	SELECT @OldParameterName = ParameterName 
	FROM VPGridQueryParameters 
	WHERE QueryName = @QueryName 
			AND Seq = @Seq;

	UPDATE VPGridQueryLinkParameters
	SET ParameterName = @NewParameterName
	WHERE RelatedQueryName = @QueryName
			AND ParameterName = @OldParameterName;
		
	SELECT	@msg = 'VPGridQueryLinkParameters updated.',@ReturnCode = 0
	RETURN @ReturnCode;

END TRY
BEGIN CATCH
    SELECT	@msg = 'VPGridQueryLinkParameters updated failed.',@ReturnCode = 1
	RETURN @ReturnCode
END CATCH; 
GO
GRANT EXECUTE ON  [dbo].[vspVPUpdateGridQueryLinkParametersByName] TO [public]
GO
