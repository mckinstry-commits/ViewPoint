SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/22/13
-- Description:	Retrieves sm invoices that are related to the filterable parameters
-- =============================================
CREATE FUNCTION [dbo].[vfSMInvoicesRelated]
(	
	@SMCo bCompany, @CustGroup bGroup, @Customer bCustomer, @WorkOrder int, @ServiceSite varchar(20), @Agreement varchar(15), @AgreementRevision int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT SMCo, Invoice
	FROM dbo.vSMInvoice
	WHERE SMCo = @SMCo AND
		(
			@CustGroup IS NULL OR
			@Customer IS NULL OR
			(CustGroup = @CustGroup AND Customer = @Customer)
		) AND
		(
			@WorkOrder IS NULL OR
			EXISTS
			(
				SELECT 1
				FROM dbo.vSMInvoiceDetail
				WHERE vSMInvoice.SMCo = vSMInvoiceDetail.SMCo AND vSMInvoice.Invoice = vSMInvoiceDetail.Invoice AND @WorkOrder = vSMInvoiceDetail.WorkOrder
			)
		) AND
		(
			@ServiceSite IS NULL OR
			EXISTS
			(
				SELECT 1
				FROM dbo.vSMInvoiceDetail
					INNER JOIN dbo.vSMWorkOrder ON vSMInvoiceDetail.SMCo = vSMWorkOrder.SMCo AND vSMInvoiceDetail.WorkOrder = vSMWorkOrder.WorkOrder
				WHERE vSMInvoice.SMCo = vSMInvoiceDetail.SMCo AND vSMInvoice.Invoice = vSMInvoiceDetail.Invoice AND vSMWorkOrder.ServiceSite = @ServiceSite
			)
		) /*
		TODO: Add the agreement relations. Make sure to include the periodic agreement invoices.
		AND
		(
			@Agreement IS NULL OR
			@AgreementRevision IS NULL OR
			EXISTS
			(
				SELECT 1
				FROM dbo.vSMInvoiceDetail
					INNER JOIN dbo.vSMWorkOrderScope ON vSMInvoiceDetail.SMCo = vSMWorkOrderScope.SMCo AND vSMInvoiceDetail.WorkOrder = vSMWorkOrderScope.WorkOrder AND vSMInvoiceDetail.Scope = vSMWorkOrderScope.Scope
				WHERE vSMInvoice.SMCo = vSMInvoiceDetail.SMCo AND vSMInvoice.Invoice = vSMInvoiceDetail.Invoice AND vSMWorkOrderScope.Agreement = @Agreement AND vSMWorkOrderScope.Revision = @AgreementRevision
			) OR
			EXISTS
			(
				SELECT 1
				FROM dbo.vSMInvoiceDetail
					INNER JOIN dbo.vSMWorkCompletedDetail ON vSMInvoiceDetail.SMCo = vSMWorkCompletedDetail.SMCo AND vSMInvoiceDetail.WorkOrder = vSMWorkCompletedDetail.WorkOrder AND vSMInvoiceDetail.WorkCompleted = vSMWorkCompletedDetail.WorkCompleted AND vSMWorkCompletedDetail.IsSession = 0
				WHERE vSMInvoice.SMCo = vSMInvoiceDetail.SMCo AND vSMInvoice.Invoice = vSMInvoiceDetail.Invoice AND vSMWorkCompletedDetail.Agreement = @Agreement AND vSMWorkCompletedDetail.Revision = @AgreementRevision
			)
		)*/
)
GO
GRANT SELECT ON  [dbo].[vfSMInvoicesRelated] TO [public]
GO
