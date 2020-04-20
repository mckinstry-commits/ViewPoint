SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

	CREATE  procedure [dbo].[vspPRAUEmployerFBTCategoryVal]
	/******************************************************
	* CREATED BY:	MV 01/06/11
	* MODIFIED By: 
	*
	* Usage:	Validates FBT Category and returns description.  
	*			Called from PRAUEmployerFBTItems.
	*
	* Input params:
	*
	*	@Category - ATO Category (FBT Category)	
	*	
	*
	* Output params:
	*	@Msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@FBTCategory varchar(4),@Msg varchar(100) output)
	AS
	SET NOCOUNT ON
	DECLARE @rcode INT

	SELECT @rcode = 0
	
	IF @FBTCategory IS NULL
	BEGIN
		SELECT @Msg = 'Missing Category.', @rcode = 1
		GOTO  vspexit
	END

	IF EXISTS
		(
			SELECT 1 
			FROM dbo.PRAUEmployerFBTCategories 
			WHERE Category=@FBTCategory
		)
	BEGIN
		SELECT @Msg = [Description]
		FROM dbo.PRAUEmployerFBTCategories
		WHERE Category=@FBTCategory
	END
	ELSE
	BEGIN
		SELECT @Msg = 'Invalid Category.', @rcode = 1
	END
	
	 
	vspexit:
	RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPRAUEmployerFBTCategoryVal] TO [public]
GO
