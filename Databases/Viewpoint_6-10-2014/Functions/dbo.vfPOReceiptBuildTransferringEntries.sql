SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/31/11
-- Description: Generates the GL Distributions needed for transferring GL to a new account for a PO Item Line
-- =============================================
CREATE FUNCTION [dbo].[vfPOReceiptBuildTransferringEntries]
(	
	@POCo bCompany, @PO varchar(30), @POItem bItem, @POItemLine int, @NewGLCo bCompany, @NewGLAcct bGLAcct, @BreakoutEntries bit
)
RETURNS TABLE 
AS
RETURN 
(
	WITH POReceiptGLEntriesCTE AS
	(
		SELECT GLDistributions.*, CASE WHEN @NewGLCo <> GLDistributions.GLCo THEN 1 ELSE 0 END AS RequiresInterCompany, CASE WHEN bGLIA.KeyID IS NOT NULL THEN 1 ELSE 0 END AS InterCompanyAvailable, ARGLCo, ARGLAcct, APGLCo, APGLAcct
		FROM dbo.vfPOReceiptGetCurrentCostGLEntries(@POCo, @PO, @POItem, @POItemLine) GLDistributions
			LEFT JOIN dbo.bGLIA ON GLDistributions.GLCo = bGLIA.ARGLCo AND @NewGLCo = bGLIA.APGLCo
		WHERE @NewGLCo <> GLDistributions.GLCo OR @NewGLAcct <> GLDistributions.GLAccount
	),
	GeneratedEntriesCTE AS
	(
		SELECT PORDGLID, GeneratedEntries.*
		FROM POReceiptGLEntriesCTE
			CROSS APPLY (
				SELECT 1 AS GLTransaction, @NewGLCo AS GLCo, @NewGLAcct AS GLAccount, POReceiptGLEntriesCTE.Amount
				UNION ALL
				SELECT 2, GLCo, GLAccount, -(POReceiptGLEntriesCTE.Amount)
				UNION ALL 
				SELECT 3, ARGLCo, ARGLAcct, POReceiptGLEntriesCTE.Amount
				WHERE GLCo <> @NewGLCo
				UNION ALL 
				SELECT 4, APGLCo, APGLAcct, -(POReceiptGLEntriesCTE.Amount)
				WHERE GLCo <> @NewGLCo) GeneratedEntries
		WHERE @BreakoutEntries = 1
	)
	SELECT POReceiptGLEntriesCTE.PORDGLID, POReceiptGLEntriesCTE.RequiresInterCompany, POReceiptGLEntriesCTE.InterCompanyAvailable, POReceiptGLEntriesCTE.GLCo AS CurrentGLCo, GeneratedEntriesCTE.GLTransaction, GeneratedEntriesCTE.GLCo, GeneratedEntriesCTE.GLAccount, GeneratedEntriesCTE.Amount, POReceiptGLEntriesCTE.[Description]
	FROM POReceiptGLEntriesCTE
		LEFT JOIN GeneratedEntriesCTE ON POReceiptGLEntriesCTE.PORDGLID = GeneratedEntriesCTE.PORDGLID
)

GO
GRANT SELECT ON  [dbo].[vfPOReceiptBuildTransferringEntries] TO [public]
GO
