SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/30/11
-- Description: Returns the Current Cost GL Entry Transactions that represent the transactions that were lasted posted to GL through PO Receipts.
-- =============================================
CREATE FUNCTION [dbo].[vfPOReceiptGetCurrentCostGLEntries]
(	
	@POCo bCompany, @PO varchar(30), @POItem bItem, @POItemLine int
)
RETURNS TABLE 
AS
RETURN 
(
	WITH POItemLineDistributionsCTE AS
	(
		SELECT vPORDGL.PORDGLID, vGLEntryTransaction.*
		FROM dbo.bPORD
			INNER JOIN dbo.vPORDGL ON bPORD.POCo = vPORDGL.POCo AND bPORD.Mth = vPORDGL.Mth AND bPORD.POTrans = vPORDGL.POTrans
			INNER JOIN dbo.vPORDGLEntry ON vPORDGL.CurrentCostGLEntryID = vPORDGLEntry.GLEntryID
			INNER JOIN dbo.vGLEntryTransaction ON vPORDGL.CurrentCostGLEntryID = vGLEntryTransaction.GLEntryID AND vPORDGLEntry.GLTransactionForPOItemLineAccount = vGLEntryTransaction.GLTransaction
		WHERE bPORD.POCo = @POCo AND bPORD.PO = @PO AND bPORD.POItem = @POItem AND bPORD.POItemLine = @POItemLine
	),
	LastDistributionCTE AS
	(
		SELECT TOP 1 PORDGLID, GLCo, GLAccount, Amount
		FROM POItemLineDistributionsCTE
		ORDER BY PORDGLID DESC
	),
	DistributionsBalanceCTE AS
	(
		SELECT CASE WHEN EXISTS(
			SELECT 1
			FROM
				(SELECT GLCo, GLAccount, Amount
				FROM POItemLineDistributionsCTE
				UNION ALL
				SELECT GLCo, GLAccount, -Amount
				FROM LastDistributionCTE)  Distributions
			GROUP BY GLCo, GLAccount
			HAVING SUM(Amount) <> 0) THEN 0 ELSE 1 END DistributionsBalance
	)
	--If the last receipt entered has a total that matches the total when summed up for all receipts and it is for the same gl account then we only need to move the cost for the last receipt entry.
	--This is because SM never does change or delete records for PO receipts but always backs out what it put in as an add batch entry and adds another add batch entry for the current receipt amount.
	SELECT POItemLineDistributionsCTE.*
	FROM POItemLineDistributionsCTE
		CROSS APPLY (SELECT * FROM LastDistributionCTE) LastDistribution
		CROSS APPLY (SELECT * FROM DistributionsBalanceCTE) DistributionsBalance
	WHERE DistributionsBalance.DistributionsBalance = 0
		OR POItemLineDistributionsCTE.PORDGLID = LastDistribution.PORDGLID
)
GO
GRANT SELECT ON  [dbo].[vfPOReceiptGetCurrentCostGLEntries] TO [public]
GO
