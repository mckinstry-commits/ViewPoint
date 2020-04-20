SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMInvoiceDetailChanges]
AS
	WITH WorkCompletedARTL_CTE
	AS
	(
		SELECT vSMWorkCompletedARTL.SMWorkCompletedID, vSMWorkCompletedARTL.SMInvoiceID, bARTL.ARCo, bARTL.ApplyMth, bARTL.ApplyTrans, bARTL.ApplyLine,
			bARTL.RecType, bARTL.[Description], bARTL.GLCo, bARTL.GLAcct, bARTL.TaxGroup, bARTL.TaxCode, bARTL.Amount, bARTL.TaxBasis, bARTL.TaxAmount, bARTL.DiscOffered, bARTL.TaxDisc
		FROM dbo.vSMWorkCompleted
			INNER JOIN dbo.vSMWorkCompletedARTL ON vSMWorkCompleted.SMWorkCompletedARTLID = vSMWorkCompletedARTL.SMWorkCompletedARTLID
			INNER JOIN dbo.bARTL ON vSMWorkCompletedARTL.ARCo = bARTL.ARCo AND vSMWorkCompletedARTL.Mth = bARTL.Mth AND vSMWorkCompletedARTL.ARTrans = bARTL.ARTrans AND vSMWorkCompletedARTL.ARLine = bARTL.ARLine
	),
	WorkCompletedInvoiceTransaction_CTE
	AS
	(
		SELECT SMWorkCompleted.SMWorkCompletedID, SMWorkCompleted.SMInvoiceID,
			COALESCE(bARCM.RecType, bARCO.RecType) RecType, CONVERT(varchar(30), SMWorkCompleted.[Description]) Description, DeriveRevenueAcct.GLCo, DeriveRevenueAcct.GLAccount, SMWorkCompleted.TaxGroup, SMWorkCompleted.TaxCode,
			ActualAmounts.PriceTotal, ActualAmounts.TaxBasis, ActualAmounts.TaxAmount, ActualAmounts.PriceTotal + ActualAmounts.TaxAmount Amount, 			 
				CASE 
					WHEN bARCO.DiscOpt = 'I' THEN CAST(ActualAmounts.PriceTotal * ActualAmounts.DiscRate AS numeric(12,2))
					ELSE 0
				END DiscOffered, 			
				CASE 
					WHEN bARCO.DiscOpt = 'I' AND bARCO.DiscTax = 'Y' THEN CAST(ActualAmounts.TaxAmount * ActualAmounts.DiscRate AS numeric(12,2)) 
					ELSE 0 
				END TaxDisc
		FROM dbo.SMWorkCompleted
			INNER JOIN dbo.vSMInvoice ON SMWorkCompleted.SMInvoiceID = vSMInvoice.SMInvoiceID	
			INNER JOIN dbo.bARCO ON vSMInvoice.ARCo = bARCO.ARCo
			INNER JOIN dbo.bARCM ON vSMInvoice.CustGroup = bARCM.CustGroup AND vSMInvoice.BillToARCustomer = bARCM.Customer
			CROSS APPLY (
				SELECT 
					CASE WHEN NoCharge = 'Y' THEN 0 ELSE ISNULL(SMWorkCompleted.PriceTotal, 0) END PriceTotal,
					CASE WHEN NoCharge = 'Y' THEN 0 ELSE ISNULL(SMWorkCompleted.TaxBasis, 0) END TaxBasis, 
					CASE WHEN NoCharge = 'Y' THEN 0 ELSE ISNULL(SMWorkCompleted.TaxAmount, 0) END TaxAmount,
					ISNULL(vSMInvoice.DiscRate, 0) DiscRate
			) ActualAmounts
			INNER JOIN dbo.vSMWorkOrderScope ON SMWorkCompleted.SMCo = vSMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = vSMWorkOrderScope.Scope
			CROSS APPLY dbo.vfSMGetWorkCompletedAccount(SMWorkCompleted.SMWorkCompletedID, 'R', CASE WHEN vSMWorkOrderScope.IsTrackingWIP = 'Y' AND vSMWorkOrderScope.IsComplete = 'N' THEN 1 ELSE 0 END) DeriveRevenueAcct
			INNER JOIN dbo.vSMWorkOrder ON vSMWorkOrderScope.SMCo = vSMWorkOrder.SMCo AND vSMWorkOrderScope.WorkOrder = vSMWorkOrder.WorkOrder
			LEFT JOIN dbo.vSMInvoiceSession ON vSMInvoice.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
		WHERE vSMInvoiceSession.VoidFlag IS NULL OR vSMInvoiceSession.VoidFlag = 'N'
	),
	WorkCompletedCurrentAndInvoice_CTE
	AS
	(
		SELECT
			ISNULL(WorkCompletedARTL_CTE.SMInvoiceID, WorkCompletedInvoiceTransaction_CTE.SMInvoiceID) SMInvoiceID,
			ISNULL(WorkCompletedARTL_CTE.SMWorkCompletedID, WorkCompletedInvoiceTransaction_CTE.SMWorkCompletedID) SMWorkCompletedID,
			WorkCompletedARTL_CTE.ARCo, WorkCompletedARTL_CTE.ApplyMth, WorkCompletedARTL_CTE.ApplyTrans, WorkCompletedARTL_CTE.ApplyLine,
			CASE
				WHEN WorkCompletedInvoiceTransaction_CTE.SMWorkCompletedID IS NULL THEN 'D' 
				WHEN WorkCompletedARTL_CTE.SMWorkCompletedID IS NULL THEN 'A'
				WHEN ChangedValues.GLCoEqual & ChangedValues.GLAcctEqual & 
					ChangedValues.TaxGroupEqual & ChangedValues.TaxCodeEqual & ChangedValues.AmountEqual &
					ChangedValues.TaxBasisEqual & ChangedValues.TaxAmountEqual
					= 0 THEN 'C'
				ELSE 'NoChange'
			END TransType,
			WorkCompletedInvoiceTransaction_CTE.RecType CurrentRecType, WorkCompletedARTL_CTE.RecType InvoicedRecType,
			WorkCompletedInvoiceTransaction_CTE.[Description] CurrentDescription, WorkCompletedARTL_CTE.[Description] InvoicedDescription,
			WorkCompletedInvoiceTransaction_CTE.GLCo CurrentGLCo, WorkCompletedARTL_CTE.GLCo InvoicedGLCo,
			WorkCompletedInvoiceTransaction_CTE.GLAccount CurrentGLAcct, WorkCompletedARTL_CTE.GLAcct InvoicedGLAcct,
			WorkCompletedInvoiceTransaction_CTE.TaxGroup CurrentTaxGroup, WorkCompletedARTL_CTE.TaxGroup InvoicedTaxGroup,
			WorkCompletedInvoiceTransaction_CTE.TaxCode CurrentTaxCode, WorkCompletedARTL_CTE.TaxCode InvoicedTaxCode,
			WorkCompletedInvoiceTransaction_CTE.Amount CurrentAmount, WorkCompletedARTL_CTE.Amount InvoicedAmount,
			WorkCompletedInvoiceTransaction_CTE.TaxBasis CurrentTaxBasis, WorkCompletedARTL_CTE.TaxBasis InvoicedTaxBasis,
			WorkCompletedInvoiceTransaction_CTE.TaxAmount CurrentTaxAmount, WorkCompletedARTL_CTE.TaxAmount InvoicedTaxAmount,
			WorkCompletedInvoiceTransaction_CTE.DiscOffered CurrentDiscOffered, WorkCompletedARTL_CTE.DiscOffered InvoicedDiscOffered,
			WorkCompletedInvoiceTransaction_CTE.TaxDisc CurrentTaxDisc, WorkCompletedARTL_CTE.TaxDisc InvoicedTaxDisc,
			ChangedValues.*
		FROM WorkCompletedARTL_CTE
			FULL JOIN WorkCompletedInvoiceTransaction_CTE ON WorkCompletedARTL_CTE.SMWorkCompletedID = WorkCompletedInvoiceTransaction_CTE.SMWorkCompletedID
			OUTER APPLY (
				SELECT
					--ReceivableType is a setup value so it is not included in the comparisons
					dbo.vfIsEqual(WorkCompletedInvoiceTransaction_CTE.GLCo, WorkCompletedARTL_CTE.GLCo) GLCoEqual,
					dbo.vfIsEqual(WorkCompletedInvoiceTransaction_CTE.GLAccount, WorkCompletedARTL_CTE.GLAcct) GLAcctEqual,
					dbo.vfIsEqual(WorkCompletedInvoiceTransaction_CTE.TaxGroup, WorkCompletedARTL_CTE.TaxGroup) TaxGroupEqual,
					dbo.vfIsEqual(WorkCompletedInvoiceTransaction_CTE.TaxCode, WorkCompletedARTL_CTE.TaxCode) TaxCodeEqual,
					dbo.vfIsEqual(WorkCompletedInvoiceTransaction_CTE.Amount, WorkCompletedARTL_CTE.Amount) AmountEqual,
					dbo.vfIsEqual(WorkCompletedInvoiceTransaction_CTE.TaxBasis, WorkCompletedARTL_CTE.TaxBasis) TaxBasisEqual,
					dbo.vfIsEqual(WorkCompletedInvoiceTransaction_CTE.TaxAmount, WorkCompletedARTL_CTE.TaxAmount) TaxAmountEqual
				WHERE WorkCompletedARTL_CTE.SMWorkCompletedID = WorkCompletedInvoiceTransaction_CTE.SMWorkCompletedID --Only compare changes. Don't worry about add/delete.
			) ChangedValues
	)
	SELECT
		WorkCompletedCurrentAndInvoice_CTE.*,
		vSMInvoiceSession.SMSessionID
	FROM dbo.vSMInvoice
		INNER JOIN WorkCompletedCurrentAndInvoice_CTE ON vSMInvoice.SMInvoiceID = WorkCompletedCurrentAndInvoice_CTE.SMInvoiceID
		LEFT JOIN dbo.vSMInvoiceSession ON vSMInvoice.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
GO
GRANT SELECT ON  [dbo].[SMInvoiceDetailChanges] TO [public]
GRANT INSERT ON  [dbo].[SMInvoiceDetailChanges] TO [public]
GRANT DELETE ON  [dbo].[SMInvoiceDetailChanges] TO [public]
GRANT UPDATE ON  [dbo].[SMInvoiceDetailChanges] TO [public]
GO
