SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/2/13
-- Description:	Retrieves for a given work order the billable invoice detail and the existing invoice detail
-- Modified:	9/20/13 JVH TFS-39816 Added support for partially billing flat price scopes
--              10/10/13 ECV TFS-64216 Changed joins to improve performance, added SMSessionID parameter.
-- =============================================
CREATE FUNCTION [dbo].[vfSMWorkOrderInvoiceDetail]
(
	@SMSessionID int,
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
			vSMWorkOrder.CustGroup, vSMWorkOrder.Customer,
			vSMWorkOrderScope.CustGroup BillToCustGroup, vSMWorkOrderScope.BillToARCustomer BillToCustomer,
			vSMWorkOrder.ServiceCenter, vSMWorkOrderScope.Division, vSMWorkOrder.ServiceSite,
			vSMWorkOrderScope.PriceMethod, vSMWorkOrderScope.Price
		FROM dbo.vSMWorkOrder
			INNER JOIN dbo.vSMWorkOrderScope ON vSMWorkOrder.SMCo = vSMWorkOrderScope.SMCo AND vSMWorkOrder.WorkOrder = vSMWorkOrderScope.WorkOrder
		WHERE vSMWorkOrder.SMCo = @SMCo AND vSMWorkOrder.Job IS NULL
	),
	InvoiceDetailCTE
	AS
	(
		SELECT vSMInvoiceDetail.SMCo, vSMInvoiceDetail.Invoice, vSMInvoiceDetail.InvoiceDetail,
			vSMInvoiceDetail.WorkOrder, vSMInvoiceDetail.Scope, vSMInvoiceDetail.WorkCompleted,
			vSMInvoiceSession.SMSessionID
		FROM dbo.vSMInvoiceDetail
			INNER JOIN dbo.vSMInvoice ON vSMInvoiceDetail.SMCo = vSMInvoice.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoice.Invoice
			LEFT JOIN dbo.vSMInvoiceSession ON vSMInvoice.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
	),
	WorkCompletedCTE
	AS
	(
		SELECT vSMWorkCompletedDetail.SMCo, vSMWorkCompletedDetail.WorkOrder, vSMWorkCompletedDetail.Scope,
			WorkOrderScopeCTE.CustGroup, WorkOrderScopeCTE.Customer,
			WorkOrderScopeCTE.BillToCustGroup, WorkOrderScopeCTE.BillToCustomer,
			WorkOrderScopeCTE.ServiceCenter, WorkOrderScopeCTE.Division, WorkOrderScopeCTE.ServiceSite,
			WorkOrderScopeCTE.PriceMethod, ISNULL(vSMWorkCompletedDetail.PriceTotal, 0) Price,
			vSMWorkCompletedDetail.WorkCompleted, vSMWorkCompletedDetail.[Date]
		FROM dbo.vSMWorkCompletedDetail
			INNER JOIN WorkOrderScopeCTE ON vSMWorkCompletedDetail.SMCo = WorkOrderScopeCTE.SMCo AND vSMWorkCompletedDetail.WorkOrder = WorkOrderScopeCTE.WorkOrder AND vSMWorkCompletedDetail.Scope = WorkOrderScopeCTE.Scope
		WHERE vSMWorkCompletedDetail.IsSession = 0
	),
	ScopeInvoiceSummaryCTE
	AS
	(
		SELECT WorkOrderScopeCTE.*,
			NULL WorkCompleted, NULL [Date],
			WorkOrderScopeCTE.Price - (ISNULL(InvoiceSummary.TotalBilled, 0) - ISNULL(InvoiceSummary.BillingAmount, 0)) BillableAmount,
			ISNULL(InvoiceSummary.TotalBilled, 0) TotalBilled,
			ISNULL(InvoiceSummary.BillingAmount, 0) BillingAmount
		FROM WorkOrderScopeCTE
			LEFT JOIN
			(
				SELECT InvoiceDetailCTE.SMCo, InvoiceDetailCTE.WorkOrder, InvoiceDetailCTE.Scope,
					SUM(vSMInvoiceLine.Amount) TotalBilled,
					SUM(CASE WHEN InvoiceDetailCTE.SMSessionID = @SMSessionID THEN vSMInvoiceLine.Amount END) BillingAmount
				FROM InvoiceDetailCTE
					LEFT JOIN dbo.vSMInvoiceLine ON InvoiceDetailCTE.SMCo = vSMInvoiceLine.SMCo AND InvoiceDetailCTE.Invoice = vSMInvoiceLine.Invoice AND InvoiceDetailCTE.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
				GROUP BY InvoiceDetailCTE.SMCo, InvoiceDetailCTE.WorkOrder, InvoiceDetailCTE.Scope
			) InvoiceSummary ON WorkOrderScopeCTE.SMCo = InvoiceSummary.SMCo AND WorkOrderScopeCTE.WorkOrder = InvoiceSummary.WorkOrder AND WorkOrderScopeCTE.Scope = InvoiceSummary.Scope
		WHERE 
			--Scopes should display regardless of whether work completed filter criteria is supplied or not.
			@WorkCompleted IS NULL AND @ReferenceNumber IS NULL
	)
	SELECT *
	FROM
	(
		SELECT WorkCompletedCTE.*,
			Price BillableAmount, NULL TotalBilled, NULL BillingAmount,
			InvoiceDetailCTE.Invoice, InvoiceDetailCTE.InvoiceDetail
		FROM WorkCompletedCTE
			INNER JOIN InvoiceDetailCTE ON WorkCompletedCTE.SMCo = InvoiceDetailCTE.SMCo AND WorkCompletedCTE.WorkOrder = InvoiceDetailCTE.WorkOrder AND WorkCompletedCTE.WorkCompleted = InvoiceDetailCTE.WorkCompleted AND SMSessionID = @SMSessionID

		UNION ALL

		SELECT WorkCompletedCTE.*,
			Price BillableAmount, NULL TotalBilled, NULL BillingAmount,
			NULL Invoice, NULL InvoiceDetail
		FROM WorkCompletedCTE
			INNER JOIN dbo.vSMWorkCompleted ON WorkCompletedCTE.SMCo = vSMWorkCompleted.SMCo AND WorkCompletedCTE.WorkOrder = vSMWorkCompleted.WorkOrder AND WorkCompletedCTE.WorkCompleted = vSMWorkCompleted.WorkCompleted
		WHERE NOT EXISTS(SELECT 1 FROM dbo.vSMInvoiceDetail WHERE WorkCompletedCTE.SMCo = vSMInvoiceDetail.SMCo AND WorkCompletedCTE.WorkOrder = vSMInvoiceDetail.WorkOrder AND WorkCompletedCTE.WorkCompleted = vSMInvoiceDetail.WorkCompleted) AND
				WorkCompletedCTE.PriceMethod = 'T' AND
				vSMWorkCompleted.IsDeleted = 0 AND
				vSMWorkCompleted.NonBillable <> 'Y' AND
				vSMWorkCompleted.Provisional = 0
				--The rest of the paramters are used as filter criteria
				--for work completed that is not part of an invoice yet.
				AND
				(
					@StartDate IS NULL OR
					WorkCompletedCTE.[Date] >= @StartDate
				) AND
				(
					@EndDate IS NULL OR
					WorkCompletedCTE.[Date] <= @EndDate
				) AND
				(
					@LineType IS NULL OR
					vSMWorkCompleted.[Type] = @LineType
				) AND
				(
					@ReferenceNumber IS NULL OR
					vSMWorkCompleted.ReferenceNo = @ReferenceNumber
				)

		UNION ALL

		SELECT ScopeInvoiceSummaryCTE.*,
			InvoiceDetailCTE.Invoice, InvoiceDetailCTE.InvoiceDetail
		FROM ScopeInvoiceSummaryCTE
			INNER JOIN InvoiceDetailCTE ON ScopeInvoiceSummaryCTE.SMCo = InvoiceDetailCTE.SMCo AND ScopeInvoiceSummaryCTE.WorkOrder = InvoiceDetailCTE.WorkOrder AND ScopeInvoiceSummaryCTE.Scope = InvoiceDetailCTE.Scope AND InvoiceDetailCTE.SMSessionID = @SMSessionID

		UNION ALL

		SELECT ScopeInvoiceSummaryCTE.*,
			NULL Invoice, NULL InvoiceDetail
		FROM ScopeInvoiceSummaryCTE
		WHERE PriceMethod = 'F' AND Price <> ISNULL(TotalBilled, 0) AND
			NOT EXISTS(SELECT 1 FROM InvoiceDetailCTE WHERE ScopeInvoiceSummaryCTE.SMCo = InvoiceDetailCTE.SMCo AND ScopeInvoiceSummaryCTE.WorkOrder = InvoiceDetailCTE.WorkOrder AND ScopeInvoiceSummaryCTE.Scope = InvoiceDetailCTE.Scope AND InvoiceDetailCTE.SMSessionID = @SMSessionID)

	) InvoiceableDetail
	WHERE	(
				@WorkOrder IS NULL OR
				WorkOrder = @WorkOrder
			) AND
			(
				@Scope IS NULL OR
				Scope = @Scope
			) AND
			(
				@WorkCompleted IS NULL OR
				WorkCompleted = @WorkCompleted
			) AND
			(
				InvoiceDetail IS NOT NULL OR
				(
					(
						@ServiceCenter IS NULL OR
						ServiceCenter = @ServiceCenter
					) AND
					(
						@Division IS NULL OR
						(ServiceCenter = @ServiceCenter AND Division = @Division)
					) AND
					(
						@Customer IS NULL OR
						(CustGroup = @CustGroup AND Customer = @Customer)
					) AND
					(
						@BillToCustomer IS NULL OR
						(BillToCustGroup = @CustGroup AND BillToCustomer = @BillToCustomer) OR
						(BillToCustomer IS NULL AND CustGroup = @CustGroup AND Customer = @BillToCustomer)
					) AND
					(
						@ServiceSite IS NULL OR
						ServiceSite = @ServiceSite
					)
				)
			)

)
GO
GRANT SELECT ON  [dbo].[vfSMWorkOrderInvoiceDetail] TO [public]
GO
