SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMInvoiceListDetail]
AS
	SELECT SMInvoiceList.SMInvoiceID, SMInvoiceList.SMCo, SMInvoiceList.Invoice, SMInvoiceList.SMSessionID, SMInvoiceList.CustGroup, SMInvoiceList.BillToARCustomer, SMInvoiceList.Customer,
		SMInvoiceList.InvoiceNumber, SMInvoiceList.InvoiceDate, SMInvoiceList.Invoiced,
		SMInvoiceList.ARCo, SMInvoiceList.BatchMonth, SMInvoiceList.VoidFlag, SMInvoiceList.DiscRate, SMInvoiceList.VoidDate,
		vSMInvoiceDetail.InvoiceDetail, vSMInvoiceDetail.IsRemoved, vSMInvoiceDetail.WorkOrder, vSMInvoiceDetail.Scope, vSMInvoiceDetail.WorkCompleted, vSMInvoiceDetail.Agreement, vSMInvoiceDetail.Revision, vSMInvoiceDetail.[Service], vSMInvoiceDetail.AgreementBilling
	FROM dbo.SMInvoiceList --Make sure to leave a space so that the view gets refreshed
		LEFT JOIN dbo.vSMInvoiceDetail ON SMInvoiceList.SMCo = vSMInvoiceDetail.SMCo AND SMInvoiceList.Invoice = vSMInvoiceDetail.Invoice
GO
GRANT SELECT ON  [dbo].[SMInvoiceListDetail] TO [public]
GRANT INSERT ON  [dbo].[SMInvoiceListDetail] TO [public]
GRANT DELETE ON  [dbo].[SMInvoiceListDetail] TO [public]
GRANT UPDATE ON  [dbo].[SMInvoiceListDetail] TO [public]
GRANT SELECT ON  [dbo].[SMInvoiceListDetail] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMInvoiceListDetail] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMInvoiceListDetail] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMInvoiceListDetail] TO [Viewpoint]
GO
