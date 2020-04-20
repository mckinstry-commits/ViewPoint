SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 6/12/12
-- Description:	Delete New work orders related to a specified agreement.
-- Modified:	
--			9/17/12 JB - Modified how existing new work orders are deleted, it will now delete new work orders
--						that are part of the original revision of the current revision.
-- =============================================

CREATE PROCEDURE [dbo].[vspSMAgreementDeleteNewWorkOrders]
	@SMCo AS bCompany, 
	@Agreement AS varchar(15), 
	@Revision int,
	@msg AS varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;
	
	DECLARE @Status int
	
	IF (@SMCo IS NULL)
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF (@Agreement IS NULL)
	BEGIN
		SET @msg = 'Missing SM Agreement!'
		RETURN 1
	END
	
	IF (@Revision IS NULL)
	BEGIN
		SET @msg = 'Missing SM Revision!'
		RETURN 1
	END
	
	BEGIN TRY
		-- Determine Scopes to delete
		DECLARE @WorkOrderScopesToDelete TABLE (SMWorkOrderScopeID int, SMCo bCompany, WorkOrder int, Scope int)

		INSERT INTO @WorkOrderScopesToDelete
		SELECT SMWorkOrderScope.SMWorkOrderScopeID, SMWorkOrderScope.SMCo, SMWorkOrderScope.WorkOrder, SMWorkOrderScope.Scope
		FROM dbo.SMAgreementExtended CurrentRevision
			  INNER JOIN dbo.SMAgreementExtended ON CurrentRevision.SMCo = SMAgreementExtended.SMCo AND CurrentRevision.Agreement = SMAgreementExtended.Agreement AND CurrentRevision.OriginalRevision = SMAgreementExtended.OriginalRevision
			  INNER JOIN dbo.SMWorkOrderScope ON SMAgreementExtended.SMCo = SMWorkOrderScope.SMCo AND SMAgreementExtended.Agreement = SMWorkOrderScope.Agreement AND SMAgreementExtended.Revision = SMWorkOrderScope.Revision
			  INNER JOIN dbo.SMWorkOrderStatus ON SMWorkOrderScope.SMCo = SMWorkOrderStatus.SMCo AND SMWorkOrderScope.WorkOrder = SMWorkOrderStatus.WorkOrder
		WHERE CurrentRevision.SMCo = @SMCo AND CurrentRevision.Agreement = @Agreement AND CurrentRevision.Revision = @Revision AND SMWorkOrderStatus.[Status] = 'New'

		-- Determine work orders that may need to be deleted
		DECLARE @WorkOrdersToDelete TABLE (SMWorkOrderID int, SMCo bCompany, WorkOrder int)

		INSERT INTO @WorkOrdersToDelete
		SELECT SMWorkOrder.SMWorkOrderID, SMWorkOrder.SMCo, SMWorkOrder.WorkOrder 
		FROM @WorkOrderScopesToDelete WorkScopes
			INNER JOIN dbo.SMWorkOrder ON SMWorkOrder.SMCo = WorkScopes.SMCo AND SMWorkOrder.WorkOrder = WorkScopes.WorkOrder
		GROUP BY SMWorkOrder.SMWorkOrderID, SMWorkOrder.SMCo, SMWorkOrder.WorkOrder

		-- Determine work completed to delete
		DECLARE @WorkCompletedToDelete TABLE (SMWorkCompletedID bigint, SMCo bCompany, WorkOrder int)

		INSERT INTO @WorkCompletedToDelete
		SELECT SMWorkCompleted.SMWorkCompletedID, SMWorkCompleted.SMCo, SMWorkCompleted.WorkOrder
		FROM @WorkOrderScopesToDelete WorkScopes
			INNER JOIN dbo.SMWorkCompleted ON SMWorkCompleted.SMCo = WorkScopes.SMCo AND SMWorkCompleted.WorkOrder = WorkScopes.WorkOrder AND SMWorkCompleted.Scope = WorkScopes.Scope

		-- Delete Work Completed
		DELETE FROM dbo.vSMWorkCompleted WHERE SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM @WorkCompletedToDelete)

		-- Delete Agreement Service Dates
		DELETE SMAgreementServiceDate FROM dbo.SMAgreementServiceDate
			INNER JOIN @WorkOrderScopesToDelete Scopes ON Scopes.SMCo = SMAgreementServiceDate.SMCo AND Scopes.WorkOrder = SMAgreementServiceDate.WorkOrder AND Scopes.Scope = SMAgreementServiceDate.Scope

		-- Now delete work order scopes
		DELETE FROM dbo.SMWorkOrderScope WHERE SMWorkOrderScopeID IN (SELECT SMWorkOrderScopeID FROM @WorkOrderScopesToDelete)

		-- Now delete work orders if there are no work order scopes remaining
		DELETE FROM dbo.SMWorkOrder WHERE SMWorkOrderID IN (SELECT SMWorkOrderID FROM @WorkOrdersToDelete)
			AND NOT EXISTS (SELECT 1 FROM dbo.SMWorkOrderScope WHERE SMWorkOrderScope.SMCo = SMWorkOrder.SMCo AND SMWorkOrderScope.WorkOrder = SMWorkOrder.WorkOrder)
	END TRY
	BEGIN CATCH
		SET @msg = 'Error when deleting related new work orders - ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH
		
    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementDeleteNewWorkOrders] TO [public]
GO
