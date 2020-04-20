SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/30/11
-- Description: Returns the Current Cost GL Entry Transactions that represent the transactions that were lasted posted to GL through AP Transaction Entry.
-- =============================================
CREATE FUNCTION [dbo].[vfAPTransactionGetCurrentCostGLEntries]
(	
	@POCo bCompany, @PO varchar(30), @POItem bItem, @POItemLine int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT vAPTLGL.APTLGLID, APTLGLEntries.IsPOReceiptGLEntry, vGLEntryTransaction.*
	FROM dbo.bAPTL
		INNER JOIN dbo.vAPTLGL ON bAPTL.APCo = vAPTLGL.APCo AND bAPTL.Mth = vAPTLGL.Mth AND bAPTL.APTrans = vAPTLGL.APTrans AND bAPTL.APLine = vAPTLGL.APLine
		LEFT JOIN dbo.vPORDGLEntry ON vAPTLGL.CurrentPOReceiptGLEntryID = vPORDGLEntry.GLEntryID
		LEFT JOIN dbo.vAPTLGLEntry ON vAPTLGL.CurrentAPInvoiceCostGLEntryID = vAPTLGLEntry.GLEntryID
		CROSS APPLY (
			SELECT 1 AS IsPOReceiptGLEntry, vPORDGLEntry.GLEntryID, vPORDGLEntry.GLTransactionForPOItemLineAccount AS GLTransactionForLineAccount
			UNION ALL
			SELECT 0 AS IsPOReceiptGLEntry, vAPTLGLEntry.GLEntryID, vAPTLGLEntry.GLTransactionForAPTransactionLineAccount) APTLGLEntries
		INNER JOIN dbo.vGLEntryTransaction ON APTLGLEntries.GLEntryID = vGLEntryTransaction.GLEntryID AND APTLGLEntries.GLTransactionForLineAccount = vGLEntryTransaction.GLTransaction
	WHERE bAPTL.APCo = @POCo AND bAPTL.PO = @PO AND bAPTL.POItem = @POItem AND bAPTL.POItemLine = @POItemLine
)

GO
GRANT SELECT ON  [dbo].[vfAPTransactionGetCurrentCostGLEntries] TO [public]
GO
