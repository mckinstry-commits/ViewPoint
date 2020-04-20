SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE  procedure [dbo].[vspVAGridQueryValidation]
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
	
	-- Validation
	SELECT QueryName
	FROM  VPGridQueries
	WHERE QueryName = @QueryName
	
	IF @@rowcount = 0
    BEGIN
		SET @msg = @QueryName + ' is not a valid VA Inquiry.'
		RETURN 1
    END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspVAGridQueryValidation] TO [public]
GO
