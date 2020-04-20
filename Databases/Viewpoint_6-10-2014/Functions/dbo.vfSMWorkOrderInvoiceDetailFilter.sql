SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/2/13
-- Description:	Retrieves for a given work order the billable invoice detail and the existing invoice detail
-- Modifications: 10/21/13 EricV TFS-64707 Added SMSessionID parameter to query of vfSMWorkOrderInvoiceDetail
-- =============================================
CREATE FUNCTION [dbo].[vfSMWorkOrderInvoiceDetailFilter]
(	
	@SMCo bCompany,
	@SMSessionID int,
	@ServiceCenter varchar(10), @Division varchar(10),
	@CustGroup bGroup, @Customer bCustomer, @BillToCustomer bCustomer,
	@ServiceSite varchar(20),
	@StartDate bDate, @EndDate bDate,
	@LineType tinyint,
	@ReferenceNumber varchar(60),
	@WorkOrder int, @Scope int
)
RETURNS TABLE
AS
RETURN 
(
	WITH FilteredInvoicableDetailCTE AS
	(
		SELECT
			--Work order scopes either don't have any invoice detail as part of an invoice
			-- or some invoice detail that has been added to an invoice
			--or all of its detail has been added to an invoice
			CASE COUNT(vfSMWorkOrderInvoiceDetail.InvoiceDetail) 
				WHEN 0 THEN 'N'
				WHEN COUNT(1) THEN 'Y'
				ELSE NULL
			END Bill,
			vfSMWorkOrderInvoiceDetail.SMCo, vfSMWorkOrderInvoiceDetail.WorkOrder, vfSMWorkOrderInvoiceDetail.Scope, vfSMWorkOrderInvoiceDetail.PriceMethod,
			vfSMWorkOrderInvoiceDetail.CustGroup, vfSMWorkOrderInvoiceDetail.Customer, vfSMWorkOrderInvoiceDetail.BillToCustomer,
			vfSMWorkOrderInvoiceDetail.ServiceSite, vfSMWorkOrderInvoiceDetail.ServiceCenter, vfSMWorkOrderInvoiceDetail.Division,
			ISNULL(SUM(ISNULL(SMWorkCompleted.ActualCost, SMWorkCompleted.ProjCost)), 0) CostAmount,
			ISNULL(SUM(vfSMWorkOrderInvoiceDetail.BillableAmount), 0) BillableAmount,
			WorkCompletedBreakDown.*
		FROM dbo.vfSMWorkOrderInvoiceDetail(@SMSessionID, @SMCo, @WorkOrder, @Scope, NULL, @ServiceCenter, @Division, @CustGroup, @Customer, @BillToCustomer, @ServiceSite, @StartDate, @EndDate, @LineType, @ReferenceNumber)
			LEFT JOIN dbo.vSMInvoice ON vfSMWorkOrderInvoiceDetail.SMCo = vSMInvoice.SMCo AND vfSMWorkOrderInvoiceDetail.Invoice = vSMInvoice.Invoice
			LEFT JOIN dbo.vSMInvoiceSession ON vSMInvoice.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
			LEFT JOIN dbo.SMWorkCompleted ON vfSMWorkOrderInvoiceDetail.SMCo = SMWorkCompleted.SMCo AND vfSMWorkOrderInvoiceDetail.WorkOrder = SMWorkCompleted.WorkOrder AND vfSMWorkOrderInvoiceDetail.WorkCompleted = SMWorkCompleted.WorkCompleted
			OUTER APPLY
			(
				--When the work order and scope aren't supplied then the results should be summarized and used for to display the work order scopes that are billable
				--If the work order and scope are supplied then the work completed detail should be returned.
				SELECT vfSMWorkOrderInvoiceDetail.WorkCompleted, SMWorkCompleted.[Type], SMWorkCompleted.[Date], SMWorkCompleted.ReferenceNo, SMWorkCompleted.[Description],
					SMWorkCompleted.ProjCost, SMWorkCompleted.ActualCost, SMWorkCompleted.PriceTotal
				WHERE @WorkOrder IS NOT NULL AND @Scope IS NOT NULL
			) WorkCompletedBreakDown
		WHERE vSMInvoiceSession.SMSessionID = @SMSessionID OR vfSMWorkOrderInvoiceDetail.InvoiceDetail IS NULL
		GROUP BY
			vfSMWorkOrderInvoiceDetail.SMCo, vfSMWorkOrderInvoiceDetail.WorkOrder, vfSMWorkOrderInvoiceDetail.Scope, vfSMWorkOrderInvoiceDetail.PriceMethod,
			vfSMWorkOrderInvoiceDetail.CustGroup, vfSMWorkOrderInvoiceDetail.Customer, vfSMWorkOrderInvoiceDetail.BillToCustomer,
			vfSMWorkOrderInvoiceDetail.ServiceSite, vfSMWorkOrderInvoiceDetail.ServiceCenter, vfSMWorkOrderInvoiceDetail.Division,
			WorkCompletedBreakDown.WorkCompleted, WorkCompletedBreakDown.[Type], WorkCompletedBreakDown.[Date], WorkCompletedBreakDown.ReferenceNo, WorkCompletedBreakDown.[Description],
			WorkCompletedBreakDown.ProjCost, WorkCompletedBreakDown.ActualCost, WorkCompletedBreakDown.PriceTotal
	)
	SELECT FilteredInvoicableDetailCTE.*,
		vSMWorkOrder.SMWorkOrderID, vSMWorkOrderScope.SMWorkOrderScopeID,
		CalculateProfit.Profit, CAST(CASE WHEN FilteredInvoicableDetailCTE.CostAmount = 0 THEN 0 ELSE CalculateProfit.Profit / FilteredInvoicableDetailCTE.CostAmount END AS numeric(12,2)) Margin,
		vSMWorkOrder.[Description] WorkOrderDescription, vSMWorkOrderScope.[Description] ScopeDescription, bARCM.Name BillToCustomerName,
		vSMServiceSite.[Description] ServiceSiteDescription, vSMServiceCenter.[Description] ServiceCenterDescription, vSMDivision.[Description] DivisionDescription
	FROM FilteredInvoicableDetailCTE
		CROSS APPLY
		(
			SELECT (BillableAmount - CostAmount) Profit
		) CalculateProfit
		LEFT JOIN dbo.vSMWorkOrder ON FilteredInvoicableDetailCTE.SMCo = vSMWorkOrder.SMCo AND FilteredInvoicableDetailCTE.WorkOrder = vSMWorkOrder.WorkOrder
		LEFT JOIN dbo.vSMWorkOrderScope ON FilteredInvoicableDetailCTE.SMCo = vSMWorkOrderScope.SMCo AND FilteredInvoicableDetailCTE.WorkOrder = vSMWorkOrderScope.WorkOrder AND FilteredInvoicableDetailCTE.Scope = vSMWorkOrderScope.Scope
		LEFT JOIN dbo.bARCM ON FilteredInvoicableDetailCTE.CustGroup = bARCM.CustGroup AND FilteredInvoicableDetailCTE.BillToCustomer = bARCM.Customer
		LEFT JOIN dbo.vSMServiceSite ON FilteredInvoicableDetailCTE.SMCo = vSMServiceSite.SMCo AND FilteredInvoicableDetailCTE.ServiceSite = vSMServiceSite.ServiceSite
		LEFT JOIN dbo.vSMServiceCenter ON FilteredInvoicableDetailCTE.SMCo = vSMServiceCenter.SMCo AND FilteredInvoicableDetailCTE.ServiceCenter = vSMServiceCenter.ServiceCenter
		LEFT JOIN dbo.vSMDivision ON FilteredInvoicableDetailCTE.SMCo = vSMDivision.SMCo AND FilteredInvoicableDetailCTE.ServiceCenter = vSMDivision.ServiceCenter AND FilteredInvoicableDetailCTE.Division = vSMDivision.Division
)
GO
GRANT SELECT ON  [dbo].[vfSMWorkOrderInvoiceDetailFilter] TO [public]
GO
