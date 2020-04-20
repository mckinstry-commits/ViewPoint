SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/31/11
-- Description: Generates the GL Distributions needed for transferring GL to a new account for a PO Item Line
-- =============================================
CREATE FUNCTION [dbo].[vfAPTransactionBuildTransferringEntries]
(	
	@POCo bCompany, @PO varchar(30), @POItem bItem, @POItemLine int, @NewGLCo bCompany, @NewGLAcct bGLAcct, @BreakoutEntries bit
)
RETURNS TABLE 
AS
RETURN 
(
	WITH APTransactionGLEntriesCTE AS
	(
		SELECT *
		FROM dbo.vfAPTransactionGetCurrentCostGLEntries(@POCo, @PO, @POItem, @POItemLine) GLDistributions
	),
	POReceiptBalancedEntriesCTE AS
	(
		SELECT APTLGLID
		FROM APTransactionGLEntriesCTE
		GROUP BY APTLGLID, GLCo, GLAccount
		HAVING SUM(Amount) <> 0
	),
	GLEntriesToReverseCTE AS
	(
		SELECT APTransactionGLEntriesCTE.*, CASE WHEN @NewGLCo <> APTransactionGLEntriesCTE.GLCo THEN 1 ELSE 0 END AS RequiresInterCompany, CASE WHEN bGLIA.KeyID IS NOT NULL THEN 1 ELSE 0 END AS InterCompanyAvailable, ARGLAcct, APGLAcct 
		FROM APTransactionGLEntriesCTE
			LEFT JOIN dbo.bGLIA ON APTransactionGLEntriesCTE.GLCo = bGLIA.ARGLCo AND @NewGLCo = bGLIA.APGLCo
		WHERE (@NewGLCo <> GLCo OR @NewGLAcct <> GLAccount) AND APTLGLID IN (SELECT APTLGLID FROM POReceiptBalancedEntriesCTE)
	),
	GeneratedEntriesCTE AS
	(
		SELECT APTLGLID, IsPOReceiptGLEntry, GeneratedEntries.*
		FROM GLEntriesToReverseCTE
			CROSS APPLY (
				SELECT 1 AS GLTransaction, @NewGLCo AS GLCo, @NewGLAcct AS GLAccount, GLEntriesToReverseCTE.Amount
				UNION ALL
				SELECT 2, GLCo, GLAccount, -(GLEntriesToReverseCTE.Amount)
				UNION ALL 
				SELECT 3, GLCo, ARGLAcct, GLEntriesToReverseCTE.Amount
				WHERE RequiresInterCompany = 1
				UNION ALL 
				SELECT 4, @NewGLCo, APGLAcct, -(GLEntriesToReverseCTE.Amount)
				WHERE RequiresInterCompany = 1) GeneratedEntries
		WHERE @BreakoutEntries = 1
	)
	SELECT GLEntriesToReverseCTE.APTLGLID, GLEntriesToReverseCTE.IsPOReceiptGLEntry, GLEntriesToReverseCTE.RequiresInterCompany, GLEntriesToReverseCTE.InterCompanyAvailable, GLEntriesToReverseCTE.GLCo AS CurrentGLCo, GeneratedEntriesCTE.GLTransaction, GeneratedEntriesCTE.GLCo, GeneratedEntriesCTE.GLAccount, GeneratedEntriesCTE.Amount, GLEntriesToReverseCTE.[Description]
	FROM GLEntriesToReverseCTE
		LEFT JOIN GeneratedEntriesCTE ON GLEntriesToReverseCTE.APTLGLID = GeneratedEntriesCTE.APTLGLID AND GLEntriesToReverseCTE.IsPOReceiptGLEntry = GeneratedEntriesCTE.IsPOReceiptGLEntry
)

GO
GRANT SELECT ON  [dbo].[vfAPTransactionBuildTransferringEntries] TO [public]
GO
