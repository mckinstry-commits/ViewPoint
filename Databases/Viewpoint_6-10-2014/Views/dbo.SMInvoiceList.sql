SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMInvoiceList]
AS
	SELECT SMInvoice.*, SMInvoice.CustGroup BillToCustGroup,
		ISNULL(InvoiceTotals.TotalBilled, 0) TotalBilled, 
		ISNULL(InvoiceTotals.TotalTaxed, 0) TotalTaxed,
		ISNULL(InvoiceTotals.TotalBilled, 0) + ISNULL(InvoiceTotals.TotalTaxed, 0) TotalAmount,
		SMSession.Prebilling, SMInvoiceSession.SMSessionID, SMInvoiceSession.VoidFlag,
		--Currently voided invoices are determined by checking to see if there is any detail related to the invoice
		--In the future it may be advantageous to explicitly indicate that the invoice has been voided
		CASE WHEN SMInvoice.Invoiced = 1 AND SMInvoice.VoidDate IS NOT NULL THEN 'Voided' WHEN SMInvoice.Invoiced = 1 THEN 'Invoiced' WHEN SMSession.Prebilling = 1 THEN 'Prebilling' ELSE 'Pending Invoice' END InvoiceStatus
	FROM dbo.SMInvoice
		OUTER APPLY (
			SELECT
				SUM(CASE WHEN SMInvoiceLine.NoCharge = 'N' THEN SMInvoiceLine.Amount ELSE 0 END) TotalBilled, --0 AS TotalTaxed
				SUM(CASE WHEN SMInvoiceLine.NoCharge = 'N' THEN SMInvoiceLine.TaxAmount ELSE 0 END) TotalTaxed
			FROM dbo.SMInvoiceDetail
				INNER JOIN dbo.SMInvoiceLine ON SMInvoiceDetail.SMCo = SMInvoiceLine.SMCo AND SMInvoiceDetail.Invoice = SMInvoiceLine.Invoice AND SMInvoiceDetail.InvoiceDetail = SMInvoiceLine.InvoiceDetail
			WHERE SMInvoice.SMCo = SMInvoiceDetail.SMCo AND SMInvoice.Invoice = SMInvoiceDetail.Invoice AND SMInvoiceDetail.IsRemoved = 0
			HAVING SMInvoice.InvoiceType = 'W' --HAVING is required here because sums will always return at least 1 row unless using a having
			UNION ALL
			SELECT BillingAmount, TaxAmount
			FROM SMAgreementBillingSchedule
			WHERE SMInvoice.InvoiceType = 'A' AND SMAgreementBillingSchedule.SMInvoiceID = SMInvoice.SMInvoiceID
		) InvoiceTotals
	LEFT JOIN dbo.SMInvoiceSession ON SMInvoice.SMInvoiceID = SMInvoiceSession.SMInvoiceID
	--It is important that NOLOCK is used when reading the SMSession view because we keep transactions open
	--on the SMSession table for the time a user is working with an invoice.
	LEFT JOIN dbo.SMSession WITH (NOLOCK) ON SMInvoiceSession.SMSessionID = SMSession.SMSessionID
GO
GRANT SELECT ON  [dbo].[SMInvoiceList] TO [public]
GRANT INSERT ON  [dbo].[SMInvoiceList] TO [public]
GRANT DELETE ON  [dbo].[SMInvoiceList] TO [public]
GRANT UPDATE ON  [dbo].[SMInvoiceList] TO [public]
GRANT SELECT ON  [dbo].[SMInvoiceList] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMInvoiceList] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMInvoiceList] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMInvoiceList] TO [Viewpoint]
GO
