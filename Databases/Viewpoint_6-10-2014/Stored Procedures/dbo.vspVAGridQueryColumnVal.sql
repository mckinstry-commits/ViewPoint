SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE  procedure [dbo].[vspVAGridQueryColumnVal]
/******************************************************
* CREATED BY:	GP 5/23/2013 TFS-44904
* MODIFIED BY: 
*
* Usage:  Validates a VA Inquiry Column
*	
*
* Input params:
*
*	@QueryName - Query Name
*	@ColumnName - Column Name
*	
*	
*
* Output params:
*	@msg		Error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/

@QueryName VARCHAR(50), @ColumnName VARCHAR(150), @msg VARCHAR(255) OUTPUT   	
   	
AS
BEGIN

	SET NOCOUNT ON
   		
	IF @QueryName IS NULL
	BEGIN
		SET @msg = 'Missing Query Name.'
		RETURN 1
	END
	
	IF @ColumnName IS NULL
	BEGIN
		SET @msg = 'Missing Column Name.'
		RETURN 1
	END
		
	IF NOT EXISTS (SELECT 1 FROM dbo.VPGridColumns WHERE QueryName = @QueryName AND ColumnName = @ColumnName)
	BEGIN
		SET @msg = 'Invalid column name for the VA Inquiry ' + @QueryName + '.'
		RETURN 1
	END
	
	RETURN 0

END

GO
GRANT EXECUTE ON  [dbo].[vspVAGridQueryColumnVal] TO [public]
GO
