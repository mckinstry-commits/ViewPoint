SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspSMWorkScopeVal]
	/******************************************************
	* CREATED BY:	MarkH 
	* MODIFIED By:	1/11/2012 - TK-11679 - Modified Scope Val proc to return the Phase
	*				JG	01/25/2012 - AT-06505 - Returning a NULL Phase when not on a Job Work Order.
	*
	* Usage:  Validates a Work Scope
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
	*	@WorkScopeSummary - Summary description of Work Order.
	*	@msg		Work Scope description or error message.
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
	
	/*************************************************************
	-- Testing harness
	BEGIN TRANSACTION
	DECLARE @SMCo bCompany, @WorkScope varchar(20), @MustExist bYN, @WorkScopeSummary varchar(MAX), @msg varchar(100), @rcode int

	INSERT SMWorkScope (SMCo, WorkScope, Description, WorkScopeSummary, Notes) VALUES (0, 'TEST1.1', 'Testing Step 1.1', 'Test that the storedprocedure works.', 'Test Notes')

	SELECT 'Testing existing entry with MustExist=Y' Test	
	SELECT @SMCo=0, @WorkScope='TEST1.1', @MustExist='Y'
	EXECUTE @rcode = vspSMWorkScopeVal @SMCo, @WorkScope, @MustExist, @WorkScopeSummary OUTPUT, @msg OUTPUT
	SELECT CASE WHEN @rcode=0 THEN 'PASSED' ELSE 'FAILED' END AS Results, @rcode 'Return code', @WorkScopeSummary [WorkScopeSummary], @msg [msg]
	
	SELECT 'Testing missing entry with MustExist=Y' Test	
	SELECT @SMCo=0, @WorkScope='TEST1.2', @MustExist='Y'
	EXECUTE @rcode = vspSMWorkScopeVal @SMCo, @WorkScope, @MustExist, @WorkScopeSummary OUTPUT, @msg OUTPUT
	SELECT CASE WHEN @rcode=1 THEN 'PASSED' ELSE 'FAILED' END AS Results, @rcode 'Return code', @WorkScopeSummary [WorkScopeSummary], @msg [msg]
	
	SELECT 'Testing missing entry with MustExist=N' Test	
	SELECT @SMCo=0, @WorkScope='TEST1.2', @MustExist='N'
	EXECUTE @rcode = vspSMWorkScopeVal @SMCo, @WorkScope, @MustExist, @WorkScopeSummary OUTPUT, @msg OUTPUT
	SELECT CASE WHEN @rcode=0 THEN 'PASSED' ELSE 'FAILED' END AS Results, @rcode 'Return code', @WorkScopeSummary [WorkScopeSummary], @msg [msg]
	
	ROLLBACK TRANSACTION
	***************************************************************/
	

   
   	(@SMCo bCompany, @WorkScope varchar(20), @MustExist bYN, @SMWorkOrder INT = NULL, @WorkScopeSummary varchar(MAX) OUTPUT, @PriorityName varchar(10) OUTPUT
   	, @Phase VARCHAR(20) OUTPUT, @msg varchar(100) OUTPUT)
	
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
		, @PriorityName = PriorityName
		, @Phase = Phase
	FROM dbo.SMWorkScope
	WHERE SMCo = @SMCo 
		AND WorkScope = @WorkScope
	
	IF @SMWorkOrder IS NULL OR EXISTS (	SELECT 1 
										FROM dbo.SMWorkOrder 
										WHERE SMCo = @SMCo 
											AND WorkOrder = @SMWorkOrder 
											AND Job IS NULL)
	BEGIN
		SET @Phase = NULL
	END	
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkScopeVal] TO [public]
GO
