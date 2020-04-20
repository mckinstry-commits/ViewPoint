SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMInvoiceListDetailLine]
AS
	SELECT SMInvoiceListDetail.*,
		vSMInvoiceLine.InvoiceLine, 
		vSMInvoiceLine.NoCharge, vSMInvoiceLine.[Description],
		vSMInvoiceLine.GLCo, vSMInvoiceLine.GLAccount, vSMInvoiceLine.Amount,
		vSMInvoiceLine.TaxGroup, vSMInvoiceLine.TaxCode, vSMInvoiceLine.TaxBasis, vSMInvoiceLine.TaxAmount,
		vSMInvoiceLine.DiscountOffered, vSMInvoiceLine.TaxDiscount,
		vSMInvoiceLine.BatchLine,

		InvoicedLine.NoCharge InvoicedNoCharge, InvoicedLine.[Description] InvoicedDescription,
		InvoicedLine.GLCo InvoicedGLCo, InvoicedLine.GLAccount InvoicedGLAccount, InvoicedLine.Amount InvoicedAmount,
		InvoicedLine.TaxGroup InvoicedTaxGroup, InvoicedLine.TaxCode InvoicedTaxCode, InvoicedLine.TaxBasis InvoicedTaxBasis, InvoicedLine.TaxAmount InvoicedTaxAmount,
		InvoicedLine.DiscountOffered InvoicedDiscountOffered, InvoicedLine.TaxDiscount InvoicedTaxDiscount,
		InvoicedLine.BatchLine InvoicedBatchLine,

		bARTL.Mth ARMth, bARTL.ARTrans, bARTL.ARLine,
		CASE
			WHEN
				SMInvoiceListDetail.Invoiced = 0 OR
				SMInvoiceListDetail.VoidFlag = 'Y' OR
				SMInvoiceListDetail.IsRemoved = 1 OR
				(
					SMInvoiceListDetail.VoidDate IS NULL AND
					(
						InvoicedLine.SMInvoiceLineID IS NULL OR
						dbo.vfIsEqual(vSMInvoiceLine.NoCharge, InvoicedLine.NoCharge) = 0 OR
						(
							InvoicedLine.NoCharge = 'N' AND
							dbo.vfIsEqual(vSMInvoiceLine.GLCo, InvoicedLine.GLCo) &
							dbo.vfIsEqual(vSMInvoiceLine.GLAccount, InvoicedLine.GLAccount) &
							dbo.vfIsEqual(vSMInvoiceLine.Amount, InvoicedLine.Amount) &
							dbo.vfIsEqual(vSMInvoiceLine.TaxGroup, InvoicedLine.TaxGroup) &
							dbo.vfIsEqual(vSMInvoiceLine.TaxCode, InvoicedLine.TaxCode) &
							dbo.vfIsEqual(vSMInvoiceLine.TaxBasis, InvoicedLine.TaxBasis) &
							dbo.vfIsEqual(vSMInvoiceLine.TaxAmount, InvoicedLine.TaxAmount)
							= 0
						)
					)
				)
			THEN 1
			ELSE 0
		END ChangesMade
	FROM dbo.SMInvoiceListDetail --Make sure to leave a space so that the view gets refreshed
		LEFT JOIN dbo.vSMInvoiceLine ON SMInvoiceListDetail.SMCo = vSMInvoiceLine.SMCo AND SMInvoiceListDetail.Invoice = vSMInvoiceLine.Invoice AND SMInvoiceListDetail.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
		LEFT JOIN dbo.bARTL ON vSMInvoiceLine.LastPostedARCo = bARTL.ARCo AND vSMInvoiceLine.LastPostedARMth = bARTL.Mth AND vSMInvoiceLine.LastPostedARTrans = bARTL.ARTrans AND vSMInvoiceLine.LastPostedARLine = bARTL.ARLine
		LEFT JOIN dbo.vSMInvoiceLine InvoicedLine ON vSMInvoiceLine.SMCo = InvoicedLine.SMCo AND vSMInvoiceLine.InvoiceLine = InvoicedLine.InvoiceLine AND InvoicedLine.Invoiced = 1
		
GO
GRANT SELECT ON  [dbo].[SMInvoiceListDetailLine] TO [public]
GRANT INSERT ON  [dbo].[SMInvoiceListDetailLine] TO [public]
GRANT DELETE ON  [dbo].[SMInvoiceListDetailLine] TO [public]
GRANT UPDATE ON  [dbo].[SMInvoiceListDetailLine] TO [public]
GRANT SELECT ON  [dbo].[SMInvoiceListDetailLine] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMInvoiceListDetailLine] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMInvoiceListDetailLine] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMInvoiceListDetailLine] TO [Viewpoint]
GO
