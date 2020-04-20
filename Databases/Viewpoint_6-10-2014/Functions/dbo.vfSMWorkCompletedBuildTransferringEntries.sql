SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/8/11
-- Description: Generates the GL Distributions needed for transferring GL to a new account for a work completed line
-- Modified:	JVH 6/24/13 - TFS-53341	Modified to support SM Flat Price Billing
-- =============================================
CREATE FUNCTION [dbo].[vfSMWorkCompletedBuildTransferringEntries]
(	
	@SMWorkCompletedID bigint, @TransferType char(1), @NewGLCo bCompany, @NewGLAccount bGLAcct, @BreakoutEntries bit
)
RETURNS TABLE 
AS
RETURN 
(
	WITH WorkCompletedGLEntryCTE AS
	(
		SELECT GLCo, GLAccount, Amount, [Description], CASE WHEN @NewGLCo <> vSMGLDetailTransaction.GLCo THEN 1 ELSE 0 END AS RequiresInterCompany, CASE WHEN bGLIA.KeyID IS NOT NULL THEN 1 ELSE 0 END AS InterCompanyAvailable, ARGLAcct, APGLAcct 
		FROM dbo.vSMWorkCompletedGL
			INNER JOIN dbo.vSMGLDetailTransaction ON CASE @TransferType WHEN 'C' THEN vSMWorkCompletedGL.CostGLDetailTransactionID WHEN 'R' THEN vSMWorkCompletedGL.RevenueGLDetailTransactionID END = vSMGLDetailTransaction.SMGLDetailTransactionID
			LEFT JOIN dbo.bGLIA ON vSMGLDetailTransaction.GLCo = bGLIA.ARGLCo AND @NewGLCo = bGLIA.APGLCo
		WHERE SMWorkCompletedID = @SMWorkCompletedID AND (GLCo <> @NewGLCo OR GLAccount <> @NewGLAccount)
	),
	GeneratedEntriesCTE AS
	(
		SELECT GeneratedEntries.*
		FROM WorkCompletedGLEntryCTE
			CROSS APPLY (
				SELECT 1 AS GLTransaction, @NewGLCo AS GLCo, @NewGLAccount AS GLAccount, 'S' GLAccountSubType, WorkCompletedGLEntryCTE.Amount
				UNION ALL
				SELECT 2, GLCo, GLAccount, 'S', -(WorkCompletedGLEntryCTE.Amount)
				UNION ALL 
				SELECT 3, GLCo, ARGLAcct, 'R', WorkCompletedGLEntryCTE.Amount
				WHERE RequiresInterCompany = 1
				UNION ALL 
				SELECT 4, @NewGLCo, APGLAcct, 'P', -(WorkCompletedGLEntryCTE.Amount)
				WHERE RequiresInterCompany = 1) GeneratedEntries
	)
	SELECT WorkCompletedGLEntryCTE.GLCo AS CurrentGLCo, WorkCompletedGLEntryCTE.RequiresInterCompany, WorkCompletedGLEntryCTE.InterCompanyAvailable, GeneratedEntriesCTE.*, WorkCompletedGLEntryCTE.[Description]
	FROM WorkCompletedGLEntryCTE
		LEFT JOIN GeneratedEntriesCTE ON @BreakoutEntries = 1
)

GO
GRANT SELECT ON  [dbo].[vfSMWorkCompletedBuildTransferringEntries] TO [public]
GO
