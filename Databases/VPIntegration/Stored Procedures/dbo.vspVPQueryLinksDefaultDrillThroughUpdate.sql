SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPQueryLinksDefaultDrillThroughUpdate]
/***********************************************************
* CREATED BY:   HH 6/12/2012
* MODIFIED BY:  
*
* Usage: Update DefaultDrillThrough for VPGridQueryLinks if none is set
*	
*
* Input params:
*	@QueryName
*
* Output params:
*	@msg
*	@ReturnCode
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
		
	DECLARE @ddtcount int		
	DECLARE @KeyID bigint

	SELECT @ddtcount = count(*)
	FROM VPGridQueryLinks 
	WHERE QueryName = @QueryName
			AND DefaultDrillThrough = 'Y'

	IF @ddtcount = 0
	BEGIN
		SELECT TOP 1 @KeyID = KeyID
		FROM VPGridQueryLinks 
		WHERE QueryName = @QueryName
		ORDER BY DisplaySeq, KeyID
		
		IF @KeyID IS NOT NULL
		BEGIN
			UPDATE VPGridQueryLinks 
			SET DefaultDrillThrough = 'Y'
			WHERE KeyID = @KeyID
		END
	END
	
	SELECT	@msg = 'DefaultDrillThrough set.',@ReturnCode = 0
	RETURN @ReturnCode;

END TRY
BEGIN CATCH
    SELECT	@msg = 'vspVPQueryLinksDefaultDrillThroughUpdate failed',@ReturnCode = 1
	RETURN @ReturnCode
END CATCH; 
GO
GRANT EXECUTE ON  [dbo].[vspVPQueryLinksDefaultDrillThroughUpdate] TO [public]
GO
