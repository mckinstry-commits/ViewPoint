SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/27/12
-- Description:	Builds the reversing and correcting vSMDetailTransactions for a given detail id
-- =============================================
CREATE FUNCTION [dbo].[vfSMWorkCompletedDetailTransaction]
(
	@HQDetailID bigint
)
RETURNS @SMDetailTransaction TABLE 
(
	IsReversing bit, SMWorkCompletedID bigint, SMWorkOrderScopeID int, SMWorkOrderID int, LineType tinyint, TransactionType char(1), GLCo bCompany, GLAccount bGLAcct, Amount bDollar
)
AS
BEGIN
	/*Return the negative amount for all previous transaction, but exclude the records if they have already been reversed. (Have a sum of 0)*/
	WITH ReversingTransactions
	AS
	(
		SELECT SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, GLCo, GLAccount, -SUM(Amount) Amount
		FROM dbo.vSMDetailTransaction
		WHERE HQDetailID = @HQDetailID AND Posted = 1
		GROUP BY SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, GLCo, GLAccount
	)
	INSERT @SMDetailTransaction
	SELECT 1 IsReversing, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, GLCo, GLAccount, Amount
	FROM ReversingTransactions
	WHERE Amount <> 0
	
	/*Build the cost work completed transaction*/
	INSERT @SMDetailTransaction
	SELECT 0 IsReversing, SMWorkCompleted.SMWorkCompletedID, vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID, SMWorkCompleted.[Type], 'C' TransactionType, vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.CurrentCostAccount, ISNULL(SMWorkCompleted.ActualCost, 0)
	FROM dbo.SMWorkCompleted --Use the SMWorkCompleted view to filter out the deleted records
		INNER JOIN dbo.vSMWorkOrderScope ON SMWorkCompleted.SMCo = vSMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = vSMWorkOrderScope.Scope
		INNER JOIN dbo.vSMWorkOrder ON SMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
		CROSS APPLY dbo.vfSMGetWorkCompletedGL(SMWorkCompleted.SMWorkCompletedID)
	WHERE CostDetailID = @HQDetailID
	
	/*Build the job revenue work completed transaction*/
	INSERT @SMDetailTransaction
	SELECT 0 IsReversing, SMWorkCompleted.SMWorkCompletedID, vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID, SMWorkCompleted.[Type], 'R' TransactionType, vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.CurrentRevenueAccount, -ISNULL(SMWorkCompleted.PriceTotal, 0)
	FROM dbo.SMWorkCompleted --Use the SMWorkCompleted view to filter out the deleted records
		INNER JOIN dbo.vSMWorkOrderScope ON SMWorkCompleted.SMCo = vSMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = vSMWorkOrderScope.Scope
		INNER JOIN dbo.vSMWorkOrder ON SMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
		CROSS APPLY dbo.vfSMGetWorkCompletedGL(SMWorkCompleted.SMWorkCompletedID)
	WHERE SMWorkCompleted.CostDetailID = @HQDetailID AND vSMWorkOrder.Job IS NOT NULL

	RETURN
END
GO
GRANT SELECT ON  [dbo].[vfSMWorkCompletedDetailTransaction] TO [public]
GO
