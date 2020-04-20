SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/2/13
-- Description:	Retrieves for a given work order the billable invoice detail and the existing invoice detail
-- =============================================
CREATE FUNCTION [dbo].[vfSMWorkOrderInvoiceDetail]
(
	@SMCo bCompany, @WorkOrder int, @Scope int, @WorkCompleted int,
	@ServiceCenter varchar(10), @Division varchar(10),
	@CustGroup bGroup, @Customer bCustomer, @BillToCustomer bCustomer,
	@ServiceSite varchar(20),
	@StartDate bDate, @EndDate bDate,
	@LineType tinyint,
	@ReferenceNumber varchar(60)
)
RETURNS TABLE 
AS
RETURN 
(
	WITH WorkOrderScopeCTE
	AS
	(
		SELECT vSMWorkOrderScope.SMCo, vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope,
			vSMWorkOrderScope.PriceMethod, vSMWorkOrderScope.Price,
			vSMWorkOrder.CustGroup, vSMWorkOrder.Customer,
			vSMWorkOrderScope.CustGroup BillToCustGroup, vSMWorkOrderScope.BillToARCustomer BillToCustomer,
			vSMWorkOrder.ServiceCenter, vSMWorkOrderScope.Division, vSMWorkOrder.ServiceSite
		FROM dbo.vSMWorkOrder
			INNER JOIN dbo.vSMWorkOrderScope ON vSMWorkOrder.SMCo = vSMWorkOrderScope.SMCo AND vSMWorkOrder.WorkOrder = vSMWorkOrderScope.WorkOrder
		WHERE vSMWorkOrder.SMCo = @SMCo AND vSMWorkOrder.Job IS NULL AND
			(
				@WorkOrder IS NULL OR
				vSMWorkOrder.WorkOrder = @WorkOrder
			) AND
			(
				@Scope IS NULL OR
				vSMWorkOrderScope.Scope = @Scope
			)
	),
	BillableScopeCTE
	AS
	(
		SELECT WorkOrderScopeCTE.SMCo, WorkOrderScopeCTE.WorkOrder, WorkOrderScopeCTE.Scope,
			WorkOrderScopeCTE.PriceMethod, vSMInvoiceDetail.Invoice, vSMInvoiceDetail.InvoiceDetail,
			WorkOrderScopeCTE.CustGroup, WorkOrderScopeCTE.Customer,
			WorkOrderScopeCTE.BillToCustGroup, WorkOrderScopeCTE.BillToCustomer,
			WorkOrderScopeCTE.ServiceCenter, WorkOrderScopeCTE.Division, WorkOrderScopeCTE.ServiceSite,
			WorkOrderScopeCTE.Price, vSMInvoiceLine.Amount
		FROM WorkOrderScopeCTE
			LEFT JOIN dbo.vSMInvoiceDetail ON WorkOrderScopeCTE.SMCo = vSMInvoiceDetail.SMCo AND WorkOrderScopeCTE.WorkOrder = vSMInvoiceDetail.WorkOrder AND WorkOrderScopeCTE.Scope = vSMInvoiceDetail.Scope
			LEFT JOIN dbo.vSMInvoiceLine ON vSMInvoiceDetail.SMCo = vSMInvoiceLine.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoiceLine.Invoice AND vSMInvoiceDetail.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
		WHERE vSMInvoiceDetail.InvoiceDetail IS NOT NULL OR
		(
			WorkOrderScopeCTE.PriceMethod = 'F' AND 
			--The rest of the paramters are used as filter criteria
			--for work completed that is not part of an invoice yet.
			(
				@ServiceCenter IS NULL OR
				WorkOrderScopeCTE.ServiceCenter = @ServiceCenter
			) AND
			(
				@Division IS NULL OR
				(WorkOrderScopeCTE.ServiceCenter = @ServiceCenter AND WorkOrderScopeCTE.Division = @Division)
			) AND
			(
				@Customer IS NULL OR
				(WorkOrderScopeCTE.CustGroup = @CustGroup AND WorkOrderScopeCTE.Customer = @Customer)
			) AND
			(
				@BillToCustomer IS NULL OR
				(WorkOrderScopeCTE.CustGroup = @CustGroup AND WorkOrderScopeCTE.BillToCustomer = @BillToCustomer) OR
				(WorkOrderScopeCTE.BillToCustomer IS NULL AND WorkOrderScopeCTE.CustGroup = @CustGroup AND WorkOrderScopeCTE.Customer = @BillToCustomer)
			) AND
			(
				@ServiceSite IS NULL OR
				WorkOrderScopeCTE.ServiceSite = @ServiceSite
			)
		)
	)
	SELECT WorkOrderScopeCTE.SMCo, WorkOrderScopeCTE.WorkOrder, WorkOrderScopeCTE.Scope, vSMWorkCompletedDetail.WorkCompleted,
		WorkOrderScopeCTE.PriceMethod, vSMInvoiceDetail.Invoice, vSMInvoiceDetail.InvoiceDetail, 
		WorkOrderScopeCTE.CustGroup, WorkOrderScopeCTE.Customer,
		WorkOrderScopeCTE.BillToCustGroup, WorkOrderScopeCTE.BillToCustomer,
		WorkOrderScopeCTE.ServiceCenter, WorkOrderScopeCTE.Division, WorkOrderScopeCTE.ServiceSite,
		ISNULL(CASE WHEN vSMWorkCompletedDetail.NoCharge <> 'Y' THEN vSMWorkCompletedDetail.PriceTotal END, 0) BillableAmount
	FROM WorkOrderScopeCTE
		INNER JOIN dbo.vSMWorkCompletedDetail ON WorkOrderScopeCTE.SMCo = vSMWorkCompletedDetail.SMCo AND WorkOrderScopeCTE.WorkOrder = vSMWorkCompletedDetail.WorkOrder AND vSMWorkCompletedDetail.IsSession = 0 AND WorkOrderScopeCTE.Scope = vSMWorkCompletedDetail.Scope
		INNER JOIN dbo.vSMWorkCompleted ON vSMWorkCompletedDetail.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		LEFT JOIN dbo.vSMInvoiceDetail ON vSMWorkCompleted.SMCo = vSMInvoiceDetail.SMCo AND vSMWorkCompleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWorkCompleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
	WHERE (
			@WorkCompleted IS NULL OR
			vSMWorkCompleted.WorkCompleted = @WorkCompleted
		) AND
		(
			--All work completed already tied to an invoice will be returned
			--so that it can be shown in the multi work order billing form.
			vSMInvoiceDetail.SMInvoiceDetailID IS NOT NULL OR
			(
				(
					--Only t&m work completed that hasn't been deleted
					--is not NonBillabe and is not provisional can be billed.
					WorkOrderScopeCTE.PriceMethod = 'T' AND
					vSMWorkCompleted.IsDeleted = 0 AND
					vSMWorkCompleted.NonBillable <> 'Y' AND
					vSMWorkCompleted.Provisional = 0
				)
				--The rest of the paramters are used as filter criteria
				--for work completed that is not part of an invoice yet.
				AND
				(
					@ServiceCenter IS NULL OR
					WorkOrderScopeCTE.ServiceCenter = @ServiceCenter
				) AND
				(
					@Division IS NULL OR
					(WorkOrderScopeCTE.ServiceCenter = @ServiceCenter AND WorkOrderScopeCTE.Division = @Division)
				) AND
				(
					@Customer IS NULL OR
					(WorkOrderScopeCTE.CustGroup = @CustGroup AND WorkOrderScopeCTE.Customer = @Customer)
				) AND
				(
					@BillToCustomer IS NULL OR
					(WorkOrderScopeCTE.CustGroup = @CustGroup AND WorkOrderScopeCTE.BillToCustomer = @BillToCustomer) OR
					(WorkOrderScopeCTE.BillToCustomer IS NULL AND WorkOrderScopeCTE.CustGroup = @CustGroup AND WorkOrderScopeCTE.Customer = @BillToCustomer)
				)
				AND
				(
					@StartDate IS NULL OR
					vSMWorkCompletedDetail.[Date] >= @StartDate
				) AND
				(
					@EndDate IS NULL OR
					vSMWorkCompletedDetail.[Date] <= @EndDate
				) AND
				(
					@LineType IS NULL OR
					vSMWorkCompleted.[Type] = @LineType
				) AND
				(
					@ReferenceNumber IS NULL OR
					vSMWorkCompleted.ReferenceNo = @ReferenceNumber
				) AND
				(
					@ServiceSite IS NULL OR
					WorkOrderScopeCTE.ServiceSite = @ServiceSite
				)
			)
		)
	
	UNION ALL	
	
	SELECT SMCo, WorkOrder, Scope, NULL WorkCompleted,
		PriceMethod, Invoice, InvoiceDetail,
		CustGroup, Customer,
		BillToCustGroup, BillToCustomer,
		ServiceCenter, Division, ServiceSite, Amount
	FROM BillableScopeCTE
	WHERE InvoiceDetail IS NOT NULL
	
	UNION ALL
	
	SELECT SMCo, WorkOrder, Scope, NULL WorkCompleted,
		PriceMethod, NULL Invoice, NULL InvoiceDetail,
		CustGroup, Customer,
		BillToCustGroup, BillToCustomer,
		ServiceCenter, Division, ServiceSite, Price - ISNULL(SUM(Amount), 0)
	FROM BillableScopeCTE
	GROUP BY SMCo, WorkOrder, Scope,
		PriceMethod,
		CustGroup, Customer,
		BillToCustGroup, BillToCustomer,
		ServiceCenter, Division, ServiceSite, Price
	HAVING Price <> ISNULL(SUM(Amount), 0)
)
GO
GRANT SELECT ON  [dbo].[vfSMWorkOrderInvoiceDetail] TO [public]
GO
