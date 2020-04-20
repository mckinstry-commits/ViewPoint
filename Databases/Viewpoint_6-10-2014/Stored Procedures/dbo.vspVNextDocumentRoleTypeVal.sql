SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE  procedure [dbo].[vspVNextDocumentRoleTypeVal]
/******************************************************
* CREATED BY:	GP 5/23/2013 TFS-44904
* MODIFIED BY: 
*
* Usage:  Validates a Document Role Type
*	
*
* Input params:
*
*	@DocumentRoleName - Document Role Name
*	
*	
*
* Output params:
*	@msg		Error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/

@DocumentRoleName VARCHAR(50), @msg VARCHAR(255) OUTPUT   	
   	
AS
BEGIN

	SET NOCOUNT ON
   		
	IF @DocumentRoleName IS NULL
	BEGIN
		SET @msg = 'Missing Document Role Name.'
		RETURN 1
	END

		
	IF NOT EXISTS (SELECT 1 FROM Document.DocumentRoleType WHERE RoleName = @DocumentRoleName)
	BEGIN
		SET @msg = 'Invalid Document Role Name.'
		RETURN 1
	END
	
	RETURN 0

END

GO
GRANT EXECUTE ON  [dbo].[vspVNextDocumentRoleTypeVal] TO [public]
GO
