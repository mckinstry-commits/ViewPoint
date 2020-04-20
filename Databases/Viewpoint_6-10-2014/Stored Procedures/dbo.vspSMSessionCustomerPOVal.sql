SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		Eric Vaterlaus
-- Create date: 10/31/2011
-- Description:	
-- Modified:	4/17/13  JVH TFS-44860 Modified for invoice detail changes
--				4/29/13  JVH TFS-44860 Updated check to see if work completed is part of an invoice
=============================================*/
CREATE PROCEDURE [dbo].[vspSMSessionCustomerPOVal]
	@SMSessionID bigint = NULL,
	@SMCo bCompany = NULL,
	@WorkOrder int = NULL,
	@msg AS varchar(MAX) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @rcode int, @CurrentWorkOrder int, @WorkOrderList varchar(MAX)

	DECLARE @WorkOrders AS TABLE (WorkOrder int, Scope int)
	
	IF @SMSessionID IS NULL
	BEGIN
		INSERT @WorkOrders
		SELECT vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope
		FROM dbo.vSMWorkCompleted
			INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompleted.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID AND vSMWorkCompletedDetail.IsSession = 0
			INNER JOIN dbo.vSMWorkOrderScope ON vSMWorkCompletedDetail.SMCo = vSMWorkOrderScope.SMCo AND vSMWorkCompletedDetail.WorkOrder = vSMWorkOrderScope.WorkOrder AND vSMWorkCompletedDetail.Scope = vSMWorkOrderScope.Scope
			INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
			LEFT JOIN dbo.vSMServiceSite ON vSMWorkOrder.SMCo = vSMServiceSite.SMCo AND vSMWorkOrder.ServiceSite = vSMServiceSite.ServiceSite
			LEFT JOIN dbo.vSMCustomer ON vSMWorkOrder.SMCo = vSMCustomer.SMCo AND vSMWorkOrder.CustGroup = vSMCustomer.CustGroup AND vSMWorkOrder.Customer = vSMCustomer.Customer
			LEFT JOIN dbo.vSMInvoiceDetail ON vSMWorkCompleted.SMCo = vSMInvoiceDetail.SMCo AND vSMWorkCompleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWorkCompleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
		WHERE vSMWorkCompleted.SMCo = @SMCo
			AND vSMWorkCompleted.WorkOrder = @WorkOrder
			AND vSMInvoiceDetail.SMInvoiceDetailID IS NULL
			AND vSMWorkCompleted.Provisional = 0
			AND vSMWorkOrderScope.CustomerPO IS NULL
			AND ISNULL(vSMServiceSite.CustomerPOSetting, vSMCustomer.CustomerPOSetting) = 'R'
	END
	ELSE
	BEGIN
		INSERT @WorkOrders
		SELECT DISTINCT vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope
		FROM dbo.vSMInvoiceSession
			INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
			INNER JOIN dbo.vSMInvoiceDetail ON vSMInvoice.SMCo = vSMInvoiceDetail.SMCo AND vSMInvoice.Invoice = vSMInvoiceDetail.Invoice
			INNER JOIN dbo.vSMWorkCompletedDetail ON vSMInvoiceDetail.SMCo = vSMWorkCompletedDetail.SMCo AND vSMInvoiceDetail.WorkOrder = vSMWorkCompletedDetail.WorkOrder AND vSMInvoiceDetail.WorkCompleted = vSMWorkCompletedDetail.WorkCompleted
			INNER JOIN dbo.vSMWorkOrderScope ON vSMWorkCompletedDetail.SMCo = vSMWorkOrderScope.SMCo AND vSMWorkCompletedDetail.WorkOrder = vSMWorkOrderScope.WorkOrder AND vSMWorkCompletedDetail.Scope = vSMWorkOrderScope.Scope
			INNER JOIN dbo.vSMWorkOrder ON vSMWorkOrderScope.SMCo = vSMWorkOrder.SMCo AND vSMWorkOrderScope.WorkOrder = vSMWorkOrder.WorkOrder
			LEFT JOIN dbo.vSMServiceSite ON vSMWorkOrder.SMCo = vSMServiceSite.SMCo AND vSMWorkOrder.ServiceSite = vSMServiceSite.ServiceSite
			LEFT JOIN dbo.vSMCustomer ON vSMWorkOrder.SMCo = vSMCustomer.SMCo AND vSMWorkOrder.CustGroup = vSMCustomer.CustGroup AND vSMWorkOrder.Customer = vSMCustomer.Customer
		WHERE
			vSMInvoiceSession.SMSessionID = @SMSessionID AND
			vSMWorkOrderScope.CustomerPO IS NULL
			AND ISNULL(vSMServiceSite.CustomerPOSetting, vSMCustomer.CustomerPOSetting) = 'R'
		ORDER BY vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope
	END

	SELECT @WorkOrderList = dbo.vfSMBuildString(@WorkOrderList, dbo.vfToString(CASE WHEN dbo.vfIsEqual(@CurrentWorkOrder, WorkOrder) = 0 THEN 'Work Order: ' + dbo.vfToString(WorkOrder) + ' Scope: ' END) + dbo.vfToString(Scope), CASE WHEN dbo.vfIsEqual(@CurrentWorkOrder, WorkOrder) = 0 THEN dbo.vfLineBreak() ELSE ', ' END), @CurrentWorkOrder = WorkOrder
	FROM @WorkOrders

	IF (@CurrentWorkOrder IS NOT NULL)
	BEGIN
		SET @msg = 'The following work order scopes require a customer PO: ' + dbo.vfLineBreak() + @WorkOrderList
		RETURN 1
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMSessionCustomerPOVal] TO [public]
GO
