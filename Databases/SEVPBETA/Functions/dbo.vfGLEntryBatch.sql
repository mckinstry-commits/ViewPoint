SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/14/12
-- Description:	Builds the entries that will be used for posting Job Cost records
-- =============================================
CREATE FUNCTION [dbo].[vfGLEntryBatch]
(	
	@GLEntrySource bSource, @BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT vHQBatchDistribution.InterfacingCo, vHQBatchDistribution.IsReversing, vGLEntry.*, vGLEntryBatchInterfacing.InterfaceLevel, vGLEntryBatchInterfacing.Journal, vGLEntryBatchInterfacing.SummaryDescription
	FROM dbo.vHQBatchDistribution
		INNER JOIN dbo.vGLEntry ON vHQBatchDistribution.HQBatchDistributionID = vGLEntry.HQBatchDistributionID
		LEFT JOIN dbo.vGLEntryBatchInterfacing ON vGLEntry.[Source] = vGLEntryBatchInterfacing.GLEntrySource AND vHQBatchDistribution.Co = vGLEntryBatchInterfacing.BatchCo AND vHQBatchDistribution.Mth = vGLEntryBatchInterfacing.BatchMth AND vHQBatchDistribution.BatchId = vGLEntryBatchInterfacing.BatchId AND vHQBatchDistribution.InterfacingCo = vGLEntryBatchInterfacing.InterfacingCo
	WHERE vHQBatchDistribution.Co = @BatchCo AND vHQBatchDistribution.Mth = @BatchMth AND vHQBatchDistribution.BatchId = @BatchId AND vGLEntry.[Source] = @GLEntrySource
)
GO
GRANT SELECT ON  [dbo].[vfGLEntryBatch] TO [public]
GO
