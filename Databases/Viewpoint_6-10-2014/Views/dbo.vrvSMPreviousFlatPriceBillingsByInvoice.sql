SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************************************************
* Author: Dan Koslicki
* Created: 06/27/13
*
* Purpose: When a flat price scope is partially billed, we need to be able to 
*			get that previously billed amount in various reports. This view 
*			is intended to aggregate the previous billings for a Flat Price Scope
*			that has been partially billed. 
*
**************************************************************************/

CREATE VIEW [dbo].[vrvSMPreviousFlatPriceBillingsByInvoice] 
AS 

	SELECT		WOS.SMCo, 
				WOS.WorkOrder, 
				WOS.Scope, 
				ID.Invoice, 
				ID.InvoiceDetail, 
				ID.WorkCompleted, 
				InvoiceLineSum.Amount, -- Invoice Amount, used as a "Previously Billed" amount 
				InvoiceLineSum.TaxAmount -- Invoice Tax Amount


	FROM		SMWorkOrderScope WOS

	INNER JOIN	SMWorkOrder WO
		ON 		WO.SMCo = WOS.SMCo
		AND 	WO.WorkOrder = WOS.WorkOrder

	INNER JOIN	SMInvoiceDetail	ID
		ON		ID.SMCo	= WOS.SMCo
		AND 	ID.WorkOrder	= WOS.WorkOrder 
		AND		ID.Scope	= WOS.Scope 

	CROSS APPLY (SELECT	SUM(SMInvoiceLine.Amount) AS Amount, 
				SUM(SMInvoiceLine.TaxAmount) AS TaxAmount
		FROM		SMInvoiceLine

		WHERE		ID.SMCo 	= SMInvoiceLine.SMCo
			AND 	ID.Invoice 	= SMInvoiceLine.Invoice
			AND 	ID.InvoiceDetail = SMInvoiceLine.InvoiceDetail) InvoiceLineSum

	CROSS APPLY (SELECT 	SUM(IL.Amount) - InvoiceLineSum.Amount AS PreviouslyBilled
		FROM		SMInvoiceLine IL

		INNER JOIN 	SMInvoiceDetail ID
			ON	ID.SMCo = IL.SMCo
			AND	ID.Invoice = IL.Invoice
			AND	ID.InvoiceDetail = IL.InvoiceDetail

		WHERE		WOS.SMCo = IL.SMCo
			AND	WOS.WorkOrder = ID.WorkOrder
			AND	WOS.Scope = ID.Scope) PreviousBillingSum
GO
GRANT SELECT ON  [dbo].[vrvSMPreviousFlatPriceBillingsByInvoice] TO [public]
GRANT INSERT ON  [dbo].[vrvSMPreviousFlatPriceBillingsByInvoice] TO [public]
GRANT DELETE ON  [dbo].[vrvSMPreviousFlatPriceBillingsByInvoice] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMPreviousFlatPriceBillingsByInvoice] TO [public]
GRANT SELECT ON  [dbo].[vrvSMPreviousFlatPriceBillingsByInvoice] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMPreviousFlatPriceBillingsByInvoice] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMPreviousFlatPriceBillingsByInvoice] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMPreviousFlatPriceBillingsByInvoice] TO [Viewpoint]
GO
