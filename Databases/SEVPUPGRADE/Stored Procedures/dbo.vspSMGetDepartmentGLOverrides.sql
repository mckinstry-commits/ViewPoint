SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

	CREATE  procedure [dbo].[vspSMGetDepartmentGLOverrides]
	/******************************************************
	* CREATED BY: 
	* MODIFIED By: Mark H 08/09/11 - TK-07482 Removed commented out code.
	*
	* Usage:
	*	
	*
	* Input params:
	*	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@SMCo bCompany, @Department varchar(10), @LineType tinyint, @CallType varchar(10), @MiscType varchar(10), 
   	@DefaultCostAcct bGLAcct output, @DefaultRevAcct bGLAcct output, @DefaultWIPAcct bGLAcct output)
	
	as 
	set nocount on
	
	--If any of the following values are null assume there are no overiddes.
	IF (@SMCo is null or @Department is null or @LineType is null or @CallType is null)
	BEGIN
		RETURN 1
	END
	
	SELECT @DefaultCostAcct = CostGLAcct, @DefaultRevAcct = RevenueGLAcct, @DefaultWIPAcct = CostWIPGLAcct
	FROM SMDepartmentOverrides WHERE SMCo = @SMCo and Department = @Department and LineType = @LineType
	AND CallType = @CallType
	
	IF @@rowcount = 0 
	BEGIN
		RETURN 1
	END
	ELSE
	BEGIN
		RETURN 0
	END
	



GO
GRANT EXECUTE ON  [dbo].[vspSMGetDepartmentGLOverrides] TO [public]
GO
