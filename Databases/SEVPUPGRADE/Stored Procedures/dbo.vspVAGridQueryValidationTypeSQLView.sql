SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE  procedure [dbo].[vspVAGridQueryValidationTypeSQLView]
/******************************************************
* CREATED BY:  HH 
* MODIFIED By: 
*
* Usage:  Validates a VA Inquiry
*	
*
* Input params:
*
*	@QueryName - Query Name
*	
*	
*
* Output params:
*	@msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/

@QueryName varchar(50), @msg varchar(100) OUTPUT   	
   	
AS
BEGIN
	SET NOCOUNT ON
   	
	IF @QueryName IS NULL
	BEGIN
		SET @msg = 'Missing Query.'
		RETURN 1
	END
	
	-- Validation on QueryName
	SELECT QueryName
	FROM  VPGridQueries
	WHERE QueryName = @QueryName
	
	IF @@rowcount = 0
    BEGIN
		SET @msg = @QueryName + ' is not a valid VA Inquiry.'
		RETURN 1
    END
    
    -- Validation on QueryType
	SELECT QueryName
	FROM  VPGridQueries
	WHERE QueryName = @QueryName
		AND QueryType in (0,1)
	
	IF @@rowcount = 0
    BEGIN
		SET @msg = @QueryName + ' is not a valid VA Inquiry of type SQL or View.'
		RETURN 1
    END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspVAGridQueryValidationTypeSQLView] TO [public]
GO
