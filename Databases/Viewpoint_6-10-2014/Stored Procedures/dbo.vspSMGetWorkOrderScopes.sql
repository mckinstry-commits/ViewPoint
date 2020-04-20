SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspSMGetWorkOrderScopes]
	/******************************************************
	* CREATED BY:	AaronL
	* MODIFIED By:	
	*	
	*
	* Input params:
	*
	*	@WorkOrderID - Key ID of WorkOrder
	*	
	*
	* Output params:
	*	@msg		error message.
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@WorkOrderID int, @SMCo bCompany, @msg varchar(100) OUTPUT)
	
AS
BEGIN
	SET NOCOUNT ON
	
	IF @WorkOrderID IS NULL
	BEGIN
		SET @msg = 'Missing Work Order ID.'
		RETURN 1
	END
	
		IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing Company'
		RETURN 1
	END

	Select SMWorkOrderScopeID, SMCo, WorkOrder, Scope, Description, OnHold, HoldReason, FollowUpDate
	FROM SMWorkOrderScope
	WHERE WorkOrder = @WorkOrderID AND SMCo = @SMCo AND IsComplete = 'N'
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMGetWorkOrderScopes] TO [public]
GO
