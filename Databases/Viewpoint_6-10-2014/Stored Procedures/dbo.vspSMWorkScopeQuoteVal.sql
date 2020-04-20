SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspSMWorkScopeQuoteVal]
	/******************************************************
	* CREATED BY:	ScottAlvey 
	* MODIFIED By:	
	*
	* Usage:  Validates a Work Scope for Work Order Quote Scopes
	*	
	*
	* Input params:
	*
	*	@SMCo - SM Company
	*	@WorkScope - Work Scopes
	*	@MustExist - Flag to control validation behavior
	*	
	*
	* Output params:
	*
	*	@WorkScopeSummary - Summary description of Work Scope.
	*	@msg		Work Scope description or error message.
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
	   
   	(
		@SMCo bCompany
		, @WorkScope varchar(20)
		, @MustExist bYN
		, @WorkScopeSummary varchar(MAX) OUTPUT
		, @msg varchar(100) OUTPUT)
	
AS
BEGIN
	SET NOCOUNT ON
	
	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company.'
		RETURN 1
	END
	
	IF @WorkScope IS NULL
	BEGIN
		SET @msg = 'Missing Work Scope.'
		RETURN 1
	END
	
	IF @MustExist = 'Y'
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM SMWorkScope WHERE SMCo = @SMCo AND WorkScope = @WorkScope)
		BEGIN
			SELECT @msg = 'Work Scope does not exist in SM Work Scopes.'
			RETURN 1
		END
	END
	
	SELECT @msg = [Description]
		, @WorkScopeSummary = WorkScopeSummary
	FROM dbo.SMWorkScope
	WHERE SMCo = @SMCo 
		AND WorkScope = @WorkScope
			
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkScopeQuoteVal] TO [public]
GO
