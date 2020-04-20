SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/9/13
-- Description:	Retrieves the invoice data displayed in the multi work order billing form.
-- =============================================
CREATE FUNCTION [dbo].[vfSMBillingInvoiceList]
(	
	@SMSessionID int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT SMInvoiceList.Invoice, NULL WorkOrder, NULL Scope, 'Bill To: ' + dbo.vfToString(bARCM.Name) + ' - $' + dbo.vfToString(SMInvoiceList.TotalBilled) [Description]
	FROM dbo.SMInvoiceList
		INNER JOIN dbo.bARCM ON SMInvoiceList.BillToCustGroup = bARCM.CustGroup AND SMInvoiceList.BillToARCustomer = bARCM.Customer
	WHERE SMInvoiceList.SMSessionID = @SMSessionID
	UNION ALL
	SELECT SMInvoiceListDetail.Invoice, vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope, 'WO: ' + dbo.vfToString(vSMWorkOrderScope.WorkOrder) + ' Scope: ' + dbo.vfToString(vSMWorkOrderScope.Scope) + ' ' + dbo.vfToString(vSMWorkOrderScope.[Description]) [Description]
	FROM dbo.SMInvoiceListDetail
		LEFT JOIN dbo.vSMWorkCompletedDetail ON SMInvoiceListDetail.SMCo = vSMWorkCompletedDetail.SMCo AND SMInvoiceListDetail.WorkOrder = vSMWorkCompletedDetail.WorkOrder AND SMInvoiceListDetail.WorkCompleted = vSMWorkCompletedDetail.WorkCompleted AND vSMWorkCompletedDetail.IsSession = 0
		INNER JOIN dbo.vSMWorkOrderScope ON SMInvoiceListDetail.SMCo = vSMWorkOrderScope.SMCo AND SMInvoiceListDetail.WorkOrder = vSMWorkOrderScope.WorkOrder AND (SMInvoiceListDetail.Scope = vSMWorkOrderScope.Scope OR vSMWorkCompletedDetail.Scope = vSMWorkOrderScope.Scope)
	WHERE SMInvoiceListDetail.SMSessionID = @SMSessionID
)
GO
GRANT SELECT ON  [dbo].[vfSMBillingInvoiceList] TO [public]
GO
