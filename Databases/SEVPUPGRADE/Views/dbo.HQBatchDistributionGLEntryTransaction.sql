SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[HQBatchDistributionGLEntryTransaction]
AS
SELECT vHQBatchDistribution.Co, vHQBatchDistribution.Mth, vHQBatchDistribution.BatchId, vJCCostEntry.*,
	JCCostEntryTransaction.value('./@JCCostTransaction','int') JCCostTransaction, JCCostEntryTransaction.value('./@GLEntryID','bigint') GLEntryID, JCCostEntryTransaction.value('./@GLTransaction','int') GLTransaction
FROM dbo.vHQBatchDistribution
	INNER JOIN dbo.vJCCostEntry ON vHQBatchDistribution.HQBatchDistributionID = vJCCostEntry.HQBatchDistributionID
	CROSS APPLY DistributionXML.nodes('/JCCostEntryTransaction') JCCostEntryTransactions(JCCostEntryTransaction)
GO
GRANT SELECT ON  [dbo].[HQBatchDistributionGLEntryTransaction] TO [public]
GRANT INSERT ON  [dbo].[HQBatchDistributionGLEntryTransaction] TO [public]
GRANT DELETE ON  [dbo].[HQBatchDistributionGLEntryTransaction] TO [public]
GRANT UPDATE ON  [dbo].[HQBatchDistributionGLEntryTransaction] TO [public]
GO
