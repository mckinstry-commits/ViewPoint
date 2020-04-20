SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		Eric Vaterlaus
-- Create date: 10/31/2011
-- Description:	
=============================================*/
CREATE PROCEDURE [dbo].[vspSMSessionCustomerPOVal]
	@SMSessionID bigint = NULL,
	@SMCo bCompany = NULL,
	@WorkOrder int = NULL,
	@msg AS varchar(MAX) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @rcode int, @WorkOrderList varchar(MAX), @ScopeList varchar(MAX)

	DECLARE @WorkOrders AS TABLE (WorkOrder bigint, Scope int)
	
	IF (NOT @SMSessionID IS NULL)
	BEGIN
		INSERT @WorkOrders
		SELECT DISTINCT SMWorkOrderScope.WorkOrder, SMWorkOrderScope.Scope
		FROM dbo.SMInvoiceSession
		INNER JOIN dbo.SMInvoice ON SMInvoice.SMInvoiceID = SMInvoiceSession.SMInvoiceID
		INNER JOIN dbo.SMWorkCompleted ON SMWorkCompleted.SMInvoiceID = SMInvoice.SMInvoiceID
		INNER JOIN dbo.SMWorkOrderScope ON SMWorkCompleted.SMCo = SMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = SMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope= SMWorkOrderScope.Scope
		INNER JOIN dbo.SMWorkOrder ON SMWorkOrder.SMCo = SMWorkOrderScope.SMCo AND SMWorkOrder.WorkOrder = SMWorkOrderScope.WorkOrder
		LEFT JOIN dbo.SMServiceSite ON SMServiceSite.SMCo = SMWorkOrderScope.SMCo AND SMServiceSite.ServiceSite = SMWorkOrder.ServiceSite
		LEFT JOIN dbo.SMCustomer ON SMCustomer.SMCo = SMWorkOrderScope.SMCo AND SMCustomer.CustGroup = SMWorkOrder.CustGroup AND SMCustomer.Customer = SMWorkOrder.Customer
		WHERE
			SMInvoiceSession.SMSessionID = @SMSessionID AND
			CustomerPO IS NULL
			AND ISNULL(SMServiceSite.CustomerPOSetting, SMCustomer.CustomerPOSetting) = 'R'
		ORDER BY SMWorkOrderScope.WorkOrder, SMWorkOrderScope.Scope
	END
	ELSE
	BEGIN
		INSERT @WorkOrders
		SELECT SMWorkOrderScope.WorkOrder, SMWorkOrderScope.Scope
		FROM dbo.SMWorkCompleted
		INNER JOIN dbo.SMWorkOrderScope ON SMWorkOrderScope.SMCo = SMWorkCompleted.SMCo AND SMWorkOrderScope.WorkOrder = SMWorkCompleted.WorkOrder AND SMWorkOrderScope.Scope = SMWorkCompleted.Scope
		INNER JOIN SMWorkOrder ON SMWorkOrder.SMCo = SMWorkOrderScope.SMCo AND SMWorkOrder.WorkOrder = SMWorkOrderScope.WorkOrder
		LEFT JOIN SMServiceSite ON SMServiceSite.SMCo = SMWorkOrderScope.SMCo AND SMServiceSite.ServiceSite = SMWorkOrder.ServiceSite
		LEFT JOIN SMCustomer ON SMCustomer.SMCo = SMWorkOrderScope.SMCo AND SMCustomer.CustGroup = SMWorkOrder.CustGroup AND SMCustomer.Customer = SMWorkOrder.Customer
		WHERE SMWorkCompleted.SMCo = @SMCo
			AND SMWorkCompleted.WorkOrder = @WorkOrder
			AND SMWorkCompleted.SMInvoiceID IS NULL 
			AND SMWorkCompleted.BackupSMInvoiceID IS NULL
			AND SMWorkCompleted.Provisional=0
			AND CustomerPO IS NULL
			AND ISNULL(SMServiceSite.CustomerPOSetting, SMCustomer.CustomerPOSetting) = 'R'
	END
	
	SELECT @WorkOrder = 0, @WorkOrderList = ''
NextWorkOrder:
	SELECT @WorkOrder = MIN(WorkOrder) FROM @WorkOrders WHERE WorkOrder>@WorkOrder
	IF NOT @WorkOrder IS NULL
	BEGIN
		SELECT @ScopeList = NULL
		SELECT @ScopeList = dbo.vfSMBuildString(@ScopeList, A.Scope, ', ')
		FROM (SELECT DISTINCT Scope FROM @WorkOrders WHERE WorkOrder = @WorkOrder) A 
		
		SELECT @WorkOrderList = @WorkOrderList + 'Work Order: '+CONVERT(varchar,@WorkOrder)+' Scope: ' + ISNULL(@ScopeList,'')+ CHAR(10)
	
		GOTO NextWorkOrder
	END
	
	IF (@ScopeList IS NOT NULL)
	BEGIN
		SET @msg = 'The following work order scopes require a customer PO: ' + CHAR(10) + @WorkOrderList
		RETURN 1
	END

	RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMSessionCustomerPOVal] TO [public]
GO
